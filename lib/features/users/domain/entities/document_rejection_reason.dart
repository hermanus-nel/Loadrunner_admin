/// Predefined rejection reasons for individual document review
enum DocumentRejectionReason {
  expired(
    code: 'expired',
    displayText: 'Document has expired',
    messageFragment: 'The document you submitted has expired',
  ),
  blurry(
    code: 'blurry',
    displayText: 'Image is blurry or unreadable',
    messageFragment: 'The image you submitted is blurry or unreadable',
  ),
  wrongDoc(
    code: 'wrong_doc',
    displayText: 'Wrong document type uploaded',
    messageFragment: 'The document you uploaded does not match the required type',
  ),
  incomplete(
    code: 'incomplete',
    displayText: 'Document is incomplete or partially visible',
    messageFragment: 'The document you submitted is incomplete or only partially visible',
  ),
  mismatch(
    code: 'mismatch',
    displayText: 'Information does not match other documents',
    messageFragment: 'The information on your document does not match your other submitted documents',
  ),
  damaged(
    code: 'damaged',
    displayText: 'Document appears damaged or altered',
    messageFragment: 'The document you submitted appears to be damaged or altered',
  ),
  notCertified(
    code: 'not_certified',
    displayText: 'Document is not certified or notarized',
    messageFragment: 'The document you submitted is not properly certified or notarized',
  ),
  other(
    code: 'other',
    displayText: 'Other (specify below)',
    messageFragment: '',
  );

  final String code;
  final String displayText;
  final String messageFragment;

  const DocumentRejectionReason({
    required this.code,
    required this.displayText,
    required this.messageFragment,
  });

  /// Get the message fragment to use in notifications.
  /// For [other], uses the custom reason text provided by the admin.
  String getMessageFragment({String? customReason}) {
    if (this == DocumentRejectionReason.other && customReason != null) {
      return customReason;
    }
    return messageFragment;
  }

  /// Find a reason by its code string
  static DocumentRejectionReason? fromCode(String code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    return null;
  }
}
