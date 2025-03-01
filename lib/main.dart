import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  final String id;
  final String message;
  final DateTime timestamp;
  final String senderName;

  ChatMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.senderName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'senderName': senderName,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        senderName: json['senderName'] as String,
      );
}

class PowerSource {
  final String id;
  final String name;
  final String description;
  final String powerType;
  final bool isFree;
  final LatLng position;
  final List<ChatMessage> chatMessages;

  PowerSource({
    required this.id,
    required this.name,
    required this.description,
    required this.powerType,
    required this.isFree,
    required this.position,
    List<ChatMessage>? chatMessages,
  }) : chatMessages = chatMessages ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'powerType': powerType,
        'isFree': isFree,
        'position': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'chatMessages': chatMessages.map((msg) => msg.toJson()).toList(),
      };

  factory PowerSource.fromJson(Map<String, dynamic> json) => PowerSource(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        powerType: json['powerType'] as String,
        isFree: json['isFree'] as bool,
        position: LatLng(
          json['position']['latitude'] as double,
          json['position']['longitude'] as double,
        ),
        chatMessages: (json['chatMessages'] as List?)
                ?.map(
                    (msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class PowerSourceForm extends StatefulWidget {
  final LatLng position;
  final Function(PowerSource) onAdd;
  final VoidCallback onCancel;

  const PowerSourceForm({
    super.key,
    required this.position,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  State<PowerSourceForm> createState() => _PowerSourceFormState();
}

class _PowerSourceFormState extends State<PowerSourceForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _powerType = 'AC';
  bool _isFree = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Power Source'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter power source name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter power source description',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text(
                  'Current Type:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('AC'),
                    value: 'AC',
                    groupValue: _powerType,
                    onChanged: (value) {
                      setState(() => _powerType = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('DC'),
                    value: 'DC',
                    groupValue: _powerType,
                    onChanged: (value) {
                      setState(() => _powerType = value!);
                    },
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Free Service'),
              value: _isFree,
              onChanged: (bool value) {
                setState(() => _isFree = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _descriptionController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please fill in all fields'),
                ),
              );
              return;
            }

            final powerSource = PowerSource(
              id: DateTime.now().toString(),
              name: _nameController.text,
              description: _descriptionController.text,
              powerType: _powerType,
              isFree: _isFree,
              position: widget.position,
            );

            widget.onAdd(powerSource);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  await dotenv.load(fileName: ".env");
  runApp(const PowerFlareApp());
}

class PowerFlareApp extends StatelessWidget {
  const PowerFlareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power Flare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: ClipRRect(
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.solar_power,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Power Flare',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Power Managment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Get Started'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;
  GoogleMapController? _mapController;
  bool _showMap = false;
  final Map<MarkerId, Marker> _markers = {};
  final Map<MarkerId, String> _markerNotes = {};
  final Map<MarkerId, PowerSource> _powerSources = {};
  bool _isAddingMarker = false;
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _isDialogOpen = false;
        });
      }
    });
    _getCurrentLocation();
    _loadPowerSources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      setState(() => _isLoading = true);
      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
      await _fetchWeatherData();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    if (_currentPosition == null) return;
    final log = Logger('WeatherAPI');

    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null) throw 'API key not found';

      final url =
          'https://api.openweathermap.org/data/2.5/forecast?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=$apiKey&units=metric';
      log.info('Fetching weather data from: $url');

      final response = await http.get(Uri.parse(url));
      log.info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log.info(
            'City: ${data['city']['name']}, Timezone: ${data['city']['timezone']}');
        log.info('Number of forecasts: ${data['list']?.length ?? 0}');
        log.info(
            'First forecast time: ${data['list']?[0]?['dt_txt'] ?? 'N/A'}');

        setState(() {
          _weatherData = data;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        throw 'Failed to fetch weather data (Status: ${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Weather API Error: $e';
        _isLoading = false;
      });
    }
  }

  double _calculateSolarPower(Map<String, dynamic> weatherData) {
    final clouds = weatherData['clouds']['all'] as int;
    final temp = weatherData['main']['temp'] as double;

    // Get timezone offset from the API response
    final timezone = _weatherData!['city']['timezone'] as int;
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

  double _calculateDayFactor(double hour) {
    // Simplified solar position model
    // Peak at noon (hour 12), zero at night (before 6 or after 18)
    if (hour < 6 || hour > 18) {
      return 0.0;
    }
    // Creates a sine curve peaking at noon
    return sin((hour - 6) * pi / 12);
  }

  double _calculateSeasonFactor(DateTime localDate) {
    // Simplified seasonal variation
    // Northern hemisphere: peak in summer (June/July), lowest in winter (December/January)
    final dayOfYear =
        localDate.difference(DateTime(localDate.year, 1, 1)).inDays;
    // Sine wave with period of 1 year, amplitude of 0.15 centered at 0.85
    return 0.85 + 0.15 * sin((dayOfYear - 172) * 2 * pi / 365);
  }

  String _getSolarCondition(double power) {
    if (power >= 800) return 'Excellent';
    if (power >= 600) return 'Very Good';
    if (power >= 400) return 'Good';
    if (power >= 200) return 'Fair';
    if (power > 0) return 'Poor';
    return 'None';
  }

  List<FlSpot> _getTodayHourlyData() {
    if (_weatherData == null) {
      debugPrint('_getTodayHourlyData: Weather data is null');
      return [];
    }

    final spots = <FlSpot>[];
    final log = Logger('TodayForecast');

    try {
      // Get timezone offset from the API response
      final timezone = _weatherData!['city']['timezone'] as int;
      final apiOffset = Duration(seconds: timezone);

      // Calculate current time in the location's timezone
      final utcNow = DateTime.now().toUtc();
      final locationNow = utcNow.add(apiOffset);

      log.info('Time calculation:'
          '\nUTC now: ${utcNow.toString()}'
          '\nAPI offset: ${apiOffset.inHours} hours'
          '\nLocation time: ${locationNow.toString()}');

      // Get all forecasts for today
      final todayForecasts = _weatherData!['list'].where((forecast) {
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
        final power = _calculateSolarPower(forecast);

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

  List<FlSpot> _getWeeklyData() {
    if (_weatherData == null) return [];
    final spots = <FlSpot>[];
    final dailyAverages = <int, List<double>>{};

    for (var forecast in _weatherData!['list']) {
      final date = DateTime.fromMillisecondsSinceEpoch(forecast['dt'] * 1000);
      final power = _calculateSolarPower(forecast);
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

  Widget _buildTodayTab() {
    if (_weatherData == null) {
      return const Center(child: Text('No data available'));
    }

    // Get timezone offset from the API response and device
    final timezone = _weatherData!['city']['timezone'] as int;
    final deviceOffset = DateTime.now().timeZoneOffset;
    final apiOffset = Duration(seconds: timezone);

    // Calculate the current time in the selected location
    final now = DateTime.now();
    final utcNow = now.toUtc();
    final locationNow = utcNow.add(apiOffset);

    final log = Logger('TimeDebug');
    log.info('Time debug:'
        '\nDevice time: ${now.toString()}'
        '\nDevice offset: ${deviceOffset.inHours} hours'
        '\nUTC time: ${utcNow.toString()}'
        '\nAPI timezone offset: ${apiOffset.inHours} hours'
        '\nLocation time: ${locationNow.toString()}');

    // Get the most recent forecast
    final forecasts = List<dynamic>.from(_weatherData!['list']);
    forecasts.sort((a, b) {
      final timeA =
          DateTime.fromMillisecondsSinceEpoch(a['dt'] * 1000, isUtc: true);
      final timeB =
          DateTime.fromMillisecondsSinceEpoch(b['dt'] * 1000, isUtc: true);
      return timeA.compareTo(timeB);
    });

    // Find the forecast closest to current time in the location's timezone
    var closestForecast = forecasts.first;
    var smallestDiff = Duration(days: 1);

    for (var forecast in forecasts) {
      final forecastUtc = DateTime.fromMillisecondsSinceEpoch(
        forecast['dt'] * 1000,
        isUtc: true,
      );
      final forecastLocal = forecastUtc.add(apiOffset);
      final diff = forecastLocal.difference(locationNow).abs();

      log.fine('Forecast time check:'
          '\nForecast UTC: ${forecastUtc.toString()}'
          '\nForecast local: ${forecastLocal.toString()}'
          '\nDiff: ${diff.inMinutes} minutes');

      if (diff < smallestDiff) {
        smallestDiff = diff;
        closestForecast = forecast;
      }
    }

    final currentPower = _calculateSolarPower(closestForecast);
    final currentCloudCover = closestForecast['clouds']['all'] as int;
    final condition = _getSolarCondition(currentPower);

    // Get forecast time in location's timezone
    final forecastUtc = DateTime.fromMillisecondsSinceEpoch(
      closestForecast['dt'] * 1000,
      isUtc: true,
    );
    final forecastLocal = forecastUtc.add(apiOffset);

    log.info('Selected forecast:'
        '\nForecast UTC: ${forecastUtc.toString()}'
        '\nForecast local: ${forecastLocal.toString()}');

    final timeString = DateFormat('h:mm a').format(forecastLocal);
    final dateString = DateFormat('E, MMM d').format(forecastLocal);
    final cityName = _weatherData!['city']['name'];

    final spots = _getTodayHourlyData();

    return Column(
      children: [
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 200,
                  verticalInterval: 2,
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Hour of Day'),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}:00');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Padding(
                      padding: EdgeInsets.only(bottom: 16, right: 8),
                      child: Text('Solar Power (W/m²)'),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 200,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const Text('');
                        return Text(value.toInt().toString());
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
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
      ],
    );
  }

  Widget _buildWeeklyTab() {
    if (_weatherData == null)
      return const Center(child: Text('No data available'));

    final spots = _getWeeklyData();

    // Get timezone offset from the API response
    final timezone = _weatherData!['city']['timezone'] as int;
    final timezoneOffset = Duration(seconds: timezone);
    final locationNow = DateTime.now().toUtc().add(timezoneOffset);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 200,
            verticalInterval: 1,
          ),
          titlesData: FlTitlesData(
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text('Next 7 Days'),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final date = locationNow.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Text(DateFormat('E').format(date)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text('Solar Power (W/m²)'),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 200,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 1000,
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
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _updateLocationFromMap(LatLng position) async {
    setState(() {
      _currentPosition = Position(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    });

    // Animate camera to new position
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    }

    // Fetch weather data for new location
    await _fetchWeatherData();

    // Close map after a short delay to show the marker
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showMap = false);
      }
    });
  }

  void _showLocationPicker() {
    setState(() => _showMap = true);
  }

  Widget _buildMap() {
    // Create a marker for current location
    final currentLocationMarker = _currentPosition != null
        ? {
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              infoWindow: const InfoWindow(
                title: 'Current Location',
                snippet: 'This location will be used for solar forecasting',
              ),
            ),
          }
        : <Marker>{};

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            setState(() {
              _mapController = controller;
            });
            debugPrint('Map controller created successfully');
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _currentPosition?.latitude ?? 40.7128,
              _currentPosition?.longitude ?? -74.0060,
            ),
            zoom: 11.0,
          ),
          onTap: (LatLng position) {
            debugPrint(
                'Map tapped at: ${position.latitude}, ${position.longitude}');
            _updateLocationFromMap(position);
          },
          markers: currentLocationMarker,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
        ),
        if (_mapController == null)
          Container(
            color: Colors.white70,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading Map...'),
                  const SizedBox(height: 8),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => setState(() => _showMap = false),
            child: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Power Flare'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Today's Forecast"),
            Tab(text: '7-Day Forecast'),
            Tab(text: 'Power Map'),
            Tab(text: 'Power Talk'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: _showLocationPicker,
            tooltip: 'Select Location on Map',
          ),
        ],
      ),
      body: _showMap
          ? _buildMap()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTodayTab(),
                        _buildWeeklyTab(),
                        _buildPowerMapTab(),
                        _buildPowerTalkTab(),
                      ],
                    ),
      floatingActionButton: _showMap
          ? null
          : FloatingActionButton(
              onPressed: _getCurrentLocation,
              tooltip: 'Get Current Location',
              child: const Icon(Icons.my_location),
            ),
    );
  }

  Widget _buildPowerMapTab() {
    return Stack(
      children: <Widget>[
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            setState(() {
              _mapController = controller;
            });
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _currentPosition?.latitude ?? 40.7128,
              _currentPosition?.longitude ?? -74.0060,
            ),
            zoom: 11.0,
          ),
          markers: Set<Marker>.of(_markers.values),
          onTap:
              (_tabController.index == 2 && !_isAddingMarker && !_isDialogOpen)
                  ? (LatLng position) {
                      // Only add marker if we're in the Power Map tab and no dialogs are open
                      if (_tabController.index == 2 &&
                          !_isAddingMarker &&
                          !_isDialogOpen) {
                        _addMarkerWithNote(position);
                      }
                    }
                  : null,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
        ),
        if (!_isAddingMarker)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'clearMarkers',
              onPressed: () {
                setState(() {
                  _markers.clear();
                  _powerSources.clear();
                  _savePowerSources();
                });
              },
              child: const Icon(Icons.clear_all),
              tooltip: 'Clear All Markers',
            ),
          ),
      ],
    );
  }

  void _addMarkerWithNote(LatLng position) {
    // Prevent opening if we're already adding a marker, a dialog is open,
    // or we're not in the Power Map tab
    if (_isAddingMarker || _isDialogOpen || _tabController.index != 2) return;

    // Set flags to prevent multiple dialogs
    setState(() {
      _isAddingMarker = true;
      _isDialogOpen = true;
    });

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PowerSourceForm(
          position: position,
          onAdd: (PowerSource powerSource) {
            setState(() {
              final markerId = MarkerId(powerSource.id);
              _powerSources[markerId] = powerSource;
              _markers[markerId] = _createMarker(markerId, powerSource);
            });
            _savePowerSources();
            Navigator.of(dialogContext).pop();
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    ).then((_) {
      setState(() {
        _isAddingMarker = false;
        _isDialogOpen = false;
      });
    });
  }

  Future<void> _loadPowerSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourcesJson = prefs.getString('power_sources');
      if (sourcesJson != null) {
        final List<dynamic> sources = json.decode(sourcesJson);
        setState(() {
          for (var source in sources) {
            final powerSource = PowerSource.fromJson(source);
            final markerId = MarkerId(powerSource.id);
            _powerSources[markerId] = powerSource;
            _markers[markerId] = _createMarker(markerId, powerSource);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading power sources: $e');
    }
  }

  Future<void> _savePowerSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourcesJson = json.encode(
        _powerSources.values.map((source) => source.toJson()).toList(),
      );
      await prefs.setString('power_sources', sourcesJson);
    } catch (e) {
      debugPrint('Error saving power sources: $e');
    }
  }

  Marker _createMarker(MarkerId markerId, PowerSource source) {
    return Marker(
      markerId: markerId,
      position: source.position,
      infoWindow: InfoWindow(
        title: source.name,
        snippet: '${source.powerType} - ${source.isFree ? 'Free' : 'Paid'}',
      ),
      onTap: () => _showPowerSourceDetails(source),
    );
  }

  void _showPowerSourceDetails(PowerSource source) {
    // Set dialog flag to prevent other dialogs from opening
    setState(() => _isDialogOpen = true);
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {},
          child: AlertDialog(
            title: Text(source.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${source.powerType}'),
                const SizedBox(height: 8),
                Text('Status: ${source.isFree ? 'Free' : 'Paid'} Service'),
                const SizedBox(height: 8),
                Text('Description: ${source.description}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Badge(
                      label: Text(source.chatMessages.length.toString()),
                      child: FilledButton.icon(
                        onPressed: () {
                          // Close this dialog first, then open chat dialog
                          Navigator.pop(context);
                          // Use a small delay to ensure the first dialog is fully closed
                          Future.delayed(const Duration(milliseconds: 100), () {
                            if (mounted) {
                              _showChatDialog(source);
                            }
                          });
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Open Chat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _markers.remove(MarkerId(source.id));
                    _powerSources.remove(MarkerId(source.id));
                  });
                  _savePowerSources();
                  Navigator.pop(context);
                },
                child: const Text('Delete'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  void _showChatDialog(PowerSource source) {
    // Set dialog flag to prevent other dialogs from opening
    setState(() => _isDialogOpen = true);
    final TextEditingController messageController = TextEditingController();
    final ScrollController scrollController = ScrollController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return GestureDetector(
              onTap: () {},
              child: AlertDialog(
                title: Text('Chat - ${source.name}'),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: source.chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = source.chatMessages[index];
                            return ListTile(
                              title: Text(message.message),
                              subtitle: Text(
                                '${message.senderName} - ${DateFormat('MMM d, h:mm a').format(message.timestamp)}',
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                if (messageController.text.isNotEmpty) {
                                  final message = ChatMessage(
                                    id: DateTime.now().toString(),
                                    message: messageController.text,
                                    timestamp: DateTime.now(),
                                    senderName: 'User',
                                  );
                                  setState(() {
                                    source.chatMessages.add(message);
                                  });
                                  messageController.clear();
                                  _savePowerSources();
                                  scrollController.animateTo(
                                    scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      messageController.dispose();
      scrollController.dispose();
      setState(() => _isDialogOpen = false);
    });
  }

  Widget _buildPowerTalkTab() {
    if (_powerSources.isEmpty) {
      return const Center(
        child: Text('No power sources added yet. Add some markers on the map!'),
      );
    }

    return ListView.builder(
      itemCount: _powerSources.length,
      itemBuilder: (context, index) {
        final source = _powerSources.values.elementAt(index);
        return ListTile(
          leading: Icon(
            source.powerType == 'AC/DC'
                ? Icons.electrical_services
                : Icons.bolt,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(source.name),
          subtitle:
              Text('${source.powerType} - ${source.isFree ? 'Free' : 'Paid'}'),
          trailing: Badge(
            label: Text(source.chatMessages.length.toString()),
            child: const Icon(Icons.chat),
          ),
          onTap: () => _showChatDialog(source),
        );
      },
    );
  }
}
