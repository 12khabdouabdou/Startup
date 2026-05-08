import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/supabase_service.dart';

class WasteMapScreen extends StatefulWidget {
  const WasteMapScreen({super.key});

  @override
  State<WasteMapScreen> createState() => _WasteMapScreenState();
}

class _WasteMapScreenState extends State<WasteMapScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final res = await SupabaseService.client
        .from('waste_posts')
        .select('*')
        .eq('status', 'posted');
    setState(() {
      _posts = List<Map<String, dynamic>>.from(res);
      _loading = false;
    });
  }

  Future<void> _selectWaste(String postId, double price) async {
    try {
      await SupabaseService.client.functions
          .invoke('match_recycler', body: {'waste_post_id': postId, 'accepted_price': price});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Waste selected!')));
      _loadPosts();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waste Map')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(40.73, -73.94),
                initialZoom: 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.cwl.app',
                ),
                MarkerLayer(
                  markers: _posts.map((post) {
                    return Marker(
                      point: LatLng(post['lat'] ?? 40.73, post['lng'] ?? -73.94),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (_) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${post['waste_type']}', style: Theme.of(context).textTheme.titleLarge),
                                  Text('${post['quantity']} ${post['quantity_unit']}'),
                                  Text('Price: \$${post['price']}'),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _selectWaste(post['id'], (post['price'] as num).toDouble());
                                    },
                                    child: const Text('Select'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
