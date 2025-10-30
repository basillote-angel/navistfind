import 'package:flutter/material.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';

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

  String _band(double s) => s >= 0.80
      ? 'High'
      : s >= 0.60
      ? 'Medium'
      : 'Low';
  Color _bandColor(double s) => s >= 0.80
      ? Colors.green.shade600
      : s >= 0.60
      ? Colors.orange.shade600
      : Colors.grey.shade600;

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
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: Colors.purple.shade600,
                ),
                const SizedBox(width: 6),
                const Flexible(
                  child: Text(
                    'AI Match',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _bandColor(score).withOpacity(0.12),
                    border: Border.all(color: _bandColor(score)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _band(score),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _bandColor(score),
                    ),
                  ),
                ),
              ],
            ),
            if (item != null) ...[
              const SizedBox(height: 8),
              Text(
                'Similar to: ${item!.title}',
                style: TextStyle(fontSize: 13, color: Colors.purple.shade600),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 6, runSpacing: 6, children: _buildWhyChips(item!)),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWhyChips(Item item) {
    final List<Widget> chips = [];
    chips.add(_whyChip('Category: ${item.category.name}'));
    // Avoid proximity/location language per spec
    if (item.date.isNotEmpty) {
      chips.add(_whyChip('Close date'));
    }
    // Prefer description similarity hint over name-only
    chips.add(_whyChip('Similar description'));
    return chips;
  }

  Widget _whyChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade100),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.purple.shade800),
      ),
    );
  }
}
