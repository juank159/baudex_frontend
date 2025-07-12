// import 'package:json_annotation/json_annotation.dart';

// part 'change_password_request_model.g.dart';

// @JsonSerializable()
// class ChangePasswordRequestModel {
//   final String currentPassword;
//   final String newPassword;
//   final String confirmPassword;

//   const ChangePasswordRequestModel({
//     required this.currentPassword,
//     required this.newPassword,
//     required this.confirmPassword,
//   });

//   factory ChangePasswordRequestModel.fromJson(Map<String, dynamic> json) =>
//       _$ChangePasswordRequestModelFromJson(json);

//   Map<String, dynamic> toJson() => _$ChangePasswordRequestModelToJson(this);

//   @override
//   String toString() => 'ChangePasswordRequestModel(newPassword: [HIDDEN])';
// }

class ChangePasswordRequestModel {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequestModel({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  factory ChangePasswordRequestModel.fromJson(Map<String, dynamic> json) {
    return ChangePasswordRequestModel(
      currentPassword: json['currentPassword'] as String,
      newPassword: json['newPassword'] as String,
      confirmPassword: json['confirmPassword'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }

  @override
  String toString() => 'ChangePasswordRequestModel(newPassword: [HIDDEN])';
}
