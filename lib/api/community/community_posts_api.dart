import 'dart:io';
import '../client/api_client.dart';
import '../common/endpoints.dart';

class CommunityPostsApi {
  CommunityPostsApi({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(enableLogging: true);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> createV2Post({
    required String userId,
    String? text,
    List<File> images = const <File>[],
    List<File> audios = const <File>[],
    List<File> videos = const <File>[],
  }) async {
    final Map<String, String> fields = <String, String>{
      'userId': userId,
      if (text != null && text.isNotEmpty) 'text': text,
    };

    final Map<String, List<File>> filesByField = <String, List<File>>{};
    if (images.isNotEmpty) filesByField['images'] = images;
    if (audios.isNotEmpty) filesByField['audio'] = audios;
    if (videos.isNotEmpty) filesByField['videos'] = videos;

    return _apiClient.postMultipartMultiple(
      url: Endpoints.createCommunityPostV2(),
      fields: fields,
      filesByField: filesByField,
    );
  }

  Future<List<Map<String, dynamic>>> getV2Posts({int limit = 20}) async {
    final Map<String, String> query = <String, String>{
      'limit': '$limit',
    };
    final Map<String, dynamic> res = await _apiClient.getJson(
      url: Endpoints.getCommunityPostsV2(),
      queryParameters: query,
    );
    final dynamic data = res['data'] ?? res['results'] ?? res['items'] ?? res;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return <Map<String, dynamic>>[];
  }

  String mediaStreamUrl({required String type, required String fileId}) {
    return Endpoints.mediaV2Stream(type: type, fileId: fileId);
  }
}


