import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

/// Screen that displays a 5-day solar power forecast
class WeeklyForecastScreen extends StatelessWidget {
  final Map<String, dynamic>? weatherData;
  final List<FlSpot> Function() getWeeklyData;

  const WeeklyForecastScreen({
    Key? key,
    required this.weatherData,
    required this.getWeeklyData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show placeholder if no data is available
    if (weatherData == null) {
      return const Center(child: Text('No data available'));
    }

    // Get data points for the chart
    final spots = getWeeklyData();

    // Calculate the current time in the location's timezone
    final timezone = weatherData!['city']['timezone'] as int;
    final timezoneOffset = Duration(seconds: timezone);
    final locationNow = DateTime.now().toUtc().add(timezoneOffset);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 24.0),
        child: LineChart(
          LineChartData(
            // Grid configuration
            gridData: const FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 200,
              verticalInterval: 1,
            ),
            // Configure chart titles and labels
            titlesData: FlTitlesData(
              // Hide right and top titles
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              // Configure bottom (x-axis) titles
              bottomTitles: AxisTitles(
                axisNameWidget: const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text('Next 5 Days'),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    // Display day of week for each data point
                    final date = locationNow.add(Duration(days: value.toInt()));
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(DateFormat('E').format(date)),
                    );
                  },
                ),
              ),
              // Configure left (y-axis) titles
              leftTitles: AxisTitles(
                axisNameWidget: const Padding(
                  padding: EdgeInsets.only(bottom: 24.0, right: 24.0),
                  child: Text('Average Solar Power (W/m²)'),
                ),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 200,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString());
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            // Chart range configuration
            minX: 0,
            maxX: 4, // 5 days (0-4)
            minY: 0,
            maxY: 1000,
            // Line configuration
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
