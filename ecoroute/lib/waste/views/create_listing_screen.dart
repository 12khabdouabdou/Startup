import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../bloc/listing_bloc.dart';
import '../bloc/listing_event.dart';
import '../bloc/listing_state.dart';
import '../models/waste_listing_model.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  WasteType _selectedWasteType = WasteType.concrete;
  String _selectedUnit = 'tons';
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _quantityController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Listing'),
        actions: [
          TextButton(
            onPressed: _submitListing,
            child: const Text('Submit'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '1. Select Waste Type',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildWasteTypeGrid(),
            const SizedBox(height: 24),
            Text(
              '2. Quantity',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.straighten),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(value!) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: ['tons', 'm³', 'kg']
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedUnit = value!),
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '3. Location',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: const Icon(Icons.location_on),
                suffixIcon: Icon(
                  Icons.map,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Required' : null,
              onTap: _openMapPicker,
            ),
            const SizedBox(height: 24),
            Text(
              '4. Description (Optional)',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional details',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<ListingBloc, ListingState>(
              builder: (context, state) {
                final isLoading = state is ListingLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : _submitListing,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Create Listing'),
                        ),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteTypeGrid() {
    const wasteTypes = [
      _WasteTypeEntry(WasteType.concrete, 'Concrete', '🧱'),
      _WasteTypeEntry(WasteType.wood, 'Wood', '🪵'),
      _WasteTypeEntry(WasteType.metal, 'Metal', '🔩'),
      _WasteTypeEntry(WasteType.soil, 'Soil', '🏔️'),
      _WasteTypeEntry(WasteType.mixed, 'Mixed', '📦'),
      _WasteTypeEntry(WasteType.hazardous, 'Hazardous', '🛢️'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: wasteTypes.length,
      itemBuilder: (context, index) {
        final entry = wasteTypes[index];
        final isSelected = _selectedWasteType == entry.type;

        return GestureDetector(
          onTap: () => setState(() => _selectedWasteType = entry.type),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(entry.icon, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(entry.label, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMapPicker() async {
    final result = await context.push<Map<String, dynamic>>(
      '/map',
      extra: {
        'isPicker': true,
        'initialPosition': _latitude != null && _longitude != null
            ? LatLng(_latitude!, _longitude!)
            : null,
      },
    );

    if (result != null) {
      setState(() {
        _latitude = result['lat'] as double?;
        _longitude = result['lng'] as double?;
        _addressController.text =
            '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
      });
    }
  }

  void _submitListing() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      context.read<ListingBloc>().add(
            ListingCreate({
              'wasteType': _selectedWasteType.name,
              'quantity': double.parse(_quantityController.text),
              'unit': _selectedUnit,
              'address': _addressController.text,
              'latitude': _latitude,
              'longitude': _longitude,
              'description': _descriptionController.text,
            }),
          );

      context.pop();
    }
  }
}

class _WasteTypeEntry {
  final WasteType type;
  final String label;
  final String icon;

  const _WasteTypeEntry(this.type, this.label, this.icon);
}
