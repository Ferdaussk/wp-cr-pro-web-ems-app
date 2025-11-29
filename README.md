# Employee Management System - Flutter Mobile App

## Description

A powerful mobile application for employees to manage their daily work activities, attendance, tasks, leaves, and view salary information. Built with Flutter for cross-platform support (Android & iOS).

## Features

### Core Features
- **User Authentication**: Secure login with token-based authentication
- **Dashboard**: Overview of pending tasks, leaves, attendance, and notifications
- **Attendance Management**: Quick check-in/check-out with location tracking
- **Task Management**: View assigned tasks, update status, track progress
- **Leave Application**: Apply for leaves with reason and date selection
- **Leave History**: View all leave applications and their status
- **Profile Management**: View and update employee profile information
- **Real-time Updates**: Pull-to-refresh functionality on all screens
- **Offline Support**: Token-based session management

### User Interface
- Clean, modern Material Design interface
- Intuitive navigation with bottom navigation bar
- Card-based layouts for better readability
- Status indicators with color coding
- Responsive design for all screen sizes

## Screenshots

[Add your app screenshots here]

## Requirements

### Development Environment
- Flutter SDK 3.0 or higher
- Dart 3.0 or higher
- Android Studio / VS Code
- Xcode (for iOS development)

### Target Platforms
- Android 5.0 (API 21) or higher
- iOS 12.0 or higher

## Installation

### Prerequisites

1. **Install Flutter**
   ```bash
   # Download Flutter SDK from https://flutter.dev
   # Add Flutter to your PATH
   flutter doctor
   ```

2. **Install Dependencies**
   ```bash
   # Clone the repository
   git clone https://github.com/yourcompany/ems-mobile-app.git
   cd ems-mobile-app

   # Get dependencies
   flutter pub get
   ```

### Configuration

1. **Update API Base URL**
   
   Open `lib/main.dart` and update the base URL:
   ```dart
   class ApiService {
     static const String baseUrl = 'https://yoursite.com/wp-json/ems/v1/mobile';
   }
   ```

2. **Configure App Name and Icons**
   
   Update in `pubspec.yaml`:
   ```yaml
   name: employee_management
   description: Employee Management System Mobile App
   version: 1.0.0+1
   ```

## Building the App

### Android

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# APK location
build/app/outputs/flutter-apk/app-release.apk
```

### iOS

```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ios --release

# Note: Requires Mac with Xcode installed
```

## Running the App

### Using VS Code
1. Open project in VS Code
2. Select target device (Android/iOS)
3. Press F5 to run

### Using Android Studio
1. Open project in Android Studio
2. Select emulator or connected device
3. Click Run button

### Using Command Line
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d device_id

# Run in release mode
flutter run --release
```

## Usage

### First Time Setup

1. **Launch App**
   - App will show splash screen
   - Automatically redirects to login if not authenticated

2. **Login**
   - Use demo credentials:
     - Username: `demo`
     - Password: `demo`
   - Or use your actual employee credentials

3. **Explore Features**
   - Dashboard: View overview
   - Attendance: Check in/out
   - Tasks: Manage your tasks
   - Leaves: Apply and track leaves
   - Profile: View your information

### Daily Usage

#### Check In/Out
1. Go to Attendance tab
2. Tap "Check In" button in the morning
3. Tap "Check Out" button when leaving
4. View attendance history below

#### Managing Tasks
1. Go to Tasks tab
2. View all assigned tasks
3. Use filters to see pending/in-progress/completed
4. Update task status using dropdown
5. Pull down to refresh

#### Applying for Leave
1. Go to Leaves tab
2. Tap "Apply Leave" tab
3. Select leave type
4. Choose start and end dates
5. Enter reason
6. Submit application
7. Check status in "Leave History" tab

#### Viewing Profile
1. Go to Profile tab
2. View personal information
3. Check employee details
4. Access settings
5. Logout when needed

## App Architecture

### State Management
- Provider pattern for state management
- Separate providers for auth and employee data
- Efficient rebuilding with Consumer widgets

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── task.dart
│   ├── leave.dart
│   └── attendance.dart
├── services/                 # API services
│   └── api_service.dart
├── providers/                # State providers
│   ├── auth_provider.dart
│   └── employee_provider.dart
├── screens/                  # App screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── attendance_screen.dart
│   ├── tasks_screen.dart
│   ├── leaves_screen.dart
│   └── profile_screen.dart
└── widgets/                  # Reusable widgets
    └── task_card.dart
```

## Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                    # HTTP requests
  provider: ^6.1.1                # State management
  shared_preferences: ^2.2.2      # Local storage
```

### Installation
```bash
flutter pub add http
flutter pub add provider
flutter pub add shared_preferences
```

## API Integration

### Base Configuration
```dart
static const String baseUrl = 'https://yoursite.com/wp-json/ems/v1/mobile';
```

### Authentication Flow
1. User enters credentials
2. App calls `/login` endpoint
3. Server returns token and user data
4. Token stored in SharedPreferences
5. Token sent with all subsequent requests

### Error Handling
- Network errors caught and displayed
- Invalid responses handled gracefully
- User-friendly error messages
- Automatic token refresh on expiry

## Troubleshooting

### Common Issues

1. **Login Failed: 401**
   - Check username and password
   - Verify WordPress user exists
   - Check API base URL is correct

2. **API Call Failed: Exception**
   - Verify internet connection
   - Check API endpoint URL
   - Ensure WordPress plugin is activated

3. **Token Expired**
   - App will automatically logout
   - User needs to login again
   - Tokens are stored securely

4. **Tasks/Leaves Not Loading**
   - Pull down to refresh
   - Check internet connection
   - Verify user has data in database

### Debug Mode

Enable debug logging:
```dart
print('API Response: $response');
```

Check Flutter logs:
```bash
flutter logs
```

### Testing API Connection

Test API manually:
```bash
# Test login
curl -X POST https://yoursite.com/wp-json/ems/v1/mobile/login \
  -H "Content-Type: application/json" \
  -d '{"username":"demo","password":"demo"}'
```

## Building for Production

### Android Release

1. **Generate Signing Key**
   ```bash
   keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
   ```

2. **Configure Signing**
   
   Create `android/key.properties`:
   ```properties
   storePassword=yourpassword
   keyPassword=yourpassword
   keyAlias=key
   storeFile=/path/to/key.jks
   ```

3. **Build Release APK**
   ```bash
   flutter build apk --release
   ```

### iOS Release

1. **Configure Xcode**
   - Open `ios/Runner.xcworkspace`
   - Set signing team
   - Configure bundle identifier

2. **Build Release**
   ```bash
   flutter build ios --release
   ```

## Performance Optimization

### Tips for Better Performance
- Images are cached automatically
- API responses are efficiently parsed
- State updates are optimized
- Minimal rebuilds with Provider

### App Size
- Android APK: ~15-20 MB
- iOS IPA: ~20-25 MB

## Security

### Best Practices
- Tokens stored securely in SharedPreferences
- Passwords not stored locally
- HTTPS required for API calls
- Input validation on all forms
- Secure authentication flow

### Data Privacy
- User data encrypted in transit
- No sensitive data in logs
- Automatic logout on token expiry

## Testing

### Manual Testing
1. Test login with valid/invalid credentials
2. Test all navigation flows
3. Test API calls with/without internet
4. Test on different screen sizes
5. Test check-in/check-out flow

### Automated Testing
```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Deployment

### Google Play Store
1. Build release APK
2. Create Play Console account
3. Upload APK
4. Fill store listing
5. Submit for review

### Apple App Store
1. Build release IPA
2. Create App Store Connect account
3. Upload via Xcode/Transporter
4. Fill app information
5. Submit for review

## Support

### Getting Help
- Email: support@yourcompany.com
- Documentation: [Link to docs]
- Issue Tracker: [GitHub Issues]

### Reporting Bugs
1. Check existing issues
2. Provide detailed description
3. Include steps to reproduce
4. Add screenshots if possible
5. Specify device and OS version

## Roadmap

### Upcoming Features
- [ ] Push notifications
- [ ] Fingerprint authentication
- [ ] Dark mode support
- [ ] Offline mode with sync
- [ ] Document upload
- [ ] Chat with HR
- [ ] Salary slip download
- [ ] Performance reviews

## Contributing

We welcome contributions! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

```
Copyright (c) 2024 Your Company Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
```

## Credits

### Development Team
- Lead Developer: Your Name
- UI/UX Designer: Designer Name
- Backend Developer: Backend Dev Name

### Third-party Libraries
- Flutter Framework
- Provider Package
- HTTP Package
- SharedPreferences Package

## Version History

### v1.0.0 (2024-01-01)
- Initial release
- Login and authentication
- Dashboard with statistics
- Attendance check-in/out
- Task management
- Leave application and history
- Profile viewing
- Bottom navigation
- Pull-to-refresh

---

**Made with ❤️ using Flutter**