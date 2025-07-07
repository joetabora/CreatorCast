# CreatorCast Project Structure

## Overview
CreatorCast is an iOS app for content creators to edit short-form videos and upload them to multiple platforms (YouTube Shorts, TikTok, Instagram Reels, Facebook Reels, and X/Twitter).

## Project Structure

```
CreatorCast/
├── iOS/                              # iOS App (SwiftUI)
│   ├── CreatorCast.xcodeproj/
│   ├── CreatorCast/
│   │   ├── App/
│   │   │   ├── CreatorCastApp.swift
│   │   │   ├── ContentView.swift
│   │   │   └── AppDelegate.swift
│   │   ├── Views/
│   │   │   ├── Authentication/
│   │   │   │   ├── SignInView.swift
│   │   │   │   ├── SignUpView.swift
│   │   │   │   └── SocialAuthView.swift
│   │   │   ├── Main/
│   │   │   │   ├── MainTabView.swift
│   │   │   │   ├── HomeView.swift
│   │   │   │   └── ProfileView.swift
│   │   │   ├── VideoEditor/
│   │   │   │   ├── VideoEditorView.swift
│   │   │   │   ├── VideoImportView.swift
│   │   │   │   ├── EditingToolsView.swift
│   │   │   │   └── VideoPreviewView.swift
│   │   │   ├── Upload/
│   │   │   │   ├── UploadSelectionView.swift
│   │   │   │   ├── PlatformConfigView.swift
│   │   │   │   ├── UploadProgressView.swift
│   │   │   │   └── UploadManagerView.swift
│   │   │   └── Components/
│   │   │       ├── VideoPlayerView.swift
│   │   │       ├── LoadingView.swift
│   │   │       └── AlertView.swift
│   │   ├── Models/
│   │   │   ├── User.swift
│   │   │   ├── Video.swift
│   │   │   ├── Platform.swift
│   │   │   └── Upload.swift
│   │   ├── Services/
│   │   │   ├── AuthService.swift
│   │   │   ├── VideoService.swift
│   │   │   ├── UploadService.swift
│   │   │   ├── APIService.swift
│   │   │   └── OAuthService.swift
│   │   ├── Utils/
│   │   │   ├── Extensions.swift
│   │   │   ├── Constants.swift
│   │   │   └── Helpers.swift
│   │   └── Resources/
│   │       ├── Assets.xcassets/
│   │       ├── LaunchScreen.storyboard
│   │       └── Info.plist
│   └── CreatorCastTests/
├── Backend/                          # Backend API
│   ├── src/
│   │   ├── routes/
│   │   │   ├── auth.js
│   │   │   ├── users.js
│   │   │   ├── videos.js
│   │   │   └── uploads.js
│   │   ├── services/
│   │   │   ├── authService.js
│   │   │   ├── videoService.js
│   │   │   ├── uploadService.js
│   │   │   └── oauthService.js
│   │   ├── models/
│   │   │   ├── User.js
│   │   │   ├── Video.js
│   │   │   └── Upload.js
│   │   ├── middleware/
│   │   │   ├── auth.js
│   │   │   ├── upload.js
│   │   │   └── validation.js
│   │   ├── config/
│   │   │   ├── database.js
│   │   │   ├── firebase.js
│   │   │   └── oauth.js
│   │   ├── utils/
│   │   │   ├── videoProcessor.js
│   │   │   ├── uploadQueue.js
│   │   │   └── retry.js
│   │   └── app.js
│   ├── package.json
│   ├── .env.example
│   └── Dockerfile
├── Documentation/
│   ├── API.md
│   ├── OAuth_Setup.md
│   └── Deployment.md
└── README.md
```

## Tech Stack

### iOS App (Frontend)
- **Framework**: SwiftUI
- **Video Processing**: AVFoundation
- **Networking**: URLSession
- **Authentication**: Firebase Auth / Apple Sign-In
- **UI Components**: Custom SwiftUI components

### Backend API
- **Runtime**: Node.js with Express
- **Database**: Firebase Firestore
- **Authentication**: Firebase Auth
- **File Storage**: Firebase Storage / AWS S3
- **Queue System**: Bull Queue (Redis)
- **API Integrations**: YouTube, TikTok, Meta, X APIs

### Services & Integrations
- **Authentication**: Firebase Auth + OAuth 2.0
- **Cloud Storage**: Firebase Storage
- **Video Processing**: FFmpeg (server-side)
- **Upload Queue**: Redis-based queue with retry logic
- **Analytics**: Firebase Analytics

## Key Features Implementation

### 1. Authentication Flow
- Email/Password and Apple ID sign-in
- OAuth integration for social platforms
- JWT token management
- Secure credential storage

### 2. Video Editing
- Import from device/cloud storage
- Basic editing tools (trim, crop, resize)
- Auto-captions generation
- Filters and overlays
- Music integration

### 3. Multi-Platform Upload
- Platform-specific optimization
- Metadata customization per platform
- Scheduled publishing
- Progress tracking
- Retry mechanism for failed uploads

### 4. Upload Management
- Queue-based upload system
- Progress monitoring
- Error handling and retries
- Upload history and analytics