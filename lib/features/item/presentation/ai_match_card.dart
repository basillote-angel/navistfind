import 'package:flutter/material.dart';
import 'package:navistfind/features/item/domain/models/item.dart';

class AiMatchCard extends StatelessWidget {
  final double score;
  final Item? item;
  final VoidCallback? onTap;

  const AiMatchCard({
    super.key,
    required this.score,
    required this.item,
    this.onTap,
  });

  Color _getScoreColor(double score) {
    if (score >= 0.8) {
      return Colors.green.shade500;
    } else if (score >= 0.6) {
      return Colors.orange.shade500;
    } else {
      return Colors.red.shade500;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: Colors.purple.shade600),
                const SizedBox(width: 6),
                Text(
                  'AI Match Found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(score),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(score * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (item != null) ...[
              const SizedBox(height: 8),
              Text(
                'Similar to: ${item!.name}',
                style: TextStyle(fontSize: 13, color: Colors.purple.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
