# SmartPDF - Flutter Mobile App

**SmartPDF** is an all-in-one PDF tools mobile app built with Flutter and Material 3 design. The app allows users to merge, split, compress, and protect PDF files, as well as convert images to PDF format.

## 🎯 Features

- **Merge PDF** - Combine multiple PDF files into one document
- **Split PDF** - Extract specific pages from PDF documents
- **Compress PDF** - Reduce file size without losing quality
- **Lock/Unlock PDF** - Add or remove password protection (Rewarded Ad)
- **Image to PDF** - Convert images to PDF format (Rewarded Ad)
- **More Tools** - Coming soon placeholder

## 🎨 Design

- **Material 3** design system
- **Custom color scheme**: Primary `#0057FF`, Secondary `#F1F3F6`, Accent `#66A3FF`
- **Inter font family** for clean typography
- **Animated splash screen** with gradient background
- **2-column tool grid** with rounded cards
- **Bottom navigation** (Home, Files, About)
- **Floating Action Button** for recent files

## 💰 AdMob Integration

The app includes comprehensive AdMob integration:

- **Native Ad** - Home screen below tools grid
- **Interstitial Ad** - After successful file operations
- **Rewarded Ad** - For Lock/Unlock and Image to PDF tools
- **Banner Ad** - Files screen and About screen

## 📱 Screens

### 1. Splash Screen
- SmartPDF logo with animation
- Gradient background (#0057FF → #66A3FF)
- Auto-navigation after 2 seconds

### 2. Home Screen
- Search bar for filtering tools
- 2-column grid of tool cards
- Native AdMob ad placement
- Bottom navigation

### 3. Tool Screens
- Step-by-step file processing UI
- File picker with multiple selection
- Reorderable file list (for merge)
- Progress overlay during processing
- Results screen with statistics
- Share and open functionality

### 4. Files Screen
- Recent files list with file info
- File actions (open, share, delete)
- Clear history functionality
- Banner ad placement

### 5. About Screen
- App information and features
- Legal links (Privacy Policy, Terms)
- Support and contact information
- Version details

## 🛠️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── pdf_tool.dart        # Tool data model
├── screens/
│   ├── splash_screen.dart   # Animated splash screen
│   ├── home_screen.dart     # Main home screen
│   ├── tool_screen.dart     # Reusable tool screen
│   ├── files_screen.dart    # Recent files screen
│   └── about_screen.dart    # About and info screen
├── widgets/
│   ├── tool_card.dart       # Tool grid card widget
│   ├── file_list_item.dart  # File list item widget
│   └── progress_overlay.dart # Processing overlay
├── services/
│   └── ad_service.dart      # AdMob service
└── theme/
    └── app_theme.dart       # Material 3 theme

assets/
├── images/                  # App images and icons
├── animations/              # Lottie animations
├── icons/                   # Custom icons
└── fonts/                   # Inter font family

android/
└── app/
    ├── build.gradle         # Android build config
    └── src/main/
        └── AndroidManifest.xml  # Android permissions & config
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   cd /Users/sadeny/Documents/devop/aga
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure AdMob**
   - Replace test ad unit IDs in `lib/services/ad_service.dart`
   - Update AdMob App ID in `android/app/src/main/AndroidManifest.xml`

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Release

1. **Create app bundle**
   ```bash
   flutter build appbundle
   ```

2. **Create APK**
   ```bash
   flutter build apk --release
   ```

## 📋 Dependencies

### Main Dependencies
- `flutter` - Flutter framework
- `material_color_utilities` - Material 3 colors
- `google_mobile_ads` - AdMob integration
- `file_picker` - File selection
- `path_provider` - File system access
- `permission_handler` - Android permissions
- `provider` - State management
- `share_plus` - File sharing
- `url_launcher` - External links

### PDF & Image Processing
- `pdf` - PDF generation and manipulation
- `printing` - PDF viewing and printing
- `image` - Image processing

### UI & Animation
- `lottie` - Lottie animations

## 🔧 Configuration

### AdMob Setup

1. **Create AdMob account** and app
2. **Replace test ad unit IDs** in `ad_service.dart`:
   ```dart
   static const String _prodBannerAdUnitId = 'ca-app-pub-YOUR_APP_ID/banner';
   static const String _prodInterstitialAdUnitId = 'ca-app-pub-YOUR_APP_ID/interstitial';
   static const String _prodRewardedAdUnitId = 'ca-app-pub-YOUR_APP_ID/rewarded';
   static const String _prodNativeAdUnitId = 'ca-app-pub-YOUR_APP_ID/native';
   ```
3. **Update app ID** in `AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-YOUR_ACTUAL_APP_ID~1234567890"/>
   ```
4. **Set test mode to false** for production:
   ```dart
   static const bool _testMode = false;
   ```

### Android Permissions

The app requires these permissions (already configured):
- `INTERNET` - For AdMob
- `ACCESS_NETWORK_STATE` - For ad loading
- `READ_EXTERNAL_STORAGE` - For file access
- `WRITE_EXTERNAL_STORAGE` - For saving files
- `MANAGE_EXTERNAL_STORAGE` - For Android 11+

## 🎯 Key Features Implementation

### Material 3 Theming
- Custom color scheme based on seed color
- Typography using Inter font family
- Rounded corners and modern card designs
- Proper elevation and shadows

### File Processing Flow
1. **File Selection** - FilePicker for PDFs/images
2. **File Management** - Reorderable list for merge operations
3. **Processing** - Progress overlay with animations
4. **Results** - Statistics and action buttons
5. **Ad Integration** - Interstitial ads after operations

### AdMob Integration
- **Service-based architecture** for centralized ad management
- **Multiple ad types** with proper lifecycle management
- **Test/Production modes** for development and release
- **Error handling** and fallback scenarios

### State Management
- **Provider pattern** for AdMob service
- **StatefulWidget** for screen-level state
- **Proper disposal** of resources

## 🔄 Development Workflow

1. **Test with AdMob test ads** during development
2. **Use Android emulator** or physical device
3. **Hot reload** for UI changes
4. **Debug mode** for detailed logging
5. **Build release** only when ready for production

## 📱 Platform Support

- **Android**: Minimum SDK 21 (Android 5.0)
- **iOS**: Not yet configured (can be added)

## 🔒 Privacy & Security

- **Local processing** - All files processed on device
- **No cloud uploads** - Files remain private
- **Minimal permissions** - Only required permissions requested
- **Privacy policy** - Link provided in About screen

## 🎨 UI/UX Highlights

- **Consistent design** across all screens
- **Intuitive navigation** with bottom tabs
- **Visual feedback** for all interactions
- **Loading states** for async operations
- **Error handling** with user-friendly messages
- **Accessibility** considerations

## 📊 Performance

- **Efficient animations** with proper disposal
- **Lazy loading** for file lists
- **Memory management** for large files
- **Background processing** for file operations

## 🚀 Future Enhancements

- **More PDF tools** (OCR, watermark, etc.)
- **Cloud integration** (Google Drive, Dropbox)
- **Batch processing** for multiple operations
- **Advanced compression** algorithms
- **iOS support** and publishing
- **Dark theme** support
- **Localization** for multiple languages

---

**Built with ❤️ using Flutter and Material 3**

For support or questions, contact: support@smartpdf.app