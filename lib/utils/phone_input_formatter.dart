import 'package:flutter/services.dart';

///          Telefon numarasını yazarken "5XX XXX XX XX" biçimine sokar.
///
/// TextInputFormatter, kullanıcı her tuşa bastığında çalışır:
/// eski değeri ve yeni değeri alır, ekrana yazılacak değeri döndürür.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Sadece rakamları en fazla 10 hane.
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);

    // 3-3-2-2 gruplarına ayırıp araya boşluk koy.
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 6 || i == 8) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();

    // İmleci her zaman metnin sonuna.
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Kullanıcının girdiği metni sadece rakamlara çevirir.
  /// "532 123 45 67" → "5321234567"
  static String digitsOnly(String formatted) =>
      formatted.replaceAll(RegExp(r'\D'), '');
}
