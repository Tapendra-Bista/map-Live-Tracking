# Flutter Map Navigation App

A feature-rich Flutter application with real-time GPS navigation, route planning, and turn-by-turn directions. Built with Google Maps integration and advanced navigation features.

## Features

### 🗺️ Map Features
- **Interactive Google Maps** - Multiple map types (Normal, Satellite, Terrain, Hybrid)
- **Real-time Location Tracking** - Get and display current GPS location
- **Place Search** - Autocomplete search for destinations with category icons
- **Custom Markers & Circles** - Visual indicators for source and destination

### 🧭 Navigation Features
- **Turn-by-Turn Navigation** - Real-time GPS-based navigation with dynamic camera following
- **Multiple Transport Modes** - Walking, Driving, and Cycling routes with accurate time estimates
- **Dynamic Route Display** - Visual distinction between traveled (light blue) and remaining route (pure blue)
- **3D Navigation View** - 60° tilted camera angle with bearing rotation for forward-looking perspective
- **Live Updates** - Real-time distance and time calculations during navigation

### 📍 Route Planning
- **Route Calculation** - Automatic route generation between source and destination
- **Distance & Duration Display** - Accurate metrics based on transport mode
- **Change Source/Destination** - Easily modify start or end points
- **Route Visualization** - Clear polyline paths with color-coded segments

### 🎯 Smart Navigation UI
- **Navigation Details Panel** - Shows current time, remaining distance, and ETA
- **Arrival Detection** - Automatic notification when reaching destination (within 20 meters)
- **Clean UI Transitions** - Search bar and controls hide during navigation for clear view
- **Easy Exit** - One-tap button to stop navigation and return to normal map view

## Prerequisites

Before running this project, ensure you have:

- **Flutter SDK** (3.10.4 or higher)
- **Dart SDK** (3.10.4 or higher)
- **Android Studio** or **VS Code** with Flutter extensions
- **Google Maps API Key** (see Configuration section)

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/map.git
   cd map
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Keys** (see Configuration section below)

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Google Maps API Key Setup

1. **Get Google Maps API Key**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a new project or select existing one
   - Enable the following APIs:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Geocoding API
     - Directions API
   - Create credentials (API Key)

2. **Add API Key to Android**
   - Open `android/app/src/main/AndroidManifest.xml`
   - Add your key:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_API_KEY_HERE"/>
     ```

3. **Add API Key to iOS**
   - Open `ios/Runner/AppDelegate.swift`
   - Add your key in the import section

4. **Configure Environment Variables**
   - Create `.env` file in project root:
     ```env
     GOOGLE_MAPS_API_KEY=your_api_key_here
     GEOAPIFY_API_KEY=your_geoapify_key_here
     ```

### Geoapify API (for routing)
- Get a free API key from [Geoapify](https://www.geoapify.com/)
- Add to `.env` file as shown above

## Usage

### Basic Navigation Flow

1. **Search for a Destination**
   - Tap the search bar
   - Enter location name
   - Select from autocomplete results

2. **Plan Your Route**
   - Choose transport mode (Walk/Drive/Bike)
   - View distance and estimated time
   - Tap "Directions" to see the route

3. **Start Navigation**
   - Tap "Start" button
   - Map rotates to navigation view
   - Follow the route with real-time updates

4. **During Navigation**
   - Watch distance and time update live
   - View navigation panel at top
   - Passed route shown in light blue
   - Remaining route in bright blue

5. **End Navigation**
   - Tap close button to exit early
   - Automatic "You have arrived!" message at destination
   - Tap "Done" to return to normal map

### Changing Source Location

1. Tap "Directions" on any destination
2. In the route details, tap on "Your location"
3. Search for a different starting point
4. Route automatically recalculates

## Project Structure

```
lib/
├── app.dart                    # App configuration
├── main.dart                   # Entry point
├── common/                     # Shared utilities
├── features/
│   ├── home/
│   │   ├── provider/
│   │   │   └── map_provider.dart          # State management
│   │   ├── repository/
│   │   │   └── map_repository.dart        # API calls
│   │   ├── screen/
│   │   │   └── map_screen.dart            # Main map screen
│   │   └── widgets/
│   │       ├── arrival_dialog.dart        # Arrival notification
│   │       ├── current_location_button.dart
│   │       ├── map_types_screen.dart      # Map type selector
│   │       ├── navigation_details.dart    # Nav info panel
│   │       ├── routes_details.dart        # Route planning UI
│   │       └── search_bar_widget.dart     # Search interface
│   └── search/
│       ├── screen/
│       │   └── address_search_screen.dart # Place search
│       └── widgets/
│           └── place_icon_data.dart       # Category icons
├── routes/                     # App routing
└── services/
    └── location_service.dart   # GPS location service
```

## Technologies Used

- **Flutter** - UI framework
- **Riverpod** - State management
- **Google Maps Flutter** - Map integration
- **Location** - GPS services
- **Dio** - HTTP client for API calls
- **Intl** - Date/time formatting
- **Geoapify API** - Route calculation and geocoding

## Key Features Implementation

### Navigation Tracking
- Uses `StreamSubscription` for continuous GPS updates
- Haversine formula for accurate distance calculations
- Bearing calculation for map rotation
- Dynamic polyline splitting based on user position

### Camera Management
- 60° tilt angle for 3D perspective
- 18.5x zoom for optimal navigation view
- User position at bottom, destination ahead
- Smooth camera animations during movement

### Performance Optimizations
- Debounced search input (500ms delay)
- Efficient polyline updates
- Proper stream subscription cleanup
- Mounted checks for context safety

## API Usage

### Geoapify Routes API
- Endpoint: `/v1/routing`
- Supports multiple transport modes
- Returns detailed route geometry
- Provides distance and duration metrics

### Google Maps
- Geocoding for place search
- Interactive map rendering
- Marker and polyline overlays
- Circle radius visualization

## Permissions

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET"/>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location for navigation.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to location for navigation.</string>
```

## Troubleshooting

### Common Issues

**Map not displaying**
- Verify API key is correctly configured
- Check that Maps SDK is enabled in Google Cloud Console
- Ensure internet connection is available

**Location not working**
- Grant location permissions in device settings
- Enable GPS/Location services
- Check for location permission in app settings

**Routes not calculating**
- Verify Geoapify API key in `.env`
- Check internet connectivity
- Ensure source and destination are valid

**Navigation not starting**
- Get current location first (tap location button)
- Ensure route is calculated before starting
- Check GPS signal strength

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Future Enhancements

- [ ] Voice-guided navigation
- [ ] Offline map support
- [ ] Save favorite locations
- [ ] Route history
- [ ] Multiple waypoints
- [ ] Traffic information
- [ ] Alternative route suggestions
- [ ] Night mode for navigation
- [ ] Speed limit warnings
- [ ] POI (Points of Interest) along route

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Google Maps Platform for mapping services
- Geoapify for routing API
- Flutter team for the amazing framework
- Open source community for packages and support

---

**Note**: Remember to keep your API keys secure and never commit them to version control. Use environment variables or secure key management systems.
