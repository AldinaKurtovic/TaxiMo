import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/statistics_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StatisticsProvider>(context, listen: false).fetchAll();
    });
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildStatCard(String label, int value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D3F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculates the overall average rating from monthly data
  double _calculateAverageRating(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0.0;
    
    // Filter out months with zero values (no data)
    final validData = data.where((item) {
      final value = (item['value'] as num?)?.toDouble() ?? 0.0;
      return value > 0;
    }).toList();
    
    if (validData.isEmpty) return 0.0;
    
    final sum = validData.fold<double>(
      0.0,
      (acc, item) => acc + ((item['value'] as num?)?.toDouble() ?? 0.0),
    );
    
    return sum / validData.length;
  }

  /// Returns a quality label based on rating
  String _getQualityLabel(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.5) return 'Good';
    if (rating >= 3.0) return 'Fair';
    if (rating > 0) return 'Needs Improvement';
    return 'No Rating';
  }

  /// Returns a color based on rating
  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 4.0) return Colors.lightGreen;
    if (rating >= 3.5) return Colors.orange;
    if (rating >= 3.0) return Colors.deepOrange;
    if (rating > 0) return Colors.red;
    return Colors.grey;
  }

  Widget _buildRatingChart(List<Map<String, dynamic>> data) {
    final averageRating = _calculateAverageRating(data);
    final hasData = averageRating > 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Progress Chart
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[200]!),
                  ),
                ),
                // Progress circle
                if (hasData)
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: averageRating / 5.0,
                      strokeWidth: 12,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRatingColor(averageRating),
                      ),
                    ),
                  ),
                // Center content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasData ? averageRating.toStringAsFixed(1) : '0.0',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: hasData
                            ? _getRatingColor(averageRating)
                            : Colors.grey[400],
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/ 5.0',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Star Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              if (!hasData) {
                return Icon(
                  Icons.star_border,
                  color: Colors.grey[300],
                  size: 32,
                );
              }
              
              final filledStars = averageRating.floor();
              final hasHalfStar = (averageRating - filledStars) >= 0.5;
              
              if (index < filledStars) {
                return Icon(
                  Icons.star,
                  color: Colors.amber[700],
                  size: 32,
                );
              } else if (index == filledStars && hasHalfStar) {
                return Icon(
                  Icons.star_half,
                  color: Colors.amber[700],
                  size: 32,
                );
              } else {
                return Icon(
                  Icons.star_border,
                  color: Colors.grey[300],
                  size: 32,
                );
              }
            }),
          ),
          const SizedBox(height: 24),
          // Quality Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: hasData
                  ? _getRatingColor(averageRating).withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getQualityLabel(averageRating),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: hasData
                    ? _getRatingColor(averageRating)
                    : Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Calculates appropriate Y-axis max value and interval for revenue chart.
  /// Uses dynamic scaling with small padding to prevent line from being stuck at bottom.
  /// Returns a tuple: (maxY, interval)
  (double, double) _calculateRevenueYAxis(List<FlSpot> spots) {
    if (spots.isEmpty) {
      return (10.0, 2.5);
    }

    // Find max value in data
    final maxValue = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    
    // Dynamic maxY with 30% padding, minimum 10
    final maxY = maxValue == 0 ? 10.0 : maxValue * 1.3;
    
    // Use 4 grid lines for clean appearance
    final interval = maxY / 4;
    
    return (maxY, interval);
  }

  Widget _buildRevenueChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: Colors.grey)),
      );
    }

    // Ensure data is sorted by month (1-12)
    final sortedData = List<Map<String, dynamic>>.from(data);
    sortedData.sort((a, b) => (a['month'] as num).compareTo(b['month'] as num));

    final spots = sortedData.map((item) {
      return FlSpot(
        (item['month'] as num).toDouble(),
        (item['value'] as num).toDouble(),
      );
    }).toList();

    // Calculate dynamic Y-axis scaling
    final (maxY, interval) = _calculateRevenueYAxis(spots);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 1 && value.toInt() <= 12) {
                  return Text(
                    _getMonthName(value.toInt()),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: Colors.purple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.purple,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.purple.withOpacity(0.25),
                  Colors.purple.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final value = touchedSpot.y;
                final month = _getMonthName(touchedSpot.x.toInt());
                return LineTooltipItem(
                  '$month: ${value.toInt()} EUR',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with Back Button (only if navigated from home page via quick access)
          Builder(
            builder: (context) {
              final canPop = Navigator.canPop(context);
              if (canPop) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, size: 24),
                      color: const Color(0xFF2D2D3F),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back to Home',
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D3F),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                );
              }
              return const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D3F),
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Stat Cards
          Consumer<StatisticsProvider>(
            builder: (context, provider, _) {
              return Row(
                children: [
                  _buildStatCard('Users', provider.totalUsers),
                  const SizedBox(width: 16),
                  _buildStatCard('Drivers', provider.totalDrivers),
                  const SizedBox(width: 16),
                  _buildStatCard('Rides', provider.totalRides),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // Charts Section
          Expanded(
            child: Consumer<StatisticsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Error loading statistics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48.0),
                          child: Text(
                            provider.errorMessage!,
                            style: TextStyle(color: Colors.red[700], fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => provider.fetchAll(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    // Avg Rating Chart
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Avg. Rating',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D2D3F),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: _buildRatingChart(provider.avgRatingData),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Revenue Chart
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Revenue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2D2D3F),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: _buildRevenueChart(provider.revenueData),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

