import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/snackbar_utils.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/features/profile/domain/models/claim_request.dart';

class EditClaimRequestPage extends ConsumerStatefulWidget {
  const EditClaimRequestPage({super.key, required this.claim});

  final ClaimRequest claim;

  @override
  ConsumerState<EditClaimRequestPage> createState() =>
      _EditClaimRequestPageState();
}

class _EditClaimRequestPageState extends ConsumerState<EditClaimRequestPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactInfoController;
  late final TextEditingController _messageController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contactNameController = TextEditingController(
      text: widget.claim.claimantContactName ?? '',
    );
    _contactInfoController = TextEditingController(
      text: widget.claim.claimantContactInfo ?? '',
    );
    _messageController = TextEditingController(
      text: widget.claim.message ?? '',
    );
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactInfoController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final notifier = ref.read(claimRequestsProvider.notifier);
    final error = await notifier.updateClaim(
      claimId: widget.claim.id,
      message: _messageController.text.trim(),
      contactName: _contactNameController.text.trim(),
      contactInfo: _contactInfoController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() => _saving = false);

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      SnackbarUtils.showError(context, error);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text(
          'Edit Claim Request',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: AppTheme.primaryBlue.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_note_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.claim.foundItem?.title ??
                                  'Claim Information',
                              style: AppTheme.heading3.copyWith(
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Update your contact details or proof of ownership message. '
                        'The admin team will review the latest information.',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textGray,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Contact Information', style: AppTheme.heading4),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNameController,
                  decoration: _inputDecoration(
                    'Full Name',
                    Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contactInfoController,
                  decoration: _inputDecoration(
                    'Phone Number or Email',
                    Icons.contact_phone_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your contact information';
                    }
                    final trimmed = value.trim();
                    final emailRegex = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    );
                    final phoneRegex = RegExp(r'^[0-9+\-\s()]+$');
                    if (!emailRegex.hasMatch(trimmed) &&
                        !phoneRegex.hasMatch(trimmed)) {
                      return 'Please enter a valid email or phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text('Proof of Ownership', style: AppTheme.heading4),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  maxLines: 6,
                  decoration: _inputDecoration(
                    'Describe why this item belongs to you',
                    Icons.description_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe why this item belongs to you';
                    }
                    if (value.trim().length < 20) {
                      return 'Please provide more details (at least 20 characters)';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: AppTheme.getPrimaryButtonStyle(),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
