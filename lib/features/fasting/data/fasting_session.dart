enum FastingStatus { idle, active, paused, completed, cancelled }

class FastingSession {
  final String id;
  final String protocolId;
  final String protocolName;
  final int durationMinutes;
  final int startTimeMs; // epoch
  final int? endTimeMs;
  final FastingStatus status;
  final int elapsedSecondsOnPause; // when paused
  final int createdAtMs;

  const FastingSession({
    required this.id,
    required this.protocolId,
    required this.protocolName,
    required this.durationMinutes,
    required this.startTimeMs,
    this.endTimeMs,
    required this.status,
    this.elapsedSecondsOnPause = 0,
    required this.createdAtMs,
  });

  int get durationSeconds => durationMinutes * 60;

  // elapsed based on now, handles active/paused/completed
  int elapsedSeconds(DateTime now) {
    if (status == FastingStatus.paused) return elapsedSecondsOnPause;
    if (status == FastingStatus.completed || status == FastingStatus.cancelled) {
      if (endTimeMs != null) {
        return ((endTimeMs! - startTimeMs) / 1000).round().clamp(0, durationSeconds);
      }
      return durationSeconds;
    }
    if (status == FastingStatus.active) {
      final e = now.millisecondsSinceEpoch - startTimeMs;
      return (e / 1000).round().clamp(0, durationSeconds);
    }
    return 0;
  }

  int remainingSeconds(DateTime now) {
    return (durationSeconds - elapsedSeconds(now)).clamp(0, durationSeconds);
  }

  double progress(DateTime now) {
    if (durationSeconds == 0) return 0;
    return (elapsedSeconds(now) / durationSeconds).clamp(0.0, 1.0);
  }

  bool get isFinished => status == FastingStatus.active && elapsedSeconds(DateTime.now()) >= durationSeconds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'protocolId': protocolId,
        'protocolName': protocolName,
        'durationMinutes': durationMinutes,
        'startTimeMs': startTimeMs,
        'endTimeMs': endTimeMs,
        'status': status.index,
        'elapsedSecondsOnPause': elapsedSecondsOnPause,
        'createdAtMs': createdAtMs,
      };

  factory FastingSession.fromJson(Map j) => FastingSession(
        id: j['id'],
        protocolId: j['protocolId'],
        protocolName: j['protocolName'],
        durationMinutes: j['durationMinutes'],
        startTimeMs: j['startTimeMs'],
        endTimeMs: j['endTimeMs'],
        status: FastingStatus.values[j['status'] ?? 0],
        elapsedSecondsOnPause: j['elapsedSecondsOnPause'] ?? 0,
        createdAtMs: j['createdAtMs'],
      );

  FastingSession copyWith({
    String? id,
    String? protocolId,
    String? protocolName,
    int? durationMinutes,
    int? startTimeMs,
    int? endTimeMs,
    FastingStatus? status,
    int? elapsedSecondsOnPause,
    int? createdAtMs,
  }) =>
      FastingSession(
        id: id ?? this.id,
        protocolId: protocolId ?? this.protocolId,
        protocolName: protocolName ?? this.protocolName,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        startTimeMs: startTimeMs ?? this.startTimeMs,
        endTimeMs: endTimeMs ?? this.endTimeMs,
        status: status ?? this.status,
        elapsedSecondsOnPause: elapsedSecondsOnPause ?? this.elapsedSecondsOnPause,
        createdAtMs: createdAtMs ?? this.createdAtMs,
      );
}
