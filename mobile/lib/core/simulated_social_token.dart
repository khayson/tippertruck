import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Mirrors API SimulatedSocialVerifier token format:
/// base64url(payload).base64url(hmac_sha256(payload, secret))
class SimulatedSocialToken {
  static const defaultSecret = String.fromEnvironment(
    'SOCIAL_DEMO_SECRET',
    defaultValue: 'tippertruck-social-demo-secret',
  );

  static String mint({
    required String provider,
    required String sub,
    required String email,
    required String name,
    String? secret,
    int ttlSeconds = 3600,
  }) {
    final payload = jsonEncode({
      'provider': provider,
      'sub': sub,
      'email': email.toLowerCase(),
      'name': name,
      'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + ttlSeconds,
    });
    final key = utf8.encode(secret ?? defaultSecret);
    final encodedPayload = _base64Url(utf8.encode(payload));
    final signature = _base64Url(
      Hmac(sha256, key).convert(utf8.encode(payload)).bytes,
    );
    return '$encodedPayload.$signature';
  }

  static String _base64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
