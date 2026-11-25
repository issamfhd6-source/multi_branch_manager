class DualSypFormatter {
  static const int ratio = 100;

  static String formatDualFromNew(num newSyp) {
    return formatFromNew(newSyp);
  }

  static String formatFromNew(num newSyp) {
    final oldSyp = (newSyp * ratio).round();
    return '${_group(newSyp.round())} ل.س جديدة (${_group(oldSyp)} قديمة)';
  }

  static String formatFromOld(num oldSyp) {
    final newSyp = oldSyp / ratio;
    final newText = newSyp % 1 == 0
        ? _group(newSyp.round())
        : newSyp.toStringAsFixed(2);
    return '$newText ل.س جديدة (${_group(oldSyp.round())} قديمة)';
  }

  static String _group(int value) {
    final neg = value < 0;
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buf.write(',');
      }
      buf.write(digits[i]);
    }
    return neg ? '-${buf.toString()}' : buf.toString();
  }
}
