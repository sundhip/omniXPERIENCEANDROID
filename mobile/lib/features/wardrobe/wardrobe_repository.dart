import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/database/app_database.dart';

class WardrobeRepository {
  final ApiClient apiClient;

  WardrobeRepository({required this.apiClient});

  /// Fetches items for the authenticated user with optional server-side filters.
  Future<List<WardrobeItemModel>> getWardrobeItems({
    String? category,
    String? subcategory,
    String? color,
    String? formality,
    String? pattern,
    bool? favorite,
    String? status = 'available',
    String? search,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (category != null && category != 'All') queryParams['category'] = category;
    if (subcategory != null) queryParams['subcategory'] = subcategory;
    if (color != null) queryParams['color'] = color;
    if (formality != null) queryParams['formality'] = formality;
    if (pattern != null) queryParams['pattern'] = pattern;
    if (favorite != null) queryParams['favorite'] = favorite;
    if (status != null) queryParams['status'] = status;
    if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

    try {
      final res = await apiClient.dio.get('/wardrobe', queryParameters: queryParams);
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((item) => WardrobeItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  /// Creates a new wardrobe item in backend
  Future<WardrobeItemModel> createWardrobeItem(WardrobeItemModel item) async {
    try {
      final res = await apiClient.dio.post('/wardrobe', data: item.toJson());
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return WardrobeItemModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Failed to create wardrobe item.');
    } on DioException catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  /// Updates an existing wardrobe item
  Future<WardrobeItemModel> updateWardrobeItem(WardrobeItemModel item) async {
    try {
      final res = await apiClient.dio.put('/wardrobe/${item.id}', data: item.toJson());
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return WardrobeItemModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update wardrobe item.');
    } on DioException catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  /// Toggles favorite state of an item
  Future<WardrobeItemModel> toggleFavorite(String itemId) async {
    try {
      final res = await apiClient.dio.post('/wardrobe/$itemId/favorite');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return WardrobeItemModel.fromJson(res.data as Map<String, dynamic>);
      }
      throw Exception('Failed to toggle favorite.');
    } on DioException catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  /// Deletes or archives a wardrobe item
  Future<void> deleteWardrobeItem(String itemId, {bool permanent = false}) async {
    try {
      await apiClient.dio.delete('/wardrobe/$itemId', queryParameters: {'permanent': permanent});
    } on DioException catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  /// Sends clothing photo to the real computer vision analysis endpoint
  Future<Map<String, dynamic>> analyzeClothingImage(
    String filePath, {
    String? contextHint,
    String? userSize,
  }) async {
    final Map<String, dynamic> map = {
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'garment.jpg',
      ),
    };
    if (contextHint != null && contextHint.trim().isNotEmpty) {
      map['context_hint'] = contextHint.trim();
    }
    if (userSize != null && userSize.trim().isNotEmpty) {
      map['user_size'] = userSize.trim();
    }

    final formData = FormData.fromMap(map);

    try {
      final res = await apiClient.dio.post(
        '/wardrobe/analyze',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('Failed to analyze garment image.');
    } on DioException catch (e) {
      final errorMsg = ApiClient.getErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// Retrieves structured taxonomy and available categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final res = await apiClient.dio.get('/wardrobe/categories');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return {};
    } on DioException {
      return {};
    }
  }
}
