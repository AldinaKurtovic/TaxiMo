import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Android Emulator uses 10.0.2.2 to access localhost
  // Web uses http://localhost:5244
  // Mobile app must use http://10.0.2.2:5244
  static String get baseUrl {
    if (kIsWeb) {
      // For web platform, use localhost
      return 'http://localhost:5244';
    } else if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2
      return 'http://10.0.2.2:5244';
    } else {
      // For iOS or other platforms, use localhost
      return 'http://localhost:5244';
    }
  }
  
  // Debug method to print current base URL
  static void printBaseUrl() {
    if (kDebugMode) {
      print('API Base URL: $baseUrl');
    }
  }
}
