import 'package:equatable/equatable.dart';

/// 宠物特征（模型B输出）
class PetFeatures extends Equatable {
  final String species; // "cat" / "dog"
  final String breed;   // "橘猫" / "柴犬"
  final String color;   // "橙色" / "棕色"
  final String pose;    // "sitting" / "lying"

  const PetFeatures({
    required this.species,
    required this.breed,
    required this.color,
    required this.pose,
  });

  factory PetFeatures.fromJson(Map<String, dynamic> json) {
    return PetFeatures(
      species: json['species'] as String,
      breed: json['breed'] as String,
      color: json['color'] as String,
      pose: json['pose'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'species': species,
      'breed': breed,
      'color': color,
      'pose': pose,
    };
  }

  @override
  List<Object?> get props => [species, breed, color, pose];
}