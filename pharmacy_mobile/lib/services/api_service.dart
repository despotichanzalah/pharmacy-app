import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// All calls to the same live backend the web app uses.
class ApiService {
  static const String baseUrl = 'https://pharmacy-app-nysc.onrender.com/api';

  // ---------- Token storage ----------

  static Future<void> saveSession(Map<String, dynamic> authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', authResponse['token']);
    await prefs.setString('name', authResponse['name']);
    await prefs.setString('email', authResponse['email']);
    await prefs.setString('role', authResponse['role']);
    await prefs.setInt('shopId', authResponse['shopId']);
    await prefs.setString('shopName', authResponse['shopName']);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String?>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('name'),
      'email': prefs.getString('email'),
      'role': prefs.getString('role'),
      'shopName': prefs.getString('shopName'),
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ---------- Low-level request helpers ----------

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _decode(http.Response res) {
    final body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final message = (body is Map && body['error'] != null)
        ? body['error']
        : 'Something went wrong (${res.statusCode}).';
    throw ApiException(message, statusCode: res.statusCode, body: body);
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
    return _decode(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body, {bool auth = true}) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<void> delete(String path, {bool auth = true}) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'), headers: await _headers(auth: auth));
    _decode(res);
  }

  // ---------- Auth ----------

  static Future<Map<String, dynamic>> login(String email, String password, bool rememberMe) async {
    final data = await post('/auth/login', {
      'email': email,
      'password': password,
      'rememberMe': rememberMe,
    }, auth: false);
    await saveSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String roleName,
    String? shopName,
    int? shopId,
  }) async {
    final data = await post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'roleName': roleName,
      if (shopName != null) 'shopName': shopName,
      if (shopId != null) 'shopId': shopId,
    }, auth: false);
    await saveSession(data);
    return data;
  }

  static Future<void> forgotPassword(String email) async {
    await post('/auth/forgot-password', {'email': email}, auth: false);
  }

  static Future<List<dynamic>> getShops() async {
    return await get('/shops', auth: false);
  }

  // ---------- Reports ----------

  static Future<Map<String, dynamic>> getProfitReport(String month) async {
    return await get('/reports/profit?month=$month');
  }

  static Future<List<dynamic>> getLowStockBatches({int threshold = 10}) async {
    return await get('/batches/low-stock?threshold=$threshold');
  }

  static Future<List<dynamic>> getExpiringBatches({int days = 30}) async {
    return await get('/batches/expiring?days=$days');
  }

  static Future<List<dynamic>> getAllBatches() async {
    return await get('/batches/low-stock?threshold=999999');
  }

  static Future<List<dynamic>> getDailySales({int days = 7}) async {
    return await get('/reports/daily-sales?days=$days');
  }

  static Future<List<dynamic>> getTopMedicines(String month, {int limit = 5}) async {
    return await get('/reports/top-medicines?month=$month&limit=$limit');
  }

  // ---------- Medicines ----------

  static Future<List<dynamic>> getMedicines({String? query}) async {
    final q = (query != null && query.isNotEmpty) ? '?query=${Uri.encodeQueryComponent(query)}' : '';
    return await get('/medicines$q');
  }

  static Future<Map<String, dynamic>> addMedicine({
    required String name,
    String? unit,
    int reorderLevel = 10,
    int packSize = 1,
    List<int>? genericIds,
    List<String>? newGenerics,
  }) async {
    return await post('/medicines', {
      'name': name,
      'unit': unit,
      'reorderLevel': reorderLevel,
      'packSize': packSize,
      'genericIds': genericIds ?? [],
      'newGenerics': newGenerics ?? [],
    });
  }

  // ---------- Generics ----------

  static Future<List<dynamic>> getGenerics({String? query}) async {
    final q = (query != null && query.isNotEmpty) ? '?query=${Uri.encodeQueryComponent(query)}' : '';
    return await get('/generics$q');
  }

  static Future<void> updateMedicine(
    int id, {
    required String name,
    String? unit,
    int reorderLevel = 10,
    int packSize = 1,
    List<int>? genericIds,
    List<String>? newGenerics,
  }) async {
    await put('/medicines/$id', {
      'name': name,
      'unit': unit,
      'reorderLevel': reorderLevel,
      'packSize': packSize,
      'genericIds': genericIds ?? [],
      'newGenerics': newGenerics ?? [],
    });
  }

  static Future<void> deleteMedicine(int id) async {
    await delete('/medicines/$id');
  }

  // ---------- Batches (stock) ----------

  static Future<void> addBatch({
    required int medicineId,
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required double purchasePrice,
    required double salePrice,
    int? supplierId,
  }) async {
    await post('/batches', {
      'medicineId': medicineId,
      'batchNumber': batchNumber,
      'quantity': quantity,
      'expiryDate': expiryDate,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      if (supplierId != null) 'supplierId': supplierId,
    });
  }

  static Future<void> updateBatch(
    int id, {
    required String batchNumber,
    required int quantity,
    required String expiryDate,
    required double purchasePrice,
    required double salePrice,
    int? supplierId,
  }) async {
    await put('/batches/$id', {
      'batchNumber': batchNumber,
      'quantity': quantity,
      'expiryDate': expiryDate,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      if (supplierId != null) 'supplierId': supplierId,
    });
  }

  static Future<void> deleteBatch(int id) async {
    await delete('/batches/$id');
  }

  // ---------- Sales ----------

  static Future<Map<String, dynamic>> createSale({
    String? customerName,
    double discountPercent = 0,
    required List<Map<String, dynamic>> items, // [{batchId, quantity}]
  }) async {
    return await post('/sales', {
      'customerName': customerName,
      'discountPercent': discountPercent,
      'items': items,
    });
  }

  static Future<List<dynamic>> listSales() async {
    return await get('/sales');
  }

  static Future<List<dynamic>> getSaleItems(int saleId) async {
    return await get('/sales/$saleId/items');
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic body;
  ApiException(this.message, {required this.statusCode, this.body});

  @override
  String toString() => message;
}
