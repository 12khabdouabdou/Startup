import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/listing_repository.dart';
import '../models/listing_model.dart';
import '../widgets/listing_card.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Listings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Archived'),
            ],
          ),
        ),
        body: listingsAsync.when(
          data: (listings) {
            final activeListings = listings.where((l) => l.status != ListingStatus.archived).toList();
            final archivedListings = listings.where((l) => l.status == ListingStatus.archived).toList();

            return TabBarView(
              children: [
                _ListingsTab(listings: activeListings, isArchived: false),
                _ListingsTab(listings: archivedListings, isArchived: true),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/listings/create'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ListingsTab extends ConsumerWidget {
  final List<Listing> listings;
  final bool isArchived;

  const _ListingsTab({required this.listings, required this.isArchived});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (listings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isArchived ? 'No archived listings.' : 'You have no active listings.'),
            if (!isArchived) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/listings/create'),
                child: const Text('Create New Listing'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        final listing = listings[index];

        // Access card directly without Dismissible if archived
        if (isArchived) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Opacity(
              opacity: 0.7,
              child: ListingCard(
                listing: listing,
                onTap: () => context.push('/listings/${listing.id}', extra: listing),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(listing.id),
            direction: DismissDirection.endToStart,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(Icons.archive, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Archive Listing?'),
                  content: const Text('This will move the listing to the Archived tab and hide it from the public feed.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Archive', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
            onDismissed: (_) {
              ref.read(listingRepositoryProvider).archiveListing(listing.id);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing archived')));
              // Refresh is handled by stream
            },
            child: ListingCard(
              listing: listing,
              onTap: () => context.push('/listings/${listing.id}', extra: listing),
            ),
          ),
        );
      },
    );
  }
}
