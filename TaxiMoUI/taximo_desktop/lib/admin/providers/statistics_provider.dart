import 'package:flutter/foundation.dart';
import '../services/statistics_service.dart';

class StatisticsProvider with ChangeNotifier {
  final StatisticsService _statisticsService = StatisticsService();

  bool _isLoading = false;
  String? _errorMessage;

  int _totalUsers = 0;
  int _totalDrivers = 0;
  int _totalRides = 0;
  List<Map<String, dynamic>> _avgRatingData = [];
  List<Map<String, dynamic>> _revenueData = [];
  int _selectedYear = DateTime.now().year;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUsers => _totalUsers;
  int get totalDrivers => _totalDrivers;
  int get totalRides => _totalRides;
  List<Map<String, dynamic>> get avgRatingData => _avgRatingData;
  List<Map<String, dynamic>> get revenueData => _revenueData;
  int get selectedYear => _selectedYear;

  Future<void> fetchAll({int? year}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final targetYear = year ?? DateTime.now().year;
      _selectedYear = targetYear;

      // Fetch all statistics in parallel
      final results = await Future.wait([
        _statisticsService.getTotalUsers(),
        _statisticsService.getTotalDrivers(),
        _statisticsService.getTotalRides(),
        _statisticsService.getAvgRatingPerMonth(targetYear),
        _statisticsService.getRevenuePerMonth(targetYear),
      ]);

      _totalUsers = results[0] as int;
      _totalDrivers = results[1] as int;
      _totalRides = results[2] as int;
      _avgRatingData = _normalizeMonthlyData(List<Map<String, dynamic>>.from(results[3] as List));
      _revenueData = _normalizeMonthlyData(List<Map<String, dynamic>>.from(results[4] as List));

      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _totalUsers = 0;
      _totalDrivers = 0;
      _totalRides = 0;
      _avgRatingData = [];
      _revenueData = [];
      debugPrint('Error fetching statistics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setYear(int year) {
    _selectedYear = year;
    fetchAll(year: year);
  }

  /// Normalizes monthly data to ensure all 12 months are present.
  /// Handles both 'month' (1-12) and date-based formats.
  List<Map<String, dynamic>> _normalizeMonthlyData(List<Map<String, dynamic>> data) {
    final normalized = <int, Map<String, dynamic>>{};

    // Process existing data
    for (final item in data) {
      int month;
      dynamic value;

      // Handle different possible formats
      if (item.containsKey('month')) {
        month = (item['month'] as num).toInt();
        value = item['value'] ?? item['Value'] ?? 0;
      } else if (item.containsKey('Month')) {
        month = (item['Month'] as num).toInt();
        value = item['value'] ?? item['Value'] ?? 0;
      } else if (item.containsKey('date') || item.containsKey('Date')) {
        // Handle date format - extract month
        final dateStr = item['date'] ?? item['Date'];
        if (dateStr is String) {
          try {
            final date = DateTime.parse(dateStr);
            month = date.month;
            value = item['value'] ?? item['Value'] ?? item['amount'] ?? item['Amount'] ?? 0;
          } catch (e) {
            continue; // Skip invalid dates
          }
        } else {
          continue; // Skip invalid entries
        }
      } else {
        continue; // Skip entries without month/date
      }

      // Ensure month is valid (1-12)
      if (month >= 1 && month <= 12) {
        normalized[month] = {
          'month': month,
          'value': (value is num) ? value.toDouble() : 0.0,
        };
      }
    }

    // Fill missing months with 0
    final completeData = <Map<String, dynamic>>[];
    for (int month = 1; month <= 12; month++) {
      if (normalized.containsKey(month)) {
        completeData.add(normalized[month]!);
      } else {
        completeData.add({
          'month': month,
          'value': 0.0,
        });
      }
    }

    // Sort by month to ensure correct order
    completeData.sort((a, b) => (a['month'] as int).compareTo(b['month'] as int));

    return completeData;
  }
}

