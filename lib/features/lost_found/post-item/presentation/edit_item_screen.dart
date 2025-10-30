import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/category_utils.dart';
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
  final GlobalKey _descriptionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    itemName = widget.item.name;
    description = widget.item.description;
    location = widget.item.location;
    date = DateTime.tryParse(widget.item.lostFoundDate) ?? DateTime.now();
    // Try category name first, fallback to id mapping if provided
    try {
      category = ItemCategoryExtension.fromString(widget.item.category);
    } catch (_) {
      // if backend returns human label, fallback to 'others'
      category = ItemCategory.others;
    }
    _descriptionFocus = FocusNode();
    // Always focus on description field when page opens to encourage better descriptions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _descriptionFocus.requestFocus();
            // Scroll to description field
            Future.delayed(const Duration(milliseconds: 200), () {
              final context = _descriptionKey.currentContext;
              if (context != null && mounted) {
                Scrollable.ensureVisible(
                  context,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  alignment: 0.3, // Show field in upper portion of screen
                );
              }
            });
          }
        });
      }
    });
  }

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
          title: itemName,
          category: category!,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Item updated successfully!'),
            ],
          ),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(postItemStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 16), // Top margin
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusXLarge),
                      bottomRight: Radius.circular(AppTheme.radiusXLarge),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            itemType == ItemType.lost
                                ? 'Update Lost Item'
                                : 'Update Found Item',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance with back button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Tip Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.tips_and_updates_outlined,
                              color: AppTheme.primaryBlue,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Enhance your description',
                                    style: TextStyle(
                                      color: AppTheme.darkText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Add specific details like color, brand, size, or unique marks to improve matching accuracy',
                                    style: TextStyle(
                                      color: AppTheme.darkText.withOpacity(0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Form Section
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Name Card
                          _buildFormSection(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Item Name',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: itemName,
                                  decoration: InputDecoration(
                                    labelText: 'Enter item name',
                                    hintText: 'e.g. Wallet, Backpack, Keys',
                                    prefixIcon: Icon(
                                      Icons.shopping_bag,
                                      color: AppTheme.primaryBlue,
                                      size: 22,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.lightPanel,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textGray,
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: AppTheme.bodyMedium,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'This field is required'
                                      : null,
                                  onSaved: (v) => itemName = v!,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category Card
                          _buildFormSection(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildCategoryGrid(),
                                if (category == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Please select a category',
                                      style: TextStyle(
                                        color: AppTheme.errorRed,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date Card
                          _buildFormSection(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date Lost',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightPanel,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${date.day}/${date.month}/${date.year}',
                                          style: AppTheme.bodyMedium,
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          color: AppTheme.primaryBlue,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Location Card
                          _buildFormSection(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Location',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: location,
                                  decoration: InputDecoration(
                                    labelText: 'Location',
                                    hintText: 'Where was the item lost?',
                                    prefixIcon: Icon(
                                      Icons.location_on,
                                      color: AppTheme.primaryBlue,
                                      size: 22,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.lightPanel,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textGray,
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: AppTheme.bodyMedium,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'This field is required'
                                      : null,
                                  onSaved: (v) => location = v!,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description Card
                          _buildFormSection(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.darkText,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  key: _descriptionKey,
                                  initialValue: description,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Enter short description',
                                    hintText:
                                        'e.g., color, brand, special marks',
                                    prefixIcon: Icon(
                                      Icons.description,
                                      color: AppTheme.primaryBlue,
                                      size: 22,
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.lightPanel,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryBlue,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.1,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                    labelStyle: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textGray,
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontSize: 12,
                                    ),
                                    helperText:
                                        'Be specific: mention color, brand, size, or unique features',
                                    helperMaxLines: 2,
                                    helperStyle: TextStyle(
                                      fontSize: 11,
                                      color: Colors.red.withOpacity(0.8),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  style: AppTheme.bodyMedium,
                                  focusNode: _descriptionFocus,
                                  autofocus:
                                      false, // We handle focus manually in initState
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'This field is required'
                                      : null,
                                  onSaved: (v) => description = v!,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: AppTheme.primaryBlue.withOpacity(
                                  0.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Save Changes',
                                    style: AppTheme.heading4.copyWith(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildFormSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: child,
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: ItemCategory.values.length,
      itemBuilder: (context, index) {
        final cat = ItemCategory.values[index];
        final isSelected = category == cat;

        return GestureDetector(
          onTap: () => setState(() => category = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryBlue : AppTheme.lightPanel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.primaryBlue.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CategoryUtils.getIcon(cat),
                  color: isSelected ? Colors.white : AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  cat.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.darkText,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
