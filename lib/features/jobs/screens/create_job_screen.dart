import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import '../../listings/repositories/listing_repository.dart';
import '../../listings/models/listing_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/models/geo_point.dart';
import '../../maps/screens/location_picker_screen.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  final String listingId;
  final String hostUid; // Listing Owner UID
  final String? initialMaterial;
  final double? initialQuantity;

  const CreateJobScreen({
    super.key,
    required this.listingId,
    required this.hostUid,
    this.initialMaterial,
    this.initialQuantity,
  });

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _notesController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _materialController = TextEditingController();
  GeoPoint? _dropoffLocation;

  bool _isSubmitting = false;
  bool _isLoadingListing = true;
  Listing? _listing;

  @override
  void initState() {
    super.initState();
    _fetchListingDetails();
  }

  Future<void> _fetchListingDetails() async {
    try {
      final listing = await ref.read(listingRepositoryProvider).fetchListing(widget.listingId);
      if (listing != null) {
        setState(() {
          _listing = listing;
          _pickupController.text = listing.address ?? '';
          _materialController.text = listing.material.name;
          _qtyController.text = listing.quantity.toString();
          // _priceController: Leave empty for offer? Or suggest listing price if not free?
          if (widget.initialMaterial != null) {
             _notesController.text = 'Interest in ${widget.initialMaterial}';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching listing: $e');
    } finally {
      if (mounted) setState(() => _isLoadingListing = false);
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Job Host = Current User (The one creating the request)
      final job = Job(
        id: '', // Supabase generates
        listingId: widget.listingId,
        hostUid: user.id, 
        haulerUid: null, // Open Job
        status: JobStatus.open,
        pickupAddress: _pickupController.text.trim(),
        dropoffAddress: _dropoffController.text.trim(),
        priceOffer: double.tryParse(_priceController.text.trim()),
        material: _materialController.text.trim().isNotEmpty 
            ? _materialController.text.trim() 
            : (widget.initialMaterial ?? 'Dirt'),
        quantity: double.tryParse(_qtyController.text.trim()) ?? widget.initialQuantity ?? 0.0,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        pickupLocation: _listing?.location ?? const GeoPoint(0, 0),
        dropoffLocation: _dropoffLocation ?? const GeoPoint(0, 0),
      );

      await ref.read(jobRepositoryProvider).createJob(job); 

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Haul Request Posted!')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Haul Job')),
      body: _isLoadingListing 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  if (_listing != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[100]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Original Listing', style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold)),
                                Text('${_listing!.material.name} • ${_listing!.quantity} units', style: TextStyle(color: Colors.blue[800])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextFormField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      labelText: 'Pickup Address (From Listing)',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _dropoffController,
                    decoration: InputDecoration(
                      labelText: 'Dropoff Address',
                      prefixIcon: const Icon(Icons.flag),
                      border: const OutlineInputBorder(),
                      helperText: 'Enter destination address',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.map, color: Colors.blue),
                        onPressed: () async {
                           final result = await Navigator.push(
                             context,
                             MaterialPageRoute(builder: (c) => LocationPickerScreen(initialLocation: _dropoffLocation)),
                           );
                           if (result is LocationResult) {
                              setState(() {
                                 _dropoffLocation = result.point;
                                 _dropoffController.text = result.address;
                              });
                           }
                        },
                      ),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                       Expanded(
                         child: TextFormField(
                           controller: _materialController,
                           decoration: const InputDecoration(
                             labelText: 'Material',
                             prefixIcon: Icon(Icons.category),
                             border: OutlineInputBorder(),
                           ),
                           validator: (v) => v?.isEmpty == true ? 'Required' : null,
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: TextFormField(
                           controller: _qtyController,
                           keyboardType: TextInputType.number,
                           decoration: const InputDecoration(
                             labelText: 'Quantity',
                             prefixIcon: Icon(Icons.scale),
                             border: OutlineInputBorder(),
                           ),
                           validator: (v) => v?.isEmpty == true ? 'Required' : null,
                         ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Offer Price (\$)',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      helperText: 'Your detailed offer for the haul',
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.note),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting 
                         ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                         : const Text('Post Job to Board', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
