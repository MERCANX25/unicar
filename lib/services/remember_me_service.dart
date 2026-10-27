import 'package:shared_preferences/shared_preferences.dart';

/// "Beni hatırla" tercihini telefonda saklar.
///
/// SharedPreferences: telefonda küçük ayarları (açık/kapalı, kısa metin)
/// 
class RememberMeService {
  RememberMeService._();

  // Telefonda saklanan değerlerin anahtarları (adları).
  static const _rememberKey = 'beni_hatirla';
  static const _emailKey = 'kayitli_eposta';

  /// "Beni hatırla" açık mı? Hiç seçim yapılmadıysa varsayılan: açık.
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberKey) ?? true;
  }

  /// Giriş kutusuna önceden yazılacak e-posta (yoksa null).
  static Future<String?> savedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Başarılı giriş veya kayıttan sonra tercihi kaydeder.
  /// Hatırla açıksa e-postayı da saklar, kapalıysa siler.
  static Future<void> save({
    required bool remember,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberKey, remember);
    if (remember) {
      await prefs.setString(_emailKey, email);
    } else {
      await prefs.remove(_emailKey);
    }
  }
}
