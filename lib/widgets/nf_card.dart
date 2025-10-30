import 'package:flutter/material.dart';

class NfCard extends StatelessWidget {
  const NfCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.radius = 30,
    this.backgroundColor = Colors.white,
    this.shadows = const [
      BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 6)),
    ],
    this.border,
    this.accentGradient,
    this.accentWidth = 4,
    this.accentAlignment = Axis.vertical,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;
  final Color backgroundColor;
  final List<BoxShadow> shadows;
  final BoxBorder? border;
  final Gradient? accentGradient;
  final double accentWidth;
  final Axis accentAlignment;

  @override
  Widget build(BuildContext context) {
    final coreContent = Container(color: backgroundColor, child: child);

    Widget core = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: coreContent,
    );

    if (accentGradient != null && accentWidth > 0) {
      final isVertical = accentAlignment == Axis.vertical;
      core = Stack(
        children: [
          core,
          // Side accent line
          Positioned(
            left: 0,
            top: 0,
            bottom: isVertical ? 0 : null,
            right: isVertical ? null : 0,
            height: isVertical ? null : accentWidth,
            width: isVertical ? accentWidth : null,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: accentGradient),
            ),
          ),
        ],
      );
    }

    final wrapped = (onTap != null || onLongPress != null)
        ? Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              onLongPress: onLongPress,
              child: core,
            ),
          )
        : core;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadows,
        border: border,
      ),
      child: wrapped,
    );
  }
}
