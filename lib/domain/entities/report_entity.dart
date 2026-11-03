enum ReportCategory {
  spam,
  harassment,
  fakeAccount,
  inappropriateContent,
  abuse,
  other,
}

enum ReportStatus {
  pending,
  reviewed,
  actioned,
  dismissed,
}

/// Domain representation of a safety and abuse report.
class ReportEntity {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportCategory category;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  const ReportEntity({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.category,
    this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });
}
