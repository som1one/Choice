import 'api_client.dart';
import 'api_config.dart';

class RemoteCompanyService {
  /// Получить профиль компании (текущего пользователя)
  Future<Map<String, dynamic>?> getCompanyProfile() async {
    final json = await ApiClient.getJson(
      '/api/company/get',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json;
  }

  /// Получить компанию по GUID
  Future<Map<String, dynamic>?> getCompany(String guid) async {
    final json = await ApiClient.getJson(
      '/api/company/getCompany?guid=$guid',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json;
  }

  /// Получить все компании
  Future<List<Map<String, dynamic>>?> getAllCompanies() async {
    final json = await ApiClient.getJson(
      '/api/company/getAll',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    if (json == null) return null;
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (json is Map<String, dynamic>) {
      final companies = json['companies'] ?? json['data'];
      if (companies is List) {
        return (companies as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  /// Получить компании по категории
  Future<List<Map<String, dynamic>>?> getCompaniesByCategory(int categoryId) async {
    final json = await ApiClient.getJson(
      '/api/company/getByCategory?category_id=$categoryId',
      baseUrl: ApiConfig.companyBaseUrl,
    );
    if (json == null) return null;
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (json is Map<String, dynamic>) {
      final companies = json['companies'] ?? json['data'];
      if (companies is List) {
        return (companies as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }

  /// Заполнить данные компании
  Future<bool> fillCompanyData(Map<String, dynamic> data) async {
    final json = await ApiClient.putJson(
      '/api/company/fillCompanyData',
      data,
      baseUrl: ApiConfig.companyBaseUrl,
      throwOnError: true,
    );
    return json != null;
  }

  /// Изменить данные компании
  Future<bool> changeData(Map<String, dynamic> data) async {
    final json = await ApiClient.putJson(
      '/api/company/changeData',
      data,
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json != null;
  }

  /// Изменить иконку компании
  Future<Map<String, dynamic>?> changeIconUri(String iconUri) async {
    final json = await ApiClient.putJson(
      '/api/company/changeIconUri?uri=${Uri.encodeComponent(iconUri)}',
      <String, dynamic>{},
      baseUrl: ApiConfig.companyBaseUrl,
    );
    return json;
  }

  /// Получить заявки для компании (с фильтрацией по категориям и радиусу)
  Future<List<Map<String, dynamic>>?> getOrderRequests({List<int>? categoriesId}) async {
    String url = '/api/company/getOrderRequests';
    
    // Формируем query параметры для categoriesId[]
    if (categoriesId != null && categoriesId.isNotEmpty) {
      final queryParams = categoriesId
          .map((id) => 'categoriesId[]=$id')
          .join('&');
      url = '$url?$queryParams';
    }
    
    final json = await ApiClient.getJson(
      url,
      baseUrl: ApiConfig.companyBaseUrl,
    );
    
    if (json == null) return null;
    if (json is List) {
      return (json as List).map((e) => e as Map<String, dynamic>).toList();
    }
    if (json is Map<String, dynamic>) {
      final requests = json['requests'] ?? json['data'];
      if (requests is List) {
        return (requests as List).map((e) => e as Map<String, dynamic>).toList();
      }
    }
    return [];
  }
}
