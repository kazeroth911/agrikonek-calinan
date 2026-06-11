import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/listing.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/listing_providers.dart';

/// Post a product/resource listing (paper workflow 2). Minimal fields
/// per the HCI commitments; photos upload best-effort so a failed
/// Storage call never costs the farmer their filled-in form.
class PostListingScreen extends ConsumerStatefulWidget {
  const PostListingScreen({super.key});

  @override
  ConsumerState<PostListingScreen> createState() => _PostListingScreenState();
}

class _PostListingScreenState extends ConsumerState<PostListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String? _category;
  String? _unit;
  bool _openToBarter = false;
  DateTime? _availableFrom;
  DateTime? _availableTo;
  final List<File> _photos = [];
  bool _busy = false;
  String? _error;

  static final _dateLabel = DateFormat('MMM d, yyyy');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1280, // keep uploads small for rural data plans
      imageQuality: 75,
    );
    if (picked != null && mounted) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _availableFrom : _availableTo) ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => isFrom ? _availableFrom = picked : _availableTo = picked);
    }
  }

  num? get _price {
    final raw = _priceController.text.trim().replaceAll(',', '');
    return raw.isEmpty ? null : num.tryParse(raw);
  }

  Future<void> _post() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      setState(() => _error = 'Please select a category. / Pilia ang kategorya.');
      return;
    }
    final price = _price;
    if (price == null && !_openToBarter) {
      setState(() => _error =
          'Enter a price, or turn on barter for a barter-only listing.');
      return;
    }

    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) {
      setState(() => _error = 'Your profile is still loading. Try again.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Best-effort upload: empty result = Storage unavailable (Spark
      // tier / offline) and the listing posts photo-less.
      final photoUrls = await ref
          .read(storageServiceProvider)
          .uploadListingPhotos(ownerUid: profile.userId, files: _photos);

      final listing = Listing(
        listingId: '', // assigned by Firestore
        ownerId: profile.userId,
        // Denormalized so feed cards render without a profile read each.
        ownerName: profile.fullName,
        ownerBarangay: profile.barangay,
        title: _titleController.text.trim(),
        category: _category!,
        description: _descriptionController.text.trim(),
        unit: price == null ? null : _unit,
        price: price,
        modes: [
          if (price != null) ListingMode.sale,
          if (_openToBarter) ListingMode.barter,
        ],
        photoUrls: photoUrls,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
      );

      await ref.read(listingRepositoryProvider).createListing(listing);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (_photos.isNotEmpty && photoUrls.length < _photos.length) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Listing posted, but photos could not be uploaded. '
              'You can add them later.'),
        ));
      } else {
        messenger.showSnackBar(const SnackBar(
          content: Text('Listing posted! / Na-post na ang baligya!'),
        ));
      }
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Could not post listing: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Listing')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What are you selling? *',
                  hintText: 'e.g. Durian (Puyat), native eggs',
                ),
                validator: (v) =>
                    Validators.requiredField(v, label: 'Title'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration:
                    const InputDecoration(labelText: 'Category / Kategorya *'),
                items: AppConstants.listingCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _busy ? null : (v) => setState(() => _category = v),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Price (₱)',
                        helperText: 'Leave blank if barter only',
                      ),
                      validator: (v) {
                        final raw = v?.trim().replaceAll(',', '') ?? '';
                        if (raw.isEmpty) return null; // barter-only is valid
                        final parsed = num.tryParse(raw);
                        if (parsed == null || parsed <= 0) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(labelText: 'Per unit'),
                      items: AppConstants.listingUnits
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged:
                          _busy ? null : (v) => setState(() => _unit = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Open to barter / Pwede i-baylo'),
                subtitle: const Text(
                    'Other farmers can propose a trade instead of cash'),
                value: _openToBarter,
                onChanged:
                    _busy ? null : (v) => setState(() => _openToBarter = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Quality, quantity available, pickup notes...',
                ),
              ),
              const SizedBox(height: 24),
              Text('Availability (optional)', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickDate(isFrom: true),
                      icon: const Icon(Icons.event_available),
                      label: Text(_availableFrom == null
                          ? 'From'
                          : _dateLabel.format(_availableFrom!)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickDate(isFrom: false),
                      icon: const Icon(Icons.event_busy),
                      label: Text(_availableTo == null
                          ? 'Until'
                          : _dateLabel.format(_availableTo!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Photos (up to ${AppConstants.maxListingPhotos})',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_photos[i],
                              width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _busy
                                ? null
                                : () => setState(() => _photos.removeAt(i)),
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < AppConstants.maxListingPhotos) ...[
                    OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _addPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _addPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ],
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _post,
                child: _busy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('POST LISTING / I-POST'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
