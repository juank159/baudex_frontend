// // lib/features/auth/data/models/user_model.dart
// import 'package:json_annotation/json_annotation.dart';
// import '../../domain/entities/user.dart';

// part 'user_model.g.dart';

// @JsonSerializable()
// class UserModel extends User {
//   const UserModel({
//     required String id,
//     required String firstName,
//     required String lastName,
//     required String email,
//     String? phone,
//     required UserRole role,
//     required UserStatus status,
//     String? avatar,
//     DateTime? lastLoginAt,
//     required DateTime createdAt,
//     required DateTime updatedAt,
//   }) : super(
//          id: id,
//          firstName: firstName,
//          lastName: lastName,
//          email: email,
//          phone: phone,
//          role: role,
//          status: status,
//          avatar: avatar,
//          lastLoginAt: lastLoginAt,
//          createdAt: createdAt,
//          updatedAt: updatedAt,
//        );

//   /// Crear UserModel desde JSON
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'] as String,
//       firstName: json['firstName'] as String,
//       lastName: json['lastName'] as String,
//       email: json['email'] as String,
//       phone: json['phone'] as String?,
//       role: _parseUserRole(json['role']),
//       status: _parseUserStatus(json['status']),
//       avatar: json['avatar'] as String?,
//       lastLoginAt:
//           json['lastLoginAt'] != null
//               ? DateTime.parse(json['lastLoginAt'] as String)
//               : null,
//       createdAt: DateTime.parse(json['createdAt'] as String),
//       updatedAt: DateTime.parse(json['updatedAt'] as String),
//     );
//   }

//   /// Convertir UserModel a JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'firstName': firstName,
//       'lastName': lastName,
//       'email': email,
//       'phone': phone,
//       'role': role.value,
//       'status': status.value,
//       'avatar': avatar,
//       'lastLoginAt': lastLoginAt?.toIso8601String(),
//       'createdAt': createdAt.toIso8601String(),
//       'updatedAt': updatedAt.toIso8601String(),
//     };
//   }

//   /// Convertir de Entity a Model
//   factory UserModel.fromEntity(User user) {
//     return UserModel(
//       id: user.id,
//       firstName: user.firstName,
//       lastName: user.lastName,
//       email: user.email,
//       phone: user.phone,
//       role: user.role,
//       status: user.status,
//       avatar: user.avatar,
//       lastLoginAt: user.lastLoginAt,
//       createdAt: user.createdAt,
//       updatedAt: user.updatedAt,
//     );
//   }

//   /// Convertir a Entity
//   User toEntity() {
//     return User(
//       id: id,
//       firstName: firstName,
//       lastName: lastName,
//       email: email,
//       phone: phone,
//       role: role,
//       status: status,
//       avatar: avatar,
//       lastLoginAt: lastLoginAt,
//       createdAt: createdAt,
//       updatedAt: updatedAt,
//     );
//   }

//   /// Crear copia con cambios
//   UserModel copyWith({
//     String? id,
//     String? firstName,
//     String? lastName,
//     String? email,
//     String? phone,
//     UserRole? role,
//     UserStatus? status,
//     String? avatar,
//     DateTime? lastLoginAt,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return UserModel(
//       id: id ?? this.id,
//       firstName: firstName ?? this.firstName,
//       lastName: lastName ?? this.lastName,
//       email: email ?? this.email,
//       phone: phone ?? this.phone,
//       role: role ?? this.role,
//       status: status ?? this.status,
//       avatar: avatar ?? this.avatar,
//       lastLoginAt: lastLoginAt ?? this.lastLoginAt,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }

//   /// Parser para UserRole
//   static UserRole _parseUserRole(dynamic value) {
//     if (value == null) return UserRole.user;
//     if (value is UserRole) return value;
//     if (value is String) return UserRole.fromString(value);
//     return UserRole.user;
//   }

//   /// Parser para UserStatus
//   static UserStatus _parseUserStatus(dynamic value) {
//     if (value == null) return UserStatus.active;
//     if (value is UserStatus) return value;
//     if (value is String) return UserStatus.fromString(value);
//     return UserStatus.active;
//   }

//   @override
//   String toString() {
//     return 'UserModel(id: $id, fullName: $fullName, email: $email, role: ${role.value})';
//   }
// }

// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required String id,
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    required UserRole role,
    required UserStatus status,
    String? avatar,
    DateTime? lastLoginAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String organizationId,
    required String organizationSlug,
    String? organizationName,
  }) : super(
         id: id,
         firstName: firstName,
         lastName: lastName,
         email: email,
         phone: phone,
         role: role,
         status: status,
         avatar: avatar,
         lastLoginAt: lastLoginAt,
         createdAt: createdAt,
         updatedAt: updatedAt,
         organizationId: organizationId,
         organizationSlug: organizationSlug,
         organizationName: organizationName,
       );

  /// Crear UserModel desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: _parseUserRole(json['role']),
      status: _parseUserStatus(json['status']),
      avatar: json['avatar'] as String?,
      lastLoginAt:
          json['lastLoginAt'] != null
              ? DateTime.parse(json['lastLoginAt'] as String)
              : null,
      // El backend no envía createdAt/updatedAt en register, usar fechas por defecto
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt:
          json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now(),
      // MULTITENANT: Información de la organización
      organizationId: json['organizationId'] as String? ?? '',
      organizationSlug: json['organizationSlug'] as String? ?? '',
      organizationName: json['organizationName'] as String?,
    );
  }

  /// Convertir UserModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'status': status.value,
      'avatar': avatar,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'organizationId': organizationId,
      'organizationSlug': organizationSlug,
      'organizationName': organizationName,
    };
  }

  /// Convertir de Entity a Model
  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      status: user.status,
      avatar: user.avatar,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      organizationId: user.organizationId,
      organizationSlug: user.organizationSlug,
      organizationName: user.organizationName,
    );
  }

  /// Convertir a Entity
  User toEntity() {
    return User(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      role: role,
      status: status,
      avatar: avatar,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      organizationId: organizationId,
      organizationSlug: organizationSlug,
      organizationName: organizationName,
    );
  }

  /// Crear copia con cambios
  UserModel copyWith({
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
    return UserModel(
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

  /// Parser para UserRole
  static UserRole _parseUserRole(dynamic value) {
    if (value == null) return UserRole.user;
    if (value is UserRole) return value;
    if (value is String) return UserRole.fromString(value);
    return UserRole.user;
  }

  /// Parser para UserStatus
  static UserStatus _parseUserStatus(dynamic value) {
    if (value == null) return UserStatus.active;
    if (value is UserStatus) return value;
    if (value is String) return UserStatus.fromString(value);
    return UserStatus.active;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, email: $email, role: ${role.value})';
  }
}
