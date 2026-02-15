import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Review {
  final String id;
  final String jobId;
  final String reviewerUid;
  final String revieweeUid;
  final double rating; // 1.0 - 5.0
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.jobId,
    required this.reviewerUid,
    required this.revieweeUid,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      jobId: data['jobId'] as String? ?? '',
      reviewerUid: data['reviewerUid'] as String? ?? '',
      revieweeUid: data['revieweeUid'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'jobId': jobId,
    'reviewerUid': reviewerUid,
    'revieweeUid': revieweeUid,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt,
  };
}

class ReviewRepository {
  final FirebaseFirestore _firestore;
  ReviewRepository(this._firestore);

  /// Submit a review after a completed job
  Future<void> submitReview(Review review) async {
    // Save review
    await _firestore.collection('reviews').add({
      ...review.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update the reviewee's aggregate rating
    await _updateUserRating(review.revieweeUid);
  }

  /// Fetch reviews for a user
  Stream<List<Review>> fetchReviewsForUser(String uid) {
    return _firestore
        .collection('reviews')
        .where('revieweeUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }

  /// Check if a review already exists for this job by this reviewer
  Future<bool> hasReviewed(String jobId, String reviewerUid) async {
    final snap = await _firestore
        .collection('reviews')
        .where('jobId', isEqualTo: jobId)
        .where('reviewerUid', isEqualTo: reviewerUid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Recalculate and store aggregate rating on user document
  Future<void> _updateUserRating(String uid) async {
    final reviews = await _firestore
        .collection('reviews')
        .where('revieweeUid', isEqualTo: uid)
        .get();

    if (reviews.docs.isEmpty) return;

    double total = 0;
    for (var doc in reviews.docs) {
      total += (doc.data()['rating'] as num?)?.toDouble() ?? 0;
    }
    final avg = total / reviews.docs.length;

    await _firestore.collection('users').doc(uid).set({
      'averageRating': avg,
      'totalReviews': reviews.docs.length,
    }, SetOptions(merge: true));
  }
}

// ─── Providers ───────────────────────────────────────

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(FirebaseFirestore.instance);
});
