import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

//           ana ekran giriş yapıldıktan sonra HOŞGELDİN.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Future'ı initState'te bir kez oluşturuyoruz. build() içinde oluştursaydık
  // ekran her yeniden çizildiğinde Firestore'a tekrar istek atılırdı.
  late final Future<AppUser?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.instance.getCurrentUserProfile();
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    // pushAndRemoveUntil: tüm eski ekranları siler ve sadece Giriş ekranını bırakır.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: _logout,
          ),
        ],
      ),
      // FutureBuilder: Future tamamlanana kadar yükleniyor göstergesi,
      // tamamlanınca gelen veriyle ekranı çizer.
      body: FutureBuilder<AppUser?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Profil bilgileri yüklenemedi.'));
          }

          final user = snapshot.data;
          // Ad soyad boşsa e-postayı gösteriyoruz.
          final name = (user == null || user.adSoyad.isEmpty)
              ? (user?.email ?? '')
              : user.adSoyad;

          return Center(
            // Yan çevrilince ekran kısalır; içerik sığmazsa kaydırılabilsin.
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.waving_hand, size: 72), // el sallayan emoji
                  const SizedBox(height: 16),
                  Text(
                    'Hoş geldin, $name!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 8),
                    Text(user.email),
                  ],
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Çıkış Yap'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
