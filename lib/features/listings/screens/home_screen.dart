import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/listing_model.dart';
import '../repositories/listing_repository.dart';
import '../widgets/listing_card.dart';
import '../../notifications/repositories/notification_repository.dart';
import '../../profile/providers/profile_provider.dart';
import '../../../core/models/app_user.dart';
import '../../alerts/widgets/create_alert_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(activeListingsProvider);
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search material, location...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              )
            : const Text('FillExchange'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: (unreadCount.valueOrNull ?? 0) > 0,
              label: Text('${unreadCount.valueOrNull ?? 0}'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterChips(),

          // Active filter summary
          if (_materialFilter != null || _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _buildFilterSummary(),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _materialFilter = null;
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                    child: const Text('Clear', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

          // Listings Feed
          Expanded(
            child: listingsAsync.when(
              data: (listings) {
                final filtered = _applyFilters(listings);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          listings.isEmpty
                              ? 'No listings yet.\nBe the first to post!'
                              : 'No listings match your filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => CreateAlertDialog(initialMaterial: _materialFilter),
                            );
                          },
                          icon: const Icon(Icons.notifications_active),
                          label: const Text('Get Notified for New Listings'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[100],
                            foregroundColor: Colors.blue[900],
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(activeListingsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                       // Filter out Needing listings if any exist in DB (just in case)
                       if (filtered[index].type == ListingType.needing) return const SizedBox.shrink();
                       
                      return ListingCard(
                        listing: filtered[index],
                        onTap: () {
                          context.push('/listings/${filtered[index].id}', extra: filtered[index]);
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: ref.watch(userDocProvider).when(
        data: (user) => user?.role == UserRole.hauler
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push('/listings/create'),
                label: const Text('Post'),
                icon: const Icon(Icons.add),
              ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  List<Listing> _applyFilters(List<Listing> listings) {
    return listings.where((l) {
      // Hard filter: Only show Offering (Seller) listings
      if (l.type == ListingType.needing) return false;
      
      if (_materialFilter != null && l.material != _materialFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesMaterial = l.material.name.toLowerCase().contains(q);
        final matchesDescription = l.description.toLowerCase().contains(q);
        final matchesAddress = (l.address ?? '').toLowerCase().contains(q);
        if (!matchesMaterial && !matchesDescription && !matchesAddress) return false;
      }
      return true;
    }).toList();
  }

  String _buildFilterSummary() {
    final parts = <String>[];
    if (_materialFilter != null) parts.add(_materialFilter!.name[0].toUpperCase() + _materialFilter!.name.substring(1));
    if (_searchQuery.isNotEmpty) parts.add('"$_searchQuery"');
    return 'Filtered by: ${parts.join(', ')}';
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Removed ListingType Chips
          
          // Material Filters
          ...FillMaterial.values.map((m) {
            final label = m.name[0].toUpperCase() + m.name.substring(1);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(label),
                selected: _materialFilter == m,
                onSelected: (selected) {
                  setState(() => _materialFilter = selected ? m : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // Removed Type Filter Section
            const SizedBox(height: 16),
            const Text('Material'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('All'), selected: _materialFilter == null, onSelected: (_) => setState(() { _materialFilter = null; Navigator.pop(context); })),
                ...FillMaterial.values.map((m) {
                  final label = m.name[0].toUpperCase() + m.name.substring(1);
                  return ChoiceChip(label: Text(label), selected: _materialFilter == m, onSelected: (_) => setState(() { _materialFilter = m; Navigator.pop(context); }));
                }),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  setState(() { _materialFilter = null; });
                  Navigator.pop(context);
                },
                child: const Text('Clear All Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
