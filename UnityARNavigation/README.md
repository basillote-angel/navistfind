r# Unity AR Navigation App

This Unity project implements the AR-based indoor navigation system that works with the Flutter main app.

## Project Requirements
- Unity 2022 LTS or later
- AR Foundation package
- ARCore XR Plugin package
- Android Build Support

## Project Structure
```
Assets/
├── Scripts/
│   ├── AndroidIntentReceiver.cs      # Receives data from Flutter app
│   ├── NavigationManager.cs          # Manages waypoint navigation
│   ├── ArrowController.cs            # Controls 3D navigation arrow
│   ├── WaypointSystem.cs             # Handles waypoint data
│   └── ARCalibration.cs              # AR tracking calibration
├── Prefabs/
│   ├── NavigationArrow.prefab        # 3D arrow for navigation
│   └── WaypointMarker.prefab         # Waypoint visualization
├── Scenes/
│   └── ARNavigation.unity            # Main AR navigation scene
└── Materials/
    └── ArrowMaterial.mat             # Arrow material
```

## Setup Instructions

### 1. Create New Unity Project
1. Open Unity Hub
2. Click "New Project"
3. Select "3D" template
4. Name: "UnityARNavigation"
5. Location: Choose your preferred location
6. Click "Create project"

### 2. Install Required Packages
1. Go to Window > Package Manager
2. Install the following packages:
   - AR Foundation (latest version)
   - ARCore XR Plugin (latest version)
   - Input System (latest version)

### 3. Configure Project Settings
1. Go to Edit > Project Settings
2. In Player settings:
   - Set Company Name: "YourCompany"
   - Set Product Name: "UnityARNavigation"
   - Set Package Name: "com.example.unity_ar_navigation"
   - Set Minimum API Level: 24 (Android 7.0)
3. In XR Plug-in Management:
   - Enable ARCore
   - Set ARCore as the active provider

### 4. Import Scripts
1. Copy all C# scripts to Assets/Scripts/
2. Create the prefabs and materials as described
3. Set up the main scene

### 5. Build Settings
1. Go to File > Build Settings
2. Select Android platform
3. Set Target Architecture to ARM64
4. Enable "Development Build" for testing
5. Click "Build" and save as "UnityARNavigation.apk"

## Integration with Flutter
The Unity app receives navigation data via Android Intent extras:
- building_name: Name of the destination building
- room_name: Specific room (if any)
- destination_lat: Latitude coordinate
- destination_lng: Longitude coordinate
- building_description: Building description

## Testing
1. Install both Flutter and Unity apps on the same device
2. Use the Flutter app to select a destination
3. Tap "Launch AR" to open Unity app
4. Unity app should display the destination and start navigation
