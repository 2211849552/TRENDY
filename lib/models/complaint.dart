class ComplaintReply {
  final String message;
  final DateTime date;
  final bool isFromUser;

  ComplaintReply({
    required this.message,
    required this.date,
    required this.isFromUser,
  });
}

class Complaint {
  final String id;
  final String typeKey;
  final String subject;
  final String details;
  final String? relatedOrderId;
  final DateTime createdAt;
  String statusKey;
  final List<String> evidenceImages;
  final List<ComplaintReply> replies;

  Complaint({
    required this.id,
    required this.typeKey,
    required this.subject,
    required this.details,
    required this.createdAt,
    required this.statusKey,
    this.relatedOrderId,
    List<String>? evidenceImages,
    List<ComplaintReply>? replies,
  })  : evidenceImages = evidenceImages ?? [],
        replies = replies ?? [];
}
