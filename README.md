# Waste Not Want Not 🥬🍞

A privacy-first mobile app for sharing extra pantry items with your neighbours. Built with Flutter for iOS and Android.

## Concept

Food waste is a massive problem — and often it's as simple as having too many bananas or an extra loaf of bread. **Waste Not Want Not** connects neighbours hyper-locally so surplus food finds a home instead of a bin.

**Two paths, one community:**

- **Waste Not** — You have extras. List what you're sharing, set a pickup address, and choose how far away neighbours can see your listing.
- **Want Not** — You need something. Browse what's available nearby, add items to your pantry, and get a pickup route with addresses grouped by stop.

## Privacy Architecture

This app is designed privacy-first at every layer:

| Principle | Implementation |
|-----------|---------------|
| **No real names** | Users pick an alias ("Baker on 5th", "Sunny Coop") |
| **Location snapping** | GPS coordinates are snapped to a ~500m grid before storage or transmission — your exact home is never revealed |
| **Coarse permissions** | The app requests `ACCESS_COARSE_LOCATION` on Android and explains usage on iOS |
| **Address reveal only on claim** | Pickup addresses are only shown after a user commits to collecting items |
| **No accounts** | The prototype uses on-device storage only — no server, no sign-up |
| **Local-only radius** | Contributors choose how far away their listing is visible (0.5–10 km) |

### Production Privacy Roadmap

For a production release, the local `SharedPreferences` layer should be replaced with one of:

1. **Peer-to-peer mesh** (BLE / Wi-Fi Direct) — data literally never leaves the neighbourhood
2. **E2E-encrypted relay** — server sees only opaque blobs keyed by geohash prefix
3. **Onion-routed queries** — IP addresses can't be correlated with physical locations

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── theme/
│   └── app_theme.dart             # Warm, organic Material 3 theme
├── models/
│   └── pantry_item.dart           # PantryItem, CartItem, PickupStop, FoodCategory
├── services/
│   ├── location_service.dart      # Privacy-preserving geolocation
│   └── local_data_service.dart    # On-device data layer + sample seeding
└── screens/
    ├── home_screen.dart           # Split choice: Waste Not / Want Not
    ├── waste_not_screen.dart      # Contribute items + add-item form
    ├── want_not_screen.dart       # Browse nearby items + cart
    └── checkout_screen.dart       # Grouped pickup route
```

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.1.0
- Xcode (for iOS)
- Android Studio (for Android)

### Run

```bash
cd waste_not_want_not
flutter pub get
flutter run
```

### Build

```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
```

## Design

The visual language uses a **garden-to-table** aesthetic:

- **Palette:** Deep sage, terracotta, honey gold, parchment cream
- **Typography:** Playfair Display (display) + DM Sans (body)
- **Motion:** Staggered fade-ins, scale-on-press cards, slide transitions
- **Iconography:** Food category emojis for instant recognition

The "Waste Not" path uses sage green; the "Want Not" path uses terracotta — keeping the two flows visually distinct while feeling like one cohesive app.

## Features

- **Category filtering** — Browse by Produce, Dairy, Bakery, Canned, etc.
- **Distance control** — Adjustable search radius with bottom sheet slider
- **Expiry dates** — Items show time-sensitivity so nothing goes to waste
- **Swipe to remove** — Cart items can be dismissed with a swipe
- **Grouped pickup route** — Checkout groups items by address with a visual timeline
- **Sample data seeding** — First launch populates nearby sample items so the app isn't empty

## License

MIT
