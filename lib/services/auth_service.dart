import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

///            Firebase ile ilgili hataları temsil eden sınıf.
/// 
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// FİREBASE İLE İLETİŞİM KURAN SERVİS
/// Ekranlar Firebase'i doğrudan bilmez, sadece bu servisi çağırır.
class AuthService {
  // Singleton: uygulama boyunca tek bir AuthService nesnesi olur.
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // "users": her belge bir kullanıcının profili, belge kimliği = uid.
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');


  CollectionReference<Map<String, dynamic>> get _allowedEmails =>
      _firestore.collection('izinli_mailler');

  /// Şu an oturum açmış kullanıcı var mı?
  bool get isLoggedIn => _auth.currentUser != null;

  /// Oturumdaki kullanıcı e-postasını doğruladı mı?
  /// bu bilgi telefonda önbellekte tutulur; güncel hali için
  /// [reloadAndCheckVerified] kullanılır.
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Oturumdaki kullanıcının e-posta adresi (doğrulama ekranında gösterilir).
  String get currentEmail => _auth.currentUser?.email ?? '';

  
  /// Firestore'da izinli_mailler belgesi varsa true 
  Future<bool> isEmailAllowed(String email) async {
    try {
      // Source.server: telefondaki eski kopyaya değil, her zaman sunucuya sor.
      final doc = await _allowedEmails
          .doc(email)
          .get(const GetOptions(source: Source.server));
      return doc.exists;
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// UNICAR kayıt akışı.
  /// 1) Firebase Authentication'da hesap oluşturul.
  /// 2) Tüm profil bilgileri Firestore'da users belgesine yazılır.
  /// 3) E-posta doğrulama bağlantısı gönderilir.
  ///
  /// Oturum açık kalır: kullanıcı izin ekranlarından sonra doğrulama
  /// kontrolüne yönlendirilir.
  ///
  /// Dönüş değeri: doğrulama e-postası gönderilebildi mi?
  Future<bool> registerUnicar({
    required String adSoyad,
    required String email,
    required String sifre,
    required String telefon,
    required UserRole rol,
    required bool kvkkOnay,
  }) async {
    final User firebaseUser;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: sifre,
      );
      firebaseUser = credential.user!;
    } catch (e) {
      throw _toAuthException(e);
    }

    final user = AppUser(
      uid: firebaseUser.uid,
      adSoyad: adSoyad,
      email: email,
      telefon: telefon,
      rol: rol,
      kvkkOnay: kvkkOnay,
      // olusturmaTarihi verilmedi: toMap() sunucu saatini (serverTimestamp) yazar.
    );

    try {
      await _users.doc(user.uid).set(user.toMap());
    } catch (e) {
      // Profil yazılamadıysa yarım kalmış hesabı geri alıyoruz. Yoksa kullanıcı
      // tekrar denediğinde "bu e-posta zaten kayıtlı" hatası alırdı.
      try {
        await firebaseUser.delete();
      } catch (_) {
        // Silme de başarısız olursa asıl hatayı göstermeye devam ediyoruz.
      }
      throw _toAuthException(e);
    }

    // Hesap oluştu; doğrulama e-postası gitmese bile kaydı başarısız saymıyoruz.
    // Kullanıcı doğrulama ekranından tekrar gönderebilir.
    try {
      await firebaseUser.sendEmailVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// E-posta ve şifre ile giriş.
  /// Girişten sonra ekran [isEmailVerified] ile doğrulamayı kontrol eder.
  Future<void> login({required String email, required String sifre}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: sifre);
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// "Şifremi unuttum": e-postaya şifre sıfırlama bağlantısı gönderir.
  /// Kullanıcı maildeki bağlantıya tıklayınca Firebase'in sayfasında
  /// yeni şifresini belirler; sonra uygulamaya yeni şifreyle girer.
  ///
  /// Güvenlik notu: Firebase, bu e-postayla bir hesap olmasa bile hata
  /// vermez. Böylece kötü niyetli biri "bu mail kayıtlı mı?" diye deneme
  /// yaparak kayıtlı kullanıcıları öğrenemez.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Doğrulama e-postasını tekrar gönderir.
  Future<void> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Kullanıcı bilgisini sunucudan yeniler ve doğrulandı mı diye bakar.
  /// Kullanıcı maildeki bağlantıya tıklasa bile telefondaki bilgi eski
  /// kalır; reload() güncel bilgiyi Firebase'den tekrar çeker.
  Future<bool> reloadAndCheckVerified() async {
    try {
      await _auth.currentUser?.reload();
      // reload'dan sonra currentUser'ı tekrar okumak gerekir.
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      throw _toAuthException(e);
    }
  }

  /// Oturum açmış kullanıcının profilini Firestore'dan okur.
  Future<AppUser?> getCurrentUserProfile() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final doc = await _users.doc(firebaseUser.uid).get();
    final data = doc.data();
    if (data == null) {
      // Profil belgesi yoksa en azından e-postayı gösterebilelim.
      return AppUser(
        uid: firebaseUser.uid,
        adSoyad: '',
        email: firebaseUser.email ?? '',
      );
    }
    return AppUser.fromMap(firebaseUser.uid, data);
  }

  /// Oturumu kapatır.
  Future<void> logout() => _auth.signOut();

  // ---------------------------------------------------------------------------
  // Hata çevirisi
  // ---------------------------------------------------------------------------

  /// Herhangi bir hatayı, ekranda gösterilecek Türkçe AuthException'a çevirir.
  /// Sıra önemli: FirebaseAuthException da bir FirebaseException olduğu için
  /// önce o kontrol edilir.
  AuthException _toAuthException(Object error) {
    if (error is AuthException) return error;
    if (error is FirebaseAuthException) {
      return AuthException(_authHataMesaji(error.code));
    }
    if (error is FirebaseException) {
      return AuthException(_firestoreHataMesaji(error.code));
    }
    return const AuthException(_genelHata);
  }

  static const _genelHata = 'Beklenmeyen bir hata oluştu. Lütfen tekrar dene.';

  // Firebase Authentication hata kodları (giriş/kayıt).
  String _authHataMesaji(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'İnternet bağlantını kontrol et.';
      case 'email-already-in-use':
        return 'Bu e-posta zaten kayıtlı.';
      case 'weak-password':
        return 'Şifre çok zayıf. Daha uzun ve karmaşık bir şifre dene.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.';
      // Yeni Firebase sürümleri güvenlik için "kullanıcı yok" ile
      // "şifre yanlış" durumunu ayırt etmez, hepsi invalid-credential döner.
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      default:
        return _genelHata;
    }
  }

  // Cloud Firestore hata kodları (okul listesi kontrolü, profil kaydı).
  String _firestoreHataMesaji(String code) {
    switch (code) {
      case 'unavailable':
        return 'İnternet bağlantını kontrol et.';
      case 'permission-denied':
        return 'Okul kayıtlarına erişilemedi. Lütfen daha sonra tekrar dene.';
      default:
        return _genelHata;
    }
  }
}
