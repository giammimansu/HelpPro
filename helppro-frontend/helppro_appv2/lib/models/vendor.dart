// lib/models/vendor.dart
class Vendor {
  final int id;
  final String companyName;
  final String address;
  final double latitude;
  final double longitude;

  Vendor({
    required this.id,
    required this.companyName,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as int,
      companyName: json['companyName'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
