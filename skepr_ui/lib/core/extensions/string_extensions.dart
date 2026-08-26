extension FormatDoubleExtension on num? {
  String get format {
    if (this == null) return "0";
    final String formatted = this!.toDouble().toStringAsFixed(2);
    return formatted.replaceAll(RegExp(r"\.?0+$"), "");
  }
}
