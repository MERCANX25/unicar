import 'package:cloud_firestore/cloud_firestore.dart';

///           UNICAR'da kullanıcının seçebileceği roller.
/// 
///  
enum UserRole {
  yolcu('yolcu', 'Yolcu'),
  surucu('surucu', 'Sürücü'),
  ikisi('ikisi', 'İkisi de');

  final String value;
  final String label;
  const UserRole(this.value, this.label);

  /// Firestore'daki metni enum'a çevirir; bilinmeyen değer için null döner.
  static UserRole? fromValue(String? value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

/// Uygulamadaki bir kullanıcıyı temsil eder.

///
/// Şifre burada TUTULMAZ. Şifreyi Firebase Authentication güvenli şekilde
/// saklar; biz Firestore'a sadece profil bilgilerini (ad soyad, e-posta) yazarız.
class AppUser {
  final String uid; // Firebase'in her kullanıcıya verdiği benzersiz kimlik
  final String adSoyad;
  final String email;


  final String telefon; // sadece rakamlar, ör. "5321234567" (+90 olmadan)
  final UserRole? rol;
  final bool kvkkOnay;
  final DateTime? olusturmaTarihi; // null: henüz Firestore'a yazılmadı

  const AppUser({ // const, çünkü nesne değişmez (immutable)
    required this.uid,
    required this.adSoyad,
    required this.email,
    this.telefon = '',
    this.rol,
    this.kvkkOnay = false,
    this.olusturmaTarihi,
  });

  // Firestore'a yazmak için nesneyi Map'e çeviririz.
  Map<String, dynamic> toMap() {
    return {
      'adSoyad': adSoyad,
      'email': email,
      'telefon': telefon,
      'rol': rol?.value,
      'kvkkOnay': kvkkOnay,
      // Tarih yoksa sunucu saatini kullan: telefonun saati yanlış olsa bile
      // Firestore doğru zamanı yazar.
      'olusturmaTarihi': olusturmaTarihi == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(olusturmaTarihi!),
    };
  }

  // Firestore'dan okunan Map'ten tekrar AppUser nesnesi oluştururuz.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      adSoyad: map['adSoyad'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telefon: map['telefon'] as String? ?? '',
      rol: UserRole.fromValue(map['rol'] as String?),
      kvkkOnay: map['kvkkOnay'] as bool? ?? false,
      // Firestore tarihleri Timestamp olarak döndürür; DateTime'a çeviriyoruz.
      olusturmaTarihi: (map['olusturmaTarihi'] as Timestamp?)?.toDate(),
    );
  }
}
