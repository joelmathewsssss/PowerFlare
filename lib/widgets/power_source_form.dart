import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/power_source.dart';

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
