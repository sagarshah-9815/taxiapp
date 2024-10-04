class Ride {
  final String id; // Optional during creation but added later
  final String customerId; // References AppUser.id for the customer
  String driverId; // References AppUser.id for the driver (now mutable)
  final String start; // Starting point of the ride
  final String end; // Destination
  String
      status; // Status of the ride (e.g., 'pending', 'completed', etc.) (now mutable)
  final double fare; // Fare for the ride
  final DateTime? createdAt; // When the ride was created

  Ride({
    required this.id,
    required this.customerId,
    required this.driverId,
    required this.start,
    required this.end,
    required this.status,
    required this.fare,
    this.createdAt,
  });

  // Convert Ride object to Map for Firestore or SQLite
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'driverId': driverId,
      'start': start,
      'end': end,
      'status': status,
      'fare': fare,
      'createdAt': createdAt?.toIso8601String(), // Convert DateTime to String
    };
  }

  // Create Ride object from Firestore or SQLite Map
  static Ride fromMap(Map<String, dynamic> map, String id) {
    return Ride(
      id: id,
      customerId: map['customerId'],
      driverId: map['driverId'],
      start: map['start'],
      end: map['end'],
      status: map['status'], // Ensure map['status'] is a String
      fare: map['fare'],
      createdAt:
          map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
    );
  }
}
