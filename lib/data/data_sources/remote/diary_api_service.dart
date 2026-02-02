import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

/// 日记列表项（对应 api.md diary list item）
class DiaryListItem {
  final String diaryId;
  final String date;
  final String title;
  final String avatar;
  final int emotion;

  const DiaryListItem({
    required this.diaryId,
    required this.date,
    required this.title,
    required this.avatar,
    required this.emotion,
  });

  factory DiaryListItem.fromJson(Map<String, dynamic> json) {
    return DiaryListItem(
      diaryId: (json['diaryId'] ?? '').toString(),
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      emotion: json['emotion'] as int? ?? 0,
    );
  }
}

/// 日记列表响应
class DiaryListResponse {
  final List<DiaryListItem> diaryList;

  const DiaryListResponse({required this.diaryList});

  factory DiaryListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['diaryList'] as List<dynamic>? ?? [];
    return DiaryListResponse(
      diaryList: list
          .map((e) => DiaryListItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 日记详情响应
class DiaryDetailResponse {
  final String date;
  final String title;
  final String avatar;
  final int emotion;
  final String content;
  final List<String> imageList;

  const DiaryDetailResponse({
    required this.date,
    required this.title,
    required this.avatar,
    required this.emotion,
    required this.content,
    required this.imageList,
  });

  factory DiaryDetailResponse.fromJson(Map<String, dynamic> json) {
    final images = json['imageList'] as List<dynamic>? ?? [];
    return DiaryDetailResponse(
      date: json['date'] as String? ?? '',
      title: json['title'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      emotion: json['emotion'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      imageList: images.map((e) => e.toString()).toList(),
    );
  }
}

/// 日历天项（对应 api.md calendar day item）
class CalendarDayItem {
  final String diaryId;
  final String date;
  final int weekDay;
  final String title;
  final String avatar;
  final int emotion;

  const CalendarDayItem({
    required this.diaryId,
    required this.date,
    required this.weekDay,
    required this.title,
    required this.avatar,
    required this.emotion,
  });

  factory CalendarDayItem.fromJson(Map<String, dynamic> json) {
    return CalendarDayItem(
      diaryId: (json['diaryId'] ?? '').toString(),
      date: json['date'] as String? ?? '',
      weekDay: json['weekDay'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      emotion: json['emotion'] as int? ?? 0,
    );
  }
}

/// 日历响应
class CalendarResponse {
  final List<CalendarDayItem> dayList;

  const CalendarResponse({required this.dayList});

  factory CalendarResponse.fromJson(Map<String, dynamic> json) {
    final list = json['dayList'] as List<dynamic>? ?? [];
    return CalendarResponse(
      dayList: list
          .map((e) => CalendarDayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 前7天响应（结构同日历响应）
class WeekDaysResponse {
  final List<CalendarDayItem> dayList;

  const WeekDaysResponse({required this.dayList});

  factory WeekDaysResponse.fromJson(Map<String, dynamic> json) {
    final list = json['dayList'] as List<dynamic>? ?? [];
    return WeekDaysResponse(
      dayList: list
          .map((e) => CalendarDayItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// 日记相关 API 调用
class DiaryApiService {
  final ApiClient _client;

  DiaryApiService({ApiClient? client}) : _client = client ?? ApiClient();

  /// 获取日记列表
  Future<ApiResponse<DiaryListResponse>> getDiaryList(String petId) {
    return _client.get<DiaryListResponse>(
      '/api/chongyu/diary/list',
      queryParams: {'petId': petId},
      fromJson: (json) =>
          DiaryListResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 获取日记详情
  ///
  /// 优先使用 [diaryId] 查询，为空时使用 [date] 查询
  Future<ApiResponse<DiaryDetailResponse>> getDiaryDetail({
    required String petId,
    String? diaryId,
    String? date,
  }) {
    final params = <String, String>{'petId': petId};
    if (diaryId != null) params['diaryId'] = diaryId;
    if (date != null) params['date'] = date;

    return _client.get<DiaryDetailResponse>(
      '/api/chongyu/pet/detail',
      queryParams: params,
      fromJson: (json) =>
          DiaryDetailResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 查询日历情绪
  ///
  /// [yearMonth] 格式: 202601
  Future<ApiResponse<CalendarResponse>> getCalendar(
    String petId,
    int yearMonth,
  ) {
    return _client.get<CalendarResponse>(
      '/api/chongyu/diary/calendar',
      queryParams: {
        'petId': petId,
        'yearMonth': yearMonth.toString(),
      },
      fromJson: (json) =>
          CalendarResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// 查询前7天情绪
  ///
  /// [date] 格式: 20260130
  Future<ApiResponse<WeekDaysResponse>> get7Days(String petId, int date) {
    return _client.get<WeekDaysResponse>(
      '/api/chongyu/diary/7days',
      queryParams: {
        'petId': petId,
        'date': date.toString(),
      },
      fromJson: (json) =>
          WeekDaysResponse.fromJson(json as Map<String, dynamic>),
    );
  }
}
