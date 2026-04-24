import 'api_client.dart';
import 'api_config.dart';
import '../constants/categories.dart';

class RemoteAdminService {
  Future<List<Map<String, dynamic>>?> getClients() async {
    final json = await ApiClient.getJson(
      '/api/client/getClients',
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return _readList(json);
  }

  Future<Map<String, dynamic>?> getClientAdmin(String guid) async {
    return ApiClient.getJson(
      '/api/client/getClientAdmin?guid=$guid',
      baseUrl: ApiConfig.clientBaseUrl,
    );
  }

  Future<Map<String, dynamic>?> updateClientAdmin({
    required String guid,
    required Map<String, dynamic> body,
  }) async {
    return ApiClient.putJson(
      '/api/client/changeUserDataAdmin?guid=$guid',
      body,
      baseUrl: ApiConfig.clientBaseUrl,
    );
  }

  Future<Map<String, dynamic>?> changeClientIconAdmin({
    required String guid,
    required String uri,
  }) async {
    return ApiClient.putJson(
      '/api/client/changeIconUriAdmin?guid=$guid&uri=$uri',
      const {},
      baseUrl: ApiConfig.clientBaseUrl,
    );
  }

  Future<bool> blockClient(String guid) async {
    final json = await ApiClient.putJson(
      '/api/client/blockClient/$guid',
      const {},
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return json != null;
  }

  Future<bool> unblockClient(String guid) async {
    final json = await ApiClient.putJson(
      '/api/client/unblockClient/$guid',
      const {},
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return json != null;
  }

  Future<bool> deleteClientByGuid(String guid) async {
    final json = await ApiClient.deleteJson(
      '/api/client/deleteClientAdmin?guid=$guid',
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return json != null;
  }

  Future<List<Map<String, dynamic>>?> getCompaniesAdmin() async {
    final json = await ApiClient.getJson(
      '/api/company/getAllAdmin',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return _readList(json);
  }

  Future<Map<String, dynamic>?> getCompanyAdmin(String guid) async {
    return ApiClient.getJson(
      '/api/company/getCompanyAdmin?guid=$guid',
      baseUrl: ApiConfig.companyBaseUrl,
    );
  }

  Future<Map<String, dynamic>?> updateCompanyAdmin(
    Map<String, dynamic> body,
  ) async {
    return ApiClient.putJson(
      '/api/company/changeDataAdmin',
      body,
      baseUrl: ApiConfig.companyBaseUrl,
    );
  }

  Future<Map<String, dynamic>?> changeCompanyIconAdmin({
    required String guid,
    required String uri,
  }) async {
    return ApiClient.putJson(
      '/api/company/changeIconUriAdmin?guid=$guid&uri=$uri',
      const {},
      baseUrl: ApiConfig.companyBaseUrl,
    );
  }

  Future<bool> blockCompany(String guid) async {
    final json = await ApiClient.putJson(
      '/api/company/blockCompany/$guid',
      const {},
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json != null;
  }

  Future<bool> unblockCompany(String guid) async {
    final json = await ApiClient.putJson(
      '/api/company/unblockCompany/$guid',
      const {},
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json != null;
  }

  Future<bool> deleteCompanyByGuid(String guid) async {
    final json = await ApiClient.deleteJson(
      '/api/company/delete?id=$guid',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json != null;
  }

  Future<List<Map<String, dynamic>>?> getCategories() async {
    final json = await ApiClient.getJson(
      '/api/category/get',
      baseUrl: ApiConfig.categoryBaseUrl,
    );
    final categories = _readList(json);
    if (categories != null) {
      updateCategoryCatalog(
        categories.map((item) => (item['title'] ?? '').toString()),
      );
    }
    return categories;
  }

  Future<Map<String, dynamic>?> createCategory({
    required String title,
    String iconUri = '',
  }) async {
    return ApiClient.postJson(
      '/api/category/create',
      {'title': title, 'icon_uri': iconUri},
      baseUrl: ApiConfig.categoryBaseUrl,
    );
  }

  Future<Map<String, dynamic>?> updateCategory({
    required int id,
    required String title,
    String iconUri = '',
  }) async {
    return ApiClient.putJson(
      '/api/category/update',
      {'id': id, 'title': title, 'icon_uri': iconUri},
      baseUrl: ApiConfig.categoryBaseUrl,
    );
  }

  Future<bool> deleteCategory(int id) async {
    final json = await ApiClient.deleteJson(
      '/api/category/delete?category_id=$id',
      baseUrl: ApiConfig.categoryBaseUrl,
    );
    return json != null;
  }

  Future<List<Map<String, dynamic>>?> getRatingCriteria() async {
    final json = await ApiClient.getJson(
      '/api/rating-criteria/',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return _readList(json);
  }

  Future<Map<String, dynamic>?> createRatingCriterion({
    required String name,
    String? description,
  }) async {
    return ApiClient.postJson(
      '/api/rating-criteria/',
      {'name': name, 'description': description},
      baseUrl: ApiConfig.companyBaseUrl,
    );
  }

  Future<Map<String, dynamic>?> updateRatingCriterion({
    required int id,
    required String name,
    String? description,
  }) async {
    return ApiClient.putJson(
      '/api/rating-criteria/$id',
      {'name': name, 'description': description},
      baseUrl: ApiConfig.companyBaseUrl,
    );
  }

  Future<bool> deleteRatingCriterion(int id) async {
    final json = await ApiClient.deleteJson(
      '/api/rating-criteria/$id',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json != null;
  }

  Future<List<Map<String, dynamic>>?> getAllReviewsAdmin() async {
    final json = await ApiClient.getJson(
      '/api/review/getAll',
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    return _readList(json);
  }

  Future<bool> deleteReview(int id) async {
    final json = await ApiClient.deleteJson(
      '/api/review/delete?id=$id',
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    return json != null;
  }

  List<Map<String, dynamic>>? _readList(Map<String, dynamic>? json) {
    if (json == null) return null;
    final data = json['data'] ?? json;
    if (data is! List) return null;
    return data
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();
  }
}
