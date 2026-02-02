class SessionModel {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String pricingMode;
  final int players;
  final int timeLimitInMinutes;
  final List<Segment> segments;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final double totalBilled;
  final String? paymentMethod;
  final String? tableName;
  final String? tableType;
  final String status;
  final double hourlyRateAtStart;
  final String? handledByName;

  SessionModel({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.pricingMode,
    required this.players,
    required this.timeLimitInMinutes,
    required this.segments,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.totalAmount = 0,
    required this.totalBilled,
    this.paymentMethod,
    this.tableName,
    this.tableType,
    required this.status,
    this.hourlyRateAtStart = 0,
    this.handledByName,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) {
    String? tName;
    String? tType;
    if (json['table'] is Map) {
      tName = json['table']['name'];
      tType = json['table']['type'];
    }

    String? staff;
    if (json['handledBy'] is Map) {
      staff = json['handledBy']['username'];
    }

    return SessionModel(
      id: json['_id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      pricingMode: json['pricingMode'] ?? 'per_hour',
      players: json['players'] ?? 1,
      timeLimitInMinutes: json['timeLimitInMinutes'] ?? 0,
      segments: (json['segments'] as List)
          .map((s) => Segment.fromJson(s))
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      totalBilled: (json['totalBilled'] as num).toDouble(),
      paymentMethod: json['paymentMethod'],
      tableName: tName,
      tableType: tType,
      status: json['status'],
      hourlyRateAtStart: (json['hourlyRateAtStart'] as num?)?.toDouble() ?? 0.0,
      handledByName: staff,
    );
  }

  int get elapsedMinutes {
    int minutes = 0;
    for (var seg in segments) {
      final end = seg.end ?? DateTime.now();
      minutes += end.difference(seg.start).inMinutes;
    }
    return minutes;
  }
}

class Segment {
  final DateTime start;
  final DateTime? end;

  Segment({required this.start, this.end});

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      start: DateTime.parse(json['start']),
      end: json['end'] != null ? DateTime.parse(json['end']) : null,
    );
  }
}

class TableModel {
  final String id;
  final String name;
  final String type;
  final String status;
  final double hourlyRate;
  final bool isActive;
  final List<String> supportedTypes;
  final SessionModel? currentSession;

  TableModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.hourlyRate,
    this.isActive = true,
    this.supportedTypes = const ['Pool'],
    this.currentSession,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['_id'],
      name: json['name'],
      type: json['type'],
      status: json['status'],
      hourlyRate: (json['hourlyRate'] as num).toDouble(),
      isActive: json['isActive'] ?? true,
      supportedTypes: List<String>.from(json['supportedTypes'] ?? ['Pool']),
      currentSession: json['currentSession'] != null && json['currentSession'] is Map
          ? SessionModel.fromJson(json['currentSession'])
          : null,
    );
  }
}
