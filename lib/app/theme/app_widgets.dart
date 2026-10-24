import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Small shared presentation widgets that keep screens visually consistent.

const _avatarPalette = [
  AppColors.primary,
  Color(0xFFF0AD7F),
  AppColors.accent,
  Color(0xFFEDA6C1),
  Color(0xFFBEAEDE),
  AppColors.success,
];

/// Colored circle with the person's initial; color is stable per name.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.onDark = false,
  });
  final String name;
  final double radius;

  /// Adds a ring so the avatar stands out on hero gradients.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color =
        _avatarPalette[name.codeUnits.fold(0, (a, b) => a + b) %
            _avatarPalette.length];
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(
          color.withValues(alpha: 0.15),
          AppColors.surface,
        ),
        border: onDark
            ? Border.all(color: color.withValues(alpha: 0.6), width: 2)
            : null,
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: AppFonts.numbers(size: radius * 0.9, color: color),
      ),
    );
  }
}

/// Section heading with an optional leading icon.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.icon, this.trailing});
  final String text;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(text, style: theme.textTheme.titleLarge)),
          ?trailing,
        ],
      ),
    );
  }
}

/// Compact colored label (status, tags).
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.6,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Graphite gradient card with subtle diagonal stripes, used as the top
/// highlight of a screen.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppTheme.heroRadius),
    ),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppTheme.heroShadow],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: const _StripesPainter(),
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: AppColors.textPrimary),
              child: IconTheme.merge(
                data: const IconThemeData(color: AppColors.textPrimary),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light diagonal stripes at 3% (14 px band, 20 px gap).
class _StripesPainter extends CustomPainter {
  const _StripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 14;
    const step = 34.0;
    for (var x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height * 0.58, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripesPainter oldDelegate) => false;
}

/// Icon + value + caption metric block.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.caption,
  });
  final IconData icon;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.controlRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, maxLines: 1, style: AppFonts.numbers()),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded square with a tinted background holding an icon.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.size = 48,
    this.circle = false,
  });
  final IconData icon;
  final Color color;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      shape: circle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: circle
          ? null
          : BorderRadius.circular(AppTheme.controlRadius),
    ),
    child: Icon(icon, color: color, size: size * 0.5),
  );
}

/// Dashed-border placeholder for empty lists.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => DashedBorder(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        children: [
          IconBadge(icon: icon, circle: true),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Rounded rectangle with a dashed 2 px border.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.border,
    this.fill,
  });
  final Widget child;
  final Color color;
  final Color? fill;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRRectPainter(color: color, fill: fill),
    child: SizedBox(width: double.infinity, child: child),
  );
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, this.fill});
  final Color color;
  final Color? fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(1),
      const Radius.circular(AppTheme.radius),
    );
    if (fill case final fill?) {
      canvas.drawRRect(rrect, Paint()..color = fill);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fill != fill;
}

/// The MinduRun bolt symbol (lime bolt + ice-blue speed stroke), drawn from
/// the same 100×100 geometry as `assets/brand/mindurun_symbol.svg`.
class MinduSymbol extends StatelessWidget {
  const MinduSymbol({super.key, this.size = 48, this.monochrome});
  final double size;

  /// Paints both shapes in one color when set.
  final Color? monochrome;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _SymbolPainter(monochrome));
}

class _SymbolPainter extends CustomPainter {
  const _SymbolPainter(this.monochrome);
  final Color? monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    final bolt = Path()
      ..moveTo(48, 20)
      ..lineTo(78, 20)
      ..lineTo(57, 43)
      ..lineTo(72, 43)
      ..lineTo(31, 80)
      ..lineTo(43, 54)
      ..lineTo(24, 54)
      ..close();
    final speed = Path()
      ..moveTo(71, 49)
      ..lineTo(82, 49)
      ..lineTo(51, 80)
      ..lineTo(40, 80)
      ..close();
    canvas
      ..drawPath(bolt, Paint()..color = monochrome ?? AppColors.primary)
      ..drawPath(speed, Paint()..color = monochrome ?? AppColors.accent);
  }

  @override
  bool shouldRepaint(_SymbolPainter oldDelegate) =>
      oldDelegate.monochrome != monochrome;
}

/// "MinduRun" wordmark: "Mindu" in light text, "Run" in lime.
class MinduWordmark extends StatelessWidget {
  const MinduWordmark({super.key, this.size = 60});
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = AppFonts.numbers(size: size)
        .copyWith(letterSpacing: -0.5, height: 0.9);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          const TextSpan(text: 'Mindu'),
          TextSpan(
            text: 'Run',
            style: style.copyWith(color: AppColors.primary),
          ),
        ],
      ),
      semanticsLabel: 'MinduRun',
    );
  }
}

/// Symbol + wordmark, stacked (entry screen) or side by side (app bar).
class MinduLogo extends StatelessWidget {
  const MinduLogo({super.key, this.stacked = false, this.height = 32});
  final bool stacked;

  /// Height of the symbol; the wordmark scales with it.
  final double height;

  @override
  Widget build(BuildContext context) {
    if (stacked) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MinduSymbol(size: height),
          MinduWordmark(size: height * 0.62),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinduSymbol(size: height),
        const SizedBox(width: 2),
        MinduWordmark(size: height * 0.72),
      ],
    );
  }
}
