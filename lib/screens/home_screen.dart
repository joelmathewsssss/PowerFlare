import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

import '../models/user.dart';
import '../models/power_source.dart';
import '../models/chat_message.dart';
import '../screens/today_forecast_screen.dart';
import '../screens/weekly_forecast_screen.dart';
import '../screens/power_map_screen.dart';
import '../screens/power_talk_screen.dart';
import '../utils/solar_calculator.dart';
import '../widgets/power_source_form.dart';

/// Main home screen with tabs for different features
class HomeScreen extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const HomeScreen({
    Key? key,
    required this.user,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  Position? _currentPosition;
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;
  GoogleMapController? _mapController;
  bool _showMap = false;
  final Map<MarkerId, Marker> _markers = {};
  final Map<MarkerId, PowerSource> _powerSources = {};
  bool _isAddingMarker = false;
  bool _isDialogOpen = false;
  final _logger = Logger('HomeScreen');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _getCurrentLocation();
    _loadPowerSources();
  }

  @override
  void dispose() {
    // Save all data when the app is closed
    _savePowerSources();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // Handle tab changes and reset dialog states
  void _handleTabChange() {
    if (_tabController.indexIsChanging ||
        _tabController.animation!.value != _tabController.index) {
      debugPrint('Tab changing to index: ${_tabController.index}');
      // Reset dialog states when changing tabs
      _resetDialogStates();
    }
  }

  // Reset all dialog state flags
  void _resetDialogStates() {
    if (_isDialogOpen || _isAddingMarker) {
      debugPrint(
          'Resetting dialog states: isDialogOpen=$_isDialogOpen, isAddingMarker=$_isAddingMarker');
      setState(() {
        _isDialogOpen = false;
        _isAddingMarker = false;
      });
    }
  }

  // Ensure all user data is saved
  Future<void> _saveAllUserData() async {
    await _savePowerSources();
    // Add any other data saving operations here
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get API key from .env file
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];

      // Check if API key is missing or using the default placeholder
      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'YOUR_OPENWEATHER_API_KEY') {
        throw 'OpenWeather API key not found or invalid. Please add your API key to the .env file.';
      }

      // Build API URL with current location
      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=$apiKey&units=metric');

      _logger.info(
          'Fetching weather data from: ${url.toString().replaceAll(apiKey, '[REDACTED]')}');

      // Make API request
      final response = await http.get(url);
      _logger.info('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Parse successful response
        final data = json.decode(response.body);
        _logger.info(
            'City: ${data['city']['name']}, Timezone: ${data['city']['timezone']}');
        _logger.info('Number of forecasts: ${data['list']?.length ?? 0}');

        setState(() {
          _weatherData = data;
          _isLoading = false;
          _errorMessage = null;
        });
      } else if (response.statusCode == 401) {
        // Handle unauthorized error (invalid API key)
        throw 'Invalid OpenWeather API key. Please check your API key in the .env file.';
      } else {
        // Handle other API errors
        throw 'Failed to fetch weather data (Status: ${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Weather API Error: $e';
        _isLoading = false;
        _weatherData = null;
      });

      // Show error dialog for API key issues
      if (e.toString().contains('API key')) {
        _showApiKeyErrorDialog();
      }
    }
  }

  /// Show dialog with instructions for fixing API key issues
  void _showApiKeyErrorDialog() {
    // Prevent showing dialog if one is already open
    if (_isDialogOpen) return;

    setState(() => _isDialogOpen = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('API Key Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
                'PowerFlare requires an OpenWeather API key to function properly.'),
            SizedBox(height: 16),
            Text('To get an API key:'),
            SizedBox(height: 8),
            Text('1. Sign up at openweathermap.org'),
            Text('2. Go to your API keys section'),
            Text('3. Copy your API key'),
            Text('4. Add it to the .env file in your project root'),
            SizedBox(height: 16),
            Text('Format of .env file:'),
            SizedBox(height: 8),
            Text('OPENWEATHER_API_KEY=your_api_key_here',
                style: TextStyle(fontFamily: 'monospace')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isDialogOpen = false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    ).then((_) => setState(() => _isDialogOpen = false));
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
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

  void _addMarkerWithNote(LatLng position) {
    // Only allow adding markers when explicitly in the Power Map tab
    // and when the user has tapped on the map to add a marker
    if (_isAddingMarker ||
        _isDialogOpen ||
        _tabController.index != 2 ||
        _showMap) {
      debugPrint(
          'Prevented opening form: isAddingMarker=$_isAddingMarker, isDialogOpen=$_isDialogOpen, tabIndex=${_tabController.index}, showMap=$_showMap');
      return;
    }

    // Set flags to prevent multiple dialogs
    setState(() {
      _isAddingMarker = true;
      _isDialogOpen = true;
    });

    debugPrint('Opening power source form dialog');
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            // Reset flags when dialog is dismissed with back button
            setState(() {
              _isAddingMarker = false;
              _isDialogOpen = false;
            });
            return true;
          },
          child: PowerSourceForm(
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
          ),
        );
      },
    ).then((_) {
      debugPrint('Power source form dialog closed');
      setState(() {
        _isAddingMarker = false;
        _isDialogOpen = false;
      });
    });
  }

  Future<void> _loadPowerSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourcesJson = prefs.getStringList('powerSources') ?? [];

      final sources = sourcesJson
          .map((sourceStr) => PowerSource.fromJson(json.decode(sourceStr)))
          .toList();

      setState(() {
        _markers.clear();
        _powerSources.clear();

        for (var powerSource in sources) {
          final markerId = MarkerId(powerSource.id);
          _powerSources[markerId] = powerSource;
          _markers[markerId] = _createMarker(markerId, powerSource);
        }
      });
    } catch (e) {
      _logger.severe('Error loading power sources: $e');
    }
  }

  Future<void> _savePowerSources() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sourcesJson = _powerSources.values
          .map((source) => json.encode(source.toJson()))
          .toList();
      await prefs.setStringList('powerSources', sourcesJson);
    } catch (e) {
      _logger.severe('Error saving power sources: $e');
    }
  }

  Future<void> _addPowerSource(PowerSource source) async {
    try {
      final markerId = MarkerId(source.id);

      // Add to local state
      setState(() {
        _powerSources[markerId] = source;
        _markers[markerId] = _createMarker(markerId, source);
      });

      // Save to SharedPreferences
      await _savePowerSources();
    } catch (e) {
      _logger.severe('Error adding power source: $e');
    }
  }

  Future<void> _deletePowerSource(MarkerId markerId) async {
    try {
      final source = _powerSources[markerId];
      if (source != null) {
        // Remove from local state
        setState(() {
          _markers.remove(markerId);
          _powerSources.remove(markerId);
        });

        // Save updated list to SharedPreferences
        await _savePowerSources();
      }
    } catch (e) {
      _logger.severe('Error deleting power source: $e');
    }
  }

  Future<void> _addChatMessage(MarkerId markerId, ChatMessage message) async {
    try {
      final source = _powerSources[markerId];
      if (source != null) {
        // Add message to local state
        final updatedMessages = List<ChatMessage>.from(source.chatMessages)
          ..add(message);
        final updatedSource = PowerSource(
          id: source.id,
          name: source.name,
          description: source.description,
          powerType: source.powerType,
          isFree: source.isFree,
          position: source.position,
          chatMessages: updatedMessages,
        );

        setState(() {
          _powerSources[markerId] = updatedSource;
        });

        // Save updated power sources to SharedPreferences
        await _savePowerSources();
      }
    } catch (e) {
      _logger.severe('Error adding chat message: $e');
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
    // Prevent opening if a dialog is already open
    if (_isDialogOpen) {
      debugPrint('Prevented opening details: isDialogOpen=$_isDialogOpen');
      return;
    }

    // Set dialog flag to prevent other dialogs from opening
    setState(() => _isDialogOpen = true);

    debugPrint('Opening power source details dialog');
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async {
            // Reset flag when dialog is dismissed with back button
            setState(() => _isDialogOpen = false);
            return true;
          },
          child: GestureDetector(
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
                            Future.delayed(const Duration(milliseconds: 100),
                                () {
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
                    final markerId = MarkerId(source.id);
                    setState(() {
                      _markers.remove(markerId);
                      _powerSources.remove(markerId);
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
          ),
        );
      },
    ).then((_) {
      debugPrint('Power source details dialog closed');
      setState(() => _isDialogOpen = false);
    });
  }

  void _showChatDialog(PowerSource source) {
    // Prevent opening if a dialog is already open
    if (_isDialogOpen) {
      debugPrint('Prevented opening chat: isDialogOpen=$_isDialogOpen');
      return;
    }

    // Set dialog flag to prevent other dialogs from opening
    setState(() => _isDialogOpen = true);

    final TextEditingController messageController = TextEditingController();
    final ScrollController scrollController = ScrollController();

    debugPrint('Opening chat dialog');
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async {
                // Reset flag when dialog is dismissed with back button
                this.setState(() => _isDialogOpen = false);
                return true;
              },
              child: GestureDetector(
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
                                      senderName: widget.user.username,
                                    );
                                    setState(() {
                                      source.chatMessages.add(message);
                                    });
                                    messageController.clear();
                                    _savePowerSources();
                                    scrollController.animateTo(
                                      scrollController.position.maxScrollExtent,
                                      duration:
                                          const Duration(milliseconds: 300),
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
              ),
            );
          },
        );
      },
    ).then((_) {
      debugPrint('Chat dialog closed');
      messageController.dispose();
      scrollController.dispose();
      setState(() => _isDialogOpen = false);
    });
  }

  void _clearMarkers() {
    setState(() {
      _markers.clear();
      _powerSources.clear();
      _savePowerSources();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PowerFlare'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Today's Forecast"),
            Tab(text: '5-Day Forecast'),
            Tab(text: 'Power Map'),
            Tab(text: 'Power Talk'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // Reset dialog states before showing map
              _resetDialogStates();
              _showLocationPicker();
            },
            tooltip: 'Select Location on Map',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Reset dialog states before showing logout dialog
              _resetDialogStates();

              // Save all data before logging out
              _saveAllUserData();

              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text(
                      'Are you sure you want to log out? Your data will be saved.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onLogout();
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Reset dialog states before showing profile dialog
              _resetDialogStates();

              // Show profile dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Profile'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(widget.user.username),
                        subtitle: widget.user.email.isNotEmpty
                            ? Text(widget.user.email)
                            : const Text('No email provided'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.password),
                        title: const Text('Password'),
                        subtitle: Text(widget.user.password),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'View Profile',
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
                        TodayForecastScreen(
                          weatherData: _weatherData,
                          calculateSolarPower: (forecast) =>
                              SolarCalculator.calculateSolarPower(
                                  forecast, _weatherData!['city']),
                          getSolarCondition: SolarCalculator.getSolarCondition,
                          getTodayHourlyData: () =>
                              SolarCalculator.getTodayHourlyData(_weatherData!),
                        ),
                        WeeklyForecastScreen(
                          weatherData: _weatherData,
                          getWeeklyData: () =>
                              SolarCalculator.getWeeklyData(_weatherData!),
                        ),
                        PowerMapScreen(
                          mapController: _mapController,
                          markers: _markers,
                          powerSources: _powerSources,
                          onMapCreated: _onMapCreated,
                          addMarkerWithNote: _addMarkerWithNote,
                          showPowerSourceDetails: _showPowerSourceDetails,
                          isAddingMarker: _isAddingMarker,
                          isDialogOpen: _isDialogOpen,
                          tabIndex: _tabController.index,
                          currentPosition: _currentPosition,
                          weatherData: _weatherData,
                          calculateSolarPower: (forecast) =>
                              SolarCalculator.calculateSolarPower(
                                  forecast, _weatherData!['city']),
                        ),
                        PowerTalkScreen(
                          user: widget.user,
                        ),
                      ],
                    ),
      floatingActionButton: _showMap
          ? null
          : FloatingActionButton(
              onPressed: () {
                // Reset dialog states before getting current location
                _resetDialogStates();
                _getCurrentLocation();
              },
              tooltip: 'Get Current Location',
              child: const Icon(Icons.my_location),
            ),
    );
  }
}
