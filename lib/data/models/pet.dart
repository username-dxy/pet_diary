import 'package:equatable/equatable.dart';

/// 宠物性别
enum PetGender {
  male,     // 男孩
  female,   // 女孩
  unknown,  // 保密
}

/// 宠物性别扩展方法
extension PetGenderExtension on PetGender {
  String get displayName {
    switch (this) {
      case PetGender.male:
        return '男孩';
      case PetGender.female:
        return '女孩';
      case PetGender.unknown:
        return '保密';
    }
  }

  String get icon {
    switch (this) {
      case PetGender.male:
        return '♂️';
      case PetGender.female:
        return '♀️';
      case PetGender.unknown:
        return '⚧️';
    }
  }
}

/// 宠物性格
enum PetPersonality {
  lively,      // 活泼
  quiet,       // 安静
  clingy,      // 粘人
  independent, // 独立
  playful,     // 爱玩
  lazy,        // 慵懒
}

/// 宠物性格扩展方法
extension PetPersonalityExtension on PetPersonality {
  String get displayName {
    switch (this) {
      case PetPersonality.lively:
        return '活泼';
      case PetPersonality.quiet:
        return '安静';
      case PetPersonality.clingy:
        return '粘人';
      case PetPersonality.independent:
        return '独立';
      case PetPersonality.playful:
        return '爱玩';
      case PetPersonality.lazy:
        return '慵懒';
    }
  }

  String get icon {
    switch (this) {
      case PetPersonality.lively:
        return '⚡';
      case PetPersonality.quiet:
        return '😌';
      case PetPersonality.clingy:
        return '🤗';
      case PetPersonality.independent:
        return '😎';
      case PetPersonality.playful:
        return '🎾';
      case PetPersonality.lazy:
        return '😴';
    }
  }
}

/// 宠物信息
class Pet extends Equatable {
  final String id;
  final String name;
  final String species; // "cat" / "dog"
  final String? breed;
  final String? profilePhotoPath;
  final DateTime? birthday;
  final String? ownerNickname;      // 主人称呼
  final PetGender? gender;          // 性别
  final PetPersonality? personality; // 性格
  final DateTime createdAt;

  const Pet({
    required this.id,
    required this.name,
    required this.species,
    this.breed,
    this.profilePhotoPath,
    this.birthday,
    this.ownerNickname,
    this.gender,
    this.personality,
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
      ownerNickname: json['ownerNickname'] as String?,
      gender: json['gender'] != null
          ? PetGender.values.byName(json['gender'] as String)
          : null,
      personality: json['personality'] != null
          ? PetPersonality.values.byName(json['personality'] as String)
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
      'ownerNickname': ownerNickname,
      'gender': gender?.name,
      'personality': personality?.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        profilePhotoPath,
        ownerNickname,
        gender,
        personality,
      ];
}