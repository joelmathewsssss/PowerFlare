import 'package:flutter/material.dart';

void main() {
  runApp(SolarFarmApp());
}

class SolarFarmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power Flare',
      theme: ThemeData(primarySwatch: Colors.green),
      home: RoleSelectionScreen(),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BusinessScreen()),
                );
              },
              child: Text('Business (Solar Farm)'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserScreen()),
                );
              },
              child: Text('User'),
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessScreen extends StatefulWidget {
  @override
  _BusinessScreenState createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  final TextEditingController latController = TextEditingController();
  final TextEditingController lonController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final List<Map<String, dynamic>> solarFarms = [];

  double estimatePower(double area) {
    return area * 5.0; // Simplified estimation (5kW per sq meter)
  }

  double calculateCost(double power) {
    return (power * 0.1) * 0.9; // Cost with 10% discount
  }

  void addSolarFarm() {
    final double latitude = double.tryParse(latController.text) ?? 0.0;
    final double longitude = double.tryParse(lonController.text) ?? 0.0;
    final double area = double.tryParse(areaController.text) ?? 0.0;
    final double power = estimatePower(area);
    final double cost = calculateCost(power);

    setState(() {
      solarFarms.add({
        'latitude': latitude,
        'longitude': longitude,
        'area': area,
        'power': power,
        'cost': cost,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Business - Add Solar Farm')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: latController,
              decoration: InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: lonController,
              decoration: InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: areaController,
              decoration: InputDecoration(labelText: 'Solar Panel Area (sq m)'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(onPressed: addSolarFarm, child: Text('Add Farm')),
          ],
        ),
      ),
    );
  }
}

class UserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User - Solar Farms List')),
      body: ListView.builder(
        itemCount: 5, // Placeholder count
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Solar Farm ${index + 1}'),
            subtitle: Text(
              'Power: ${(index + 1) * 50} kW | Cost: \$${(index + 1) * 5}',
            ),
          );
        },
      ),
    );
  }
}
