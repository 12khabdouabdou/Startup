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
  FillMaterial? _materialFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listingsAsync = ref.watch(activeListingsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    const forestGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'Search material, location...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  filled: false,
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
              )
            : const Text('Fill Exchange', style: TextStyle(color: forestGreen, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: (unreadCount.valueOrNull ?? 0) > 0,
              label: Text('${unreadCount.valueOrNull ?? 0}'),
              backgroundColor: Colors.orange,
              child: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
            ),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search_rounded, color: Colors.black87),
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
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildFilterChips(),
          ),

          // Active filter summary
          if (_materialFilter != null || _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              color: forestGreen.withOpacity(0.04),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 14, color: forestGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _buildFilterSummary(),
                      style: const TextStyle(fontSize: 12, color: forestGreen, fontWeight: FontWeight.bold),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _materialFilter = null;
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: forestGreen.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: forestGreen),
                    ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                            child: Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[200]),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            listings.isEmpty
                                ? 'Marketplace is Quiet\nBe the first to post material!'
                                : 'No matching hauls found\nTry adjusting your filters.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => CreateAlertDialog(initialMaterial: _materialFilter),
                              );
                            },
                            icon: const Icon(Icons.notifications_active_outlined),
                            label: const Text('CREATE SAVED SEARCH'),
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
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(activeListingsProvider),
                  color: forestGreen,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      // Filter out Needing listings if any exist in DB (just in case)
                      if (item.type == ListingType.needing) return const SizedBox.shrink();
                       
                      return ListingCard(
                        listing: item,
                        onTap: () => context.push('/listings/${item.id}', extra: item),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: forestGreen)),
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
                backgroundColor: forestGreen,
                label: const Text('POST MATERIAL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                icon: const Icon(Icons.add, color: Colors.white),
              ),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  List<Listing> _applyFilters(List<Listing> listings) {
    return listings.where((l) {
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
    if (_materialFilter != null) parts.add(_materialFilter!.name.toUpperCase());
    if (_searchQuery.isNotEmpty) parts.add('"${_searchQuery.toUpperCase()}"');
    return 'RESULTS FOR: ${parts.join(' + ')}';
  }

  Widget _buildFilterChips() {
    const forestGreen = Color(0xFF2E7D32);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ...FillMaterial.values.map((m) {
            final label = m.name[0].toUpperCase() + m.name.substring(1).toLowerCase();
            final isSelected = _materialFilter == m;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) => setState(() => _materialFilter = selected ? m : null),
                backgroundColor: Colors.white,
                selectedColor: forestGreen.withOpacity(0.12),
                checkmarkColor: forestGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSelected ? forestGreen.withOpacity(0.5) : Colors.grey[200]!),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? forestGreen : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
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
