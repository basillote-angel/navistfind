# AR Navigation Launcher for NavistFind

This implementation provides a complete solution for launching Unity AR navigation apps from your Flutter app with proper device compatibility checking and user guidance.

## Features

✅ **ARCore Support Detection** - Checks if device supports Google Play Services for AR  
✅ **Unity App Installation Check** - Verifies if Unity AR app is installed  
✅ **Conditional Display** - AR navigation buttons only show when Unity app is installed  
✅ **Smart Dialog System** - Provides appropriate user guidance based on device state  
✅ **Multiple Widget Options** - Button, FAB, and Card variants for different UI needs  
✅ **Error Handling** - Graceful fallbacks and user-friendly error messages  
✅ **Easy Integration** - Simple to add to existing screens  

## Quick Start

### 1. Add Dependencies

The following dependencies are already included in your `pubspec.yaml`:

```yaml
dependencies:
  external_app_launcher: ^4.0.3
  android_intent_plus: ^5.3.0
  url_launcher: ^6.2.5
```

### 2. Update Package Names

Edit `lib/features/map/data/ar_navigation_launcher_service.dart`:

```dart
// Update these constants with your actual values
static const String _unityAppPackageName = 'com.yourcompany.navistfind.ar';
static const String _unityAppPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.yourcompany.navistfind.ar';
```

### 3. Basic Usage

```dart
import 'package:your_app/features/map/data/ar_navigation_launcher_service.dart';

// Simple launch
await ARNavigationLauncherService.launchARNavigation(context);
```

## Widget Options

### 1. Basic Button
```dart
ARNavigationLauncherWidget(
  buildingName: 'Library', // Optional
)
```

### 2. Floating Action Button
```dart
ARNavigationFAB(
  buildingName: 'Campus', // Optional
)
```

### 3. Card Widget
```dart
ARNavigationCard(
  buildingName: 'Science Building',
  description: 'Navigate using AR technology',
)
```

### 4. Conditional Widgets (Recommended)
These widgets automatically hide when the Unity AR app is not installed:

```dart
// Conditional AR Button
ConditionalARButton(
  buildingName: 'Library',
)

// Conditional AR Icon Button for App Bars
ConditionalARIconButton(
  tooltip: 'Launch Unity AR App',
)

// Generic Conditional Widget
ARNavigationConditionalWidget(
  builder: (context) => YourCustomARWidget(),
  fallbackWidget: AlternativeWidget(), // Optional
)
```

## Integration Examples

### Campus Map Screen
The campus map screen now includes a "Launch Unity AR" button in building info dialogs. The button only appears when the Unity AR app is installed.

### AR Navigation Screen
Added a Unity AR launch button in the app bar for easy access. The button only appears when the Unity AR app is installed.

### Custom Implementation
```dart
ElevatedButton(
  onPressed: () async {
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
      // Handle errors
    }
  },
  child: Text('Start AR Navigation'),
)
```

## How It Works

1. **Device Check**: Verifies ARCore support using package detection
2. **App Check**: Checks if Unity AR app is installed
3. **Conditional Display**: AR navigation buttons only appear when Unity app is installed
4. **Launch**: Opens Unity app if available
5. **Fallback**: Shows appropriate dialogs for unsupported devices or missing apps

## User Experience Flow

### Device Supports AR + App Installed
- ✅ Launches Unity AR app directly

### Device Supports AR + App Not Installed
- 📱 Shows "Install AR Module" dialog
- 🔗 [Install] button opens Play Store
- ❌ [Cancel] closes dialog

### Device Doesn't Support AR
- ⚠️ Shows "AR Navigation Not Supported" dialog
- 💡 Suggests using map view instead
- ✅ [OK] button closes dialog

## Customization

### Dialog Styling
Modify the dialog appearance in `_showARNotSupportedDialog()` and `_showInstallARModuleDialog()` methods.

### Error Handling
Add custom error handling in the `_launchUnityApp()` method.

### Additional Checks
Extend `_checkARCoreCompatibility()` for more sophisticated device capability detection.

## Testing

### Test Scenarios
1. **ARCore Supported + App Installed**: Should launch Unity app
2. **ARCore Supported + App Missing**: Should show install dialog
3. **ARCore Not Supported**: Should show unsupported dialog

### Debug Mode
Enable debug logging by checking console output for:
- ARCore detection results
- Unity app installation status
- Launch attempts and results

## Troubleshooting

### Common Issues

**"Failed to launch Unity AR app"**
- Check package name is correct
- Verify Unity app is properly installed
- Check device permissions

**"AR Navigation Not Supported" on supported devices**
- ARCore may not be installed
- Device may need Google Play Services update
- Check device compatibility list

**Play Store doesn't open**
- Verify Play Store package name
- Check device has Play Store installed
- Test with fallback launch method

### Debug Commands

```bash
# Check if dependencies are properly installed
flutter pub get

# Verify no linter errors
flutter analyze

# Test on device
flutter run
```

## File Structure

```
lib/features/map/
├── data/
│   ├── ar_navigation_launcher_service.dart    # Core service
│   └── ar_navigation_service.dart             # Existing AR service
├── presentation/
│   ├── ar_navigation_launcher_widget.dart     # Widget components
│   ├── ar_navigation_screen.dart              # Updated with Unity launch
│   ├── campus_map_screen.dart                 # Updated with Unity launch
│   └── ar_navigation_example_screen.dart      # Example implementations
```

## Future Enhancements

- [ ] iOS ARKit support
- [ ] Deep linking with Unity app
- [ ] AR session state management
- [ ] Offline AR capability detection
- [ ] Custom AR app store integration

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Verify package names and URLs are correct
3. Test on different device configurations
4. Review console logs for error details

---

**Note**: This implementation assumes Android platform for ARCore detection. For iOS support, additional ARKit detection logic would be needed.
