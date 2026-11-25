import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/domain_models.dart';
import '../../exchange_rate/data/exchange_rate_service.dart';
import '../../insights/presentation/insights_and_calc_screen.dart';
import '../../inventory/data/inventory_service.dart';
import '../../inventory/presentation/inventory_screen.dart';
import '../../pos/data/pos_service.dart';
import '../../pos/presentation/pos_screen.dart';
import '../../reports/data/reports_service.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../reset/data/reset_service.dart';
import '../../settings/data/settings_service.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../users/data/audit_service.dart';
import '../../users/domain/auth_models.dart';
import '../../users/domain/permission_middleware.dart';

class MainShellScreen extends StatefulWidget {
  final AppDatabase db;
  final AuthSession session;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;
  final VoidCallback onLogout;

  const MainShellScreen({
    super.key,
    required this.db,
    required this.session,
    required this.darkMode,
    required this.onDarkModeChanged,
    required this.onLogout,
  });

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  List<ProductModel> _products = [];

  late final PermissionMiddleware _permissions;
  late final AuditService _audit;
  late final ExchangeRateService _rateService;
  late final InventoryService _inventoryService;
  late final PosService _posService;
  late final ReportsService _reportsService;
  late final SettingsService _settingsService;
  late final ResetService _resetService;

  String get _activeBranchId =>
      widget.session.user.assignedBranchId ?? 'branch_main';

  @override
  void initState() {
    super.initState();
    _permissions = PermissionMiddleware();
    _audit = AuditService(widget.db);
    _rateService = ExchangeRateService(widget.db, _permissions, _audit);
    _inventoryService =
        InventoryService(widget.db, _permissions, _audit, _rateService);
    _posService = PosService(widget.db, _permissions, _audit, _rateService);
    _reportsService = ReportsService(widget.db, _permissions);
    _settingsService = SettingsService(widget.db, _permissions);
    _resetService = ResetService(widget.db, _permissions, _audit);
    _bootstrapInitialProducts();
  }

  Future<void> _bootstrapInitialProducts() async {
    try {
      final list = await _inventoryService.getAllProducts();
      if (!mounted) return;
      setState(() => _products = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      PosScreen(
        posService: _posService,
        session: widget.session,
        branchId: _activeBranchId,
        availableProducts: _products,
      ),
      InventoryScreen(
        inventoryService: _inventoryService,
        session: widget.session,
        branchId: _activeBranchId,
        onProductsChanged: (updated) {
          if (mounted) {
            setState(() => _products = updated);
          }
        },
      ),
      ReportsScreen(
        reportsService: _reportsService,
        session: widget.session,
        branchId: _activeBranchId,
      ),
      const InsightsAndCalcScreen(),
      SettingsScreen(
        settingsService: _settingsService,
        resetService: _resetService,
        session: widget.session,
        darkMode: widget.darkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'نقطة البيع',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'المخزون',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'التقارير',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'الحاسبة',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
