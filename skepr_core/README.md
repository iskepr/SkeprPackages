# Skepr Core

A robust, lightweight core utility package for Flutter applications[cite: 1]. It provides a unified database abstraction layer (with built-in Supabase support), offline caching with Hive, automatic internet connectivity monitoring, and device identification helpers[cite: 1].

## Features

* **Unified Database Client:** Abstract database interface with an out-of-the-box `SupabaseService` implementation covering Auth and CRUD operations with query filters[cite: 1].
* **Offline Caching & Sync (`DataResource` & `HiveHelper`):** Seamless local caching, cache-first resource handling, and incremental sync management using Hive[cite: 1].
* **Real-time Internet Checker:** Device-level connection checking that distinguishes between active internet access, local network (no internet), and completely disconnected states[cite: 1].
* **Device Service:** Easy cross-platform unique device identifier extraction (Android, iOS, Linux, Web)[cite: 1].
* **Environment Configuration:** Helper for retrieving environment variables safely across platforms[cite: 1].

## Getting Started

Add `skepr_core` to your `pubspec.yaml`:

```yaml
dependencies:
  skepr_core: ^0.0.0

```

## Usage

### 1. Initialize Hive & Database Client

```dart
import "package:skepr_core/skepr_core.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive boxes
  await HiveHelper.init(boxes: ["users", "settings"]);

  // Initialize Supabase client
  final db = SupabaseService();
  await db.init(
    url: "YOUR_SUPABASE_URL",
    anonKey: "YOUR_SUPABASE_ANON_KEY",
  );

  runApp(const MyApp());
}

```

### 2. Internet Connectivity Listener

```dart
import "package:flutter/material.dart";
import "package:skepr_core/skepr_core.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Text("Home").listenToInternet(
        onChange: (context, status) {
          if (status == ConnectionStateStatus.disconnected) {
            // Handle offline state
          }
        },
      ),
    );
  }
}

```

## License

MIT License

