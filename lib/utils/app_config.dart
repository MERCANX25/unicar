/// 
/// 
/// Uygulama genelindeki açma/kapama ayarları .
///
class AppConfig {
  AppConfig._();

  /// E-posta doğrulaması zorunlu mu?
  ///
  /// false (şu an): Geliştirme ve test sırasında doğrulama maili beklemeden
  ///   giriş yapılabilir; kullanıcı doğrudan Ana Sayfa'ya gider.
  ///   Doğrulama maili yine de gönderilir.
  /// true: Doğrulanmamış kullanıcı Ana Sayfa yerine doğrulama ekranını görür.
  ///
  /// Teslim sürümünde kapalı: demo e-posta adreslerinin gerçek posta kutusu
  /// olmadığı için doğrulama bağlantısı açılamaz (bkz. README).
  static const bool requireEmailVerification = false;
}
