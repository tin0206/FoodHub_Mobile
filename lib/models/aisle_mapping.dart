class AisleMappingJob {
  const AisleMappingJob({
    required this.taskId,
    required this.status,
    this.force = false,
    this.recipeId,
    this.total = 0,
    this.processed = 0,
    this.mapped = 0,
    this.skipped = 0,
    this.failed = 0,
    this.errorMessage,
  });

  final String taskId;
  final String status;
  final bool force;
  final int? recipeId;
  final int total;
  final int processed;
  final int mapped;
  final int skipped;
  final int failed;
  final String? errorMessage;

  bool get isActive => status == 'pending' || status == 'processing';

  factory AisleMappingJob.fromJson(Map<String, dynamic> json) {
    return AisleMappingJob(
      taskId: json['task_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      force: json['force'] as bool? ?? false,
      recipeId: json['recipe_id'] as int?,
      total: json['total'] as int? ?? 0,
      processed: json['processed'] as int? ?? 0,
      mapped: json['mapped'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      failed: json['failed'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
    );
  }
}

class AisleMappingStatus {
  const AisleMappingStatus({
    required this.total,
    required this.mapped,
    required this.missing,
    this.aisles = const [],
    this.job,
    this.alreadyRunning = false,
  });

  final int total;
  final int mapped;
  final int missing;
  final List<String> aisles;
  final AisleMappingJob? job;
  final bool alreadyRunning;

  bool get isRunning => job?.isActive ?? false;

  factory AisleMappingStatus.fromJson(Map<String, dynamic> json) {
    final rawJob = json['job'];
    return AisleMappingStatus(
      total: json['total'] as int? ?? 0,
      mapped: json['mapped'] as int? ?? 0,
      missing: json['missing'] as int? ?? 0,
      aisles: (json['aisles'] as List?)?.map((e) => '$e').toList() ?? const [],
      job: rawJob is Map
          ? AisleMappingJob.fromJson(Map<String, dynamic>.from(rawJob))
          : null,
      alreadyRunning: json['already_running'] as bool? ?? false,
    );
  }
}
