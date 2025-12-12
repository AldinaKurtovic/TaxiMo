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
      _avgRatingData = List<Map<String, dynamic>>.from(results[3] as List);
      _revenueData = List<Map<String, dynamic>>.from(results[4] as List);

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
}

