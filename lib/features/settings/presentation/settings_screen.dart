import 'package:flutter/material.dart';

import '../../reset/data/reset_service.dart';
import '../../users/domain/auth_models.dart';
import '../data/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final SettingsService settingsService;
  final ResetService resetService;
  final AuthSession session;
  final bool darkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsScreen({
    super.key,
    required this.settingsService,
    required this.resetService,
    required this.session,
    required this.darkMode,
    required this.onDarkModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDark;
  bool _resetting = false;

  @override
  void initState() {
    super.initState();
    _isDark = widget.darkMode;
  }

  Future<void> _toggleDark(bool val) async {
    setState(() => _isDark = val);
    widget.onDarkModeChanged(val);
    try {
      await widget.settingsService.saveSetting(
        session: widget.session,
        key: 'dark_mode',
        value: val,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تنبيه الإعدادات: $e')),
      );
    }
  }

  Future<void> _confirmReset() async {
    if (_resetting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد تصفير البيانات المحلية'),
        content: const Text(
          'سيتم حذف الفواتير وعناصرها والمخزون وقائمة المزامنة المحلية فقط. هل أنت متأكد؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد التصفير'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() => _resetting = true);
    try {
      await widget.resetService.resetLocalOperationalData(
        session: widget.session,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تصفير البيانات التشغيلية المحلية.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر التصفير: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _resetting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: ListTile(
              title: const Text('المستخدم الحالي'),
              subtitle: Text(
                '${widget.session.user.name} (${widget.session.role.name})',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('الوضع الليلي (Dark Mode)'),
              value: _isDark,
              onChanged: _toggleDark,
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              title: Text('نسبة الليرة المزدوجة'),
              subtitle: Text('ثابتة 1 : 100 (ليرة جديدة ↔ ليرة قديمة)'),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _resetting ? null : _confirmReset,
            icon: const Icon(Icons.delete_forever),
            label: Text(
              _resetting
                  ? 'جاري التصفير...'
                  : 'تصفير البيانات التشغيلية المحلية',
            ),
          ),
        ],
      ),
    );
  }
}
