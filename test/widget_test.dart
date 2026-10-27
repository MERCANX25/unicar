// Bu testler Firebase'e bağlanmaz: sadece doğrulama kurallarını ve
// Giriş formunun hata mesajlarını kontrol eder.
// Çalıştırmak için: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:register_login/screens/login_screen.dart';
import 'package:register_login/utils/phone_input_formatter.dart';
import 'package:register_login/utils/validators.dart';

void main() {
  group('UNICAR doğrulayıcıları', () {
    test('sadece @asu.edu.tr kabul edilir', () {
      expect(Validators.validateAsuEmail('ali@gmail.com'),
          'Sadece @asu.edu.tr uzantılı adresler kabul edilir');
      expect(Validators.validateAsuEmail('Ali.Veli@ASU.edu.tr'), isNull);
      expect(Validators.isAsuEmail('ali@asu.edu.tr.com'), isFalse);
    });

    test('Türkçe karakterler', () {
      // Ad Soyad Türkçe harfleri kabul eder, rakam ve sembol kabul etmez.
      expect(Validators.validateName('Çağrı Öztürk'), isNull);
      expect(Validators.validateName('İlkay Şükrü Ağaoğlu'), isNull);
      expect(Validators.validateName('Ayşe-Nur Gül'), isNull);
      expect(Validators.validateName('Ali 123'), 'Ad Soyad sadece harf içermeli');
      expect(Validators.validateName('Ali@Veli'), 'Ad Soyad sadece harf içermeli');
      // "İ" harfi iki parça (I + üst nokta) olarak gelse de kabul edilir.
      expect(Validators.validateName('İlkay Çelik'), isNull);
      // Tüm Türkçe harfler, büyük ve küçük.
      expect(Validators.validateName('ÇĞİÖŞÜ çğıöşü'), isNull);
      // E-postadaki Türkçe karakter ayrıca belirtilir.
      expect(Validators.validateAsuEmail('ahmet.çelik@asu.edu.tr'),
          'E-postada Türkçe karakter (ç, ğ, ı, ö, ş, ü) kullanılamaz');
      // Türkçe büyük harf (Ş) şifrede büyük harf sayılır.
      expect(Validators.validateUnicarPassword('şifrem12Ş'), isNull);
    });

    test('şifre: 8 karakter, 1 büyük harf, 1 rakam', () {
      expect(Validators.validateUnicarPassword('Abc1'),
          'Şifre en az 8 karakter olmalı');
      expect(Validators.validateUnicarPassword('abcdefg1'),
          'Şifre en az 1 büyük harf içermeli');
      expect(Validators.validateUnicarPassword('Abcdefgh'),
          'Şifre en az 1 rakam içermeli');
      expect(Validators.validateUnicarPassword('ABCDEFG1'), isNull);
    });

    test('şifre gücü', () {
      expect(Validators.passwordStrength(''), PasswordStrength.none);
      expect(Validators.passwordStrength('abc'), PasswordStrength.weak);
      expect(Validators.passwordStrength('ABCDEFG1'), PasswordStrength.medium);
      expect(Validators.passwordStrength('Abcdefg1!'), PasswordStrength.strong);
    });

    test('telefon: 10 hane, 5 ile başlar', () {
      expect(Validators.validatePhone('532 123 45 6'),
          'Telefon numarası 10 haneli olmalı');
      expect(Validators.validatePhone('432 123 45 67'),
          'Cep telefonu numarası 5 ile başlamalı');
      expect(Validators.validatePhone('532 123 45 67'), isNull);
    });

    test('telefon biçimlendirici 5XX XXX XX XX yapar', () {
      final result = PhoneInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '53212345678999'),
      );
      expect(result.text, '532 123 45 67');
      expect(PhoneInputFormatter.digitsOnly(result.text), '5321234567');
    });
  });

  group('Validators', () {
    test('e-posta kuralları', () {
      expect(Validators.validateEmail(''), 'E-posta boş olamaz');
      expect(Validators.validateEmail('ali@'), 'Geçerli bir e-posta adresi girin');
      expect(Validators.validateEmail('ali.veli@ogr.edu.tr'), isNull);
    });

    test('e-posta temizleme (trim + küçük harf)', () {
      expect(Validators.normalizeEmail('  Ali.Veli@ASU.edu.tr '),
          'ali.veli@asu.edu.tr');
      // Boşluklu ve büyük harfli yazım da @asu.edu.tr kontrolünden geçer.
      expect(Validators.validateAsuEmail('  Ali.Veli@ASU.edu.tr '), isNull);
    });

    test('giriş şifresi sadece boşluk kontrolü yapar', () {
      expect(Validators.validateLoginPassword(''), 'Şifre boş olamaz');
      expect(Validators.validateLoginPassword('abc'), isNull);
    });

    test('şifre tekrar kuralı', () {
      expect(Validators.validateConfirmPassword('Abcdefg1', 'Abcdefg2'), 'Şifreler eşleşmiyor');
      expect(Validators.validateConfirmPassword('Abcdefg1', 'Abcdefg1'), isNull);
    });
  });

  testWidgets('boş giriş formu Türkçe hata gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    // Alanlar boşken "Giriş Yap" butonuna bas.
    await tester.tap(find.widgetWithText(FilledButton, 'Giriş Yap'));
    await tester.pump();

    expect(find.text('E-posta boş olamaz'), findsOneWidget);
    expect(find.text('Şifre boş olamaz'), findsOneWidget);
  });
}
