import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primaryBlue = Color(0xFF123A7D);
  static const Color goldenAccent = Color(0xFFFFC857);
  static const Color softYellow = Color(0xFFFFF4D8);
  static const Color lightGray = Color(0xFFF4F6F8);
  static const Color textGray = Color(0xFF6B7280);
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color lightPanel = Color(0xFFF0F3F8);
  static const Color successGreen = Color(0xFF2E7D32);
  static const Color errorRed = Color(0xFFC62828);
  static const Color warningOrange = Color(0xFF8A6D3B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, goldenAccent],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F0FF), Color(0xFFDFF7FF)],
  );

  

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 3)),
  ];

  static const List<BoxShadow> strongShadow = [
    BoxShadow(color: Color(0x20000000), blurRadius: 15, offset: Offset(0, 8)),
  ];

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 18.0;
  static const double radiusXXLarge = 30.0;
  static const double radiusXXXL = 32.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: primaryBlue,
    letterSpacing: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: primaryBlue,
    letterSpacing: 0.2,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: primaryBlue,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: primaryBlue,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: darkText,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: darkText,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textGray,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textGray,
  );

  // Card Styles
  static BoxDecoration getCardDecoration({
    Color backgroundColor = Colors.white,
    double borderRadius = radiusXXLarge,
    List<BoxShadow>? shadows,
    BoxBorder? border,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: shadows ?? cardShadow,
      border: border,
    );
  }

  // Button Styles
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    );
  }

  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: primaryBlue,
      side: const BorderSide(color: primaryBlue),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    );
  }

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 350);

  // Animation Curves
  static const Curve easeOutCurve = Curves.easeOut;
  static const Curve bounceCurve = Curves.bounceOut;
}
