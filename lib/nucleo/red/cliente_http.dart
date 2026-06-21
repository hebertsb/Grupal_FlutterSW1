import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IP de la PC donde corre el backend Django en la red WiFi local.
// Celular/emulador y PC deben estar en la misma red. Si cambia la IP
// de la PC (ipconfig), actualizar este valor.
const String _urlBase      = 'http://192.168.1.7:8000/api';
const String urlDjango     = 'http://192.168.1.7:8000';   // base Django sin /api
const String urlIaServidor = 'http://192.168.1.7:8002';   // servidor FastAPI IA

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
