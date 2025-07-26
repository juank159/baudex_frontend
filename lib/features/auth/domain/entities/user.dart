// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

enum UserRole {
  admin('admin'),
  manager('manager'),
  user('user');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.user,
    );
  }
}

enum UserStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended');

  const UserStatus(this.value);
  final String value;

  static UserStatus fromString(String value) {
    return UserStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => UserStatus.active,
    );
  }
}

class User extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final String? avatar;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // MULTITENANT: Información de la organización del usuario
  final String organizationId;
  final String organizationSlug;
  final String? organizationName;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.avatar,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    required this.organizationId,
    required this.organizationSlug,
    this.organizationName,
  });

  // Computed properties
  String get fullName => '$firstName $lastName';

  bool get isActive => status == UserStatus.active;

  bool get isAdmin => role == UserRole.admin;

  bool get isManager => role == UserRole.manager;

  bool get canManageUsers => role == UserRole.admin || role == UserRole.manager;

  // Copy with method for immutability
  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    UserRole? role,
    UserStatus? status,
    String? avatar,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? organizationId,
    String? organizationSlug,
    String? organizationName,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      avatar: avatar ?? this.avatar,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizationId: organizationId ?? this.organizationId,
      organizationSlug: organizationSlug ?? this.organizationSlug,
      organizationName: organizationName ?? this.organizationName,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phone,
    role,
    status,
    avatar,
    lastLoginAt,
    createdAt,
    updatedAt,
    organizationId,
    organizationSlug,
    organizationName,
  ];

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, role: ${role.value}, status: ${status.value})';
  }
}
