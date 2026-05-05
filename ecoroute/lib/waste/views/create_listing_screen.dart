import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/listing_bloc.dart';
import '../bloc/listing_event.dart';

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
  
  String _selectedWasteType = 'concrete';
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
            // Step indicator
            _buildStepIndicator(),
            const SizedBox(height: 24),
            
            // Waste type selection
            Text('1. Select Waste Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildWasteTypeGrid(),
            const SizedBox(height: 24),
            
            // Quantity
            Text('2. Quantity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      if (double.tryParse(value!) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    items: ['tons', 'm³', 'kg'].map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                    onChanged: (value) => setState(() => _selectedUnit = value!),
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Location
            Text('3. Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                suffixIcon: Icon(Icons.map, color: Colors.blue),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              onTap: () async {
                // TODO: Open map picker
                final result = await Navigator.pushNamed(context, '/map-picker');
                if (result != null) {
                  setState(() {
                    _latitude = result['lat'];
                    _longitude = result['lng'];
                    _addressController.text = result['address'];
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            
            // Description
            Text('4. Description (Optional)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            
            // Submit button
            BlocBuilder<ListingBloc, ListingState>(
              builder: (context, state) {
                final isLoading = state is ListingLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : _submitListing,
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Padding(padding: EdgeInsets.all(12), child: Text('Create Listing')),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepDot(1, true),
        const SizedBox(width: 8),
        _buildStepDot(2, false),
        const SizedBox(width: 8),
        _buildStepDot(3, false),
        const SizedBox(width: 8),
        _buildStepDot(4, false),
      ],
    );
  }

  Widget _buildStepDot(int step, bool active) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildWasteTypeGrid() {
    final wasteTypes = [
      {'type': 'concrete', 'label': 'Concrete', 'icon': '🧱'},
      {'type': 'wood', 'label': 'Wood', 'icon': '🪵'},
      {'type': 'metal', 'label': 'Metal', 'icon': '🔩'},
      {'type': 'soil', 'label': 'Soil', 'icon': '🏔️'},
      {'type': 'mixed', 'label': 'Mixed', 'icon': '📦'},
      {'type': 'hazardous', 'label': 'Hazardous', 'icon': '🛢️'},
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
        final wasteType = wasteTypes[index];
        final isSelected = _selectedWasteType == wasteType['type'];
        
        return GestureDetector(
          onTap: () => setState(() => _selectedWasteType = wasteType['type']!),
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
                Text(wasteType['icon']!, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(wasteType['label']!, textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitListing() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a location on the map')),
        );
        return;
      }

      context.read<ListingBloc>().add(ListingCreate({
        'wasteType': _selectedWasteType,
        'quantity': double.parse(_quantityController.text),
        'unit': _selectedUnit,
        'address': _addressController.text,
        'latitude': _latitude,
        'longitude': _longitude,
        'description': _descriptionController.text,
      }));
      
      // Navigate back on success
      context.pop();
    }
  }
}
