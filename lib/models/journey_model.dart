/// Represents the status of a journey.
enum JourneyStatus { completed, cancelled, sosTriggered }

/// Represents a past or active journey in the SafeCircle app.
class JourneyModel {
  final String id;
  final String destination;
  final DateTime dateTime;
  final String duration;
  final double distanceKm;
  final JourneyStatus status;
  final String eta;
  final String? notes;
  final List<String> sharedContactIds;
  final int startBattery;
  final int? endBattery;

  const JourneyModel({
    required this.id,
    required this.destination,
    required this.dateTime,
    required this.duration,
    required this.distanceKm,
    required this.status,
    required this.eta,
    this.notes,
    required this.sharedContactIds,
    required this.startBattery,
    this.endBattery,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'destination': destination,
      'dateTime': dateTime.toIso8601String(),
      'duration': duration,
      'distanceKm': distanceKm,
      'status': status.index,
      'eta': eta,
      'notes': notes,
      'sharedContactIds': sharedContactIds,
      'startBattery': startBattery,
      'endBattery': endBattery,
    };
  }

  factory JourneyModel.fromJson(Map<String, dynamic> json) {
    return JourneyModel(
      id: json['id'] as String,
      destination: json['destination'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      duration: json['duration'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      status: JourneyStatus.values[json['status'] as int],
      eta: json['eta'] as String,
      notes: json['notes'] as String?,
      sharedContactIds: List<String>.from(json['sharedContactIds'] as List),
      startBattery: json['startBattery'] as int,
      endBattery: json['endBattery'] as int?,
    );
  }

  JourneyModel copyWith({
    String? id,
    String? destination,
    DateTime? dateTime,
    String? duration,
    double? distanceKm,
    JourneyStatus? status,
    String? eta,
    String? notes,
    List<String>? sharedContactIds,
    int? startBattery,
    int? endBattery,
  }) {
    return JourneyModel(
      id: id ?? this.id,
      destination: destination ?? this.destination,
      dateTime: dateTime ?? this.dateTime,
      duration: duration ?? this.duration,
      distanceKm: distanceKm ?? this.distanceKm,
      status: status ?? this.status,
      eta: eta ?? this.eta,
      notes: notes ?? this.notes,
      sharedContactIds: sharedContactIds ?? this.sharedContactIds,
      startBattery: startBattery ?? this.startBattery,
      endBattery: endBattery ?? this.endBattery,
    );
  }
}