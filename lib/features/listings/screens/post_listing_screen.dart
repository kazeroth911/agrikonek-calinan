import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/listing.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/listing_providers.dart';
import '../../../core/l10n/app_language.dart';

/// Post a product/resource listing (paper workflow 2), or edit one when
/// [existing] is given. Minimal fields per the HCI commitments; photos
/// upload best-effort so a failed Storage call never costs the farmer
/// their filled-in form.
class PostListingScreen extends ConsumerStatefulWidget {
  const PostListingScreen({super.key, this.existing});

  /// The listing being edited, or null for a new listing.
  final Listing? existing;

  /// Longest title the security rules accept.
  static const maxTitleLength = 120;

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

  /// Photos already uploaded for the listing being edited.
  final List<String> _existingPhotoUrls = [];
  bool _busy = false;
  String? _error;

  static final _dateLabel = DateFormat('MMM d, yyyy');

  bool get _editing => widget.existing != null;

  int get _photoCount => _existingPhotoUrls.length + _photos.length;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    if (l != null) {
      _titleController.text = l.title;
      _descriptionController.text = l.description;
      if (l.price != null) _priceController.text = l.price.toString();
      _category = AppConstants.listingCategories.contains(l.category)
          ? l.category
          : null;
      _unit = AppConstants.listingUnits.contains(l.unit) ? l.unit : null;
      _openToBarter = l.modes.contains(ListingMode.barter);
      _availableFrom = l.availableFrom;
      _availableTo = l.availableTo;
      _existingPhotoUrls.addAll(l.photoUrls);
    }
  }

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
    final initial = (isFrom ? _availableFrom : _availableTo) ?? now;
    // An edited listing may already have a past date; the picker must
    // allow it or it throws.
    final earliest = now.subtract(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: initial.isBefore(earliest) ? initial : earliest,
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
      setState(() => _error =
          context.tr('Please select a category.', 'Pilia ang kategorya.'));
      return;
    }
    final price = _price;
    if (price == null && !_openToBarter) {
      setState(() => _error = context.tr(
          'Enter a price, or turn on barter for a barter-only listing.',
          'Butangi og presyo, o i-on ang baylo kung baylo lang.'));
      return;
    }

    final profile = ref.read(currentProfileProvider).valueOrNull;
    if (profile == null) {
      setState(() => _error = context.tr(
          'Your profile is still loading. Try again.',
          'Nag-load pa ang imong profile. Sulayi pag-usab.'));
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Best-effort upload: empty result = Storage unavailable (Spark
      // tier / offline) and the listing posts photo-less.
      final newPhotoUrls = await ref
          .read(storageServiceProvider)
          .uploadListingPhotos(ownerUid: profile.userId, files: _photos);
      final photoUrls = [..._existingPhotoUrls, ...newPhotoUrls];
      final modes = [
        if (price != null) ListingMode.sale,
        if (_openToBarter) ListingMode.barter,
      ];

      final existing = widget.existing;
      if (existing != null) {
        // Only the fields the form edits; owner, name and createdAt stay
        // as they are (the security rules refuse to change them).
        await ref.read(listingRepositoryProvider).updateListing(
          existing.listingId,
          {
            'title': _titleController.text.trim(),
            'category': _category!,
            'description': _descriptionController.text.trim(),
            'unit': price == null ? null : _unit,
            'price': price,
            'modes': modes.map((m) => m.name).toList(),
            'photoUrls': photoUrls,
            'availableFrom': _availableFrom == null
                ? null
                : Timestamp.fromDate(_availableFrom!),
            'availableTo':
                _availableTo == null ? null : Timestamp.fromDate(_availableTo!),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_photos.isNotEmpty &&
                  newPhotoUrls.length < _photos.length
              ? context.tr(
                  'Changes saved, but new photos could not be uploaded.',
                  'Na-save na, pero wala ma-upload ang bag-ong mga litrato.')
              : context.tr('Changes saved.', 'Na-save na.')),
        ));
        Navigator.of(context).pop();
        return;
      }

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
        modes: modes,
        photoUrls: photoUrls,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
      );

      await ref.read(listingRepositoryProvider).createListing(listing);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (_photos.isNotEmpty && newPhotoUrls.length < _photos.length) {
        messenger.showSnackBar(SnackBar(
          content: Text(context.tr(
              'Listing posted, but photos could not be uploaded. '
                  'You can add them later.',
              'Na-post na ang baligya, pero wala ma-upload ang mga litrato. '
                  'Mahimo nimo kining idugang unya.')),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(
              context.tr('Listing posted!', 'Na-post na ang baligya!')),
        ));
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final language = ref.read(languageProvider);
        setState(() => _error = _editing
            ? '${tr(language, 'Could not save changes', 'Wala na-save ang mga kausaban')}: $e'
            : '${tr(language, 'Could not post listing', 'Wala na-post ang baligya')}: $e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
          title: Text(_editing
              ? context.tr('Edit Listing', 'Usba ang Baligya')
              : context.tr('Post a Listing', 'Mag-post og Baligya'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                maxLength: PostListingScreen.maxTitleLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr(
                      'What are you selling? *', 'Unsa imong ibaligya? *'),
                  hintText: context.tr('e.g. Durian (Puyat), native eggs',
                      'pananglitan: Durian (Puyat), itlog nga bisaya'),
                ),
                validator: (v) => Validators.requiredField(v, label: 'Title') ==
                        null
                    ? null
                    : context.tr('Title is required', 'Kinahanglan ang titulo'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // Long labels shrink with '...' instead of overflowing.
                isExpanded: true,
                initialValue: _category,
                decoration: InputDecoration(
                    labelText: context.tr('Category *', 'Kategorya *')),
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
                      decoration: InputDecoration(
                        labelText: context.tr('Price (₱)', 'Presyo (₱)'),
                        helperText: context.tr('Leave blank if barter only',
                            'Ayaw butangi kung baylo lang'),
                      ),
                      validator: (v) {
                        final raw = v?.trim().replaceAll(',', '') ?? '';
                        if (raw.isEmpty) return null; // barter-only is valid
                        final parsed = num.tryParse(raw);
                        if (parsed == null || parsed <= 0) {
                          return context.tr(
                              'Enter a valid price', 'Butangi og saktong presyo');
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      // Long labels shrink with '...' instead of overflowing.
                      isExpanded: true,
                      initialValue: _unit,
                      decoration: InputDecoration(
                          labelText: context.tr('Per unit', 'Matag')),
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
                title: Text(context.tr('Open to barter', 'Pwede i-baylo')),
                subtitle: Text(context.tr(
                    'Other farmers can propose a trade instead of cash',
                    'Ang ubang mag-uuma makatanyag og baylo imbes kwarta')),
                value: _openToBarter,
                onChanged:
                    _busy ? null : (v) => setState(() => _openToBarter = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: context.tr(
                      'Description (optional)', 'Paghulagway (opsyonal)'),
                  hintText: context.tr(
                      'Quality, quantity available, pickup notes...',
                      'Kalidad, pila ang naa, asa kuhaon...'),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                  context.tr('Availability (optional)',
                      'Kanus-a available (opsyonal)'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickDate(isFrom: true),
                      icon: const Icon(Icons.event_available),
                      label: Text(_availableFrom == null
                          ? context.tr('From', 'Gikan')
                          : _dateLabel.format(_availableFrom!)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickDate(isFrom: false),
                      icon: const Icon(Icons.event_busy),
                      label: Text(_availableTo == null
                          ? context.tr('Until', 'Hangtod')
                          : _dateLabel.format(_availableTo!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                  context.tr(
                      'Photos (up to ${AppConstants.maxListingPhotos})',
                      'Mga litrato (hangtod ${AppConstants.maxListingPhotos})'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < _existingPhotoUrls.length; i++)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(_existingPhotoUrls[i],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Icon(Icons.broken_image))),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _busy
                                ? null
                                : () => setState(
                                    () => _existingPhotoUrls.removeAt(i)),
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
                  if (_photoCount < AppConstants.maxListingPhotos) ...[
                    OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _addPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: Text(context.tr('Camera', 'Kamera')),
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
                    : Text(_editing
                        ? context.tr('SAVE CHANGES', 'I-SAVE')
                        : context.tr('POST LISTING', 'I-POST')),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
