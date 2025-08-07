# FLUTTER SHIELD EXAMPLE

Demonstrates how to use the flutter_shield plugin.

## 🚀 Build & Run Instructions

### Prerequisites

Before running the example app, ensure you have:

- Flutter SDK installed (`flutter doctor` should pass)
- iOS development tools (Xcode for iOS/macOS)
- Android development tools (Android Studio for Android)
- Connected device or running simulator

### 1. Check Prerequisites

```bash
flutter doctor
```

If Android licenses are not accepted, run:
```bash
flutter doctor --android-licenses
```

### 2. Install Dependencies

Navigate to the example directory and install dependencies:

```bash
cd example
flutter pub get
```

### 3. Check Available Devices

```bash
flutter devices
```

### 4. Launch Emulators (Optional)

#### iOS Simulator
```bash
flutter emulators --launch apple_ios_simulator
```

#### Android Emulator
```bash
flutter emulators --launch Medium_Phone_API_35
```

### 5. Run the Example App

#### Option A: Run on Default Device
```bash
flutter run
```

#### Option B: Run on Specific Device
```bash
# iOS Physical Device
flutter run -d "00008130-000A10603AA0001C"

# iOS Simulator
flutter run -d "314D4D27-A97B-4182-96A7-B87D1156ECDD"

# macOS Desktop
flutter run -d macos

# Android Emulator
flutter run -d Medium_Phone_API_35

# Chrome Web
flutter run -d chrome
```

#### Option C: Using VS Code
1. Open the project in VS Code:
   ```bash
   code .
   ```
2. Select target device from the bottom status bar
3. Press `F5` or use "Run and Debug" panel

#### Option D: Using Xcode (iOS only)
1. Open iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Select target device/simulator
3. Click the Run button

### 6. Test the SDK Features

Once the app is running, you can test various features:

#### 🔑 Generate Certificate
- Tap "Generate Cert" to create key pairs and certificates
- Test with different access control options

#### 🔐 AES Decrypt Test (New Feature)
- Tap "AES Decrypt Test" to test the new AES decryption functionality
- Use the pre-filled sample data or input your own encrypted JSON
- Test the complete flow: RSA decrypt → AES decrypt

#### ✍️ Signature & Verify
- Test digital signing and verification
- Generate signatures and verify them

#### 🌐 MTLS Call
- Test mutual TLS authentication
- Verify certificate-based communication

#### 🔒 Password Testing
- Test secure password storage and retrieval

## 🔧 Development Commands

### Hot Reload
While the app is running, press `r` in the terminal to hot reload.

### Hot Restart
Press `R` to hot restart the application.

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

### Debug Mode vs Release Mode
```bash
# Debug mode (default)
flutter run

# Release mode
flutter run --release

# Profile mode
flutter run --profile
```

## 📱 Platform Support

- ✅ **iOS**: Full Secure Enclave support with biometric authentication
- ✅ **Android**: Hardware Security Module (HSM) support
- ✅ **macOS**: Desktop security features
- ⚠️ **Web**: Limited functionality (fallback implementations)

## 🧪 Testing AES Decryption

The example app includes a comprehensive test for the new AES decryption feature:

1. **Navigate to "AES Decrypt Test"**
2. **Input Format**: The app expects a JSON response from your server:
   ```json
   {
     "transactionId": "uuid-here",
     "encryptedKey": "base64-encoded-rsa-encrypted-aes-key",
     "encryptData": "base64-encoded-aes-encrypted-payload"
   }
   ```
3. **Test Flow**:
   - RSA decrypt the `encryptedKey` to get AES key
   - AES decrypt the `encryptData` using the retrieved key
   - Display the decrypted payload

## 🐛 Troubleshooting

### Common Issues

1. **Build Errors**:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **iOS Simulator Issues**:
   - Ensure Xcode is properly installed
   - Try restarting the simulator

3. **Android License Issues**:
   ```bash
   flutter doctor --android-licenses
   ```

4. **Device Not Found**:
   ```bash
   flutter devices
   flutter emulators
   ```

### Platform-Specific Issues

#### iOS
- Ensure your Apple Developer account is set up
- Check code signing settings in Xcode
- Verify device is trusted for development

#### Android
- Ensure USB debugging is enabled
- Check Android SDK installation
- Verify emulator has enough storage

## 📚 API Documentation

For detailed API documentation, see the main [Flutter Shield README](../README.md).

## 🤝 Contributing

Found a bug or want to contribute? Please check the main repository for contribution guidelines.