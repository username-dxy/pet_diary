import 'package:equatable/equatable.dart';

/// 宠物信息
class Pet extends Equatable {
  final String id;
  final String name;
  final String species; // "cat" / "dog"
  final String? breed;
  final String? profilePhotoPath;
  final DateTime? birthday;
  final DateTime createdAt;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.profilePhotoPath,
    this.birthday,
    required this.createdAt,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      profilePhotoPath: json['profilePhotoPath'] as String?,
      birthday: json['birthday'] != null 
          ? DateTime.parse(json['birthday'] as String) 
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'breed': breed,
      'profilePhotoPath': profilePhotoPath,
      'birthday': birthday?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, name, profilePhotoPath];
}