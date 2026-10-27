import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/remember_me_service.dart';
import '../utils/app_colors.dart';
import '../utils/embedded_images.dart';
import '../utils/phone_input_formatter.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_field.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/role_card.dart';
import '../widgets/staggered_field.dart';
import 'register_success_screen.dart';

/// UNICAR kayıt ekranı: 3 adım (Hesap - Profil - Onay).
/// 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepCount = 3;
  static const _stepTitles = ['Hesap', 'Profil', 'Onay'];
  static const _pageDuration = Duration(milliseconds: 350);

  final _pageController = PageController();
  int _currentStep = 0;

  // Her adımın kendi Form'u var; "Devam et" sadece o adımı doğrular.
  final _formKeys = List.generate(_stepCount, (_) => GlobalKey<FormState>());

  // Adım 1 – Hesap
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _emailValid = false; // yeşil tik için
  bool _emailNotInList = false; // okul listesi kontrolü başarısız oldu mu
  PasswordStrength _strength = PasswordStrength.none; // şifre güç göstergesi

  // Adım 2 – Profil
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  UserRole? _role;

  // Adım 3 – Onay
  bool _kvkkAccepted = false;
  // Metnin bir parçasını tıklanabilir yapmak için; dispose edilmesi gerekir.
  late final TapGestureRecognizer _kvkkTap = TapGestureRecognizer()
    ..onTap = _showKvkkSheet;

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _kvkkTap.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Adımlar arası geçiş 
  // ---------------------------------------------------------------------------

  void _goToStep(int step) {
    FocusScope.of(context).unfocus(); // klavyeyi kapat
    // Önce _currentStep'i güncelliyoruz: ilerleme çubuğu ve yeni adımdaki
    // alanların sırayla belirme animasyonu sayfa kayarken başlasın.
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: _pageDuration,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onNext() async {
    // Bu adımın formu geçerli değilse ilerleme; hata mesajları görünür.
    if (!_formKeys[_currentStep].currentState!.validate()) return;

    if (_currentStep == 0) {
      // Biçim doğru (@asu.edu.tr). okul listesinde var mı
      final allowed = await _checkSchoolList();
      if (!allowed) return;
    }

    if (_currentStep < _stepCount - 1) {
      _goToStep(_currentStep + 1);
    } else {
      await _register();
    }
  }

  /// E-postanın Firestore'daki izinli_mailler listesinde olup olmadığını
  /// kontrol eder. Yoksa e-posta alanının altında hata mesajı gösterir.
  Future<bool> _checkSchoolList() async {
    setState(() => _isLoading = true);
    try {
      final email = Validators.normalizeEmail(_emailController.text);
      final allowed = await AuthService.instance.isEmailAllowed(email);
      if (!mounted) return false;

      if (!allowed) {
        // Mesajı alanın doğrulayıcısına veriyoruz ve formu tekrar doğruluyoruz;
        // böylece hata, diğer hatalar gibi alanın altında kırmızı görünür.
        setState(() => _emailNotInList = true);
        _formKeys[0].currentState!.validate();
      }
      return allowed;
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _onBack() {
    if (_isLoading) return;
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.of(context).pop(); // 1. adımdaysak Giriş ekranına dön
    }
  }

  // ---------------------------------------------------------------------------
  // Kayıt olma 
  // ---------------------------------------------------------------------------

  Future<void> _register() async {
    // Çift tıklamayı engelle: bayrak true olunca buton pasifleşir
    // ve içinde yükleniyor göstergesi görünür.
    setState(() => _isLoading = true);
    final email = Validators.normalizeEmail(_emailController.text);

    try {
      final emailSent = await AuthService.instance.registerUnicar(
        adSoyad: _nameController.text.trim(),
        email: email,
        sifre: _passwordController.text,
        telefon: PhoneInputFormatter.digitsOnly(_phoneController.text),
        rol: _role!, // Adım 2'nin doğrulaması rolün seçildiğini garanti eder.
        kvkkOnay: _kvkkAccepted,
      );
      // Yeni kayıt olan kullanıcı hatırlansın; uygulama kapanınca oturum düşmesin.
      await RememberMeService.save(remember: true, email: email);

      if (!mounted) return;
      // pushAndRemoveUntil: Giriş ve Kayıt ekranlarını yığından siler;
      // geri tuşuyla kayıt ekranına dönülemez.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              RegisterSuccessScreen(email: email, emailSent: emailSent),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      // finally her durumda (başarı veya hata) çalışır; bayrak mutlaka sıfırlanır.
      // mounted: ekran hâlâ açık mı? Kapandıysa setState çağırmak hata verir.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showKvkkSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true, // üstteki sürükleme çubuğu
      builder: (context) => Padding( 
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KVKK Aydınlatma Metni',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'UNICAR olarak ad soyad, e-posta ve telefon bilgilerini; '
              'kampüs içi yolculuk eşleştirmesi yapmak, hesabını doğrulamak '
              've seninle iletişim kurmak amacıyla 6698 sayılı Kişisel '
              'Verilerin Korunması Kanunu kapsamında işliyoruz. Verilerin '
              'üçüncü kişilerle paylaşılmaz. Dilediğin zaman verilerinin '
              'silinmesini talep edebilirsin.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Arayüz
  // ---------------------------------------------------------------------------

  // Arka plan SVG'sinin tasarım boyutu ve üstteki dalganın (indigo + camgöbeği)
  // en alt noktası. Değerler register_bg.svg dosyasından alındı.
  static const _bgDesignSize = Size(412, 915);
  static const _bgWaveBottom = 295.0;

  /// Dalganın ekrandaki alt sınırı (dp). SVG, BoxFit.cover ile ekranı
  /// kaplayacak kadar büyütülür; aynı ölçeği dalga yüksekliğine uyguluyoruz.
  /// Böylece farklı ekran boyutlarında da yazılar dalganın altında kalır.
  double _waveBottomOnScreen(Size screen) {
    final scale = math.max(
      screen.width / _bgDesignSize.width,
      screen.height / _bgDesignSize.height,
    );
    return _bgWaveBottom * scale;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top; // durum çubuğu
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;
    // Telefon yan mı çevrilmiş? (genişlik > yükseklik)
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    // PopScope: telefonun geri tuşu da ekrandaki geri ok gibi davransın.
    // 1. adımda (ve yükleme yokken) sayfa normal şekilde kapanabilir.
    return PopScope(
      canPop: _currentStep == 0 && !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        // Klavye açılınca arka plan küçülüp kaymasın; klavye boşluğunu
        // aşağıda içeriğe padding olarak kendimiz veriyoruz.
        resizeToAvoidBottomInset: false,
        body: isLandscape
            ? _buildLandscape(screen, keyboardHeight)
            : _buildPortrait(screen, topInset, keyboardHeight),
      ),
    );
  }

  /// DİKEY düzen: üstte SVG dalgası içinde logo, altında adımlar (Column).
  Widget _buildPortrait(Size screen, double topInset, double keyboardHeight) {
    // Başlık alanı tam olarak dalganın içini kaplasın.
    final headerHeight = _waveBottomOnScreen(screen) - topInset;

    return Stack(
      children: [
        Positioned.fill(
          // Arka plan, assets/ yerine koda gömülü SVG metninden çiziliyor
          // (bkz. lib/utils/embedded_images.dart).
          child: SvgPicture.string(
            EmbeddedImages.registerBackgroundSvg,
            fit: BoxFit.cover,
            // Üste hizalı: dalga her zaman ekranın en üstünde başlar.
            alignment: Alignment.topCenter,
            // SVG çizilemezse düz arka plan rengi kalsın.
            errorBuilder: (context, error, stackTrace) =>
                ColoredBox(color: AppColors.background),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: headerHeight, child: _buildHeader()),
                // Dalganın altındaki koyu alan: tüm yazılar burada.
                Expanded(
                  child: _buildStepArea(
                    const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// YATAY düzen: solda indigo marka paneli, sağda adımlar (Row).
  /// Yatay ekran çok kısa olduğu için dalgalı SVG burada kullanılmıyor;
  /// dalganın rengini sol paneldeki indigo kutu temsil ediyor.
  Widget _buildLandscape(Size screen, double keyboardHeight) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sol panel: ekran genişliğinin en fazla %35'i, en fazla 300 dp.
            Container(
              width: math.min(screen.width * 0.35, 300),
              decoration: BoxDecoration(
                color: AppColors.primary,
                // Sadece sağ köşeler yuvarlak.
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(32),
                ),
              ),
              child: _buildHeader(),
            ),
            // Sağ taraf: kalan tüm genişlik.
            Expanded(
              child: _buildStepArea(const EdgeInsets.fromLTRB(24, 12, 24, 12)),
            ),
          ],
        ),
      ),
    );
  }

  /// İki düzende de aynı olan kısım: ilerleme çubuğu, adımlar, buton.
  Widget _buildStepArea(EdgeInsets padding) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgress(),
          const SizedBox(height: 16),
          Expanded(child: _buildPages()),
          const SizedBox(height: 12),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildPages() {
    return PageView(
      controller: _pageController,
      // Kaydırarak geçişi kapatıyoruz; adımlar sadece
      // butonlarla (doğrulamadan sonra) değişir.
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildAccountStep(),
        _buildProfileStep(),
        _buildConfirmStep(),
      ],
    );
  }

  /// Dalganın içindeki alan: solda geri ok, ortada logo ve uygulama adı.
  /// İndigo zeminde okunsun diye hepsi beyaz.
  Widget _buildHeader() {
    return Stack(
      children: [
        Positioned(
          top: 4,
          left: 8,
          child: IconButton(
            onPressed: _isLoading ? null : _onBack,
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            iconSize: 28,
            tooltip: 'Geri',
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 64),
              const SizedBox(height: 10),
              Text(
                'UNICAR',
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Adım ${_currentStep + 1}/$_stepCount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: '  ·  ${_stepTitles[_currentStep]}',
                style: TextStyle(fontSize: 16, color: AppColors.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => Container(
            height: 8,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
            // Genişlik adım sayısına göre değişir; AnimatedContainer
            // aradaki geçişi kendisi animasyonla yapar.
            child: AnimatedContainer(
              duration: _pageDuration,
              curve: Curves.easeInOut,
              width: constraints.maxWidth * (_currentStep + 1) / _stepCount,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final isLastStep = _currentStep == _stepCount - 1;
    return ElevatedButton(
      onPressed: _isLoading ? null : _onNext,
      // AnimatedSwitcher: child değişince (yazı ↔ yükleniyor) geçişi
      // yumuşak yapar. Farklı child'ları ayırt etmesi için key veriyoruz.
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                isLastStep ? 'Kayıt ol' : 'Devam et',
                key: ValueKey(isLastStep),
              ),
      ),
    );
  }

  /// Bir adımın ortak iskeleti: kaydırılabilir alan + Form + sırayla belirme.
  Widget _buildStep({required int step, required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Form(
        key: _formKeys[step],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++)
              StaggeredField(
                index: i,
                visible: _currentStep == step,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: children[i],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // Adım 1 – Hesap -------------------------------------------------------------

  Widget _buildAccountStep() {
    return _buildStep(
      step: 0,
      children: [
        _stepTitle('Hesabını oluştur', 'Üniversite e-postanla kayıt ol.'),
        CustomTextField(
          controller: _emailController,
          label: 'Üniversite e-postası',
          hintText: 'ad.soyad@asu.edu.tr',
          icon: Icons.school_outlined,
          keyboardType: TextInputType.emailAddress,
          // Önce biçim kontrolü (@asu.edu.tr), sonra okul listesi sonucu.
          validator: (value) =>
              Validators.validateAsuEmail(value) ??
              (_emailNotInList ? 'Bu e-posta okul kayıtlarında bulunamadı' : null),
          // Kullanıcı yazmaya başlayınca hata mesajı canlı olarak güncellensin.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (value) => setState(() {
            _emailValid = Validators.isAsuEmail(value);
            _emailNotInList = false; // e-posta değişti, eski liste sonucu geçersiz
          }),
          suffixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            // Tik belirirken küçükten büyüyerek gelsin.
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _emailValid
                ? Icon(
                    Icons.check_circle,
                    key: const ValueKey('valid'),
                    color: AppColors.success,
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PasswordField(
              controller: _passwordController,
              validator: Validators.validateUnicarPassword,
              onChanged: (value) => setState(
                () => _strength = Validators.passwordStrength(value),
              ),
            ),
            PasswordStrengthBar(strength: _strength),
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                'En az 8 karakter, 1 büyük harf ve 1 rakam',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
        PasswordField(
          controller: _confirmPasswordController,
          label: 'Şifre tekrar',
          textInputAction: TextInputAction.done,
          validator: (value) => Validators.validateConfirmPassword(
            value,
            _passwordController.text,
          ),
        ),
      ],
    );
  }

  // Adım 2 – Profil ------------------------------------------------------------

  Widget _buildProfileStep() {
    return _buildStep(
      step: 1,
      children: [
        _stepTitle('Profilin', 'Sürücüler ve yolcular seni bu bilgilerle tanır.'),
        CustomTextField(
          controller: _nameController,
          label: 'Ad Soyad',
          icon: Icons.person_outline,
          keyboardType: TextInputType.name,
          // "ömer çelik" yazılırken klavye "Ömer Çelik" diye başlatır.
          textCapitalization: TextCapitalization.words,
          validator: Validators.validateName,
        ),
        CustomTextField(
          controller: _phoneController,
          label: 'Telefon',
          icon: Icons.phone_outlined,
          prefixText: '+90 ', // sabit ön ek, kullanıcı silemez
          hintText: '5XX XXX XX XX',
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          inputFormatters: [PhoneInputFormatter()],
          validator: Validators.validatePhone,
        ),
        // Rol seçimi bir TextField değil; Form'un doğrulamasına katılması
        // için FormField ile sarıyoruz.
        FormField<UserRole>(
          initialValue: _role,
          validator: (value) => value == null ? 'Lütfen bir rol seç' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rolün', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (role, icon) in [
                    (UserRole.yolcu, Icons.hail),
                    (UserRole.surucu, Icons.directions_car),
                    (UserRole.ikisi, Icons.swap_horiz),
                  ]) ...[
                    Expanded(
                      child: RoleCard(
                        icon: icon,
                        title: role.label,
                        selected: field.value == role,
                        onTap: () {
                          field.didChange(role); // FormField'ın değerini güncelle
                          setState(() => _role = role);
                        },
                      ),
                    ),
                    if (role != UserRole.ikisi) const SizedBox(width: 12),
                  ],
                ],
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Adım 3 – Onay --------------------------------------------------------------

  Widget _buildConfirmStep() {
    return _buildStep(
      step: 2,
      children: [
        _stepTitle('Son kontrol', 'Bilgilerin doğruysa kaydını tamamla.'),
        _buildSummaryCard(),
        FormField<bool>(
          initialValue: _kvkkAccepted,
          validator: (value) => value == true
              ? null
              : 'Kayıt olmak için KVKK metnini onaylamalısın',
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: field.value ?? false,
                    onChanged: (value) {
                      field.didChange(value);
                      setState(() => _kvkkAccepted = value ?? false);
                    },
                  ),
                  Expanded(
                    // Text.rich: tek metin içinde farklı stiller; sadece
                    // "KVKK Aydınlatma Metni" kısmı tıklanabilir.
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'KVKK Aydınlatma Metni',
                            style: TextStyle(
                              color: AppColors.secondary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.secondary,
                            ),
                            recognizer: _kvkkTap,
                          ),
                          const TextSpan(text: '\'ni okudum ve kabul ediyorum.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final rows = [
      ('Ad Soyad', _nameController.text.trim()),
      ('E-posta', Validators.normalizeEmail(_emailController.text)),
      ('Telefon', '+90 ${_phoneController.text}'),
      ('Rol', _role?.label ?? '-'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      label,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
