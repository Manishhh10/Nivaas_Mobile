import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nivaas/core/api/api_endpoints.dart';
import 'package:nivaas/core/providers/app_providers.dart';

/// Full-screen host application form with ID document upload.
class HostApplyScreen extends ConsumerStatefulWidget {
  const HostApplyScreen({super.key});

  @override
  ConsumerState<HostApplyScreen> createState() => _HostApplyScreenState();
}

class _HostApplyScreenState extends ConsumerState<HostApplyScreen> {
  static const Color primaryOrange = Color(0xFFFF6518);

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _govIdCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _idDocumentFile;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from user data
    final verifyData = ref.read(verifyProvider).value;
    if (verifyData?.user != null) {
      _nameCtrl.text = verifyData!.user!.name;
      _phoneCtrl.text = verifyData.user!.phoneNumber;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _govIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: primaryOrange),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: primaryOrange),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() => _idDocumentFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final govId = _govIdCtrl.text.trim();

    if (name.isEmpty || phone.isEmpty || address.isEmpty || govId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in all required fields'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = ref.read(apiClientProvider);

      // Build multipart form data so the backend receives the file
      final formData = FormData.fromMap({
        'legalName': name,
        'phoneNumber': phone,
        'address': address,
        'governmentId': govId,
        if (_idDocumentFile != null)
          'idDocument': await MultipartFile.fromFile(
            _idDocumentFile!.path,
            filename: _idDocumentFile!.path.split(Platform.pathSeparator).last,
          ),
      });

      await api.post(ApiEndpoints.hostApply, data: formData);
      ref.invalidate(verifyProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Host application submitted!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context); // return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Host Application',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fill in your details to apply as a host',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 24),

            _field(_nameCtrl, 'Legal Name *', Icons.person_outline),
            const SizedBox(height: 14),
            _field(_phoneCtrl, 'Phone Number *', Icons.phone_outlined,
                keyboard: TextInputType.phone),
            const SizedBox(height: 14),
            _field(_addressCtrl, 'Address *', Icons.location_on_outlined),
            const SizedBox(height: 14),
            _field(_govIdCtrl, 'Government ID Number *', Icons.badge_outlined),
            const SizedBox(height: 20),

            // ID Document upload
            const Text('ID Document Image',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
                'Upload a photo of your government-issued ID (citizenship, passport, driving license)',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDocument,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _idDocumentFile != null
                        ? primaryOrange
                        : colorScheme.outline.withOpacity(0.45),
                    width: _idDocumentFile != null ? 2 : 1,
                  ),
                ),
                child: _idDocumentFile != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(
                              _idDocumentFile!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _idDocumentFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 18, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 40, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text('Tap to upload ID document',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('JPEG, PNG • Max 5MB',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.9), fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: primaryOrange.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Application',
                        style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryOrange),
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
      ),
    );
  }
}
