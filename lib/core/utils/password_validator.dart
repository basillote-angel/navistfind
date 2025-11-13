/// Password validation and strength checking utility
class PasswordValidator {
  /// Check password strength (0-100)
  static double getPasswordStrength(String password) {
    if (password.isEmpty) return 0.0;

    double strength = 0.0;

    // Length criteria (40% weight)
    if (password.length >= 8) {
      strength += 40.0;
    } else if (password.length >= 6) {
      strength += 20.0;
    }

    // Uppercase letter (15% weight)
    if (password.contains(RegExp(r'[A-Z]'))) {
      strength += 15.0;
    }

    // Lowercase letter (15% weight)
    if (password.contains(RegExp(r'[a-z]'))) {
      strength += 15.0;
    }

    // Number (15% weight)
    if (password.contains(RegExp(r'[0-9]'))) {
      strength += 15.0;
    }

    // Special character (15% weight)
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength += 15.0;
    }

    // Bonus for longer passwords
    if (password.length >= 12) {
      strength = (strength * 1.1).clamp(0.0, 100.0);
    }

    return strength.clamp(0.0, 100.0);
  }

  /// Get password strength level
  static PasswordStrengthLevel getPasswordStrengthLevel(String password) {
    final strength = getPasswordStrength(password);

    if (strength < 40) {
      return PasswordStrengthLevel.weak;
    } else if (strength < 70) {
      return PasswordStrengthLevel.medium;
    } else {
      return PasswordStrengthLevel.strong;
    }
  }

  /// Get password strength text
  static String getPasswordStrengthText(String password) {
    final level = getPasswordStrengthLevel(password);
    return level.displayName;
  }

  /// Get password strength color
  static int getPasswordStrengthColor(String password) {
    final level = getPasswordStrengthLevel(password);
    return level.color;
  }

  /// Validate password meets minimum requirements
  static PasswordValidationResult validatePassword(String password) {
    final errors = <String>[];

    if (password.isEmpty) {
      return PasswordValidationResult(
        isValid: false,
        errors: ['Password is required'],
      );
    }

    if (password.length < 8) {
      errors.add('Password must be at least 8 characters');
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }

    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain at least one special character');
    }

    return PasswordValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Get password requirements as list
  static List<PasswordRequirement> getPasswordRequirements(String password) {
    return [
      PasswordRequirement(
        text: 'At least 8 characters',
        met: password.length >= 8,
      ),
      PasswordRequirement(
        text: 'One uppercase letter',
        met: password.contains(RegExp(r'[A-Z]')),
      ),
      PasswordRequirement(
        text: 'One lowercase letter',
        met: password.contains(RegExp(r'[a-z]')),
      ),
      PasswordRequirement(
        text: 'One number',
        met: password.contains(RegExp(r'[0-9]')),
      ),
      PasswordRequirement(
        text: 'One special character',
        met: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
  }
}

/// Password strength levels
enum PasswordStrengthLevel {
  weak,
  medium,
  strong;

  String get displayName {
    switch (this) {
      case PasswordStrengthLevel.weak:
        return 'Weak';
      case PasswordStrengthLevel.medium:
        return 'Medium';
      case PasswordStrengthLevel.strong:
        return 'Strong';
    }
  }

  int get color {
    switch (this) {
      case PasswordStrengthLevel.weak:
        return 0xFFE53935; // Red
      case PasswordStrengthLevel.medium:
        return 0xFFFB8C00; // Orange
      case PasswordStrengthLevel.strong:
        return 0xFF43A047; // Green
    }
  }
}

/// Password validation result
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;

  PasswordValidationResult({required this.isValid, required this.errors});
}

/// Password requirement
class PasswordRequirement {
  final String text;
  final bool met;

  PasswordRequirement({required this.text, required this.met});
}
