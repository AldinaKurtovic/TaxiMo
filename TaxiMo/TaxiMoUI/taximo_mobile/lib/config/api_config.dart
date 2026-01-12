class ApiConfig {
  // Android Emulator uses 10.0.2.2 to access localhost
  // Admin app uses http://localhost:5244
  // Mobile app must use http://10.0.2.2:5244
  static const String baseUrl = 'http://10.0.2.2:5244';
}

