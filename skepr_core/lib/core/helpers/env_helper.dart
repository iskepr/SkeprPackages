import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";

abstract class EnvHelper {
  static Future<void> load({
    String fileName = ".env",
    List<String> overrideWithFiles = const [],
    Map<String, String> mergeWith = const {},
    bool isOptional = false,
    Parser parser = const Parser(),
  }) => dotenv.load(
    fileName: fileName,
    overrideWithFiles: overrideWithFiles,
    mergeWith: mergeWith,
    isOptional: isOptional,
    parser: parser,
  );

  static String get(String key, {String defaultValue = ""}) {
    if (!kIsWeb) {
      const webEnv = bool.hasEnvironment("FLUTTER_WEB")
          ? {}
          : <String, String>{};

      if (dotenv.isInitialized && dotenv.env.containsKey(key)) {
        return dotenv.env[key]!;
      }
      return webEnv[key] ?? defaultValue;
    }

    if (dotenv.isInitialized && dotenv.env.containsKey(key)) {
      final value = dotenv.env[key];
      if (value != null && value.isNotEmpty) return value;
    }

    return defaultValue;
  }
}
