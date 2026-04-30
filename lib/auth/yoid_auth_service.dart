import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class YoIDAuthService {
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  // OIDC Configuration
  static const String _clientId = 'mop-app-client';
  static const String _redirectUrl = 'in.myonepercent.app://callback'; // Placeholder scheme
  static const String _issuer = 'https://auth.yoid.in'; // Placeholder YoID issuer URL
  static const String _discoveryUrl = '$_issuer/.well-known/openid-configuration';

  Future<Map<String, dynamic>?> login() async {
    try {
      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUrl,
          issuer: _issuer,
          discoveryUrl: _discoveryUrl,
          scopes: ['openid', 'profile', 'minimal_age_verification'],
        ),
      );

      if (result != null && result.idToken != null) {
        // Parse the JWT claims
        Map<String, dynamic> decodedToken = JwtDecoder.decode(result.idToken!);
        
        // Extract claims
        String yoidId = decodedToken['sub']; // DID or unique ID
        bool isAgeVerified = decodedToken['minimal_age_verification'] ?? false;
        
        // Store session locally securely
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('yoid_id', yoidId);
        await prefs.setBool('is_age_verified', isAgeVerified);
        await prefs.setString('id_token', result.idToken!);
        
        return {
          'yoid_id': yoidId,
          'is_age_verified': isAgeVerified,
        };
      }
    } catch (e) {
      print('YoID Login Error: $e');
      return null;
    }
    return null;
  }
}
