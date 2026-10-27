import 'package:flutter/material.dart';

///           Göz ikonuyla göster/gizle özelliği olan şifre alanı.
///
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged; 

  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Şifre',
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true; // Başlangıçta şifre gizli

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      // Kenarlık ve dolgu main.dart'taki inputDecorationTheme'den gelir.
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          // Şifre gizliyse "göster" ikonu, görünürse "gizle" ikonu.
          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
          tooltip: _obscureText ? 'Şifreyi göster' : 'Şifreyi gizle',
          onPressed: () {
            
            setState(() => _obscureText = !_obscureText);
          },
        ),
      ),
    );
  }
}
