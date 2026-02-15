import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/app_user.dart';
import '../models/listing_model.dart';
import '../../profile/providers/profile_provider.dart';

class ListingRepository {
  final FirebaseFirestore _firestore;

  ListingRepository(this._firestore);
  
  // Create
  Future<void> createListing(Listing listing) async {
    // Map listing model to firestore map
    // We omit ID as it might be auto-generated or passed
    // If listing.id is empty, add should be used
    if (listing.id.isEmpty) {
        await _firestore.collection('listings').add({
            ...listing.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
        });
    } else {
        await _firestore.collection('listings').doc(listing.id).set({
            ...listing.toMap(),
            'createdAt': FieldValue.serverTimestamp(),
        });
    }
  }

  // Read: Stream of active listings
  Stream<List<Listing>> fetchActiveListings() {
    return _firestore
        .collection('listings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
            return snapshot.docs.map((doc) => Listing.fromMap(doc.data(), doc.id)).toList();
        });
  }

  // Update
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    await _firestore.collection('listings').doc(id).update(data);
  }

  // Delete (Archive)
  Future<void> archiveListing(String id) async {
    await updateListing(id, {'status': 'archived'});
  }
}

final listingRepositoryProvider = Provider<ListingRepository>((ref) {
  return ListingRepository(FirebaseFirestore.instance);
});

final activeListingsProvider = StreamProvider.autoDispose<List<Listing>>((ref) {
  final repo = ref.watch(listingRepositoryProvider);
  return repo.fetchActiveListings();
});
