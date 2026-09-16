import 'package:flutter/material.dart';
import '../../domain/validators/incident_validator.dart';

/// Modal dialog for collecting and validating incident resolution notes from an administrator.
class AdminResolveIncidentDialog extends StatefulWidget {
  final String incidentId;
  final bool isSubmitting;
  final Future<bool> Function(String resolutionText) onResolve;

  const AdminResolveIncidentDialog({
    super.key,
    required this.incidentId,
    required this.isSubmitting,
    required this.onResolve,
  });

  @override
  State<AdminResolveIncidentDialog> createState() =>
      _AdminResolveIncidentDialogState();
}

class _AdminResolveIncidentDialogState
    extends State<AdminResolveIncidentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  bool _localSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validationError =
        IncidentValidator.validateResolution(_textController.text);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _localSubmitting = true;
      _error = null;
    });

    final success = await widget.onResolve(_textController.text.trim());
    if (mounted) {
      setState(() => _localSubmitting = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.isSubmitting || _localSubmitting;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green),
          SizedBox(width: 8),
          Text('Resolve Incident'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Please enter the resolution details and corrective actions taken for this incident.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('resolution_text_field'),
                controller: _textController,
                maxLines: 4,
                enabled: !busy,
                decoration: InputDecoration(
                  hintText:
                      'e.g., Perimeter breach inspected, wire mended, extra patrol deployed.',
                  labelText: 'Resolution Notes *',
                  errorText: _error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (val) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('submit_resolution_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Confirm Resolution'),
        ),
      ],
    );
  }
}
