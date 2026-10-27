import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/validators.dart';

///           Şifre alanının altında görünen güç çubuğu.
/// Zayıf: kırmızı 1/3, Orta: sarı 2/3, Güçlü: yeşil tam dolu.
class PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    // Her seviye için: doluluk oranı, renk ve yazı.
    final (double fill, Color color, String label) = switch (strength) {
      PasswordStrength.none => (0.0, AppColors.border, ''),
      PasswordStrength.weak => (1 / 3, AppColors.error, 'Zayıf'),
      PasswordStrength.medium => (2 / 3, AppColors.warning, 'Orta'),
      PasswordStrength.strong => (1.0, AppColors.success, 'Güçlü'),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Row(
        children: [
          Expanded(
            // LayoutBuilder çubuğun toplam genişliğini verir; dolu kısmın
            // genişliğini bu değerin oranı olarak hesaplıyoruz.
            child: LayoutBuilder(
              builder: (context, constraints) => Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
                alignment: Alignment.centerLeft,
                // AnimatedContainer: genişlik veya renk değişince
                // aradaki geçişi kendisi animasyonla yapar.
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: constraints.maxWidth * fill,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 44,
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
