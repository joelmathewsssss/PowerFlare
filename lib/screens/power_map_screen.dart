import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/power_source.dart';
import '../widgets/power_source_form.dart';
import 'dart:math';

/// Screen that displays a map of solar power potential by region
class PowerMapScreen extends StatelessWidget {
  final GoogleMapController? mapController;
  final Map<MarkerId, Marker> markers;
  final Map<MarkerId, PowerSource> powerSources;
  final Function(GoogleMapController) onMapCreated;
  final Function(LatLng) addMarkerWithNote;
  final Function(PowerSource) showPowerSourceDetails;
  final bool isAddingMarker;
  final bool isDialogOpen;
  final int tabIndex;
  final Position? currentPosition;
  final Map<String, dynamic>? weatherData;
  final Function(Map<String, dynamic>) calculateSolarPower;

  const PowerMapScreen({
    Key? key,
    required this.mapController,
    required this.markers,
    required this.powerSources,
    required this.onMapCreated,
    required this.addMarkerWithNote,
    required this.showPowerSourceDetails,
    required this.isAddingMarker,
    required this.isDialogOpen,
    required this.tabIndex,
    required this.currentPosition,
    required this.weatherData,
    required this.calculateSolarPower,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show placeholder if no data is available
    if (weatherData == null) {
      return const Center(child: Text('No data available'));
    }

    // Get location name from weather data
    final cityName = weatherData!['city']['name'] as String;

    // Get current forecast
    final forecasts = List<dynamic>.from(weatherData!['list']);
    final currentForecast = forecasts.first;

    // Calculate solar power for current forecast
    final currentPower = calculateSolarPower(currentForecast);

    // Generate random power values for nearby regions
    final random = Random();
    final nearbyRegions =
        _generateNearbyRegions(cityName, currentPower, random);

    return Stack(
      children: <Widget>[
        GoogleMap(
          onMapCreated: onMapCreated,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              currentPosition?.latitude ?? 40.7128,
              currentPosition?.longitude ?? -74.0060,
            ),
            zoom: 11.0,
          ),
          markers: Set<Marker>.of(markers.values),
          onTap: (tabIndex == 2 && !isAddingMarker && !isDialogOpen)
              ? (LatLng position) {
                  // Only add marker if we're in the Power Map tab and no dialogs are open
                  if (tabIndex == 2 && !isAddingMarker && !isDialogOpen) {
                    addMarkerWithNote(position);
                  }
                }
              : null,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          mapToolbarEnabled: true,
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map title
              Text(
                'Solar Power Map',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Showing solar potential for $cityName and nearby regions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),

              // Map legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem(context, Colors.red, 'Low'),
                  _buildLegendItem(context, Colors.orange, 'Medium'),
                  _buildLegendItem(context, Colors.green, 'High'),
                ],
              ),
              const SizedBox(height: 24),

              // Map visualization
              Expanded(
                child: Center(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: nearbyRegions.length,
                    itemBuilder: (context, index) {
                      final region = nearbyRegions[index];
                      return _buildRegionTile(context, region);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a legend item with color and label
  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  /// Build a region tile with power information
  Widget _buildRegionTile(BuildContext context, Map<String, dynamic> region) {
    // Determine color based on power level
    final power = region['power'] as double;
    final color = _getPowerColor(power);

    // Highlight current location
    final isCurrent = region['isCurrent'] as bool;
    final borderColor = isCurrent ? Colors.blue : Colors.grey;
    final borderWidth = isCurrent ? 3.0 : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              region['name'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${power.toInt()} W/m²',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on power level
  Color _getPowerColor(double power) {
    if (power < 300) return Colors.red;
    if (power < 600) return Colors.orange;
    return Colors.green;
  }

  /// Generate nearby regions with random power values
  List<Map<String, dynamic>> _generateNearbyRegions(
    String cityName,
    double currentPower,
    Random random,
  ) {
    // Create a list of nearby region names
    final directions = [
      'North',
      'South',
      'East',
      'West',
      'Northeast',
      'Northwest',
      'Southeast',
      'Southwest',
    ];

    // Generate regions with random power values
    final regions = <Map<String, dynamic>>[];

    // Add current location in the center
    regions.add({
      'name': cityName,
      'power': currentPower,
      'isCurrent': true,
    });

    // Add nearby regions with randomized power values
    for (final direction in directions) {
      // Randomize power within 30% of current power
      final powerVariation = currentPower * 0.3;
      final regionPower = currentPower +
          (random.nextDouble() * powerVariation * 2) -
          powerVariation;

      regions.add({
        'name': '$direction $cityName',
        'power': regionPower.clamp(0, 1000),
        'isCurrent': false,
      });
    }

    return regions;
  }
}
