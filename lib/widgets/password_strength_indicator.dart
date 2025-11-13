import 'package:flutter/material.dart';
import 'package:navistfind/core/utils/password_validator.dart';

/// Widget that displays password strength visually
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = false,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = PasswordValidator.getPasswordStrength(password);
    final level = PasswordValidator.getPasswordStrengthLevel(password);
    final color = Color(level.color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              level.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        if (showRequirements) ...[
          const SizedBox(height: 12),
          ...PasswordValidator.getPasswordRequirements(password).map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    req.met ? Icons.check_circle : Icons.circle_outlined,
                    size: 16,
                    color: req.met ? Colors.green : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: req.met
                            ? Colors.grey.shade700
                            : Colors.grey.shade500,
                        decoration: req.met
                            ? TextDecoration.none
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
