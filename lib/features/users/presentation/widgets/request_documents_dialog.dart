// lib/features/users/presentation/widgets/request_documents_dialog.dart
import 'package:flutter/material.dart';

/// Result from the request documents dialog
class RequestDocumentsResult {
  final List<DocumentType> requestedDocuments;
  final String message;

  const RequestDocumentsResult({
    required this.requestedDocuments,
    required this.message,
  });
}

/// Types of documents that can be requested
enum DocumentType {
  driverLicenseFront('Driver\'s License (Front)', 'license_front'),
  driverLicenseBack('Driver\'s License (Back)', 'license_back'),
  idDocument('National ID / Passport', 'id_document'),
  proofOfAddress('Proof of Address', 'proof_of_address'),
  vehicleRegistration('Vehicle Registration', 'vehicle_registration'),
  vehicleInsurance('Vehicle Insurance', 'vehicle_insurance'),
  vehiclePhotoFront('Vehicle Photo (Front)', 'vehicle_photo_front'),
  vehiclePhotoBack('Vehicle Photo (Back)', 'vehicle_photo_back'),
  vehiclePhotoSide('Vehicle Photo (Side)', 'vehicle_photo_side'),
  vehiclePhotoCargo('Vehicle Photo (Cargo Area)', 'vehicle_photo_cargo'),
  profilePhoto('Profile Photo', 'profile_photo'),
  other('Other Document', 'other');

  final String displayName;
  final String code;
  const DocumentType(this.displayName, this.code);
}

/// Dialog for requesting additional documents from a driver
class RequestDocumentsDialog extends StatefulWidget {
  final String driverName;

  const RequestDocumentsDialog({
    super.key,
    required this.driverName,
  });

  /// Shows the dialog and returns the result if confirmed, null if cancelled
  static Future<RequestDocumentsResult?> show({
    required BuildContext context,
    required String driverName,
  }) async {
    return showDialog<RequestDocumentsResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RequestDocumentsDialog(driverName: driverName),
    );
  }

  @override
  State<RequestDocumentsDialog> createState() => _RequestDocumentsDialogState();
}

class _RequestDocumentsDialogState extends State<RequestDocumentsDialog> {
  final Set<DocumentType> _selectedDocuments = {};
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Group documents by category
  static const Map<String, List<DocumentType>> _documentGroups = {
    'Personal Documents': [
      DocumentType.driverLicenseFront,
      DocumentType.driverLicenseBack,
      DocumentType.idDocument,
      DocumentType.proofOfAddress,
      DocumentType.profilePhoto,
    ],
    'Vehicle Documents': [
      DocumentType.vehicleRegistration,
      DocumentType.vehicleInsurance,
    ],
    'Vehicle Photos': [
      DocumentType.vehiclePhotoFront,
      DocumentType.vehiclePhotoBack,
      DocumentType.vehiclePhotoSide,
      DocumentType.vehiclePhotoCargo,
    ],
    'Other': [
      DocumentType.other,
    ],
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _toggleDocument(DocumentType doc) {
    setState(() {
      if (_selectedDocuments.contains(doc)) {
        _selectedDocuments.remove(doc);
      } else {
        _selectedDocuments.add(doc);
      }
    });
  }

  void _selectAllInGroup(List<DocumentType> docs) {
    setState(() {
      final allSelected = docs.every((d) => _selectedDocuments.contains(d));
      if (allSelected) {
        _selectedDocuments.removeAll(docs);
      } else {
        _selectedDocuments.addAll(docs);
      }
    });
  }

  void _onConfirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(RequestDocumentsResult(
        requestedDocuments: _selectedDocuments.toList(),
        message: _messageController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.file_upload_outlined,
          size: 48,
          color: Colors.orange,
        ),
      ),
      title: const Text(
        'Request Documents',
        textAlign: TextAlign.center,
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request additional documents from',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    widget.driverName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Document selection
                Text(
                  'Select Documents to Request *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),

                // Document groups
                ..._documentGroups.entries.map((entry) {
                  final groupName = entry.key;
                  final docs = entry.value;
                  final allSelected = docs.every(
                    (d) => _selectedDocuments.contains(d),
                  );
                  final someSelected = docs.any(
                    (d) => _selectedDocuments.contains(d),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group header with select all
                        InkWell(
                          onTap: () => _selectAllInGroup(docs),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  allSelected
                                      ? Icons.check_box
                                      : someSelected
                                          ? Icons.indeterminate_check_box
                                          : Icons.check_box_outline_blank,
                                  size: 20,
                                  color: allSelected || someSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  groupName,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Document checkboxes
                        ...docs.map((doc) {
                          final isSelected = _selectedDocuments.contains(doc);
                          return InkWell(
                            onTap: () => _toggleDocument(doc),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleDocument(doc),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  Expanded(
                                    child: Text(
                                      doc.displayName,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                }),

                // Validation message
                if (_selectedDocuments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Please select at least one document',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),

                // Message to driver
                const SizedBox(height: 8),
                Text(
                  'Message to Driver *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Explain why these documents are needed...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a message to the driver';
                    }
                    if (value.trim().length < 20) {
                      return 'Message must be at least 20 characters';
                    }
                    return null;
                  },
                ),

                // Info notice
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'The driver will receive a notification to upload the requested documents. Their status will change to "Documents Requested".',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ),
        FilledButton.icon(
          onPressed: _selectedDocuments.isEmpty ? null : _onConfirm,
          icon: const Icon(Icons.send, size: 18),
          label: Text('Request (${_selectedDocuments.length})'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
}
