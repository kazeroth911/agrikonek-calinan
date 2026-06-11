import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/profile.dart';
import '../providers/profiling_providers.dart';

/// The Sprint 1 centerpiece: the researcher's field profiling form
/// (paper §4.4 Phase 2). Captures identity, products, barter
/// willingness, device/data-plan attributes, optional farm GPS,
/// photos, and consent — then creates the auth account + profile doc.
class ProfilingFormScreen extends ConsumerStatefulWidget {
  const ProfilingFormScreen({super.key});

  @override
  ConsumerState<ProfilingFormScreen> createState() =>
      _ProfilingFormScreenState();
}

class _ProfilingFormScreenState extends ConsumerState<ProfilingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _productsController = TextEditingController();
  final _tradeResourcesController = TextEditingController();
  final _farmSizeController = TextEditingController();
  final _deviceController = TextEditingController();
  final _dataPlanController = TextEditingController();

  String? _barangay;
  final Set<String> _roles = {AppConstants.roleSeller, AppConstants.roleBuyer};
  bool _barterWilling = false;
  bool _consentGiven = false;
  GeoPoint? _farmLocation;
  final List<File> _photos = [];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _phoneController,
      _emailController,
      _productsController,
      _tradeResourcesController,
      _farmSizeController,
      _deviceController,
      _dataPlanController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _splitList(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  Future<void> _captureLocation() async {
    setState(() => _error = null);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _error = 'Location permission denied.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(
          () => _farmLocation = GeoPoint(pos.latitude, pos.longitude));
    } catch (e) {
      setState(() => _error = 'Could not get location: $e');
    }
  }

  Future<void> _addPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1280, // keep uploads small for rural data plans
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_barangay == null) {
      setState(() => _error = 'Please select a barangay.');
      return;
    }
    if (!_consentGiven) {
      setState(() =>
          _error = 'Written consent must be confirmed before saving (RA 10173).');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final draft = Profile(
        userId: '', // assigned by the controller after auth creation
        fullName: _nameController.text.trim(),
        roles: _roles.toList(),
        barangay: _barangay!,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : Validators.toE164Ph(_phoneController.text),
        products: _splitList(_productsController.text),
        barterWillingness: _barterWilling,
        preferredTradeResources: _splitList(_tradeResourcesController.text),
        farmSizeNote: _farmSizeController.text.trim().isEmpty
            ? null
            : _farmSizeController.text.trim(),
        deviceType: _deviceController.text.trim().isEmpty
            ? null
            : _deviceController.text.trim(),
        dataPlan: _dataPlanController.text.trim().isEmpty
            ? null
            : _dataPlanController.text.trim(),
        consentGiven: _consentGiven,
      );

      final result =
          await ref.read(profilingControllerProvider).saveNewFarmer(
                draft: draft,
                email: _emailController.text.trim(),
                photos: _photos,
                farmLocation: _farmLocation,
              );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Profile saved!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Write these on the credential slip '
                  'for the farmer:'),
              const SizedBox(height: 12),
              SelectableText('Email: ${result.email}\n'
                  'Password: ${result.starterPassword}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('DONE'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile a Farmer')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Identity', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name *'),
                validator: (v) =>
                    Validators.requiredField(v, label: 'Full name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _barangay,
                decoration: const InputDecoration(labelText: 'Barangay *'),
                items: AppConstants.calinanBarangays
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _barangay = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Mobile number (09XXXXXXXXX)'),
                validator: (v) => Validators.phPhone(v, optional: true),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Account email *',
                  helperText:
                      'Used for sign-in. A managed address like name.agrikonek@gmail.com works.',
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 24),
              Text('Roles', style: theme.textTheme.titleMedium),
              Wrap(
                spacing: 8,
                children: [
                  for (final role in [
                    AppConstants.roleSeller,
                    AppConstants.roleBuyer,
                    AppConstants.roleTrader,
                  ])
                    FilterChip(
                      label: Text(role),
                      selected: _roles.contains(role),
                      onSelected: (selected) => setState(() {
                        selected ? _roles.add(role) : _roles.remove(role);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Farm & Products', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _productsController,
                decoration: const InputDecoration(
                  labelText: 'Products (comma-separated)',
                  hintText: 'durian, eggs, manure',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmSizeController,
                decoration: const InputDecoration(
                    labelText: 'Approximate farm size / notes'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Willing to barter?'),
                value: _barterWilling,
                onChanged: (v) => setState(() => _barterWilling = v),
              ),
              if (_barterWilling)
                TextFormField(
                  controller: _tradeResourcesController,
                  decoration: const InputDecoration(
                    labelText: 'Preferred trade resources (comma-separated)',
                    hintText: 'compost, feeds, seedlings',
                  ),
                ),
              const SizedBox(height: 24),
              Text('Device & Connectivity', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deviceController,
                decoration: const InputDecoration(
                    labelText: 'Device type', hintText: 'e.g. Android 10, 2GB RAM'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dataPlanController,
                decoration: const InputDecoration(
                    labelText: 'Data plan', hintText: 'e.g. prepaid promo, Wi-Fi at home'),
              ),
              const SizedBox(height: 24),
              Text('Farm Location (optional, with consent)',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(_farmLocation == null
                        ? 'Not captured'
                        : 'Lat ${_farmLocation!.latitude.toStringAsFixed(5)}, '
                          'Lng ${_farmLocation!.longitude.toStringAsFixed(5)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _captureLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Capture'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Farm Photos', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final photo in _photos)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(photo,
                          width: 80, height: 80, fit: BoxFit.cover),
                    ),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _addPhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Add photo'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                    'Written informed consent has been signed (RA 10173) *'),
                value: _consentGiven,
                onChanged: (v) =>
                    setState(() => _consentGiven = v ?? false),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('SAVE PROFILE'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
