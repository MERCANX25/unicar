import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/remember_me_service.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/password_field.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';


/// Giriş ekranı: e-posta ve şifre ile giriş yapılır. E-posta doğrulanmamışsa
/// doğrulama ekranına yönlendirilir.
/// 
/// 
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override // sateful yapıp değişken yapıyoruz.
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form'un anahtarı: validate() çağırarak tüm alanları tek seferde kontrol ederiz.
  final _formKey = GlobalKey<FormState>();

  // Controller'lar alanlardaki metni okumamızı sağlar.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false; // Firebase'den cevap beklerken true
  bool _rememberMe = true; // "Beni hatırla" kutusu işaretli mi?

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  /// Ekran açılınca kayıtlı tercihi ve e-postayı yükler.
  Future<void> _loadRememberMe() async {
    final remember = await RememberMeService.isEnabled();
    final email = await RememberMeService.savedEmail();
    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      // Daha önce "Beni hatırla" ile giriş yapıldıysa e-posta hazır gelsin.
      if (email != null && _emailController.text.isEmpty) {
        _emailController.text = email;
      }
    });
  }

  /// "Şifremi unuttum" penceresini açar.
  void _showForgotPassword() {
    showDialog<void>(
      context: context,
      builder: (_) => ForgotPasswordDialog(
        initialEmail: Validators.normalizeEmail(_emailController.text),
      ),
    );
  }

  @override
  void dispose() {
    //dispose override edilip geçmiş controller temzleniyor.
    // Ekran kapanınca controller'ları bellekten temizliyoruz.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Doğrulamalardan biri bile hata verirse girişi denemiyoruz.
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    // Bütün boşlukları silip küçük harfe çeviriyoruz.
    final email = Validators.normalizeEmail(_emailController.text);
    try {
      await AuthService.instance.login(
        email: email,
        sifre: _passwordController.text,
      );
      // Giriş başarılı: "Beni hatırla" tercihini telefona kaydet.
      await RememberMeService.save(remember: _rememberMe, email: email);

      // await'ten sonra ekran kapanmış olabilir; context'i kullanmadan önce kontrol.
      if (!mounted) return;
      // pushReplacement: Giriş ekranını yığından çıkarır, böylece geri tuşuyla
      // giriş ekranına dönülmez. screenForSignedInUser(): e-posta doğrulandıysa
      // Ana Sayfa'yı, doğrulanmadıysa doğrulama ekranını döndürür.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => screenForSignedInUser()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Telefon yan mı çevrilmiş? (genişlik > yükseklik)
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      //ekran iskeleti, appbar ve body içerir.
      appBar: AppBar(title: const Text('Giriş Yap')), //appbar başlığı
      body: SafeArea(
        child: isLandscape
            // YATAY: iki sütun -> solda logo, sağda form (Row)
            ? Row(
                children: [
                  Expanded(child: Center(child: _buildBrand(logoSize: 72))),
                  Expanded(
                    // Klavye açılınca taşma olmaması için kaydırılabilir
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildForm(),
                    ),
                  ),
                ],
              )
            // DİKEY: alt alta -> logo, sonra form (Column)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    _buildBrand(logoSize: 96),
                    const SizedBox(height: 32),
                    _buildForm(),
                  ],
                ),
              ),
      ),
    );
  }

  /// Logo + UNICAR yazısı. Dikeyde formun üstünde, yatayda solda durur.
  Widget _buildBrand({required double logoSize}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Kayıt ekranındaki logoyla aynı Hero etiketini taşır;
        // ekranlar arası geçişte logo uçarak yer değiştirir.
        AppLogo(size: logoSize),
        const SizedBox(height: 16),
        Text(
          'UNICAR',
          textAlign: TextAlign.center,
          // bu yazıya uygular. İçine normal TextStyle özellikleri verilir.
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 6, // harfler arası boşluk, logo havası verir
            // Temadaki ana renk (primary); tema değişirse bu da değişir.
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// E-posta, şifre, "Beni hatırla", giriş butonu ve "Kayıt ol" bağlantısı.
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, //  tüm genişliği kaplamasını sağlar.
        children: [
          CustomTextField(
            controller: _emailController,
            label: 'E-posta',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 16),
          PasswordField(
            controller: _passwordController,
            textInputAction: TextInputAction.done,
            // Girişte sadece boşluk kontrolü; şifre kuralları kayıtta uygulanır.
            validator: Validators.validateLoginPassword,
          ),
          const SizedBox(height: 4),
          // BENİ HATIRLA (solda) ve ŞİFREMİ UNUTTUM (sağda) aynı satırda.
          // Wrap: sığdığı sürece Row gibi yan yana dizer; dar ekranda
          // (ör. yatay düzenin sağ sütunu) taşmak yerine alt satıra geçer.
          Wrap(
            // spaceBetween: ilk öğe en sola, son öğe en sağa yaslanır.
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min, // sadece içeriği kadar yer kapla
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) =>
                        setState(() => _rememberMe = value ?? false),
                  ),
                  // Yazıya dokunmak da kutuyu işaretlesin.
                  GestureDetector(
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: const Text('Beni hatırla'),
                  ),
                ],
              ),
              TextButton(
                onPressed: _showForgotPassword,
                child: const Text('Şifremi unuttum'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            // Yüklenirken null vererek butonu pasif yapıyoruz (çift tıklamayı önler).
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Giriş Yap'),
          ),
          const SizedBox(height: 16),
          // HESABIN YOK MU? KAYIT OL BUTONU
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Hesabın yok mu?'),
              TextButton(
                onPressed: () async {
                  // await: Kayıt ekranı kapanana kadar burada bekler.
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                  // Geri dönünce formdaki eski hata mesajlarını temizle.
                  _formKey.currentState?.reset();
                },
                child: const Text('Kayıt ol'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
