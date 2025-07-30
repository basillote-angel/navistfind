# AR Navigation Implementation Guide

## Overview

This document explains the AR (Augmented Reality) navigation feature implemented in the NavistFind mobile app. The feature provides real-time navigation guidance to campus buildings using camera overlay and GPS coordinates.

## Implementation Approach

### Why This Approach?

After evaluating multiple AR solutions (Unity, ARCore Flutter Plugin, AR Flutter Plugin), we chose a **camera-based overlay approach** because:

1. **Stability**: Avoids complex AR plugin compatibility issues
2. **Performance**: Lightweight and fast implementation
3. **Compatibility**: Works across different Android devices
4. **Maintainability**: Easier to debug and maintain

### Technology Stack

- **Flutter**: Main framework
- **Camera Plugin**: For camera access and preview
- **Geolocator**: For GPS location services
- **Permission Handler**: For camera and location permissions
- **Custom Paint**: For AR overlay graphics

## Features

### 1. Real-time Navigation
- Calculates distance and bearing between current location and destination
- Displays directional arrow overlay on camera feed
- Shows distance and building name information

### 2. Camera Integration
- Live camera preview
- Permission handling for camera access
- High-resolution camera support

### 3. Location Services
- GPS-based location tracking
- Real-time position updates
- Distance and bearing calculations

### 4. User Interface
- Intuitive control panel
- Start/Stop navigation controls
- Real-time status updates
- **Demo Mode**: Test AR navigation from any location

## File Structure

```
lib/features/map/
├── data/
│   └── ar_navigation_service.dart    # Core navigation logic
└── presentation/
    ├── ar_navigation_screen.dart     # Main AR screen
    └── campus_map_screen.dart        # Entry point from map
```

## Key Components

### 1. ARNavigationService
Located in `lib/features/map/data/ar_navigation_service.dart`

**Key Methods:**
- `calculateDistance()`: Calculates distance between two GPS coordinates
- `calculateBearing()`: Calculates bearing (direction) between coordinates
- `requestPermissions()`: Handles camera and location permissions
- `getCurrentLocation()`: Gets current device location

### 2. ARNavigationScreen
Located in `lib/features/map/presentation/ar_navigation_screen.dart`

**Features:**
- Camera preview with AR overlay
- Navigation controls
- Real-time distance and bearing display
- Custom paint overlay for directional arrows

### 3. NavigationPainter
Custom painter class for AR overlay graphics

**Features:**
- Directional arrow drawing
- Distance text overlay
- Real-time bearing calculations

## How It Works

### 1. User Flow
1. User opens campus map
2. Selects a building
3. Clicks "Start Navigation"
4. App requests camera and location permissions
5. Camera opens with AR overlay
6. Directional arrow shows the way to destination

### 2. Technical Flow
1. **Permission Check**: Verify camera and location permissions
2. **Location Acquisition**: Get current GPS coordinates
3. **Distance Calculation**: Calculate distance to destination
4. **Bearing Calculation**: Calculate direction to destination
5. **Camera Initialization**: Start camera preview
6. **Overlay Rendering**: Draw directional arrow and text
7. **Real-time Updates**: Update position and direction as user moves

### 3. Navigation Algorithm
```dart
// Calculate distance using Haversine formula
double distance = ARNavigationService.calculateDistance(current, destination);

// Calculate bearing using spherical trigonometry
double bearing = ARNavigationService.calculateBearing(current, destination);

// Convert bearing to screen coordinates for arrow drawing
double arrowAngle = bearing * (π / 180);
```

## Installation & Setup

### 1. Dependencies
Add these to `pubspec.yaml`:
```yaml
dependencies:
  camera: ^0.11.1
  geolocator: ^11.0.0
  permission_handler: ^11.3.1
  vector_math: ^2.1.4
```

### 2. Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### 3. Android Configuration
Update `android/app/build.gradle.kts`:
```kotlin
android {
    defaultConfig {
        minSdk = 24 // Required for camera features
    }
}
```

## Usage

### Starting Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ARNavigationScreen(
      buildingName: "Library",
      destination: LatLng(7.359008, 125.706665),
    ),
  ),
);
```

### Customizing the Overlay
Modify the `NavigationPainter` class to change:
- Arrow color and size
- Text style and position
- Overlay transparency
- Additional visual elements

## Troubleshooting

### Common Issues

1. **Camera Not Opening**
   - Check camera permissions
   - Verify device has camera
   - Ensure camera is not in use by another app

2. **Location Not Working**
   - Check location permissions
   - Enable GPS on device
   - Check if location services are enabled

3. **Build Errors**
   - Update dependencies to latest versions
   - Check Android SDK version compatibility
   - Verify Gradle configuration

4. **Type Conflicts**
   - **Error**: `type 'LatLng' is not a subtype of type 'Latlng'`
   - **Cause**: Conflict between custom LatLng class and latlong2 package
   - **Solution**: Use `import 'package:latlong2/latlong.dart';` and remove custom LatLng class
   - **Fixed**: AR navigation service now uses the correct LatLng from latlong2 package

### Debug Tips

1. **Test Permissions**: Use `ARNavigationService.requestPermissions()` to test
2. **Check Location**: Use `ARNavigationService.getCurrentLocation()` to verify GPS
3. **Monitor Performance**: Check camera initialization and overlay rendering
4. **Type Safety**: Ensure all LatLng objects use the same type from latlong2 package

## Future Enhancements

### Potential Improvements

1. **3D AR Integration**
   - Integrate with ARCore for true 3D AR
   - Add 3D building models
   - Implement AR anchors

2. **Advanced Navigation**
   - Indoor navigation support
   - Turn-by-turn directions
   - Route optimization

3. **Enhanced UI**
   - Compass overlay
   - Distance markers
   - Building information cards

4. **Performance Optimizations**
   - Background location updates
   - Cached building data
   - Optimized overlay rendering

## Conclusion

This AR navigation implementation provides a solid foundation for campus navigation. While it uses a simplified approach compared to full 3D AR, it offers:

- **Reliability**: Stable across different devices
- **Performance**: Fast and responsive
- **Maintainability**: Easy to debug and extend
- **User Experience**: Intuitive and effective navigation

The implementation can be easily extended with more advanced AR features as needed, while maintaining the current stability and performance. 