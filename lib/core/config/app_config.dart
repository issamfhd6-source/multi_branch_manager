class AppConfig {
  AppConfig._();

  static const Duration sessionTimeout = Duration(hours: 8);
  static const Duration syncInterval = Duration(seconds: 60);
  static const String defaultBranchId = 'br_main';
}
