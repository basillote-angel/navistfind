import 'package:navistfind/core/constants.dart';
import 'package:navistfind/features/item/application/item_provider.dart';
import 'package:navistfind/features/post-item/domain/enums/category.dart';
import 'package:navistfind/features/post-item/domain/enums/item_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'claim_item.dart';


void showItemDetailsModal(BuildContext context, int itemId) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => ItemDetailsModal(itemId: itemId),
  );
}

class ItemDetailsModal extends ConsumerWidget {
  final int itemId;
  const ItemDetailsModal({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailsProvider(itemId));
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: itemAsync.when(
          loading: () => const SizedBox(
              height: 200, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => SizedBox(
              height: 200, child: Center(child: Text('Error: $e'))),
          data: (item) {
            //Format helpers
            final dateFmt = DateFormat('MMM d, yyyy');
            final dtLostFound = DateTime.parse(item.lost_found_date);
            final createdAt = DateTime.parse(item.created_at); // ensure this is the correct field
            final fullDateTimeFormat = DateFormat('MMM dd, yyyy • hh:mm a');

            final lfLabel =
                item.type == ItemType.found ? 'Date Found' : 'Date Lost';

            // Notice text depending on type
            final noticeLost = 'If you locate this item, please notify the admin office immediately.';
            final noticeFound = 'Please bring valid proof of ownership when claiming this item at the admin office.';
            final noticeText = item.type == ItemType.found ? noticeFound : noticeLost;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title 
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Info rows
                _infoRow('Type', item.type == ItemType.found ? 'Found' : 'Lost'),
                _infoRow('Category', item.category.label),
                _infoRow('Location', item.location),
                _infoRow(lfLabel, dateFmt.format(dtLostFound)),
                _infoRow('Date Posted', fullDateTimeFormat.format(createdAt)),
                const Divider(height: 28),

                // Notice
                Text('Notice:',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(noticeText),

                const SizedBox(height: 24),

                // Buttons (found only) 
                if (item.type == ItemType.found) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Message sent to Admin.')),
                            );
                          },
                          icon: const Icon(Icons.message_outlined),
                          label: const Text('Message Admin'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClaimItemPage(),
                              ),
                            );
                          },
                          child: const Text('Claim'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Utility: single two‑column row
  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
