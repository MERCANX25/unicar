import 'package:flutter/material.dart';

/// İçinde Spacer olan bir Column'u hem dikey hem yatay ekranda düzgün gösterir.
///
/// Sorun: Spacer, "boş yeri doldur" demektir. Dikey ekranda yer bol olduğu
/// için sorun yok; ama telefon yan çevrilince ekran çok kısalır, içerik sığmaz
/// ve Flutter sarı-siyah "overflow" şeridi gösterir.
///
/// Çözüm:
/// - Ekran yeterince uzunsa: içerik ekranı doldurur, Spacer'lar çalışır.
/// - Ekran kısaysa: içerik kaydırılabilir olur, hiçbir şey taşmaz.
/// - Geniş ekranda (yatay) içerik [maxWidth]'ten fazla yayılmaz, ortada durur.
class ScrollableFill extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double maxWidth;

  const ScrollableFill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder: bu widget'a ayrılan alanın boyutunu (constraints) verir.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // En az ekran yüksekliği kadar ol (Spacer'lar boşluğu doldursun)...
              minHeight: constraints.maxHeight - padding.vertical,
              // ...ama yatay ekranda çok geniş olma.
              maxWidth: maxWidth,
            ),
            // IntrinsicHeight: Column'un içeriğin gerçek yüksekliğini
            // bilmesini sağlar; Spacer kaydırılabilir alanda da çalışır.
            child: IntrinsicHeight(child: child),
          ),
        ),
      ),
    );
  }
}
