import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/embedded_images.dart';

///        UNICAR logosu. Giriş ve Kayıt ekranında aynı Hero etiketiyle kullanılır;
/// ekran değişirken Flutter logoyu bir ekrandan diğerine uçurarak taşır.
class AppLogo extends StatelessWidget {
  static const String heroTag = 'app-logo';

  final double size;

  const AppLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        // Logo, assets/ yerine koda gömülü veriden okunuyor
        // (bkz. lib/utils/embedded_images.dart).
        child: Image.memory(
          EmbeddedImages.appLogoPng,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Veri bozuksa uygulama çökmesin, araba ikonu görünsün.
          errorBuilder: (context, error, stackTrace) => Container(
            width: size,
            height: size,
            color: AppColors.primary,
            child: Icon(
              Icons.directions_car,
              size: size * 0.55,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
