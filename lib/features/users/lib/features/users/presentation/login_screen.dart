import 'package:flutter/material.dart';

import '../domain/auth_models.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<AuthSession> onAuthenticated;

  const LoginScreen({
    super.key,
    required this.onAuthenticated,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController(text: 'مدير النظام');
  final _branchCtrl = TextEditingController(text: 'branch_main');
  String _selectedRoleId = 'admin';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  void _login() {
    final cleanName = _nameCtrl.text.trim().isEmpty
        ? 'مستخدم محلي'
        : _nameCtrl.text.trim();
    final cleanBranch = _branchCtrl.text.trim().isEmpty
        ? 'branch_main'
        : _branchCtrl.text.trim();

    final isAdmin = _selectedRoleId == 'admin';
    final role = RoleModel(
      id: _selectedRoleId,
      name: isAdmin ? 'مدير عام' : 'مستخدم فرع',
      scope: isAdmin ? 'all' : 'branch',
      permissions: const <String, bool>{},
    );

    final user = UserModel(
      id: 'usr_$_selectedRoleId',
      name: cleanName,
      roleId: role.id,
      branchIds: <String>[cleanBranch],
      isActive: true,
    );

    final now = DateTime.now();
    final session = AuthSession(
      user: user,
      role: role,
      deviceId: 'android_device',
      signedInAt: now,
      lastActivityAt: now,
    );

    widget.onAuthenticated(session);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول المحلي'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'اسم المستخدم',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedRoleId,
            decoration: const InputDecoration(
              labelText: 'الصلاحية / الدور',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem<String>(
                value: 'admin',
                child: Text('مدير عام (admin)'),
              ),
              DropdownMenuItem<String>(
                value: 'staff',
                child: Text('مستخدم فرع (staff)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedRoleId = val);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _branchCtrl,
            decoration: const InputDecoration(
              labelText: 'معرّف الفرع',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _login,
            child: const Text('دخول إلى النظام'),
          ),
        ],
      ),
    );
  }
}
