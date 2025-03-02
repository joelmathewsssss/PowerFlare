import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logging/logging.dart';

/// Screen that displays today's solar power forecast by hour
class TodayForecastScreen extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final Function(Map<String, dynamic>) calculateSolarPower;
  final String Function(double) getSolarCondition;
  final List<FlSpot> Function() getTodayHourlyData;

  const TodayForecastScreen({
    Key? key,
    required this.weatherData,
    required this.calculateSolarPower,
    required this.getSolarCondition,
    required this.getTodayHourlyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show placeholder if no data is available
    if (weatherData == null) {
      return const Center(child: Text('No data available'));
    }

    // Get timezone information
    final timezone = weatherData!['city']['timezone'] as int;
    final apiOffset = Duration(seconds: timezone);
    final now = DateTime.now();
    final utcNow = now.toUtc();
    final locationNow = utcNow.add(apiOffset);

    // Set up logging
    final log = Logger('TimeDebug');

    // Get all forecasts and sort by time
    final forecasts = List<dynamic>.from(weatherData!['list']);
    forecasts.sort((a, b) {
      final timeA =
          DateTime.fromMillisecondsSinceEpoch(a['dt'] * 1000, isUtc: true);
      final timeB =
          DateTime.fromMillisecondsSinceEpoch(b['dt'] * 1000, isUtc: true);
      return timeA.compareTo(timeB);
    });

    // Find the forecast closest to current time
    var closestForecast = forecasts.first;
    var smallestDiff = Duration(days: 1);

    for (var forecast in forecasts) {
      final forecastUtc = DateTime.fromMillisecondsSinceEpoch(
        forecast['dt'] * 1000,
        isUtc: true,
      );
      final forecastLocal = forecastUtc.add(apiOffset);
      final diff = forecastLocal.difference(locationNow).abs();

      if (diff < smallestDiff) {
        smallestDiff = diff;
        closestForecast = forecast;
      }
    }

    // Calculate current conditions
    final currentPower = calculateSolarPower(closestForecast);
    final currentCloudCover = closestForecast['clouds']['all'] as int;
    final condition = getSolarCondition(currentPower);

    // Get forecast time in location's timezone
    final forecastUtc = DateTime.fromMillisecondsSinceEpoch(
      closestForecast['dt'] * 1000,
      isUtc: true,
    );
    final forecastLocal = forecastUtc.add(apiOffset);
    final cityName = weatherData!['city']['name'];

    // Get hourly data points for the chart
    final spots = getTodayHourlyData();

    return Column(
      children: [
        // Current conditions section
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Current Solar Conditions for $cityName',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                condition,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              Text(
                'Cloud Cover: $currentCloudCover%',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        // Hourly chart section
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 24.0),
              child: BarChart(
                BarChartData(
                  // Grid configuration
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 200,
                    verticalInterval: 2,
                  ),
                  // Configure chart titles and labels
                  titlesData: FlTitlesData(
                    // Hide right and top titles
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    // Configure bottom (x-axis) titles
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Text('Hour of Day'),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 3,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}:00');
                        },
                      ),
                    ),
                    // Configure left (y-axis) titles
                    leftTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(bottom: 32, right: 24),
                        child: Text('Average Solar Power (W/m²)'),
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 200,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const Text('');
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  // Bar chart configuration
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 1000,
                  minY: 0,
                  barGroups: spots.map((spot) {
                    return BarChartGroupData(
                      x: spot.x.toInt(),
                      barRods: [
                        BarChartRodData(
                          toY: spot.y,
                          color: Theme.of(context).colorScheme.primary,
                          width: 24,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    );
                  }).toList(),
                  baselineY: 0,
                  groupsSpace: 8,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
