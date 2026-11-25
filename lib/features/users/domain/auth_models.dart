class UserModel {
  final String id;
  final String name;
  final String roleId;
  final List<String> branchIds;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.roleId,
    required this.branchIds,
    required this.isActive,
  });
}

class RoleModel {
  final String id;
  final String name;
  final String scope;
  final Map<String, bool> permissions;

  const RoleModel({
    required this.id,
    required this.name,
    required this.scope,
    required this.permissions,
  });
}

class AuthSession {
  final UserModel user;
  final RoleModel role;
  final String deviceId;
  final DateTime? signedInAt;
  final DateTime? lastActivityAt;

  const AuthSession({
    required this.user,
    required this.role,
    required this.deviceId,
    this.signedInAt,
    this.lastActivityAt,
  });
}
