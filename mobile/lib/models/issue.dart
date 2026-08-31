class IssueItem {
  final int id;
  final String issueType;
  final String issueTypeLabel;
  final String description;
  final String status;
  final String? adminResponse;
  final String? orderRef;
  final String createdAt;

  const IssueItem({
    required this.id,
    required this.issueType,
    required this.issueTypeLabel,
    required this.description,
    required this.status,
    this.adminResponse,
    this.orderRef,
    required this.createdAt,
  });

  factory IssueItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['issue_type'];
    final value = rawType?.toString() ?? '';
    final label = value
        .split('_')
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');

    return IssueItem(
      id: json['id'] as int,
      issueType: value,
      issueTypeLabel: label,
      description: json['description'] as String,
      status: json['status'] as String,
      adminResponse: json['admin_response'] as String?,
      orderRef: json['order_ref'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
