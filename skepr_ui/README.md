# Skepr UI

A modern and highly customizable Flutter UI toolkit[cite: 1]. Designed with built-in localization (Arabic/English), glassmorphism styles, structured section widgets with filtering/sorting/search, interactive inputs, and bidirectional Markdown support[cite: 1].

## Features

* **Smart Sections (`Section<T>`):** Pre-built lists and containers featuring built-in search bar, dynamic sorting, and multi-condition filter chips[cite: 1].
* **Comprehensive Inputs:** Modern text fields, searchable/expandable select pickers (`SelectInput`, `MulteSelect`), segmented radio bars, and number inputs[cite: 1].
* **Bi-directional Markdown (`SkeprMarkdown`):** GitHub-styled markdown viewer with automatic text direction detection (RTL/LTR) per line[cite: 1].
* **Material & Theming Helpers:** `MyMaterial` wrapper supporting glassmorphism and solid styles, custom dialogs, bottom sheets, and haptic feedback utilities[cite: 1].
* **Navigation UI:** Customizable bottom navigation bar and page wrappers with sticky headers[cite: 1].

## Getting Started

Add `skepr_ui` to your `pubspec.yaml`:

```yaml
dependencies:
  skepr_ui: ^0.0.0

```

## Usage

### 1. Setup SkeprMaterial

```dart
import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: SkeprMaterial.messengerKey,
      localizationsDelegates: SkeprLocalizations.localizationsDelegates,
      supportedLocales: SkeprLocalizations.supportedLocales,
      home: const MainScreen(),
    );
  }
}

```

### 2. Structured Section Example

```dart
Section<User>(
  title: "المستخدمين",
  listData: usersList,
  searchMatcher: (user) => user.name,
  itemBuilder: (context, user, index) => CustomListTile(
    title: user.name,
    subtitle: user.email,
  ),
);

```

### 3. Bi-directional Markdown Viewer

```dart
SkeprMarkdown(
  content: """
# عنوان المقال
هذا النص باللغة العربية وسيتم ضبط اتجاهه تلقائياً.

- Point 1 in English
- Point 2
  """,
);

```

## License

MIT License

