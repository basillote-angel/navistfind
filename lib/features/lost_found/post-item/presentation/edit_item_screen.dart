// ignore_for_file: unused_import
import 'package:navistfind/core/navigation/app_routes.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/post-item/application/post_item_provider.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ------------------------------------------------------------
/// EditItemScreen – shares the *exact* visual style of PostItemScreen
/// but submits to `updateItem()` instead of `postItem()`.
/// ------------------------------------------------------------
class EditItemScreen extends ConsumerStatefulWidget {
  const EditItemScreen({
    super.key,
    required this.item,
    this.focusDescription = false,
  });
  final PostedItem item;
  final bool focusDescription;

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final ItemType itemType = ItemType.lost;
  // Prefilled fields
  late String itemName;
  late String description;
  late String location;
  late DateTime date;
  late ItemCategory? category;
  late final FocusNode _descriptionFocus;

  @override
  void initState() {
    super.initState();
    itemName = widget.item.name;
    description = widget.item.description;
    location = widget.item.location;
    date = DateTime.tryParse(widget.item.lostFoundDate) ?? DateTime.now();
    category = ItemCategoryExtension.fromString(widget.item.category);
    _descriptionFocus = FocusNode();
    if (widget.focusDescription) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).requestFocus(_descriptionFocus);
        }
      });
    }
  }

  Color get _accent => const Color(0xFF1C2A40);

  /*━━━━━━━━━━━━━━  UI helpers  ━━━━━━━━━━━━━━*/
  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1C2A40),
    ),
  );

  InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey[200],
    contentPadding: const EdgeInsets.all(16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFF1C2A40), width: 2),
    ),
  );

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.grey[200],
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1C2A40), width: 2),
    ),
  );

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != date) {
      setState(() => date = picked);
    }
  }

  /*━━━━━━━━━━━━━━  Submit  ━━━━━━━━━━━━━━*/
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    ref.read(postItemStateProvider.notifier).state = true;
    final error = await ref
        .read(postItemProvider)
        .updateItem(
          itemId: widget.item.id,
          itemName: itemName,
          category: category!.apiValue,
          description: description,
          location: location,
          date: date,
          type: itemType,
        );
    ref.read(postItemStateProvider.notifier).state = false;

    if (!mounted) return;

    if (error == null) {
      // refresh lists & pop back (realtime UX)
      ref.invalidate(postedItemsProvider);
      ref.invalidate(itemListProvider);
      ref.invalidate(itemsByTypeProvider(ItemType.lost));
      ref.invalidate(recommendedItemsProvider);
      // Ensure details modal shows updated fields like location immediately
      ref.invalidate(itemDetailsProvider(widget.item.id));
      // Navigate back to My Posts (Lost & Found screen is tabbed; keeping simple pop works if we came from it)
      Navigator.pop(context);
      // Success green
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item updated successfully'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item updated successfully!'),
          backgroundColor: _accent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFC62828), // error red
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(postItemStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2A40),
        title: Text(
          itemType == ItemType.lost ? 'Update Lost Item' : 'Update Found Item',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1C2A40)),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name
                      _label('Item Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: itemName,
                        decoration: _fieldDecoration(
                          hint: 'e.g. Wallet, Backpack',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'This field is required'
                            : null,
                        onSaved: (v) => itemName = v!,
                      ),
                      const SizedBox(height: 18),

                      // Category
                      _label('Category'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ItemCategory>(
                        value: category,
                        decoration: _dropdownDecoration(),
                        items: ItemCategory.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => category = v),
                        validator: (v) =>
                            v == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 18),

                      // Date
                      _label('Date'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: _dropdownDecoration(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${date.day}/${date.month}/${date.year}',
                                style: const TextStyle(
                                  color: Color(0xFF1C2A40),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_month_outlined,
                                color: Color(0xFFF4B431),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Location
                      _label('Location'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: location,
                        decoration: _fieldDecoration(
                          hint: 'Where was the item lost/found?',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'This field is required'
                            : null,
                        onSaved: (v) => location = v!,
                      ),
                      const SizedBox(height: 20),

                      // Description helper (no chips); highlight by focusing the field
                      const Text(
                        'Add color/brand or unique marks in the description to improve matches.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      _label('Short Description'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: description,
                        maxLines: 3,
                        decoration:
                            _fieldDecoration(
                              hint: 'e.g., color, brand, special marks',
                            ).copyWith(
                              // Navy blue border to highlight where to type
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1C2A40),
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1C2A40),
                                  width: 2,
                                ),
                              ),
                            ),
                        focusNode: _descriptionFocus,
                        autofocus: widget.focusDescription,
                        validator: (v) => v == null || v.isEmpty
                            ? 'This field is required'
                            : null,
                        onSaved: (v) => description = v!,
                      ),
                      const SizedBox(height: 28),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.grey[200],
                            backgroundColor: const Color(0xFF1C2A40),
                            elevation: 2,
                            shadowColor: const Color(
                              0xFF1C2A40,
                            ).withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
