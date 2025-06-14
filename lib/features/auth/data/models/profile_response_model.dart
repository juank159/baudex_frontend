import 'user_model.dart';

class ProfileResponseModel {
  final UserModel user;

  const ProfileResponseModel({required this.user});

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson()};
  }

  @override
  String toString() => 'ProfileResponseModel(user: ${user.email})';
}
