class DualSypFormatter {
  static const double ratio = 100.0;

  static double newToOld(double newSyp) => newSyp * ratio;

  static double oldToNew(double oldSyp) => oldSyp / ratio;

  static String formatNumber(double value) {
    final isWhole = value % 1 == 0;
    final formatted = isWhole
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
  }

  static String formatNew(double newSyp) => '${formatNumber(newSyp)} ل.س جديدة';

  static String formatOld(double oldSyp) => '${formatNumber(oldSyp)} ل.س قديمة';

  static String formatDualFromNew(double newSyp) {
    final oldSyp = newToOld(newSyp);
    return '${formatNew(newSyp)} (${formatOld(oldSyp)})';
  }

  static String formatDualFromOld(double oldSyp) {
    final newSyp = oldToNew(oldSyp);
    return '${formatNew(newSyp)} (${formatOld(oldSyp)})';
  }
}
