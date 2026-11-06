import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../models/profile.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profiling_providers.dart';
import 'cooperatives_screen.dart';
import '../../../core/l10n/app_language.dart';

/// The researcher's profile-preparation form (paper §3.5.4). Captures
/// identity, products, barter willingness, device/data-plan attributes,
/// farm GPS only with consent C3, and the verification level (Table 3.4;
/// level 2 only with consent C5). The profile is saved hidden. No farm
/// photographs are taken (Table 3.14).
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

  /// C3: agreed to share farm GPS coordinates.
  bool _locationConsent = false;

  /// C5: agreed to cooperative confirmation, and the cooperative has
  /// confirmed membership. Together these make verification level 2.
  bool _cooperativeConsent = false;
  bool _cooperativeConfirmed = false;

  /// The farmer's cooperative, saved only with consent C5.
  String? _cooperativeId;
  GeoPoint? _farmLocation;
  bool _busy = false;

  int get _verificationLevel => _cooperativeConsent && _cooperativeConfirmed
      ? Profile.levelCooperativeConfirmed
      : Profile.levelVisited;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_barangay == null) {
      setState(() => _error = 'Please select a barangay.');
      return;
    }
    if (_cooperativeConfirmed && _cooperativeId == null) {
      setState(() => _error =
          'Choose the cooperative that confirmed membership, or untick the '
          'confirmation.');
      return;
    }
    if (!_consentGiven) {
      setState(() => _error =
          'Consent to participate and to account registration (C8) must be '
          'confirmed before saving (RA 10173).');
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
        phone: Validators.toE164Ph(_phoneController.text),
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
        cooperativeId: _cooperativeConsent ? _cooperativeId : null,
      );

      final result =
          await ref.read(profilingControllerProvider).saveNewFarmer(
                draft: draft,
                email: _emailController.text.trim(),
                farmLocation: _locationConsent ? _farmLocation : null,
                verificationLevel: _verificationLevel,
              );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(context.tr(
              'Profile saved (hidden)', 'Na-save ang profile (nakatago)')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Record these in the restricted research records. Do NOT '
                  'give them to the participant during Phase 2; they are '
                  'used only if the participant joins a separately '
                  'consented testing phase.'),
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
      appBar: AppBar(
          title: Text(context.tr('Profile a Farmer', 'I-profile ang Mag-uuma'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(context.tr('Identity', 'Pagkatawo'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                    labelText: context.tr('Full name *', 'Tibuok ngalan *')),
                validator: (v) =>
                    Validators.requiredField(v, label: 'Full name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // Long labels shrink with '...' instead of overflowing.
                isExpanded: true,
                initialValue: _barangay,
                decoration:
                    const InputDecoration(labelText: 'Barangay *'),
                items: AppConstants.calinanBarangays
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _barangay = v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText:
                        context.tr('Mobile number *', 'Numero sa cellphone *'),
                    helperText: '09XXXXXXXXX'),
                validator: (v) => Validators.phPhone(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.tr('Account email *', 'Email sa account *'),
                  helperText:
                      'Used for sign-in. A managed address like name.agrikonek@gmail.com works.',
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 24),
              Text(context.tr('Roles', 'Mga papel'),
                  style: theme.textTheme.titleMedium),
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
              Text(context.tr('Farm & Products', 'Uma ug Produkto'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _productsController,
                decoration: InputDecoration(
                  labelText: context.tr('Products (comma-separated)',
                      'Mga produkto (bulagon og koma)'),
                  hintText: 'durian, eggs, manure',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _farmSizeController,
                decoration: InputDecoration(
                    labelText: context.tr('Approximate farm size, notes',
                        'Gibanabana nga gidak-on sa uma, mga nota')),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('Willing to barter?', 'Andam mo-baylo?')),
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
              Text(context.tr('Device & Connectivity', 'Cellphone ug Internet'),
                  style: theme.textTheme.titleMedium),
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
              Text(context.tr('Farm Location', 'Lokasyon sa uma'),
                  style: theme.textTheme.titleMedium),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                    'C3: The participant agreed to share farm GPS coordinates'),
                value: _locationConsent,
                onChanged: (v) => setState(() {
                  _locationConsent = v ?? false;
                  if (!_locationConsent) _farmLocation = null;
                }),
              ),
              if (_locationConsent) Row(
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
                    label: Text(context.tr('Capture', 'Kuhaa')),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(context.tr('Verification', 'Pag-verify'),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text('Level 1 "Visited by researchers" is recorded for '
                  'everyone met in Calinan.'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                    'C5: The participant agreed to cooperative confirmation'),
                value: _cooperativeConsent,
                onChanged: (v) => setState(() {
                  _cooperativeConsent = v ?? false;
                  if (!_cooperativeConsent) {
                    _cooperativeConfirmed = false;
                    _cooperativeId = null;
                  }
                }),
              ),
              if (_cooperativeConsent) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        // Long labels shrink with '...' instead of overflowing.
                        isExpanded: true,
                        initialValue: _cooperativeId,
                        decoration: const InputDecoration(
                            labelText: 'Cooperative or association'),
                        items: [
                          for (final c
                              in ref.watch(cooperativesProvider).valueOrNull ??
                                  const [])
                            DropdownMenuItem(
                                value: c.cooperativeId, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _cooperativeId = v),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add a cooperative',
                      icon: const Icon(Icons.add_business_outlined),
                      onPressed: () async {
                        final id = await showAddCooperativeDialog(context, ref,
                            barangay: _barangay);
                        if (id != null && mounted) {
                          setState(() => _cooperativeId = id);
                        }
                      },
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                      'The cooperative or association confirmed membership '
                      '(level 2 "Cooperative-confirmed")'),
                  value: _cooperativeConfirmed,
                  onChanged: (v) =>
                      setState(() => _cooperativeConfirmed = v ?? false),
                ),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                    'The participant gave informed consent and agreed to '
                    'account registration (C1, C2, C8) *'),
                subtitle: const Text(
                    'The profile is saved hidden from other users.'),
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
                    : Text(context.tr('SAVE PROFILE', 'I-SAVE ANG PROFILE')),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
