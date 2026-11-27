import 'package:flutter/widgets.dart';

class SelectEntity {
  final String name;
  final String? description;
  final dynamic value;
  final IconData? icon;

  SelectEntity({
    required this.name,
    required this.value,
    this.description,
    this.icon,
  });

  factory SelectEntity.same(String value) {
    return SelectEntity(name: value, value: value);
  }

  static List<SelectEntity> fromList(List<String> list) {
    return list.map((e) => SelectEntity.same(e)).toList();
  }

  factory SelectEntity.fromMap(Map<String, dynamic> map) => SelectEntity(
    name: map["name"],
    value: map["value"],
    description: map["description"],
    icon: map["icon"] is IconData ? map["icon"] as IconData : null,
  );

  Map<String, dynamic> toMap() {
    return {"name": name, "value": value, "description": description};
  }

  @override
  String toString() => toMap().toString();
}
