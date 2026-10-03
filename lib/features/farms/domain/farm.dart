class Farm {
  const Farm({required this.id, required this.name});

  final String id;
  final String name;

  factory Farm.fromJson(Map<String, dynamic> json) =>
      Farm(id: json['id'] as String, name: json['nombre'] as String);
}
