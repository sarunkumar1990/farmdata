class FarmData {
  final String id;
  final String name;
  final String location;
  final String crop;
  final double area;

  FarmData({
    required this.id,
    required this.name,
    required this.location,
    required this.crop,
    required this.area,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'crop': crop,
      'area': area,
    };
  }

  factory FarmData.fromMap(String id, Map<String, dynamic> map) {
    return FarmData(
      id: id,
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      crop: map['crop'] ?? '',
      area: (map['area'] ?? 0).toDouble(),
    );
  }
}
