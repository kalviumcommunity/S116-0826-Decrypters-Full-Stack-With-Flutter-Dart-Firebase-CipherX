import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../identity/presentation/providers/identity_providers.dart';
import '../../domain/entities/site.dart';
import '../../domain/validators/site_validator.dart';
import '../providers/site_providers.dart';

class SiteFormScreen extends ConsumerStatefulWidget {
  final Site? existingSite;

  const SiteFormScreen({
    super.key,
    this.existingSite,
  });

  @override
  ConsumerState<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends ConsumerState<SiteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _geofenceRadiusController;
  late SiteStatus _status;

  @override
  void initState() {
    super.initState();
    final site = widget.existingSite;
    _nameController = TextEditingController(text: site?.name ?? '');
    _addressController = TextEditingController(text: site?.address ?? '');
    _latitudeController = TextEditingController(
      text: site != null ? site.latitude.toString() : '',
    );
    _longitudeController = TextEditingController(
      text: site != null ? site.longitude.toString() : '',
    );
    _geofenceRadiusController = TextEditingController(
      text: site != null ? site.geofenceRadius.toString() : '500.0',
    );
    _status = site?.status ?? SiteStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _geofenceRadiusController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final profile = ref.read(currentUserProfileProvider).asData?.value;
    final orgId =
        widget.existingSite?.organizationId ?? profile?.organizationId ?? '';

    if (orgId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organization context missing. Unable to save site.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    final radius = double.tryParse(_geofenceRadiusController.text.trim());

    final isEditMode = widget.existingSite != null;
    final site = Site(
      siteId: isEditMode ? widget.existingSite!.siteId : '',
      organizationId: orgId,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: latitude ?? 0.0,
      longitude: longitude ?? 0.0,
      geofenceRadius: radius ?? 500.0,
      status: _status,
      createdAt: widget.existingSite?.createdAt,
      updatedAt: widget.existingSite?.updatedAt,
    );

    final controller = ref.read(siteControllerProvider.notifier);
    final success = isEditMode
        ? await controller.updateSite(site)
        : await controller.createSite(site);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? 'Site updated successfully!'
                : 'Site created successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final errorState = ref.read(siteControllerProvider);
      final errorMsg = errorState.error?.toString() ??
          'An error occurred while saving the site.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.existingSite != null;
    final controllerState = ref.watch(siteControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Site' : 'Create Site'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Site Name *',
                  hintText: 'e.g. Headquarters Campus',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (val) => SiteValidator.validateName(val ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address *',
                  hintText: 'e.g. 123 Security Way, Tech Park',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.place),
                ),
                maxLines: 2,
                validator: (val) => SiteValidator.validateAddress(val ?? ''),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude *',
                        hintText: '-90.0 to 90.0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.navigation),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter latitude.';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) {
                          return 'Invalid number.';
                        }
                        return SiteValidator.validateLatitude(parsed);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude *',
                        hintText: '-180.0 to 180.0',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.navigation_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Enter longitude.';
                        }
                        final parsed = double.tryParse(val.trim());
                        if (parsed == null) {
                          return 'Invalid number.';
                        }
                        return SiteValidator.validateLongitude(parsed);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _geofenceRadiusController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Geofence Radius *',
                  hintText: 'e.g. 500.0',
                  suffixText: 'meters',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.radar),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Enter radius.';
                  }
                  final parsed = double.tryParse(val.trim());
                  if (parsed == null) {
                    return 'Invalid number.';
                  }
                  return SiteValidator.validateGeofenceRadius(parsed);
                },
              ),
              const SizedBox(height: 16),
              if (isEditMode) ...[
                const Text(
                  'Site Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<SiteStatus>(
                  segments: const [
                    ButtonSegment<SiteStatus>(
                      value: SiteStatus.active,
                      label: Text('Active'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                    ButtonSegment<SiteStatus>(
                      value: SiteStatus.inactive,
                      label: Text('Inactive'),
                      icon: Icon(Icons.block),
                    ),
                  ],
                  selected: {_status},
                  onSelectionChanged: (Set<SiteStatus> newSelection) {
                    setState(() {
                      _status = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        isEditMode ? 'Save Changes' : 'Create Site',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
