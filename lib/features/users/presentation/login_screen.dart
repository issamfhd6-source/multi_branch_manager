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
  UserRole _selectedRole = UserRole.admin;

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

    final session = AuthSession(
      user: AppUserModel(
        id: 'usr_${_selectedRole.name}',
        name: cleanName,
        role: _selectedRole,
        assignedBranchId:
            _selectedRole == UserRole.admin ? null : cleanBranch,
      ),
      sessionToken: 'local_${DateTime.now().millisecondsSinceEpoch}',
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      isLocalOfflineSession: true,
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
          DropdownButtonFormField<UserRole>(
            value: _selectedRole,
            decoration: const InputDecoration(
              labelText: 'الصلاحية / الدور',
              border: OutlineInputBorder(),
            ),
            items: UserRole.values
                .map(
                  (r) => DropdownMenuItem<UserRole>(
                    value: r,
                    child: Text(r.name),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedRole = val);
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _branchCtrl,
            decoration: const InputDecoration(
              labelText: 'معرّف الفرع (لغير الأدمن)',
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
