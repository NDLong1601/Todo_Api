class UserInfo {
  String username;
  String email;

  UserInfo({required this.username, required this.email});

  // Factory constructor to create a User object from a JSON map
  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }
}

class UserLoginRequest {
  String username;
  String password;
  int expiresInMins;

  UserLoginRequest({
    required this.expiresInMins,
    required this.password,
    required this.username,
  });

  // Method to convert a User object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'expiresInMins': expiresInMins,
    };
  }
}
