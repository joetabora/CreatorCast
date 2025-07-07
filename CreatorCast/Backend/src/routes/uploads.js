const express = require('express');
const admin = require('firebase-admin');
const { body, validationResult } = require('express-validator');
const uploadQueue = require('../utils/uploadQueue');
const { uploadToPlatform } = require('../services/uploadService');

const router = express.Router();
const db = admin.firestore();

// Start upload to multiple platforms
router.post('/start', [
  body('videoId').isString().notEmpty(),
  body('platforms').isArray().notEmpty()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { videoId, platforms } = req.body;
    const userId = req.user.userId;

    // Verify video exists and belongs to user
    const videoDoc = await db.collection('videos').doc(videoId).get();
    if (!videoDoc.exists || videoDoc.data().userId !== userId) {
      return res.status(404).json({
        success: false,
        error: 'Video not found'
      });
    }

    // Create upload record
    const uploadData = {
      userId,
      videoId,
      platforms,
      status: 'pending',
      progress: 0,
      results: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const uploadRef = await db.collection('uploads').add(uploadData);
    const uploadId = uploadRef.id;

    // Add to upload queue
    await uploadQueue.add('process-upload', {
      uploadId,
      userId,
      videoId,
      platforms
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000
      }
    });

    res.status(201).json({
      success: true,
      uploadId,
      message: 'Upload started successfully'
    });

  } catch (error) {
    console.error('Upload start error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Get upload status
router.get('/:uploadId/status', async (req, res) => {
  try {
    const { uploadId } = req.params;
    const userId = req.user.userId;

    const uploadDoc = await db.collection('uploads').doc(uploadId).get();
    if (!uploadDoc.exists || uploadDoc.data().userId !== userId) {
      return res.status(404).json({
        success: false,
        error: 'Upload not found'
      });
    }

    const uploadData = uploadDoc.data();
    
    res.json({
      success: true,
      upload: {
        id: uploadId,
        ...uploadData,
        createdAt: uploadData.createdAt?.toDate(),
        updatedAt: uploadData.updatedAt?.toDate()
      }
    });

  } catch (error) {
    console.error('Get upload status error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Get all uploads for user
router.get('/', async (req, res) => {
  try {
    const userId = req.user.userId;
    const { status, limit = 50, offset = 0 } = req.query;

    let query = db.collection('uploads').where('userId', '==', userId);
    
    if (status) {
      query = query.where('status', '==', status);
    }

    const uploadsSnapshot = await query
      .orderBy('createdAt', 'desc')
      .limit(parseInt(limit))
      .offset(parseInt(offset))
      .get();

    const uploads = uploadsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate()
    }));

    res.json({
      success: true,
      uploads,
      count: uploads.length,
      hasMore: uploads.length === parseInt(limit)
    });

  } catch (error) {
    console.error('Get uploads error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Cancel upload
router.post('/:uploadId/cancel', async (req, res) => {
  try {
    const { uploadId } = req.params;
    const userId = req.user.userId;

    const uploadDoc = await db.collection('uploads').doc(uploadId).get();
    if (!uploadDoc.exists || uploadDoc.data().userId !== userId) {
      return res.status(404).json({
        success: false,
        error: 'Upload not found'
      });
    }

    const uploadData = uploadDoc.data();
    
    // Only allow cancellation if upload is in progress
    if (!['pending', 'processing'].includes(uploadData.status)) {
      return res.status(400).json({
        success: false,
        error: 'Upload cannot be cancelled'
      });
    }

    // Update upload status
    await uploadDoc.ref.update({
      status: 'cancelled',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // TODO: Cancel actual upload jobs in queue
    
    res.json({
      success: true,
      message: 'Upload cancelled successfully'
    });

  } catch (error) {
    console.error('Cancel upload error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Retry failed upload
router.post('/:uploadId/retry', async (req, res) => {
  try {
    const { uploadId } = req.params;
    const userId = req.user.userId;

    const uploadDoc = await db.collection('uploads').doc(uploadId).get();
    if (!uploadDoc.exists || uploadDoc.data().userId !== userId) {
      return res.status(404).json({
        success: false,
        error: 'Upload not found'
      });
    }

    const uploadData = uploadDoc.data();
    
    // Only allow retry if upload failed
    if (uploadData.status !== 'failed') {
      return res.status(400).json({
        success: false,
        error: 'Upload is not in failed state'
      });
    }

    // Reset upload status
    await uploadDoc.ref.update({
      status: 'pending',
      progress: 0,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Re-add to queue
    await uploadQueue.add('process-upload', {
      uploadId,
      userId: uploadData.userId,
      videoId: uploadData.videoId,
      platforms: uploadData.platforms
    }, {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000
      }
    });

    res.json({
      success: true,
      message: 'Upload retry started successfully'
    });

  } catch (error) {
    console.error('Retry upload error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

// Schedule upload
router.post('/schedule', [
  body('videoId').isString().notEmpty(),
  body('platforms').isArray().notEmpty(),
  body('scheduledTime').isISO8601().toDate()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { videoId, platforms, scheduledTime } = req.body;
    const userId = req.user.userId;

    // Verify video exists and belongs to user
    const videoDoc = await db.collection('videos').doc(videoId).get();
    if (!videoDoc.exists || videoDoc.data().userId !== userId) {
      return res.status(404).json({
        success: false,
        error: 'Video not found'
      });
    }

    // Create scheduled upload record
    const uploadData = {
      userId,
      videoId,
      platforms,
      status: 'scheduled',
      scheduledTime: admin.firestore.Timestamp.fromDate(scheduledTime),
      progress: 0,
      results: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };

    const uploadRef = await db.collection('uploads').add(uploadData);
    const uploadId = uploadRef.id;

    // Add to scheduled queue
    const delay = scheduledTime.getTime() - Date.now();
    await uploadQueue.add('process-upload', {
      uploadId,
      userId,
      videoId,
      platforms
    }, {
      delay: Math.max(0, delay),
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 2000
      }
    });

    res.status(201).json({
      success: true,
      uploadId,
      scheduledTime,
      message: 'Upload scheduled successfully'
    });

  } catch (error) {
    console.error('Schedule upload error:', error);
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

module.exports = router;