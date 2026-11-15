import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _logoAspectRatio = 375 / 126;

const _darkLogoFilter = ColorFilter.matrix(<double>[
  0.614,
  0,
  0,
  0,
  93,
  0,
  0.652,
  0,
  0,
  92,
  0,
  0,
  0.716,
  0,
  84,
  0,
  0,
  0,
  1,
  0,
]);

class _LogoLayer {
  const _LogoLayer(this.asset, this.start, this.end);

  final String asset;
  final double start;
  final double end;
}

const _layers = [
  _LogoLayer('assets/branding/logo_emblem.svg', 0.00, 0.58),
  _LogoLayer('assets/branding/logo_nepali.svg', 0.06, 0.76),
  _LogoLayer('assets/branding/logo_english.svg', 0.16, 0.88),
  _LogoLayer('assets/branding/logo_address.svg', 0.30, 1.00),
];

class AppLogo extends StatefulWidget {
  const AppLogo({
    super.key,
    this.width = 280,
    this.animate = true,
    this.pulse = false,
    this.duration = const Duration(milliseconds: 1800),
    this.semanticLabel = 'Battar Sanjibani Polyclinic',
  });

  final double width;
  final bool animate;
  final bool pulse;
  final Duration duration;
  final String semanticLabel;

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with TickerProviderStateMixin {
  late final AnimationController _reveal;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: widget.duration);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _pulseScale = Tween<double>(begin: 1.0, end: 1.014).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.animate) {
      _reveal.forward();
    } else {
      _reveal.value = 1;
    }
    if (widget.pulse) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AppLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      if (widget.animate) {
        _reveal.forward();
      } else {
        _reveal.value = 1;
      }
    }
    if (oldWidget.pulse != widget.pulse) {
      if (widget.pulse) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  double _progress(double value, double start, double end) {
    if (value <= start) return 0;
    if (value >= end) return 1;
    return Curves.easeOutCubic.transform((value - start) / (end - start));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = widget.width / _logoAspectRatio;

    Widget logo = RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: height,
        child: AnimatedBuilder(
          animation: _reveal,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                for (final layer in _layers)
                  _LogoLayerView(
                    layer: layer,
                    progress: _progress(_reveal.value, layer.start, layer.end),
                  ),
              ],
            );
          },
        ),
      ),
    );

    if (isDark) {
      logo = ColorFiltered(colorFilter: _darkLogoFilter, child: logo);
    }
    if (widget.pulse) {
      logo = AnimatedBuilder(
        animation: _pulseScale,
        builder: (context, child) =>
            Transform.scale(scale: _pulseScale.value, child: child),
        child: logo,
      );
    }

    return Semantics(image: true, label: widget.semanticLabel, child: logo);
  }
}

class _LogoLayerView extends StatelessWidget {
  const _LogoLayerView({required this.layer, required this.progress});

  final _LogoLayer layer;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, (1 - progress) * 12),
        child: SvgPicture.asset(layer.asset, fit: BoxFit.contain),
      ),
    );
  }
}
