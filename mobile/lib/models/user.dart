class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  String get firstName => name.split(' ').first;
}
