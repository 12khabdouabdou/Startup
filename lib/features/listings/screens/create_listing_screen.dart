import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:fill_exchange/core/services/storage_service.dart';
import 'package:fill_exchange/features/auth/repositories/auth_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import '../../../core/models/geo_point.dart';
import '../models/listing_model.dart';
import '../repositories/listing_repository.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

enum _CreateStep { photo, material, details }

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  _CreateStep _currentStep = _CreateStep.photo;
  bool _isLoading = false;
  XFile? _capturedPhoto;
  File? _compressedPhoto;
  
  // Data
  FillMaterial? _selectedMaterial;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  final _addressController = TextEditingController();
  GeoPoint? _captureLocation;
  VolumeUnit _selectedUnit = VolumeUnit.loads;

  @override
  void initState() {
    super.initState();
    // Immediate camera trigger - Story 3.1 AC
    WidgetsBinding.instance.addPostFrameCallback((_) => _takePhoto());
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    try {
      // Capture location simultaneously
      _getLocation();

      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Initial JPEG quality compression
        maxWidth: 1280,   // Story 3.1 AC
      );

      if (photo == null) {
        if (mounted) context.pop(); // User cancelled camera, exit flow
        return;
      }

      setState(() {
        _capturedPhoto = photo;
        _currentStep = _CreateStep.material;
      });
      
      _compressImage(File(photo.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Camera error: $e')));
        context.pop();
      }
    }
  }

  Future<void> _getLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _captureLocation = GeoPoint(position.latitude, position.longitude);
        _addressController.text = "Detecting address...";
      });
      
      _addressController.text = "GPS: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    } catch (_) {
    }
  }

  Future<void> _compressImage(File file) async {
    // Advanced compression via 'image' package as per Story 3.1 AC
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    final compressedBytes = img.encodeJpg(image, quality: 80);
    final tempDir = await getTemporaryDirectory();
    final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await compressedFile.writeAsBytes(compressedBytes);
    
    if (mounted) {
      setState(() => _compressedPhoto = compressedFile);
    }
  }

  Future<void> _submit() async {
    if (_selectedMaterial == null || _qtyController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Auth Session Expired');

      // 1. Upload Photo to Supabase Storage
      final storage = ref.read(storageServiceProvider);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final remotePath = 'listings/${user.id}/$fileName';
      
      final uploadFile = _compressedPhoto ?? File(_capturedPhoto!.path);
      final photoUrl = await storage.uploadFile(
        localPath: uploadFile.path,
        remotePath: remotePath,
      );

      if (photoUrl == null) throw Exception('Photo upload failed');

      // 2. Create Listing Row
      final listing = Listing(
        id: '', 
        hostUid: user.id,
        type: ListingType.offering,
        material: _selectedMaterial!,
        quantity: double.tryParse(_qtyController.text) ?? 0.0,
        unit: _selectedUnit,
        price: double.tryParse(_priceController.text) ?? 0.0,
        photos: [photoUrl],
        location: _captureLocation,
        address: _addressController.text,
        createdAt: DateTime.now(),
      );

      await ref.read(listingRepositoryProvider).createListing(listing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Posted. Buyers in your area notified.')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_currentStep == _CreateStep.material ? 'Select Soil Type' : 'Listing Details'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case _CreateStep.photo:
        return const Center(child: Text('Opening Camera...'));
      case _CreateStep.material:
        return _buildMaterialStep();
      case _CreateStep.details:
        return _buildDetailsStep();
    }
  }

  Widget _buildMaterialStep() {
    return Column(
      children: [
        if (_capturedPhoto != null)
           Expanded(
             flex: 2,
             child: Container(
               width: double.infinity,
               margin: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(12),
                 image: DecorationImage(
                   image: FileImage(File(_capturedPhoto!.path)),
                   fit: BoxFit.cover,
                 ),
               ),
               child: Align(
                 alignment: Alignment.topRight,
                 child: IconButton(
                   icon: const CircleAvatar(backgroundColor: Colors.white70, child: Icon(Icons.refresh)),
                   onPressed: _takePhoto,
                 ),
               ),
             ),
           ),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('What are you moving?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: FillMaterial.values.map((m) {
            final isSelected = _selectedMaterial == m;
            return ChoiceChip(
              label: Text(m.name[0].toUpperCase() + m.name.substring(1)),
              selected: isSelected,
              onSelected: (val) => setState(() => _selectedMaterial = val ? m : null),
              selectedColor: const Color(0xFF2E7D32),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            );
          }).toList(),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedMaterial == null ? null : () => setState(() => _currentStep = _CreateStep.details),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('Use Photo & Material →', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quantity & Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _qtyController,
                  decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<VolumeUnit>(
                  value: _selectedUnit,
                  items: VolumeUnit.values.map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
                  onChanged: (v) => setState(() => _selectedUnit = v!),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Location / Site Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on, color: Color(0xFF2E7D32)),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price per Load (\$)',
              hintText: '0 for free',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
              child: const Text('Post Dirt →', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
