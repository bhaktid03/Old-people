# Quick Start Guide

## 🚀 Running Your App with Backend on Port 4000

### Step 1: Update Backend URL (Already Done!)

The backend URL is configured in `lib/api/common/endpoints.dart`:
- **Android Emulator**: `http://10.0.2.2:4000` ✅ (Already set)
- **iOS Simulator**: Change to `http://localhost:4000`
- **Physical Device**: Change to `http://YOUR_LOCAL_IP:4000`

### Step 2: Start Your Backend Server

Make sure your backend is running on port 4000:
```bash
# Your backend should be accessible at:
http://localhost:4000
```

### Step 3: Start Android Emulator

```bash
# Option 1: List available emulators
flutter emulators

# Option 2: Launch emulator from Android Studio
# Open Android Studio → Tools → Device Manager → Click Play button

# Option 3: Launch from command line
flutter emulators --launch <emulator_id>
```

### Step 4: Install Dependencies & Run

```bash
# Install Flutter dependencies
flutter pub get

# Verify emulator is running
flutter devices

# Run the app
flutter run
```

## ✅ What's Already Configured

1. ✅ **API Base URL**: Set to `http://10.0.2.2:4000` (for Android Emulator)
2. ✅ **Network Security**: HTTP connections allowed for development
3. ✅ **INTERNET Permission**: Added to AndroidManifest.xml

## 📝 Quick Reference

| Scenario | Backend URL |
|----------|-------------|
| Android Emulator | `http://10.0.2.2:4000` |
| iOS Simulator | `http://localhost:4000` |
| Physical Device (same network) | `http://YOUR_LOCAL_IP:4000` |
| Production | `https://api.yourdomain.com` |

## 🔧 Troubleshooting

**Can't connect to backend?**
- ✅ Check backend is running: `curl http://localhost:4000`
- ✅ Verify emulator is using `10.0.2.2` (Android) or `localhost` (iOS)
- ✅ Check firewall isn't blocking port 4000

**Network security error?**
- ✅ Already configured in `network_security_config.xml`

**Need more help?**
- 📖 See `BACKEND_INTEGRATION_GUIDE.md` for detailed instructions

## 🎯 Next Steps

1. Start your backend server on port 4000
2. Start Android/iOS emulator
3. Run `flutter run`
4. Test API calls from your app!

