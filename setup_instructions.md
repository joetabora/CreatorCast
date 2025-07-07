# CreatorCast Quick Setup Guide

Follow these steps to get CreatorCast running locally in under 30 minutes.

## 🚀 Quick Start (Development)

### 1. Prerequisites Setup (5 minutes)

```bash
# Install Node.js 18+ from https://nodejs.org/
node --version  # Should be 18+

# Install Redis
# macOS:
brew install redis && brew services start redis

# Ubuntu:
sudo apt install redis-server && sudo systemctl start redis

# Windows: Use Docker
docker run -d -p 6379:6379 redis:alpine
```

### 2. Firebase Setup (10 minutes)

1. **Create Firebase Project**:
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Create a project" → "CreatorCast"
   - Disable Google Analytics (optional)

2. **Enable Authentication**:
   - Go to Authentication → Sign-in method
   - Enable "Email/Password"
   - Enable "Apple" (add iOS bundle ID: `com.yourname.creatorcast`)

3. **Create Firestore Database**:
   - Go to Firestore Database → Create database
   - Start in "Production mode"
   - Choose nearest location

4. **Download Service Account**:
   - Go to Project Settings → Service Accounts
   - Click "Generate new private key"
   - Save the JSON file as `firebase-service-account.json`

### 3. Backend Setup (5 minutes)

```bash
# Navigate to backend
cd CreatorCast/Backend

# Install dependencies
npm install

# Setup environment
cp .env.example .env

# Edit .env file with your Firebase credentials
# At minimum, set:
# - FIREBASE_PROJECT_ID
# - JWT_SECRET (any random string)
# - JWT_REFRESH_SECRET (any random string)
```

**Quick .env setup:**
```bash
# Replace with your actual Firebase project ID
echo "FIREBASE_PROJECT_ID=your-project-id-here" >> .env
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
echo "JWT_REFRESH_SECRET=$(openssl rand -base64 32)" >> .env
```

### 4. Start Backend (1 minute)

```bash
# Start the backend server
npm run dev

# You should see:
# 🚀 CreatorCast Backend running on port 3000
# 📱 Environment: development
```

### 5. iOS App Setup (5 minutes)

```bash
# Navigate to iOS project
cd ../iOS

# Open in Xcode
open CreatorCast.xcodeproj
```

**In Xcode:**
1. Add Firebase SDK:
   - File → Add Package Dependencies
   - Enter: `https://github.com/firebase/firebase-ios-sdk`
   - Add: `FirebaseAuth`, `FirebaseFirestore`

2. Add Firebase config:
   - Download `GoogleService-Info.plist` from Firebase Console
   - Drag it into Xcode project (add to target)

3. Update Bundle ID:
   - Select project → General → Bundle Identifier
   - Change to `com.yourname.creatorcast`

### 6. Test the App (2 minutes)

1. **Build and Run** (Cmd+R)
2. **Create Account**:
   - Tap "Sign Up"
   - Enter email, password, name
   - Tap "Create Account"
3. **Import Video**:
   - Tap "Import Video"
   - Select a short video from Photos
4. **Test Upload** (without platform connections):
   - Go to Upload tab
   - You'll see mock upload progress

## 🎯 Next Steps

### Connect Real Platforms (Optional)

To connect real social media platforms, you'll need API credentials:

1. **YouTube**: [Google Cloud Console](https://console.cloud.google.com/) → Enable YouTube Data API v3
2. **TikTok**: [TikTok for Developers](https://developers.tiktok.com/) (requires approval)
3. **Instagram/Facebook**: [Facebook for Developers](https://developers.facebook.com/)
4. **Twitter**: [Twitter Developer Portal](https://developer.twitter.com/)

### Production Deployment

1. **Backend**: Deploy to Railway, Heroku, or AWS
2. **iOS**: Configure for App Store submission

## 🐛 Troubleshooting

### Backend won't start:
```bash
# Check Redis is running
redis-cli ping  # Should return "PONG"

# Check Firebase credentials
node -e "console.log(process.env.FIREBASE_PROJECT_ID)"
```

### iOS build fails:
```bash
# Clean build
# In Xcode: Product → Clean Build Folder (Cmd+Shift+K)

# Check iOS Simulator
# Make sure you have iOS 17+ simulator installed
```

### App crashes on launch:
```bash
# Check GoogleService-Info.plist is added
# Verify bundle ID matches Firebase project
```

## 📱 Testing Without Platform APIs

The app works without real platform API keys:

- ✅ User authentication (Firebase)
- ✅ Video import and editing
- ✅ Upload UI and progress tracking
- ✅ Mock upload simulation
- ❌ Real platform uploads (requires API keys)

This lets you develop and test the core functionality before setting up platform integrations.

## 🎉 You're Ready!

Your CreatorCast development environment is now set up. You can:

- Create accounts and sign in
- Import and edit videos
- Test upload flows
- Develop new features
- Add real platform integrations when ready

Happy coding! 🚀