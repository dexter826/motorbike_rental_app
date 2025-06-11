class Brand {
  String id;
  String name;
  String? description;
  String? logoUrl;
  String? country;

  Brand({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.country,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'country': country,
    };
  }
}
