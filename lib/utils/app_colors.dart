import 'package:flutter/material.dart';
import 'package:hexcolor/hexcolor.dart';

///                      UNICAR renk paleti.

/// HexColor bir constructor içinde metni çözümlediği için `const` olamaz,
/// bu yüzden alanlar `static final`.
class AppColors {
  AppColors._(); // Bu sınıftan nesne üretilmesin, sadece AppColors.primary gibi kullanılsın.

  static final Color primary = HexColor('#6366F1'); // indigo: ana butonlar, odak
  static final Color secondary = HexColor('#22D3EE'); // camgöbeği: ilerleme çubuğu
  static final Color accent = HexColor('#F472B6'); // pembe: vurgular
  static final Color background = HexColor('#0F172A'); // ekran arka planı
  static final Color surface = HexColor('#1E293B'); // kart ve metin alanı dolgusu
  static final Color border = HexColor('#334155'); // kenarlıklar
  static final Color textPrimary = HexColor('#F1F5F9'); // ana metin
  static final Color textSecondary = HexColor('#94A3B8'); // açıklama metinleri
  static final Color error = HexColor('#F87171'); // hata mesajları
  static final Color success = HexColor('#34D399'); // başarı, onay tiki
  // şifre gücü çubuğundaki "orta" seviye için sarı.
  static final Color warning = HexColor('#FBBF24');
}
