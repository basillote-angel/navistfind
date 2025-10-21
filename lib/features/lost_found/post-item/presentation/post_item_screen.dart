// ignore_for_file: unused_import
import 'package:navistfind/core/navigation/app_routes.dart';
import 'package:navistfind/core/navigation/navigation_wrapper.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/post-item/application/post_item_provider.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
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
            itemName: itemName,
            description: description,
            location: location,
            date: date,
            category: category!.apiValue,
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
            content: const Text('Item posted successfully'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
    final theme = Theme.of(context);
    final isLoading = ref.watch(postItemStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2A40),
        title: Text(
          "Report Lost Item",
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
                key: formKey,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Item Name',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2A40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildTextField(
                        label: 'Enter item name',
                        hint: 'e.g. Wallet, Backpack, Keys',
                        onSaved: (value) => itemName = value!,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Category',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2A40),
                        ),
                      ),
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
                        onChanged: (value) => setState(() => category = value),
                        validator: (value) =>
                            value == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Date',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2A40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => selectDate(context),
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
                      Text(
                        'Location',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2A40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildTextField(
                        label: 'Location',
                        hint: 'Where was the item lost/found?',
                        onSaved: (value) => location = value!,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Short Description',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2A40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      buildTextField(
                        label: 'Enter short description',
                        hint: 'e.g., color, brand, special marks',
                        maxLines: 3,
                        onSaved: (value) => description = value!,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: submitForm,
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
                            'Post Lost Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
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

  // _label kept for potential future use; currently not referenced

  InputDecoration _dropdownDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.grey[200],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFF1C2A40), width: 2),
    ),
  );

  Widget buildTextField({
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, color: Color(0xFFF4B431)) : null,
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          borderSide: BorderSide(color: Color(0xFF1C2A40), width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF1C2A40)),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF1C2A40),
          fontSize: 12,
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xFF1C2A40)),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'This field is required' : null,
      onSaved: onSaved,
    );
  }
}
