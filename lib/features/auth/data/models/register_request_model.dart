// import 'package:json_annotation/json_annotation.dart';
// import '../../domain/entities/user.dart';

// part 'register_request_model.g.dart';

// @JsonSerializable()
// class RegisterRequestModel {
//   final String firstName;
//   final String lastName;
//   final String email;
//   final String password;
//   final String? role;

//   const RegisterRequestModel({
//     required this.firstName,
//     required this.lastName,
//     required this.email,
//     required this.password,
//     this.role,
//   });

//   factory RegisterRequestModel.fromJson(Map<String, dynamic> json) =>
//       _$RegisterRequestModelFromJson(json);

//   Map<String, dynamic> toJson() {
//     final json = _$RegisterRequestModelToJson(this);
//     // Remover role si es null para usar el default del backend
//     if (role == null) {
//       json.remove('role');
//     }
//     return json;
//   }

//   /// Factory constructor para crear desde parámetros del domain
//   factory RegisterRequestModel.fromParams({
//     required String firstName,
//     required String lastName,
//     required String email,
//     required String password,
//     UserRole? role,
//   }) {
//     return RegisterRequestModel(
//       firstName: firstName,
//       lastName: lastName,
//       email: email,
//       password: password,
//       role: role?.value,
//     );
//   }

//   @override
//   String toString() =>
//       'RegisterRequestModel(firstName: $firstName, lastName: $lastName, email: $email)';
// }

import '../../domain/entities/user.dart';

class RegisterRequestModel {
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String? role;

  const RegisterRequestModel({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    this.role,
  });

  factory RegisterRequestModel.fromJson(Map<String, dynamic> json) {
    return RegisterRequestModel(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    };

    // Solo agregar role si no es null
    if (role != null) {
      json['role'] = role;
    }

    return json;
  }

  /// Factory constructor para crear desde parámetros del domain
  factory RegisterRequestModel.fromParams({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    UserRole? role,
  }) {
    return RegisterRequestModel(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      role: role?.value,
    );
  }

  @override
  String toString() =>
      'RegisterRequestModel(firstName: $firstName, lastName: $lastName, email: $email)';
}
