class GroupModel {
  final int id;
  final String name;
  final String description;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['group_id'],
      name: json['group_name'],
      description: json['description'] ?? '',
    );
  }
}
