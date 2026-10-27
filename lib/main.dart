// İMPORT: Firebase ve Flutter paketlerini tnıtıyoruz.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

//  Firebase'i Flutter'a bağlamak için gerekli ayarları içeriyor.
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/verify_email_screen.dart';
import 'services/auth_service.dart';
import 'services/remember_me_service.dart';
import 'utils/app_colors.dart';

// main async, çünkü uygulama açılmadan önce Firebase'in hazır olmasını bekliyoruz.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // "Beni hatırla" işaretlenmeden giriş yapıldıysa, uygulama her açılışta
  // oturumu kapatır ve kullanıcı Giriş ekranından tekrar girer.
  // (Firebase normalde girişi hep hatırlar; bunu biz kapatıyoruz.)
  if (AuthService.instance.isLoggedIn && !await RememberMeService.isEnabled()) {
    await AuthService.instance.logout();
  }

  runApp(const MyApp()); // runapp widget ister.
}

class MyApp extends StatelessWidget {
  //sınıf olması için extends ile StatelessWidget eklenmeli.

  const MyApp({super.key}); // const constructor, widget ağacında değişmeyen widget'lar için kullanılır.

  @override
  Widget build(BuildContext context) {
    //zorunlu override build metodu, widget ağacını oluşturur.
    return MaterialApp(
      // ekrana çizdirmemizi sağlar.
      title: 'UNICAR',
      debugShowCheckedModeBanner: false, // sağ üstteki debug yazısını kaldırır.
      theme: _buildTheme(),
      locale: const Locale('tr', 'TR'), //türkçe dil ayarı.
      supportedLocales: const [Locale('tr', 'TR')],
      localizationsDelegates: const [
        // Türkçe dil desteği için gerekli ayarlar.
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Açılış ekranı (Firebase oturumu uygulama kapansa da hatırlar)
      home: AuthService.instance.isLoggedIn
          ? screenForSignedInUser()
          : const LoginScreen(),
    );
  }

  //         FONT VE RENK TEMASI
  // 
  ThemeData _buildTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          tertiary: AppColors.accent,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          error: AppColors.error,
          onError: AppColors.background,
          // SnackBar'lar varsayılan olarak bu iki rengi kullanır: açık zemin, koyu yazı.
          inverseSurface: AppColors.textPrimary,
          onInverseSurface: AppColors.background,
        );

    // Metin alanları ve butonlar için ortak köşe yuvarlaklığı.
    final radius = BorderRadius.circular(14);
    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    // Hem ElevatedButton hem FilledButton (Giriş ekranı) aynı görünsün.
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        // Pasif butonu (yüklenirken) soluk gösteriyoruz.
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.border
            : AppColors.primary,
      ),
      foregroundColor: const WidgetStatePropertyAll(Colors.white),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: radius),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      // Poppins korunuyor; koyu zemin için tüm yazılar açık renge çevriliyor.
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // TextField / TextFormField görünümü: surface dolgu, border kenarlık,
      // odaklanınca primary, köşe 14.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: TextStyle(color: AppColors.textSecondary),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        errorStyle: TextStyle(color: AppColors.error),
        border: inputBorder(AppColors.border),
        enabledBorder: inputBorder(AppColors.border),
        focusedBorder: inputBorder(AppColors.primary, 2),
        errorBorder: inputBorder(AppColors.error),
        focusedErrorBorder: inputBorder(AppColors.error, 2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
    );
  }
}
