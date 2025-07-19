// lib/models/vendor.dart
class Vendor {
  final int id;
  final int accountId;
  final String companyName;
  final String category;
  final String country;
  final String city;
  final String postcode;
  final String address;
  final double latitude;
  final double longitude;

  Vendor({
    required this.id,
    required this.accountId,
    required this.companyName,
    required this.category,
    required this.country,
    required this.city,
    required this.postcode,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as int,
      accountId: json['account_id'] as int,
      companyName: json['company_name'] as String,
      category: json['category'] as String,
      country: json['country'] as String,
      city: json['city'] as String,
      postcode: json['postcode'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
