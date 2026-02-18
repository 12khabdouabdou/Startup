import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/job_model.dart';
import '../repositories/job_repository.dart';
import '../../auth/repositories/auth_repository.dart';
import '../../../core/models/geo_point.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  final String listingId;
  final String hostUid;
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
  final _qtyController = TextEditingController(); // Logic to split if needed?
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMaterial != null) {
      // Potentially prefield notes?
      _notesController.text = 'Material: ${widget.initialMaterial}';
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _notesController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw Exception('Not authenticated');

      final job = Job(
        id: '', // Supabase generates
        listingId: widget.listingId,
        hostUid: widget.hostUid, // The Owner of the material (or the poster of the job?) 
        // Logic: Job poster is "host"? No, HostUid in Job refers to the "Job Owner".
        // If User (Dev) posts job, User is Host?
        // JobModel says: "hostUid: Excavator/Developer who posted the listing".
        // Actually, Job links to Listing. Listing has Owner.
        // If Logic is "Haul Request", the Job Owner is the one PAYING.
        // Let's assume User is Job Owner.
        // But JobModel structure ties to Listing Host?
        // Let's use currentUser as the creator of the Job.
        // We might need a separate field 'creator_uid' or just use hostUid for now?
        // Let's use hostUid = widget.hostUid (Original Listing Owner)?
        // Or currentUser?
        // If User A requests Haul for User B's dirt. 
        // Job Host = Creator (User A).
        // Let's use currentUser.id.
        
        status: JobStatus.open,
        pickupAddress: _pickupController.text.trim(),
        dropoffAddress: _dropoffController.text.trim(),
        priceOffer: double.tryParse(_priceController.text.trim()),
        material: widget.initialMaterial,
        quantity: double.tryParse(_qtyController.text.trim()) ?? widget.initialQuantity,
        notes: _notesController.text.trim(),
        createdAt: DateTime.now(),
        // Simple GeoPoints (0,0) as placeholder if not using map picker yet
        pickupLocation: const GeoPoint(0, 0),
        dropoffLocation: const GeoPoint(0, 0),
      );

      // We need createJob logic that handles ID generation or use insert().select()
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pickup Address',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dropoffController,
                decoration: const InputDecoration(
                  labelText: 'Dropoff Address',
                  prefixIcon: Icon(Icons.flag),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Offer Price (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (Material, Access, etc.)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSubmitting 
                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                     : const Text('Post Job to Board'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
