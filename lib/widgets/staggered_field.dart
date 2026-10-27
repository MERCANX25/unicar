import 'dart:async';

import 'package:flutter/material.dart';

/// Form alanlarını sırayla (kademeli) belirten sarmalayıcı.
///

class StaggeredField extends StatefulWidget {
  final int index;
  final bool visible;
  final Widget child;

  const StaggeredField({
    super.key,
    required this.index,
    required this.visible,
    required this.child,
  });

  @override
  State<StaggeredField> createState() => _StaggeredFieldState();
}

class _StaggeredFieldState extends State<StaggeredField> {
  static const _stepDelay = Duration(milliseconds: 80);
  static const _duration = Duration(milliseconds: 350);

  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _scheduleShow();
  }

  @override
  void didUpdateWidget(StaggeredField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Görünürlük değiştiyse animasyonu başlat ya da sıfırla.
    if (widget.visible && !oldWidget.visible) {
      _scheduleShow();
    } else if (!widget.visible && oldWidget.visible) {
      _timer?.cancel();
      setState(() => _shown = false);
    }
  }

  void _scheduleShow() {
    _timer?.cancel();
    // Her alan bir öncekinden 80 ms sonra başlar: 0, 80, 160, 240 ms...
    _timer = Timer(_stepDelay * widget.index, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Ekran kapanırsa bekleyen zamanlayıcı çalışmasın.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: _duration,
      curve: Curves.easeOut,
      child: AnimatedSlide(
        // Offset, widget'ın kendi boyutuna oranlıdır: 0.15 = yüksekliğinin %15'i aşağıda.
        offset: _shown ? Offset.zero : const Offset(0, 0.15),
        duration: _duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
