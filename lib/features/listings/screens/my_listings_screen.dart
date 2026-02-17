import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/listing_repository.dart';
import '../widgets/listing_item.dart';

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(myListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: listingsAsync.when(
        data: (listings) {
          if (listings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text('You have not posted any listings yet.'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                      onPressed: () => context.push('/listings/create'),
                      child: const Text('Create New Listing'),
                   ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
               final listing = listings[index];
               return ListingItem(
                  listing: listing,
                  onTap: () => context.push('/listings/${listing.id}', extra: listing),
               );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/listings/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
