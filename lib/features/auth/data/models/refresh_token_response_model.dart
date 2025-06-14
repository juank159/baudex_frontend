class RefreshTokenResponseModel {
  final String token;

  const RefreshTokenResponseModel({required this.token});

  factory RefreshTokenResponseModel.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponseModel(token: json['token'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'token': token};
  }

  @override
  String toString() =>
      'RefreshTokenResponseModel(token: ${token.substring(0, 10)}...)';
}
