import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String TOKEN_KEY = 'auth_token';
  final Dio _dio;
  
  ApiService() : _dio = Dio(BaseOptions(
    baseUrl: 'https://evika.onrender.com',
    connectTimeout: const Duration(seconds: 30), 
    receiveTimeout: const Duration(seconds: 30), 
    sendTimeout: const Duration(seconds: 30),  
  )) {
    _setupAuthInterceptor();
    _setupRetryInterceptor();
  }

  void _setupAuthInterceptor() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getStoredToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _clearStoredToken();
        }
        return handler.next(error);
      },
    ));
  }

  void _setupRetryInterceptor() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          if (_shouldRetry(error)) {
            try {
              // Retry the request
              final options = error.requestOptions;
              final response = await _dio.request(
                options.path,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                ),
                data: options.data,
                queryParameters: options.queryParameters,
              );
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.sendTimeout ||
           (error.response?.statusCode ?? 0) >= 500;
  }

  Future<String?> _getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN_KEY);
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/api/auth/signin', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(TOKEN_KEY, response.data['token']);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print('Login error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      }
      throw Exception('Login failed: ${e.message}');
    } catch (e) {
      print('Unexpected login error: $e');
      throw Exception('An unexpected error occurred during login');
    }
  }

  Future<Map<String, dynamic>> getPosts({int page = 1, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/api/event', 
        queryParameters: {
          'page': page,
          'limit': limit,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('data') && 
            responseData['data'] is Map<String, dynamic> && 
            responseData['data'].containsKey('events')) {
          return {
            'events': responseData['data']['events'] as List<dynamic>,
            'currentPage': responseData['data']['currentPage'] as int,
            'totalPages': responseData['data']['totalPages'] as int,
          };
        }
      }
      throw Exception('Invalid response format');
    } on DioException catch (e) {
      print('Error fetching posts: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      }
      throw Exception('Failed to fetch posts: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching posts: $e');
      throw Exception('An unexpected error occurred while fetching posts');
    }
  }

  Future<Map<String, dynamic>> searchPosts({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
        },
      );
      return response.data;
    } on DioException catch (e) {
      print('Error searching posts: $e');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Search timeout. Please try again.');
      }
      throw Exception('Search failed: ${e.message}');
    } catch (e) {
      print('Unexpected search error: $e');
      throw Exception('An unexpected error occurred during search');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _getStoredToken();
    return token != null;
  }

  Future<void> logout() async {
    await _clearStoredToken();
  }
}