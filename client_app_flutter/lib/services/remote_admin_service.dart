import 'api_client.dart';
import 'api_config.dart';

class RemoteAdminService {
  Future<List<Map<String, dynamic>>?> getClients() async {
    final json = await ApiClient.getJson('/api/client/getClients', baseUrl: ApiConfig.clientBaseUrl);
    if (json == null) return null;
    final data = json['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return null;
  }

  Future<bool> deleteClientByGuid(String guid) async {
    final json = await ApiClient.deleteJson(
      '/api/client/deleteClientAdmin?guid=$guid',
      baseUrl: ApiConfig.clientBaseUrl,
    );
    return json != null;
  }

  Future<List<Map<String, dynamic>>?> getCompaniesAdmin() async {
    // Новый админ-эндпоинт (добавим в бэке): возвращает ВСЕ компании, в т.ч. не заполненные
    final json = await ApiClient.getJson('/api/company/getAllAdmin', baseUrl: ApiConfig.companyBaseUrl);
    if (json == null) return null;
    final data = json['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return null;
  }

  Future<bool> deleteCompanyByGuid(String guid) async {
    final json = await ApiClient.deleteJson(
      '/api/company/delete?id=$guid',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json != null;
  }

  Future<List<Map<String, dynamic>>?> getAllReviewsAdmin() async {
    final json = await ApiClient.getJson('/api/review/getAll', baseUrl: ApiConfig.reviewBaseUrl);
    if (json == null) return null;
    final data = json['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return null;
  }

  Future<bool> deleteReview(int id) async {
    final json = await ApiClient.deleteJson(
      '/api/review/delete?id=$id',
      baseUrl: ApiConfig.reviewBaseUrl,
    );
    return json != null;
  }
}

