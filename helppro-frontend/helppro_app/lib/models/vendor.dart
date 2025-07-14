// lib/models/vendor.dart
class Vendor {
  final int id;
  final String companyName, category, country, city, postcode, address;

  Vendor({
    required this.id,
    required this.companyName,
    required this.category,
    required this.country,
    required this.city,
    required this.postcode,
    required this.address,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
    id: json['id'],
    companyName: json['company_name'],
    category: json['category'],
    country: json['country'],
    city: json['city'],
    postcode: json['postcode'],
    address: json['address'],
  );
}
