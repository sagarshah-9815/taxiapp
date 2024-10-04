class Driver {
  final String id;
  final String name;
  final double earnings;
  final String license; // Added field for driver's license
  final String vehicleNumber; // Added field for vehicle number

  Driver({
    required this.id,
    required this.name,
    required this.earnings,
    required this.license, // Include license in constructor
    required this.vehicleNumber, // Include vehicle number in constructor
  });

  factory Driver.fromMap(Map<String, dynamic> data, String id) {
    return Driver(
      id: id,
      name: data['name'] ?? '',
      earnings: data['earnings']?.toDouble() ?? 0.0,
      license: data['license'] ?? '', // Map for driver's license
      vehicleNumber: data['vehicle_number'] ?? '', // Map for vehicle number
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'earnings': earnings,
      'license': license, // Include license in the map
      'vehicle_number': vehicleNumber, // Include vehicle number in the map
    };
  }
}
