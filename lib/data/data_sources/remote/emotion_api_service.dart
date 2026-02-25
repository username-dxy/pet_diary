import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/emotion_record.dart';

/// 情绪记录保存响应
class EmotionSaveResponse {
  final String recordId;
  final String syncedAt;

  const EmotionSaveResponse({
    required this.recordId,
    required this.syncedAt,
  });

  factory EmotionSaveResponse.fromJson(Map<String, dynamic> json) {
    return EmotionSaveResponse(
      recordId: json['recordId'] as String? ?? '',
      syncedAt: json['syncedAt'] as String? ?? '',
    );
  }
}

/// 情绪记录相关 API 调用
class EmotionApiService {
  final ApiClient _client;

  EmotionApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// 保存情绪记录到服务器
  Future<ApiResponse<EmotionSaveResponse>> saveEmotionRecord(
    Map<String, dynamic> recordJson,
  ) {
    return _client.post<EmotionSaveResponse>(
      '/api/mengyu/emotions/save',
      body: recordJson,
      fromJson: (json) =>
          EmotionSaveResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 按月查询情绪记录
  Future<ApiResponse<List<EmotionRecord>>> getMonthRecords({
    required int year,
    required int month,
    String? petId,
  }) {
    final query = <String, String>{
      'year': year.toString(),
      'month': month.toString(),
    };
    if (petId != null && petId.isNotEmpty) {
      query['petId'] = petId;
    }

    return _client.get<List<EmotionRecord>>(
      '/api/mengyu/emotions/month',
      queryParams: query,
      fromJson: (json) {
        final map = json as Map<String, dynamic>;
        final rawList = map['records'] as List<dynamic>? ?? const [];
        return rawList
            .map((e) => EmotionRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
