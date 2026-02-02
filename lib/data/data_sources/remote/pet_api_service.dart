import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

/// 宠物 API 数据模型（对应 api.md 字段）
class PetApiModel {
  final String petId;
  final int type;
  final int gender;
  final String birthday;
  final String ownerTitle;
  final String avatar;
  final String nickName;
  final String character;
  final String description;

  const PetApiModel({
    required this.petId,
    required this.type,
    required this.gender,
    required this.birthday,
    required this.ownerTitle,
    required this.avatar,
    required this.nickName,
    required this.character,
    required this.description,
  });

  factory PetApiModel.fromJson(Map<String, dynamic> json) {
    return PetApiModel(
      petId: (json['petId'] ?? '').toString(),
      type: json['type'] as int? ?? 0,
      gender: json['gender'] as int? ?? 0,
      birthday: json['birthday'] as String? ?? '',
      ownerTitle: json['ownerTitle'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      nickName: json['nickName'] as String? ?? '',
      character: json['character'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'petId': petId,
        'type': type,
        'gender': gender,
        'birthday': birthday,
        'ownerTitle': ownerTitle,
        'avatar': avatar,
        'nickName': nickName,
        'character': character,
        'description': description,
      };

  /// type: 1=dog, 2=cat → species string
  String get species {
    switch (type) {
      case 1:
        return 'dog';
      case 2:
        return 'cat';
      default:
        return 'unknown';
    }
  }

  /// gender: 1=male, 2=female → gender string
  String get genderString {
    switch (gender) {
      case 1:
        return 'male';
      case 2:
        return 'female';
      default:
        return 'unknown';
    }
  }
}

/// 宠物列表响应
class PetListResponse {
  final List<PetApiModel> petList;

  const PetListResponse({required this.petList});

  factory PetListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['petList'] as List<dynamic>? ?? [];
    return PetListResponse(
      petList: list
          .map((e) => PetApiModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 宠物相关 API 调用
class PetApiService {
  final ApiClient _client;

  PetApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// 获取宠物列表
  Future<ApiResponse<PetListResponse>> getPetList() {
    return _client.get<PetListResponse>(
      '/api/chongyu/pet/list',
      fromJson: (json) =>
          PetListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取宠物详情
  Future<ApiResponse<PetApiModel>> getPetDetail(String petId) {
    return _client.get<PetApiModel>(
      '/api/chongyu/pet/detail',
      queryParams: {'petId': petId},
      fromJson: (json) => PetApiModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
