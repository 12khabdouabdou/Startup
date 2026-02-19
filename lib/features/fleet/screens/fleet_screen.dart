import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/truck_model.dart';
import '../repositories/fleet_repository.dart';
import '../../auth/repositories/auth_repository.dart';

class FleetScreen extends ConsumerWidget {
  const FleetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleetAsync = ref.watch(myFleetProvider);
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('My Fleet', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: fleetAsync.when(
        data: (trucks) {
          if (trucks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 24),
                  const Text('No vehicles added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Start building your fleet to accept hauls.', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTruckDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('ADD FIRST TRUCK'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            );
          }

          final activeTrucks = trucks.where((t) => t.isActive).length;
          final totalCapacity = trucks.where((t) => t.isActive).fold(0.0, (sum, t) => sum + t.capacityTons);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: forestGreen,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: forestGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('FLEET OVERVIEW', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickStat(label: 'ACTIVE VEHICLES', value: '$activeTrucks / ${trucks.length}'),
                            ),
                            Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                            Expanded(
                              child: _QuickStat(label: 'TOTAL CAPACITY', value: '${totalCapacity.toInt()} TONS'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text('REGISTERED VEHICLES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TruckCard(truck: trucks[index]),
                    childCount: trucks.length,
                  ),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTruckDialog(context, ref),
        backgroundColor: forestGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('ADD VEHICLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddTruckDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddTruckSheet(),
    );
  }
}

class _TruckCard extends ConsumerWidget {
  final Truck truck;
  const _TruckCard({required this.truck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const forestGreen = Color(0xFF2E7D32);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: truck.isActive ? forestGreen.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_shipping_outlined, 
                color: truck.isActive ? forestGreen : Colors.grey[400],
              ),
            ),
            title: Text(truck.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${truck.type.name.toUpperCase()} • ${truck.capacityTons} TONS', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                Text('PLATE: ${truck.plateNumber}', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
            trailing: Switch.adaptive(
              value: truck.isActive,
              activeColor: forestGreen,
              onChanged: (val) {
                ref.read(fleetRepositoryProvider).toggleTruckStatus(truck.id, val);
                ref.invalidate(myFleetProvider);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTruckSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddTruckSheet> createState() => _AddTruckSheetState();
}

class _AddTruckSheetState extends ConsumerState<_AddTruckSheet> {
  final _formKey = GlobalKey<FormState>();
  String _nickname = '';
  String _plate = '';
  TruckType _type = TruckType.dump;
  double _capacity = 15.0;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(fleetRepositoryProvider).addTruck(Truck(
        id: '',
        ownerUid: userId,
        nickname: _nickname,
        plateNumber: _plate,
        type: _type,
        capacityTons: _capacity,
        createdAt: DateTime.now(),
      ));
      ref.invalidate(myFleetProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF2E7D32);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Add New Vehicle', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nickname (e.g., Rig #1)', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onSaved: (v) => _nickname = v!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'License Plate', border: OutlineInputBorder()),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onSaved: (v) => _plate = v!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TruckType>(
                    value: _type,
                    decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                    items: TruckType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: '15.0',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity (Tons)', border: OutlineInputBorder()),
                    onSaved: (v) => _capacity = double.tryParse(v ?? '15.0') ?? 15.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: forestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('REGISTER VEHICLE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  const _QuickStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }
}
