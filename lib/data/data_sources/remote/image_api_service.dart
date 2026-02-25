import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

/// 图片上传项
class ImageUploadItem {
  /// 图片文件路径
  final String filePath;

  /// 相册 asset ID（用于去重）
  final String? assetId;

  /// 宠物 ID
  final String? petId;

  /// 日期 (yyyy-MM-dd)
  final String? date;

  /// 拍摄时间戳（毫秒）
  final int? time;

  /// 拍摄地点
  final String? location;

  const ImageUploadItem({
    required this.filePath,
    this.assetId,
    this.petId,
    this.date,
    this.time,
    this.location,
  });
}

/// 图片上传响应
class ImageUploadResponse {
  final int uploaded;
  final int duplicates;

  const ImageUploadResponse({required this.uploaded, required this.duplicates});

  factory ImageUploadResponse.fromJson(Map<String, dynamic> json) {
    return ImageUploadResponse(
      uploaded: json['uploaded'] as int? ?? 0,
      duplicates: json['duplicates'] as int? ?? 0,
    );
  }
}

/// 图片相关 API 调用
class ImageApiService {
  final ApiClient _client;

  ImageApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// 批量上传相册图片
  Future<ApiResponse<ImageUploadResponse>> uploadImages(
      List<ImageUploadItem> imageList) {
    final filePaths = imageList.map((e) => e.filePath).toList();

    final fields = <String, String>{};
    for (var i = 0; i < imageList.length; i++) {
      final item = imageList[i];
      if (item.assetId != null) {
        fields['assetId_$i'] = item.assetId!;
      }
      if (item.petId != null) {
        fields['petId_$i'] = item.petId!;
      }
      if (item.date != null) {
        fields['date_$i'] = item.date!;
      }
      if (item.time != null) {
        fields['time_$i'] = item.time.toString();
      }
      if (item.location != null) {
        fields['location_$i'] = item.location!;
      }
    }

    return _client.uploadFiles<ImageUploadResponse>(
      '/api/mengyu/image/list/upload',
      files: {'image': filePaths},
      fields: fields,
      fromJson: (json) {
        if (json is Map<String, dynamic>) {
          return ImageUploadResponse.fromJson(json);
        }
        // Backward compat: old server returns true
        return const ImageUploadResponse(uploaded: 1, duplicates: 0);
      },
    );
  }
}
