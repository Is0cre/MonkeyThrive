enum BaselineUserResponse {
  okay,
  notReally,
}

class NotificationDecision {
  final String sensorSnapshotId;
  final double modelConfidence;
  final int baselineVersion;
  final bool shouldNotify;
  final DateTime decidedAt;

  const NotificationDecision({
    required this.sensorSnapshotId,
    required this.modelConfidence,
    required this.baselineVersion,
    required this.shouldNotify,
    required this.decidedAt,
  });
}

class UserFeedback {
  final DateTime timestamp;
  final String sensorSnapshotId;
  final double modelConfidence;
  final int baselineVersion;
  final BaselineUserResponse userResponse;
  final bool toolRecommended;
  final bool toolStarted;
  final bool toolCompleted;

  const UserFeedback({
    required this.timestamp,
    required this.sensorSnapshotId,
    required this.modelConfidence,
    required this.baselineVersion,
    required this.userResponse,
    required this.toolRecommended,
    required this.toolStarted,
    required this.toolCompleted,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'sensor_snapshot_id': sensorSnapshotId,
        'model_confidence': modelConfidence,
        'baseline_version': baselineVersion,
        'user_response': userResponse.name,
        'tool_recommended': toolRecommended,
        'tool_started': toolStarted,
        'tool_completed': toolCompleted,
      };

  static UserFeedback fromJson(Map<String, dynamic> json) => UserFeedback(
        timestamp: DateTime.parse(json['timestamp'] as String),
        sensorSnapshotId: json['sensor_snapshot_id'] as String,
        modelConfidence: (json['model_confidence'] as num).toDouble(),
        baselineVersion: json['baseline_version'] as int,
        userResponse: BaselineUserResponse.values.byName(
          json['user_response'] as String,
        ),
        toolRecommended: json['tool_recommended'] as bool,
        toolStarted: json['tool_started'] as bool,
        toolCompleted: json['tool_completed'] as bool,
      );

  UserFeedback copyWith({
    bool? toolStarted,
    bool? toolCompleted,
  }) {
    return UserFeedback(
      timestamp: timestamp,
      sensorSnapshotId: sensorSnapshotId,
      modelConfidence: modelConfidence,
      baselineVersion: baselineVersion,
      userResponse: userResponse,
      toolRecommended: toolRecommended,
      toolStarted: toolStarted ?? this.toolStarted,
      toolCompleted: toolCompleted ?? this.toolCompleted,
    );
  }
}
