import 'package:navistfind/core/navigation/navigation_wrapper.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/post-item/application/post_item_provider.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostItemScreen extends ConsumerStatefulWidget {
  const PostItemScreen({super.key});

  @override
  ConsumerState<PostItemScreen> createState() => PostItemScreenState();
}

class PostItemScreenState extends ConsumerState<PostItemScreen> {
  final formKey = GlobalKey<FormState>();
  // Users can ONLY report lost items
  final ItemType itemType = ItemType.lost;

  String itemName = '';
  String description = '';
  String location = '';
  DateTime date = DateTime.now();
  ItemCategory? category;

  Future<void> selectDate(BuildContext context) async {
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

  Future<void> submitForm() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();

      ref.read(postItemStateProvider.notifier).state = true;
      final error = await ref
          .read(postItemProvider)
          .postItem(
            title: itemName,
            description: description,
            location: location,
            date: date,
            category: category!,
            type: itemType,
          );
      ref.read(postItemStateProvider.notifier).state = false;

      if (!mounted) return;

      if (error == null) {
        // Invalidate all relevant providers so lists update immediately
        ref.invalidate(itemListProvider);
        ref.invalidate(postedItemsProvider);
        ref.invalidate(itemsByTypeProvider(ItemType.lost));
        ref.invalidate(recommendedItemsProvider);

        // Navigate to Home and select Lost & Found -> My Posts (tab index 2 within Lost & Found)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const NavigationWrapper(
              initialIndex: 1, // Lost & Found in bottom nav
              lostFoundInitialTabIndex: 2, // My Posts tab
            ),
          ),
          (route) => false,
        );
        // Success color palette per UX: green for success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Item posted successfully!'),
              ],
            ),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
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
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Report Lost Item",
                            style: TextStyle(
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
                key: formKey,
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
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Provide accurate details to increase chances of recovery',
                                style: TextStyle(
                                  color: AppTheme.darkText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
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
                                buildTextField(
                                  label: 'Enter item name',
                                  hint: 'e.g. Wallet, Backpack, Keys',
                                  icon: Icons.shopping_bag,
                                  onSaved: (value) => itemName = value!,
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
                                  onTap: () => selectDate(context),
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
                                buildTextField(
                                  label: 'Location',
                                  hint: 'Where was the item lost?',
                                  icon: Icons.location_on,
                                  onSaved: (value) => location = value!,
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
                                buildTextField(
                                  label: 'Enter short description',
                                  hint: 'e.g., color, brand, special marks',
                                  icon: Icons.description,
                                  maxLines: 3,
                                  onSaved: (value) => description = value!,
                                  helperText:
                                      'Be specific: mention color, brand, size, or unique features',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: submitForm,
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
                                  const Icon(Icons.upload_file, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Post Lost Item',
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
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.primaryBlue,
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

  Widget buildTextField({
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    required Function(String?) onSaved,
    String? helperText,
  }) {
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, color: AppTheme.primaryBlue, size: 22)
            : null,
        filled: true,
        fillColor: AppTheme.lightPanel,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textGray),
        floatingLabelStyle: const TextStyle(
          color: AppTheme.primaryBlue,
          fontSize: 12,
        ),
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: TextStyle(
          fontSize: 11,
          color: Colors.red.withOpacity(0.8),
          fontStyle: FontStyle.italic,
        ),
      ),
      style: AppTheme.bodyMedium,
      validator: (v) =>
          (v == null || v.isEmpty) ? 'This field is required' : null,
      onSaved: onSaved,
    );
  }
}
