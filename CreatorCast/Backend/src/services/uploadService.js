const axios = require('axios');
const fs = require('fs');
const FormData = require('form-data');
const { google } = require('googleapis');
const admin = require('firebase-admin');

const db = admin.firestore();

// Platform upload implementations
const platformUploaders = {
  youtube: uploadToYouTube,
  tiktok: uploadToTikTok,
  instagram: uploadToInstagram,
  facebook: uploadToFacebook,
  twitter: uploadToTwitter
};

// Main upload function
async function uploadToPlatform(videoData, platformConfig) {
  const { platform } = platformConfig;
  const uploader = platformUploaders[platform];
  
  if (!uploader) {
    throw new Error(`Unsupported platform: ${platform}`);
  }

  try {
    const result = await uploader(videoData, platformConfig);
    return {
      platform,
      success: true,
      ...result
    };
  } catch (error) {
    console.error(`Upload to ${platform} failed:`, error);
    return {
      platform,
      success: false,
      error: error.message
    };
  }
}

// YouTube upload implementation
async function uploadToYouTube(videoData, platformConfig) {
  const { userId } = videoData;
  
  // Get user's YouTube access token
  const tokenDoc = await db.collection('users').doc(userId)
    .collection('tokens').doc('youtube').get();
  
  if (!tokenDoc.exists) {
    throw new Error('YouTube account not connected');
  }

  const tokens = tokenDoc.data();
  const oauth2Client = new google.auth.OAuth2(
    process.env.YOUTUBE_CLIENT_ID,
    process.env.YOUTUBE_CLIENT_SECRET,
    process.env.YOUTUBE_REDIRECT_URI
  );

  oauth2Client.setCredentials({
    access_token: tokens.accessToken,
    refresh_token: tokens.refreshToken
  });

  const youtube = google.youtube({ version: 'v3', auth: oauth2Client });

  // Prepare video metadata
  const videoMetadata = {
    snippet: {
      title: platformConfig.title,
      description: platformConfig.description,
      tags: platformConfig.tags || [],
      categoryId: '22' // People & Blogs
    },
    status: {
      privacyStatus: platformConfig.isPrivate ? 'private' : 'public'
    }
  };

  // Upload video
  const response = await youtube.videos.insert({
    part: 'snippet,status',
    requestBody: videoMetadata,
    media: {
      body: fs.createReadStream(videoData.filePath)
    }
  });

  return {
    platformVideoId: response.data.id,
    platformURL: `https://www.youtube.com/watch?v=${response.data.id}`,
    uploadedAt: new Date()
  };
}

// TikTok upload implementation
async function uploadToTikTok(videoData, platformConfig) {
  const { userId } = videoData;
  
  // Get user's TikTok access token
  const tokenDoc = await db.collection('users').doc(userId)
    .collection('tokens').doc('tiktok').get();
  
  if (!tokenDoc.exists) {
    throw new Error('TikTok account not connected');
  }

  const tokens = tokenDoc.data();

  // TikTok upload process (simplified)
  // Note: TikTok's API has specific requirements and approval process
  
  const formData = new FormData();
  formData.append('video', fs.createReadStream(videoData.filePath));
  formData.append('title', platformConfig.title);
  formData.append('description', platformConfig.description);
  formData.append('privacy', platformConfig.isPrivate ? 'private' : 'public');

  const response = await axios.post('https://open-api.tiktok.com/share/video/upload/', formData, {
    headers: {
      'Authorization': `Bearer ${tokens.accessToken}`,
      ...formData.getHeaders()
    }
  });

  return {
    platformVideoId: response.data.share_id,
    platformURL: response.data.share_url,
    uploadedAt: new Date()
  };
}

// Instagram upload implementation
async function uploadToInstagram(videoData, platformConfig) {
  const { userId } = videoData;
  
  // Get user's Instagram access token
  const tokenDoc = await db.collection('users').doc(userId)
    .collection('tokens').doc('instagram').get();
  
  if (!tokenDoc.exists) {
    throw new Error('Instagram account not connected');
  }

  const tokens = tokenDoc.data();

  // Instagram Reels upload process
  // Step 1: Create media container
  const containerResponse = await axios.post(
    `https://graph.facebook.com/v18.0/${tokens.instagramAccountId}/media`,
    {
      media_type: 'REELS',
      video_url: videoData.publicUrl, // Video needs to be publicly accessible
      caption: `${platformConfig.title}\n\n${platformConfig.description}`,
      access_token: tokens.accessToken
    }
  );

  const creationId = containerResponse.data.id;

  // Step 2: Publish the reel
  const publishResponse = await axios.post(
    `https://graph.facebook.com/v18.0/${tokens.instagramAccountId}/media_publish`,
    {
      creation_id: creationId,
      access_token: tokens.accessToken
    }
  );

  return {
    platformVideoId: publishResponse.data.id,
    platformURL: `https://www.instagram.com/reel/${publishResponse.data.id}`,
    uploadedAt: new Date()
  };
}

// Facebook upload implementation
async function uploadToFacebook(videoData, platformConfig) {
  const { userId } = videoData;
  
  // Get user's Facebook access token
  const tokenDoc = await db.collection('users').doc(userId)
    .collection('tokens').doc('facebook').get();
  
  if (!tokenDoc.exists) {
    throw new Error('Facebook account not connected');
  }

  const tokens = tokenDoc.data();

  // Facebook video upload
  const formData = new FormData();
  formData.append('source', fs.createReadStream(videoData.filePath));
  formData.append('title', platformConfig.title);
  formData.append('description', platformConfig.description);
  formData.append('privacy', JSON.stringify({ 
    value: platformConfig.isPrivate ? 'SELF' : 'EVERYONE' 
  }));

  const response = await axios.post(
    `https://graph.facebook.com/v18.0/${tokens.pageId}/videos`,
    formData,
    {
      headers: {
        'Authorization': `Bearer ${tokens.accessToken}`,
        ...formData.getHeaders()
      }
    }
  );

  return {
    platformVideoId: response.data.id,
    platformURL: `https://www.facebook.com/watch/?v=${response.data.id}`,
    uploadedAt: new Date()
  };
}

// Twitter upload implementation
async function uploadToTwitter(videoData, platformConfig) {
  const { userId } = videoData;
  
  // Get user's Twitter access token
  const tokenDoc = await db.collection('users').doc(userId)
    .collection('tokens').doc('twitter').get();
  
  if (!tokenDoc.exists) {
    throw new Error('Twitter account not connected');
  }

  const tokens = tokenDoc.data();

  // Twitter video upload (using Twitter API v2)
  // Step 1: Initialize upload
  const initResponse = await axios.post(
    'https://upload.twitter.com/1.1/media/upload.json',
    {
      command: 'INIT',
      media_type: 'video/mp4',
      total_bytes: videoData.fileSize
    },
    {
      headers: {
        'Authorization': `Bearer ${tokens.accessToken}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );

  const mediaId = initResponse.data.media_id_string;

  // Step 2: Upload video chunks (simplified for this example)
  const videoBuffer = fs.readFileSync(videoData.filePath);
  
  await axios.post(
    'https://upload.twitter.com/1.1/media/upload.json',
    {
      command: 'APPEND',
      media_id: mediaId,
      segment_index: 0,
      media: videoBuffer.toString('base64')
    },
    {
      headers: {
        'Authorization': `Bearer ${tokens.accessToken}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );

  // Step 3: Finalize upload
  await axios.post(
    'https://upload.twitter.com/1.1/media/upload.json',
    {
      command: 'FINALIZE',
      media_id: mediaId
    },
    {
      headers: {
        'Authorization': `Bearer ${tokens.accessToken}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    }
  );

  // Step 4: Create tweet with media
  const tweetResponse = await axios.post(
    'https://api.twitter.com/2/tweets',
    {
      text: `${platformConfig.title}\n\n${platformConfig.description}`,
      media: {
        media_ids: [mediaId]
      }
    },
    {
      headers: {
        'Authorization': `Bearer ${tokens.accessToken}`,
        'Content-Type': 'application/json'
      }
    }
  );

  return {
    platformVideoId: tweetResponse.data.data.id,
    platformURL: `https://twitter.com/user/status/${tweetResponse.data.data.id}`,
    uploadedAt: new Date()
  };
}

module.exports = {
  uploadToPlatform,
  uploadToYouTube,
  uploadToTikTok,
  uploadToInstagram,
  uploadToFacebook,
  uploadToTwitter
};