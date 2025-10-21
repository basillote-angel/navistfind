import 'package:flutter/material.dart';
import 'package:navistfind/features/lost_found/item/data/item_service.dart';

class ClaimItemPage extends StatefulWidget {
  final int itemId;
  const ClaimItemPage({super.key, required this.itemId});

  @override
  State<ClaimItemPage> createState() => _ClaimItemPageState();
}

class _ClaimItemPageState extends State<ClaimItemPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactInfoController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final service = ItemService();
      await service.claimFoundItem(
        id: widget.itemId,
        message: _messageController.text.trim(),
        contactName: _contactNameController.text.trim().isEmpty
            ? null
            : _contactNameController.text.trim(),
        contactInfo: _contactInfoController.text.trim().isEmpty
            ? null
            : _contactInfoController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Claim submitted. Awaiting admin approval.'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to submit claim: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.grey[200],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Item', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C2A40),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 24),
              const Text(
                'Your Name',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contactNameController,
                decoration: _inputDecoration('Full name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              const Text(
                'Contact Info',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contactInfoController,
                decoration: _inputDecoration('Phone or email'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              const Text(
                'Proof of ownership / description',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: _inputDecoration('Describe why this is yours'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: const Color(0xFF1C2A40),
                  foregroundColor: Colors.white,
                ),
                child: Text(_submitting ? 'Submitting…' : 'Submit Claim'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
