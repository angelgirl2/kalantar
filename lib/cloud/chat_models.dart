class ChatMessage {
  ChatMessage({required this.id, required this.senderId, required this.type, required this.body, required this.createdAt, this.attachmentId, this.attachmentName, this.replyTo, this.reaction, this.deliveredAt, this.readAt});
  final String id; final String senderId; final String type; final String body; final DateTime createdAt; final String? attachmentId; final String? attachmentName; final String? replyTo; final String? reaction; final DateTime? deliveredAt; final DateTime? readAt;
  bool get hasAttachment => attachmentId != null && attachmentId!.isNotEmpty;
  bool get isRead => readAt != null;
  bool get isDelivered => deliveredAt != null;
  factory ChatMessage.fromJson(Map<String,dynamic> json) => ChatMessage(id: json['id']?.toString() ?? '', senderId: json['sender_id']?.toString() ?? '', type: json['type']?.toString() ?? 'text', body: json['body']?.toString() ?? '', createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt']).toString()) ?? DateTime.now(), attachmentId: json['attachment_id']?.toString(), attachmentName: json['attachment_name']?.toString(), replyTo: json['reply_to']?.toString(), reaction: json['reaction']?.toString(), deliveredAt: json['delivered_at'] == null ? null : DateTime.tryParse(json['delivered_at'].toString()), readAt: json['read_at'] == null ? null : DateTime.tryParse(json['read_at'].toString()));
}
