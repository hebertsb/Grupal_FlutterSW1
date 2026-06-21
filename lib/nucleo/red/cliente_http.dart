import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _urlBase      = 'http://98.93.156.209/api';
const String urlDjango     = 'http://98.93.156.209';
const String urlIaServidor = 'http://98.93.156.209/ia-personas';

Dio crearClienteHttp() {
  final dio = Dio(BaseOptions(
    baseUrl: _urlBase,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('sivic_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) {
      return handler.next(error);
    },
  ));

  return dio;
}
