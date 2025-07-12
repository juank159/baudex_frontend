// import 'package:json_annotation/json_annotation.dart';

// part 'update_profile_request_model.g.dart';

// @JsonSerializable()
// class UpdateProfileRequestModel {
//   final String? firstName;
//   final String? lastName;
//   final String? phone;
//   final String? avatar;

//   const UpdateProfileRequestModel({
//     this.firstName,
//     this.lastName,
//     this.phone,
//     this.avatar,
//   });

//   factory UpdateProfileRequestModel.fromJson(Map<String, dynamic> json) =>
//       _$UpdateProfileRequestModelFromJson(json);

//   Map<String, dynamic> toJson() {
//     final json = _$UpdateProfileRequestModelToJson(this);
//     // Remover campos null para no enviarlos al backend
//     json.removeWhere((key, value) => value == null);
//     return json;
//   }

//   /// Factory constructor para crear desde parámetros del domain
//   factory UpdateProfileRequestModel.fromParams({
//     String? firstName,
//     String? lastName,
//     String? phone,
//     String? avatar,
//   }) {
//     return UpdateProfileRequestModel(
//       firstName: firstName,
//       lastName: lastName,
//       phone: phone,
//       avatar: avatar,
//     );
//   }

//   /// Verificar si hay algún campo para actualizar
//   bool get hasUpdates {
//     return firstName != null ||
//         lastName != null ||
//         phone != null ||
//         avatar != null;
//   }

//   @override
//   String toString() =>
//       'UpdateProfileRequestModel(firstName: $firstName, lastName: $lastName, phone: $phone)';
// }

class UpdateProfileRequestModel {
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;

  const UpdateProfileRequestModel({
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
  });

  factory UpdateProfileRequestModel.fromJson(Map<String, dynamic> json) {
    return UpdateProfileRequestModel(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    // Solo agregar campos que no sean null
    if (firstName != null) json['firstName'] = firstName;
    if (lastName != null) json['lastName'] = lastName;
    if (phone != null) json['phone'] = phone;
    if (avatar != null) json['avatar'] = avatar;

    return json;
  }

  /// Factory constructor para crear desde parámetros del domain
  factory UpdateProfileRequestModel.fromParams({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
  }) {
    return UpdateProfileRequestModel(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      avatar: avatar,
    );
  }

  /// Verificar si hay algún campo para actualizar
  bool get hasUpdates {
    return firstName != null ||
        lastName != null ||
        phone != null ||
        avatar != null;
  }

  @override
  String toString() =>
      'UpdateProfileRequestModel(firstName: $firstName, lastName: $lastName, phone: $phone)';
}
