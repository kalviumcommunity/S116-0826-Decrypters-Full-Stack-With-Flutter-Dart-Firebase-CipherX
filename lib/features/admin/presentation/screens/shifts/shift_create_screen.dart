import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../guards/domain/entities/guard.dart';
import '../../../../guards/presentation/providers/guard_providers.dart';
import '../../../../identity/presentation/providers/identity_providers.dart';
import '../../../../sites/domain/entities/site.dart';
import '../../../../sites/presentation/providers/site_providers.dart';
import '../../../../shifts/domain/entities/shift.dart';
import '../../../../shifts/domain/failures/shift_failure.dart';
import '../../../../shifts/domain/validators/shift_validator.dart';
import '../../../../shifts/presentation/providers/shift_providers.dart';

class ShiftCreateScreen extends ConsumerStatefulWidget {
  const ShiftCreateScreen({super.key});

  @override
  ConsumerState<ShiftCreateScreen> createState() => _ShiftCreateScreenState();
}

class _ShiftCreateScreenState extends ConsumerState<ShiftCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  Guard? _selectedGuard;
  Site? _selectedSite;
  DateTime? _selectedDate;
  TimeOfDay? _startTimeOfDay;
  TimeOfDay? _endTimeOfDay;

  String? _guardError;
  String? _siteError;
  String? _dateError;
  String? _startTimeError;
  String? _endTimeError;
  String? _timeOrderError;

  @override
  Widget build(BuildContext context) {
    final guardsAsync = ref.watch(guardsStreamProvider);
    final sitesAsync = ref.watch(sitesStreamProvider);
    final controllerState = ref.watch(shiftCreationControllerProvider);
    final isSubmitting = controllerState.isLoading;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Shift'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGuardSection(context, guardsAsync, isSubmitting),
                const SizedBox(height: 16),
                _buildSiteSection(context, sitesAsync, isSubmitting),
                const SizedBox(height: 16),
                _buildDateSection(context, isSubmitting),
                const SizedBox(height: 16),
                _buildTimeSection(context, isSubmitting),
                if (_timeOrderError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _timeOrderError!,
                    style: TextStyle(color: colorScheme.error, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
                if (_selectedGuard != null ||
                    _selectedSite != null ||
                    _selectedDate != null)
                  _buildSummaryCard(context),
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const Key('create_shift_button'),
                  onPressed: isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'Create Shift',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildGuardSection(
    BuildContext context,
    AsyncValue<List<Guard>> guardsAsync,
    bool isSubmitting,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return guardsAsync.when(
      data: (guards) {
        final activeGuards =
            guards.where((g) => g.status == GuardStatus.active).toList();

        if (activeGuards.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Guard',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No active guards available.\nCreate or activate a guard before assigning a shift.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.adminGuards),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Manage Guards'),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guard',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Guard>(
              key: const Key('guard_dropdown'),
              initialValue: _selectedGuard,
              decoration: InputDecoration(
                hintText: 'Select Guard',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
                errorText: _guardError,
              ),
              items: activeGuards.map((guard) {
                return DropdownMenuItem<Guard>(
                  value: guard,
                  child: Text(
                    '${guard.name} (${guard.employeeId.isNotEmpty ? guard.employeeId : 'Guard'})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: isSubmitting
                  ? null
                  : (guard) {
                      setState(() {
                        _selectedGuard = guard;
                        _guardError = null;
                      });
                    },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading guards...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Unable to load guards.',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(guardsStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteSection(
    BuildContext context,
    AsyncValue<List<Site>> sitesAsync,
    bool isSubmitting,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return sitesAsync.when(
      data: (sites) {
        final activeSites =
            sites.where((s) => s.status == SiteStatus.active).toList();

        if (activeSites.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Site',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No active sites available.\nCreate or activate a site before scheduling a shift.',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Site',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Site>(
              key: const Key('site_dropdown'),
              initialValue: _selectedSite,
              decoration: InputDecoration(
                hintText: 'Select Site',
                prefixIcon: const Icon(Icons.location_city_outlined),
                border: const OutlineInputBorder(),
                errorText: _siteError,
              ),
              items: activeSites.map((site) {
                return DropdownMenuItem<Site>(
                  value: site,
                  child: Text(
                    site.address.isNotEmpty
                        ? '${site.name} — ${site.address}'
                        : site.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: isSubmitting
                  ? null
                  : (site) {
                      setState(() {
                        _selectedSite = site;
                        _siteError = null;
                      });
                    },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Loading sites...'),
            ],
          ),
        ),
      ),
      error: (error, stack) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Unable to load sites.',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () => ref.refresh(sitesStreamProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, bool isSubmitting) {
    final formattedDate = _selectedDate != null
        ? '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : 'Select date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        InkWell(
          key: const Key('date_picker_button'),
          onTap: isSubmitting ? null : () => _pickDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.calendar_today_outlined),
              border: const OutlineInputBorder(),
              errorText: _dateError,
            ),
            child: Text(formattedDate),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(BuildContext context, bool isSubmitting) {
    final startDisplay = _startTimeOfDay != null
        ? _startTimeOfDay!.format(context)
        : 'Select start time';
    final endDisplay = _endTimeOfDay != null
        ? _endTimeOfDay!.format(context)
        : 'Select end time';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start Time',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                key: const Key('start_time_picker_button'),
                onTap: isSubmitting ? null : () => _pickStartTime(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time),
                    border: const OutlineInputBorder(),
                    errorText: _startTimeError,
                  ),
                  child: Text(
                    startDisplay,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'End Time',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                key: const Key('end_time_picker_button'),
                onTap: isSubmitting ? null : () => _pickEndTime(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.access_time_filled),
                    border: const OutlineInputBorder(),
                    errorText: _endTimeError,
                  ),
                  child: Text(
                    endDisplay,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final guardText = _selectedGuard?.name ?? 'Not selected';
    final siteText = _selectedSite?.name ?? 'Not selected';
    final dateText = _selectedDate != null
        ? '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
        : 'Not selected';

    final startText =
        _startTimeOfDay != null ? _startTimeOfDay!.format(context) : 'Not set';
    final endText =
        _endTimeOfDay != null ? _endTimeOfDay!.format(context) : 'Not set';

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shift Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const Divider(height: 16),
            _summaryRow(Icons.person, 'Guard', guardText),
            const SizedBox(height: 8),
            _summaryRow(Icons.location_city, 'Site', siteText),
            const SizedBox(height: 8),
            _summaryRow(Icons.calendar_month, 'Date', dateText),
            const SizedBox(height: 8),
            _summaryRow(Icons.schedule, 'Time', '$startText - $endText'),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final lastDate = DateTime(now.year + 2, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
      _validateTimeRange();
    }
  }

  Future<void> _pickStartTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTimeOfDay ?? const TimeOfDay(hour: 9, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _startTimeOfDay = picked;
        _startTimeError = null;
      });
      _validateTimeRange();
    }
  }

  Future<void> _pickEndTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTimeOfDay ?? const TimeOfDay(hour: 17, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _endTimeOfDay = picked;
        _endTimeError = null;
      });
      _validateTimeRange();
    }
  }

  DateTime? _buildDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  bool _validateTimeRange() {
    final startDateTime = _buildDateTime(_selectedDate, _startTimeOfDay);
    final endDateTime = _buildDateTime(_selectedDate, _endTimeOfDay);

    if (startDateTime != null && endDateTime != null) {
      final orderErr =
          ShiftValidator.validateTimeOrdering(startDateTime, endDateTime);
      setState(() {
        _timeOrderError = orderErr;
      });
      return orderErr == null;
    } else {
      setState(() {
        _timeOrderError = null;
      });
      return true;
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _guardError = ShiftValidator.validateGuard(_selectedGuard?.guardId);
      _siteError = ShiftValidator.validateSite(_selectedSite?.siteId);
      _dateError = ShiftValidator.validateDate(_selectedDate);
      _startTimeError = ShiftValidator.validateStartTime(
        _buildDateTime(_selectedDate, _startTimeOfDay),
      );
      _endTimeError = ShiftValidator.validateEndTime(
        _buildDateTime(_selectedDate, _endTimeOfDay),
      );
    });

    final isTimeValid = _validateTimeRange();

    final hasErrors = _guardError != null ||
        _siteError != null ||
        _dateError != null ||
        _startTimeError != null ||
        _endTimeError != null ||
        !isTimeValid;

    if (hasErrors) {
      return;
    }

    final startDateTime = _buildDateTime(_selectedDate!, _startTimeOfDay!)!;
    final endDateTime = _buildDateTime(_selectedDate!, _endTimeOfDay!)!;

    final dateStr =
        '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    final profile = ref.read(currentUserProfileProvider).asData?.value;
    final orgId = profile?.organizationId ?? _selectedGuard!.organizationId;

    final shiftInput = Shift(
      id: '',
      organizationId: orgId,
      siteId: _selectedSite!.siteId,
      siteName: _selectedSite!.name,
      guardId: _selectedGuard!.guardId,
      guardName: _selectedGuard!.name,
      supervisorId: profile?.uid ?? '',
      shiftDate: dateStr,
      startTime: startDateTime,
      endTime: endDateTime,
      status: ShiftStatus.scheduled,
    );

    final success = await ref
        .read(shiftCreationControllerProvider.notifier)
        .createShift(shiftInput);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Shift created successfully for ${_selectedGuard!.name}.',
          ),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final controllerState = ref.read(shiftCreationControllerProvider);
      final error = controllerState.error;
      String errorMsg = 'Failed to create shift. Please try again.';

      if (error is ShiftFailure) {
        errorMsg = error.message;
      } else if (error != null) {
        errorMsg = error.toString();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
