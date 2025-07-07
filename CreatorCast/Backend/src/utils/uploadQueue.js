const Bull = require('bull');
const redis = require('redis');
const admin = require('firebase-admin');
const { uploadToPlatform } = require('../services/uploadService');

// Create Redis client
const redisClient = redis.createClient({
  host: process.env.REDIS_HOST || 'localhost',
  port: process.env.REDIS_PORT || 6379,
  password: process.env.REDIS_PASSWORD
});

// Create upload queue
const uploadQueue = new Bull('upload processing', {
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD
  }
});

const db = admin.firestore();

// Process upload jobs
uploadQueue.process('process-upload', 5, async (job) => {
  const { uploadId, userId, videoId, platforms } = job.data;
  
  try {
    console.log(`Processing upload: ${uploadId}`);
    
    // Update upload status to processing
    await db.collection('uploads').doc(uploadId).update({
      status: 'processing',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Get video data
    const videoDoc = await db.collection('videos').doc(videoId).get();
    if (!videoDoc.exists) {
      throw new Error('Video not found');
    }

    const videoData = videoDoc.data();
    const results = [];
    let completedCount = 0;

    // Process each platform
    for (const platformConfig of platforms) {
      try {
        console.log(`Uploading to ${platformConfig.platform}`);
        
        // Update progress
        await updateUploadProgress(uploadId, completedCount / platforms.length);

        // Upload to platform
        const result = await uploadToPlatform(videoData, platformConfig);
        results.push(result);

        if (result.success) {
          completedCount++;
        }

        // Update progress
        await updateUploadProgress(uploadId, completedCount / platforms.length);

      } catch (error) {
        console.error(`Failed to upload to ${platformConfig.platform}:`, error);
        results.push({
          platform: platformConfig.platform,
          success: false,
          error: error.message
        });
      }
    }

    // Determine final status
    const successCount = results.filter(r => r.success).length;
    const finalStatus = successCount === platforms.length ? 'completed' : 
                       successCount > 0 ? 'partial' : 'failed';

    // Update upload with final results
    await db.collection('uploads').doc(uploadId).update({
      status: finalStatus,
      progress: 1.0,
      results: results,
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    console.log(`Upload ${uploadId} completed with status: ${finalStatus}`);
    
    return {
      uploadId,
      status: finalStatus,
      results
    };

  } catch (error) {
    console.error(`Upload ${uploadId} failed:`, error);
    
    // Update upload status to failed
    await db.collection('uploads').doc(uploadId).update({
      status: 'failed',
      error: error.message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    throw error;
  }
});

// Handle job completion
uploadQueue.on('completed', (job, result) => {
  console.log(`Job ${job.id} completed with result:`, result);
});

// Handle job failure
uploadQueue.on('failed', (job, err) => {
  console.error(`Job ${job.id} failed:`, err);
});

// Handle job progress
uploadQueue.on('progress', (job, progress) => {
  console.log(`Job ${job.id} progress: ${progress}%`);
});

// Utility function to update upload progress
async function updateUploadProgress(uploadId, progress) {
  try {
    await db.collection('uploads').doc(uploadId).update({
      progress: progress,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  } catch (error) {
    console.error('Failed to update upload progress:', error);
  }
}

// Clean up completed jobs periodically
setInterval(async () => {
  try {
    await uploadQueue.clean(24 * 60 * 60 * 1000, 'completed'); // Clean completed jobs older than 24 hours
    await uploadQueue.clean(7 * 24 * 60 * 60 * 1000, 'failed'); // Clean failed jobs older than 7 days
  } catch (error) {
    console.error('Failed to clean queue:', error);
  }
}, 60 * 60 * 1000); // Run every hour

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Closing upload queue...');
  await uploadQueue.close();
  process.exit(0);
});

module.exports = uploadQueue;