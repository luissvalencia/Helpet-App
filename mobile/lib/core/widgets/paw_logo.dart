import 'package:flutter/material.dart';

/// Logo animado: una respiración suave + un pequeño balanceo en loop, para
/// que se sienta "vivo" en vez de una imagen estática. Respeta la
/// preferencia de reducir animaciones del sistema.
class PawLogo extends StatefulWidget {
  const PawLogo({super.key, this.size = 96});

  final double size;

  @override
  State<PawLogo> createState() => _PawLogoState();
}

class _PawLogoState extends State<PawLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );
  late final Animation<double> _scale = Tween<double>(begin: 1.0, end: 1.06).animate(_curve);
  late final Animation<double> _tilt = Tween<double>(begin: -0.035, end: 0.035).animate(_curve);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // El logo se ve mejor sobre su propio cuadro blanco (igual que el ícono
    // de la app), en vez de flotar directo sobre el fondo de la pantalla —
    // así se ve igual en modo claro y oscuro.
    final content = Container(
      width: widget.size,
      height: widget.size,
      padding: EdgeInsets.all(widget.size * 0.14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: widget.size * 0.12,
            offset: Offset(0, widget.size * 0.04),
          ),
        ],
      ),
      child: Image.asset('assets/icon/foreground.png'),
    );

    if (MediaQuery.of(context).disableAnimations) return content;

    return AnimatedBuilder(
      animation: _controller,
      child: content,
      builder: (context, child) {
        return Transform.rotate(
          angle: _tilt.value,
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
    );
  }
}
