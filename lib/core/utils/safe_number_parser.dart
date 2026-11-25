class SafeNumberParser {
  static double parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) {
      return value.isFinite ? value.toDouble() : fallback;
    }
    final text = value
        .toString()
        .trim()
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('٫', '.');
    if (text.isEmpty) return fallback;
    final parsed = double.tryParse(text);
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed;
  }

  static int parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) {
      return value.isFinite ? value.round() : fallback;
    }
    final d = parseDouble(value, fallback: fallback.toDouble());
    return d.isFinite ? d.round() : fallback;
  }
}
