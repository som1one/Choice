import '../constants/categories.dart';
import 'api_client.dart';
import 'api_config.dart';

class RemoteCategoryService {
  Future<List<Map<String, dynamic>>?> getCategories() async {
    final json = await ApiClient.getJson(
      '/api/category/get',
      baseUrl: ApiConfig.categoryBaseUrl,
    );
    if (json == null) return null;

    final data = json['data'];
    if (data is! List) return null;

    final categories = data
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();

    updateCategoryCatalog(
      categories.map((item) => (item['title'] ?? '').toString()),
    );
    return categories;
  }
}
