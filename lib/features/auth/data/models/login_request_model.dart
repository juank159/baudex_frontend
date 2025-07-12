// import 'package:json_annotation/json_annotation.dart';

// part 'login_request_model.g.dart';

// @JsonSerializable()
// class LoginRequestModel {
//   final String email;
//   final String password;

//   const LoginRequestModel({required this.email, required this.password});

//   factory LoginRequestModel.fromJson(Map<String, dynamic> json) =>
//       _$LoginRequestModelFromJson(json);

//   Map<String, dynamic> toJson() => _$LoginRequestModelToJson(this);

//   @override
//   String toString() => 'LoginRequestModel(email: $email)';
// }

class LoginRequestModel {
  final String email;
  final String password;

  const LoginRequestModel({required this.email, required this.password});

  factory LoginRequestModel.fromJson(Map<String, dynamic> json) {
    return LoginRequestModel(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }

  @override
  String toString() => 'LoginRequestModel(email: $email)';
}
