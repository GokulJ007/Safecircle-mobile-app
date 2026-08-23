/// Represents an authenticated SafeCircle user.
/// Backed by mock data until the FastAPI backend is available.
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? profileImageUrl;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.profileImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}