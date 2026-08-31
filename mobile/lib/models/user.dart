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
    // Guard against accidental JsonResource wrapping: { "data": { ...user } }
    final map = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    return User(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      role: (map['role'] as String?) ?? 'client',
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  bool get isClient => role == 'client';
  bool get isOperator => role == 'operator';
  bool get isAdmin => role == 'admin';

  String get firstName => name.split(' ').first;
}
