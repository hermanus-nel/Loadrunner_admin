/// Predefined reasons for requesting a document re-upload
enum DocumentReuploadReason {
  betterQuality(
    code: 'better_quality',
    displayText: 'Better quality image needed',
    messageFragment: 'We need a clearer, higher-quality image of your document.',
  ),
  newerVersion(
    code: 'newer_version',
    displayText: 'Newer version of document required',
    messageFragment: 'We need a more recent version of your document.',
  ),
  bothSides(
    code: 'both_sides',
    displayText: 'Both sides of document needed',
    messageFragment: 'We need images of both sides of your document.',
  ),
  colourCopy(
    code: 'colour_copy',
    displayText: 'Colour copy required',
    messageFragment: 'We need a colour copy of your document (not black and white).',
  ),
  additionalInfo(
    code: 'additional_info',
    displayText: 'Additional information needed',
    messageFragment: 'We need additional information visible on your document.',
  ),
  other(
    code: 'other',
    displayText: 'Other (specify below)',
    messageFragment: '',
  );

  final String code;
  final String displayText;
  final String messageFragment;

  const DocumentReuploadReason({
    required this.code,
    required this.displayText,
    required this.messageFragment,
  });

  /// Get the message fragment to use in notifications.
  /// For [other], uses the custom reason text provided by the admin.
  String getMessageFragment({String? customReason}) {
    if (this == DocumentReuploadReason.other && customReason != null) {
      return customReason;
    }
    return messageFragment;
  }

  /// Find a reason by its code string
  static DocumentReuploadReason? fromCode(String code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }
}
