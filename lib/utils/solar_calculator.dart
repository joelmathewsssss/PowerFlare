import 'dart:math';
import 'package:logging/logging.dart';
import 'package:fl_chart/fl_chart.dart';

class SolarCalculator {
  static double calculateSolarPower(
      Map<String, dynamic> weatherData, Map<String, dynamic> cityData) {
    final clouds = weatherData['clouds']['all'] as int;
    final temp = weatherData['main']['temp'] as double;

    // Get timezone offset from the API response
    final timezone = cityData['timezone'] as int;
    final apiOffset = Duration(seconds: timezone);

    // Convert timestamp to location's local time
    final forecastUtc = DateTime.fromMillisecondsSinceEpoch(
      weatherData['dt'] * 1000,
      isUtc: true,
    );
    final localTime = forecastUtc.add(apiOffset);

    // Base solar radiation (W/m²) considering clear sky
    const maxSolarRadiation = 1000.0;

    // Time of day factor (0.0 to 1.0)
    final hour = localTime.hour + (localTime.minute / 60.0);
    final dayFactor = _calculateDayFactor(hour);

    // Season factor (0.7 to 1.0)
    final seasonFactor = _calculateSeasonFactor(localTime);

    // Cloud cover factor (0.0 to 1.0)
    final cloudFactor = 1 - (clouds / 100) * 0.75;

    // Temperature efficiency factor
    final tempFactor = 1 - max(0, temp - 25) * 0.004;

    final estimatedPower =
        maxSolarRadiation * dayFactor * seasonFactor * cloudFactor * tempFactor;

    // Enhanced logging for time calculations
    final log = Logger('SolarCalculation');
    log.fine('Time calculation details:'
        '\nForecast UTC: ${forecastUtc.toString()}'
        '\nAPI offset: ${apiOffset.inHours} hours'
        '\nLocal time: ${localTime.toString()}'
        '\nHour: ${hour.toStringAsFixed(2)}'
        '\nDay factor: ${dayFactor.toStringAsFixed(2)}'
        '\nSeason factor: ${seasonFactor.toStringAsFixed(2)}'
        '\nCloud factor: ${cloudFactor.toStringAsFixed(2)}'
        '\nTemp factor: ${tempFactor.toStringAsFixed(2)}'
        '\nEstimated power: ${estimatedPower.toStringAsFixed(2)} W/m²');

    return estimatedPower;
  }

  static double _calculateDayFactor(double hour) {
    // Simplified solar position model
    // Peak at noon (hour 12), zero at night (before 6 or after 18)
    if (hour < 6 || hour > 18) {
      return 0.0;
    }
    // Creates a sine curve peaking at noon
    return sin((hour - 6) * pi / 12);
  }

  static double _calculateSeasonFactor(DateTime localDate) {
    // Simplified seasonal variation
    // Northern hemisphere: peak in summer (June/July), lowest in winter (December/January)
    final dayOfYear =
        localDate.difference(DateTime(localDate.year, 1, 1)).inDays;
    // Sine wave with period of 1 year, amplitude of 0.15 centered at 0.85
    return 0.85 + 0.15 * sin((dayOfYear - 172) * 2 * pi / 365);
  }

  static String getSolarCondition(double power) {
    if (power >= 800) return 'Excellent';
    if (power >= 600) return 'Very Good';
    if (power >= 400) return 'Good';
    if (power >= 200) return 'Fair';
    if (power > 0) return 'Poor';
    return 'None';
  }

  static List<FlSpot> getTodayHourlyData(Map<String, dynamic> weatherData) {
    if (weatherData == null) {
      return [];
    }

    final spots = <FlSpot>[];
    final log = Logger('TodayForecast');

    try {
      // Get timezone offset from the API response
      final timezone = weatherData['city']['timezone'] as int;
      final apiOffset = Duration(seconds: timezone);

      // Calculate current time in the location's timezone
      final utcNow = DateTime.now().toUtc();
      final locationNow = utcNow.add(apiOffset);

      log.info('Time calculation:'
          '\nUTC now: ${utcNow.toString()}'
          '\nAPI offset: ${apiOffset.inHours} hours'
          '\nLocation time: ${locationNow.toString()}');

      // Get all forecasts for today
      final todayForecasts = weatherData['list'].where((forecast) {
        final forecastUtc = DateTime.fromMillisecondsSinceEpoch(
          forecast['dt'] * 1000,
          isUtc: true,
        );
        final forecastLocal = forecastUtc.add(apiOffset);

        return forecastLocal.year == locationNow.year &&
            forecastLocal.month == locationNow.month &&
            forecastLocal.day == locationNow.day;
      }).toList();

      // Sort forecasts by time
      todayForecasts.sort((a, b) {
        final timeA =
            DateTime.fromMillisecondsSinceEpoch(a['dt'] * 1000, isUtc: true);
        final timeB =
            DateTime.fromMillisecondsSinceEpoch(b['dt'] * 1000, isUtc: true);
        return timeA.compareTo(timeB);
      });

      // Process each forecast
      for (var forecast in todayForecasts) {
        final forecastUtc = DateTime.fromMillisecondsSinceEpoch(
          forecast['dt'] * 1000,
          isUtc: true,
        );
        final forecastLocal = forecastUtc.add(apiOffset);
        final hour =
            forecastLocal.hour.toDouble() + (forecastLocal.minute / 60.0);
        final power = calculateSolarPower(forecast, weatherData['city']);

        spots.add(FlSpot(hour, power));
        log.info('Added forecast point: Hour: $hour, Power: $power W/m²');
      }

      // Add zero points for beginning and end of day if needed
      if (spots.isNotEmpty) {
        if (spots.first.x > 0) {
          spots.insert(0, FlSpot(0, 0));
        }
        if (spots.last.x < 24) {
          spots.add(FlSpot(24, 0));
        }
      }

      spots.sort((a, b) => a.x.compareTo(b.x));
      log.info('Generated ${spots.length} data points');
    } catch (e, stackTrace) {
      log.severe('Error processing today\'s forecast: $e');
      log.severe('Stack trace: $stackTrace');
    }

    return spots;
  }

  static List<FlSpot> getWeeklyData(Map<String, dynamic> weatherData) {
    if (weatherData == null) return [];
    final spots = <FlSpot>[];
    final dailyAverages = <int, List<double>>{};

    for (var forecast in weatherData['list']) {
      final date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      final power = calculateSolarPower(forecast, weatherData['city']);
      dailyAverages.putIfAbsent(date.day, () => []);
      dailyAverages[date.day]!.add(power);
    }

    var dayIndex = 0;
    dailyAverages.forEach((day, powers) {
      final avgPower = powers.reduce((a, b) => a + b) / powers.length;
      spots.add(FlSpot(dayIndex.toDouble(), avgPower));
      dayIndex++;
    });

    return spots;
  }
}
