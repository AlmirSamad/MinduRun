/// Lifecycle states of a competition.
enum CompetitionStatus { scheduled, active, finished, cancelled }

/// Platform-neutral kinds of evidence storage.
enum EvidenceKind {
  /// Bundled Flutter asset (e.g. `assets/demo/...`).
  asset,

  /// Bytes held by the in-memory evidence repository for this session.
  memory,

  /// Object path in the Supabase `evidence` storage bucket.
  remote,
}

/// Moderation state of a submitted activity.
enum ActivityModerationStatus { published, underReview, rejected }

/// Reasons a participant may report an activity.
enum ReportReason {
  distanceMismatch,
  durationMismatch,
  paceMismatch,
  invalidEvidence,
  duplicateActivity,
  suspectedOtherPersonActivity,
  other,
}

/// Lifecycle states of a report.
enum ReportStatus { open, upheld, dismissed }

/// Possible vote values on a report.
enum VoteType { valid, invalid }
