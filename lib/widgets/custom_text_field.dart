import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

///  Tüm formlarda aynı görünen, tekrar kullanılabilir metin alanı.

///
/// Görünüm (dolgu, kenarlık, köşe yuvarlaklığı) main.dart'taki
/// inputDecorationTheme'den gelir; burada ayrıca kenarlık vermiyoruz.
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;

  // İsteğe bağlı parametreler 

  
  final Widget? suffixIcon; // alanın sağındaki widget tik gibi.
  final String? prefixText; // alanın başındaki sabit metin (ör. "+90 ")
  final String? hintText; // alan boşken görünen örnek
  final List<TextInputFormatter>? inputFormatters; // yazarken biçimlendirme
  final ValueChanged<String>? onChanged; // her tuş vuruşunda çağrılır
  // Hata mesajı ne zaman gösterilsin? Varsayılan: sadece form doğrulanınca.
  final AutovalidateMode autovalidateMode;
  // Klavye büyük harfle mi başlasın? (ör. Ad Soyad için her kelime)
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.suffixIcon,
    this.prefixText,
    this.hintText,
    this.inputFormatters,
    this.onChanged,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      // "next": klavyedeki tuş bir sonraki alana geçer.
      textInputAction: textInputAction,
      validator: validator,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      autovalidateMode: autovalidateMode,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        hintText: hintText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
