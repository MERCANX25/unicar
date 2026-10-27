///            Form alanlarının doğrulama fonksiyonları.
///            format kontrolü, boş alan kontrolü, şifre gücü, e-posta uzantısı kontrolü
///
class Validators {
  // E-posta regex'i:
  //   [\w.+-]+      -> @ işaretinden önce harf, rakam, _, nokta, + veya -
  //   @             -> tam olarak bir @
  //   [\w-]+        -> alan adı (ör. gmail)
  //   (\.[\w-]+)+   -> en az bir uzantı (ör. .com, .edu.tr)
  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static final RegExp _nameRegex = RegExp(r"^[\p{L}\p{M}' -]+$", unicode: true);

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad Soyad boş olamaz';
    }
    if (value.trim().length < 3) {
      return 'Ad Soyad en az 3 karakter olmalı';
    }
    if (!_nameRegex.hasMatch(value.trim())) {
      return 'Ad Soyad sadece harf içermeli';
    }
    return null;
  }

  static String normalizeEmail(String value) =>
      value.trim().toLowerCase(); //boşlukları at, küçük harfe çevir

  static String? validateEmail(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) {
      return 'E-posta boş olamaz';
    }
    if (!_emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta adresi girin';
    }
    return null;
  }

  /// Şifre Tekrar alanı, asıl şifreyi de bilmek zorunda olduğu için
  /// iki parametre alır. Kullanımı:
  /// `validator: (v) => Validators.validateConfirmPassword(v, sifreController.text)`
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı boş olamaz';
    }
    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // UNICAR kayıt akışı için doğrulayıcılar
  // ---------------------------------------------------------------------------

  static const String asuDomain = '@asu.edu.tr';

  // Türkçe büyük harfler de sayılsın (Ç, Ğ, İ, Ö, Ş, Ü).
  static final RegExp _upperCase = RegExp(r'[A-ZÇĞİÖŞÜ]');
  static final RegExp _lowerCase = RegExp(r'[a-zçğıöşü]');
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9çğıöşüÇĞİÖŞÜ]');

  /// E-posta geçerli formatta ve @asu.edu.tr uzantılı mı?
  /// Doğrulayıcının yanında, alanın sağındaki yeşil tiki göstermek için de kullanılır.
  static bool isAsuEmail(String value) {
    final email = normalizeEmail(value);
    return _emailRegex.hasMatch(email) && email.endsWith(asuDomain);
  }

  // E-posta adreslerinde kullanılamayan Türkçe harfler.
  static final RegExp _turkishChars = RegExp(r'[çğıöşüÇĞİÖŞÜ]');

  static String? validateAsuEmail(String? value) {
    final email = normalizeEmail(value ?? '');
    if (email.isEmpty) {
      return 'E-posta boş olamaz';
    }

    if (_turkishChars.hasMatch(value!)) {
      return 'E-postada Türkçe karakter (ç, ğ, ı, ö, ş, ü) kullanılamaz';
    }
    if (!isAsuEmail(email)) {
      return 'Sadece @asu.edu.tr uzantılı adresler kabul edilir';
    }
    return null;
  }

  /// en az 8 karakter, 1 büyük harf, 1 rakam.
  static String? validateUnicarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş olamaz';
    }
    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }
    if (!_upperCase.hasMatch(value)) {
      return 'Şifre en az 1 büyük harf içermeli';
    }
    if (!_digit.hasMatch(value)) {
      return 'Şifre en az 1 rakam içermeli';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş olamaz';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'Telefon numarası boş olamaz';
    }
    if (digits.length != 10) {
      return 'Telefon numarası 10 haneli olmalı';
    }
    if (!digits.startsWith('5')) {
      return 'Cep telefonu numarası 5 ile başlamalı';
    }
    return null;
  }

  //                şifre gücü hesaplaması: zayıf, orta, güçlü.
  static PasswordStrength passwordStrength(String value) {
    if (value.isEmpty) return PasswordStrength.none;

    final meetsRules =
        value.length >= 8 &&
        _upperCase.hasMatch(value) &&
        _digit.hasMatch(value);
    if (!meetsRules) return PasswordStrength.weak;

    var extras = 0;
    if (_lowerCase.hasMatch(value)) extras++;
    if (_special.hasMatch(value)) extras++;
    if (value.length >= 12) extras++;
    return extras >= 2 ? PasswordStrength.strong : PasswordStrength.medium;
  }
}

enum PasswordStrength { none, weak, medium, strong }
