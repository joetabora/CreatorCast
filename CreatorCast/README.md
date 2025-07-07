# CreatorCast

CreatorCast is an iOS app designed for streamers and content creators who want to edit short-form videos and upload them to multiple platforms — specifically YouTube Shorts, TikTok, Instagram Reels, Facebook Reels, and X (Twitter) — from one central app.

## Features

### 🎥 Core Features
- **Account Management**: Sign in/up via email or Apple ID
- **Social Media Integration**: Connect to YouTube, TikTok, Instagram, Facebook, and X via OAuth
- **Video Import & Editing**: Import videos from device or cloud storage with basic editing tools
- **Multi-Platform Publishing**: Select platforms, customize posts, and schedule uploads
- **Upload Manager**: Track progress, retry failed uploads, and manage upload history

### 🛠 Tech Stack

#### iOS App (Frontend)
- **Framework**: SwiftUI
- **Video Processing**: AVFoundation
- **Authentication**: Firebase Auth + Apple Sign-In
- **Networking**: URLSession with Combine

#### Backend API
- **Runtime**: Node.js with Express
- **Database**: Firebase Firestore
- **Queue System**: Bull Queue with Redis
- **Authentication**: JWT + Firebase Auth
- **File Storage**: Firebase Storage / AWS S3

## Project Structure

```
CreatorCast/
├── iOS/                    # iOS SwiftUI App
│   └── CreatorCast/
│       ├── App/           # App entry point
│       ├── Views/         # SwiftUI views
│       ├── Models/        # Data models
│       ├── Services/      # Business logic
│       └── Utils/         # Utilities
├── Backend/               # Node.js API
│   └── src/
│       ├── routes/        # API routes
│       ├── services/      # Business services
│       ├── utils/         # Utilities
│       ├── config/        # Configuration
│       └── middleware/    # Express middleware
└── Documentation/         # Project documentation
```

## Getting Started

### Prerequisites

- **iOS Development**:
  - Xcode 15+ 
  - iOS 17+ deployment target
  - Apple Developer Account (for device testing)

- **Backend Development**:
  - Node.js 18+
  - Redis server
  - Firebase project
  - Platform API access (YouTube, TikTok, etc.)

### Step 1: Firebase Setup

1. **Create Firebase Project**:
   ```bash
   # Go to https://console.firebase.google.com/
   # Create a new project named "CreatorCast"
   ```

2. **Enable Authentication**:
   - Go to Authentication > Sign-in method
   - Enable Email/Password and Apple
   - Configure Apple Sign-In with your iOS bundle ID

3. **Create Firestore Database**:
   - Go to Firestore Database
   - Create database in production mode
   - Set up security rules

4. **Generate Service Account**:
   - Go to Project Settings > Service Accounts
   - Generate new private key
   - Download the JSON file

### Step 2: Backend Setup

1. **Install Dependencies**:
   ```bash
   cd CreatorCast/Backend
   npm install
   ```

2. **Environment Configuration**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   ```

3. **Redis Setup**:
   ```bash
   # macOS with Homebrew
   brew install redis
   brew services start redis
   
   # Ubuntu
   sudo apt install redis-server
   sudo systemctl start redis
   
   # Docker
   docker run -d -p 6379:6379 redis:alpine
   ```

4. **Platform API Setup**:

   **YouTube Data API v3**:
   ```bash
   # Go to Google Cloud Console
   # Enable YouTube Data API v3
   # Create OAuth 2.0 credentials
   # Add redirect URI: http://localhost:3000/api/oauth/youtube/callback
   ```

   **TikTok for Developers**:
   ```bash
   # Apply for TikTok for Developers access
   # Create app and get client credentials
   # Note: TikTok API requires approval
   ```

   **Facebook/Instagram Graph API**:
   ```bash
   # Go to Facebook for Developers
   # Create app with Instagram Basic Display
   # Get app ID and secret
   ```

   **Twitter API v2**:
   ```bash
   # Apply for Twitter Developer account
   # Create app and get API keys
   ```

5. **Start Backend**:
   ```bash
   npm run dev
   ```

### Step 3: iOS App Setup

1. **Open Xcode Project**:
   ```bash
   cd CreatorCast/iOS
   open CreatorCast.xcodeproj
   ```

2. **Install Dependencies**:
   - Add Firebase SDK via Swift Package Manager
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Add: FirebaseAuth, FirebaseFirestore

3. **Firebase Configuration**:
   - Download GoogleService-Info.plist from Firebase Console
   - Add to Xcode project

4. **Configure App Identifiers**:
   - Set your development team
   - Update bundle identifier
   - Configure Apple Sign-In capability

5. **Update API Endpoint**:
   ```swift
   // In APIService.swift
   private let baseURL = "http://localhost:3000/api" // Development
   // or your deployed backend URL for production
   ```

6. **Build and Run**:
   - Select target device/simulator
   - Build and run (Cmd+R)

### Step 4: OAuth Configuration

1. **Update Redirect URIs**:
   Each platform needs redirect URIs configured:
   
   ```
   YouTube: http://localhost:3000/api/oauth/youtube/callback
   TikTok: http://localhost:3000/api/oauth/tiktok/callback
   Facebook: http://localhost:3000/api/oauth/facebook/callback
   Twitter: http://localhost:3000/api/oauth/twitter/callback
   ```

2. **Test OAuth Flow**:
   - Start backend server
   - Run iOS app
   - Try connecting each platform

### Step 5: Production Deployment

#### Backend Deployment (Railway/Heroku/AWS)

1. **Environment Variables**:
   ```bash
   # Set all production environment variables
   # Update FRONTEND_URL to your iOS app scheme
   ```

2. **Redis Setup**:
   ```bash
   # Use Redis Cloud, AWS ElastiCache, or similar
   ```

3. **Deploy**:
   ```bash
   # Railway
   railway deploy
   
   # Heroku
   git push heroku main
   
   # AWS/GCP
   # Use Docker or serverless deployment
   ```

#### iOS App Store Deployment

1. **Update Configuration**:
   ```swift
   // Update API endpoints to production URLs
   // Configure release signing certificates
   ```

2. **Build for Release**:
   ```bash
   # Archive and upload to App Store Connect
   ```

## API Documentation

### Authentication Endpoints

```http
POST /api/auth/signup
POST /api/auth/signin
POST /api/auth/refresh
POST /api/auth/signout
```

### Video Management

```http
GET /api/videos
POST /api/videos/upload
DELETE /api/videos/:id
```

### Upload Management

```http
POST /api/uploads/start
GET /api/uploads/:id/status
POST /api/uploads/:id/retry
POST /api/uploads/:id/cancel
POST /api/uploads/schedule
```

### OAuth Integration

```http
GET /api/oauth/:platform/url
POST /api/oauth/:platform/exchange
```

## Platform-Specific Requirements

### YouTube Shorts
- Max duration: 60 seconds
- Aspect ratio: 9:16 or 1:1
- Max file size: 256MB
- Requires YouTube Data API v3

### TikTok
- Max duration: 3 minutes
- Aspect ratio: 9:16
- Max file size: 287MB
- Requires TikTok for Developers approval

### Instagram Reels
- Max duration: 90 seconds
- Aspect ratio: 9:16 or 1:1
- Max file size: 100MB
- Requires Facebook/Instagram Graph API

### Facebook Reels
- Max duration: 90 seconds
- Aspect ratio: 9:16 or 1:1
- Max file size: 100MB
- Uses Facebook Graph API

### X (Twitter)
- Max duration: 2 minutes 20 seconds
- Aspect ratio: 9:16, 1:1, or 16:9
- Max file size: 512MB
- Requires Twitter API v2

## Development Workflow

1. **Local Development**:
   ```bash
   # Terminal 1: Start Redis
   redis-server
   
   # Terminal 2: Start Backend
   cd CreatorCast/Backend
   npm run dev
   
   # Terminal 3: Start iOS Simulator
   cd CreatorCast/iOS
   open CreatorCast.xcodeproj
   # Run in Xcode
   ```

2. **Testing Uploads**:
   - Import test video (< 60 seconds, 9:16 aspect ratio)
   - Select platforms to upload to
   - Monitor upload progress in app and backend logs

3. **Debugging**:
   - Backend logs: Check console output
   - iOS logs: Use Xcode debugger and console
   - Redis: Use `redis-cli monitor`

## Troubleshooting

### Common Issues

1. **Firebase Authentication Issues**:
   ```bash
   # Check GoogleService-Info.plist is added to Xcode
   # Verify bundle ID matches Firebase configuration
   ```

2. **OAuth Flow Issues**:
   ```bash
   # Verify redirect URIs are correctly configured
   # Check API credentials are valid
   ```

3. **Upload Failures**:
   ```bash
   # Check platform API quotas and limits
   # Verify video format compatibility
   # Check Redis connection
   ```

4. **iOS Build Issues**:
   ```bash
   # Clean build folder (Cmd+Shift+K)
   # Update Xcode and dependencies
   # Check provisioning profiles
   ```

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue on GitHub
- Check troubleshooting section
- Review platform-specific documentation

---

**Built with ❤️ for content creators**