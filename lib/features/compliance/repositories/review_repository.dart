import 'package:supabase_flutter/supabase_flutter.dart';
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
      createdAt: (data['createdAt'] is String)
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'jobId': jobId,
    'reviewerUid': reviewerUid,
    'revieweeUid': revieweeUid,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ReviewRepository {
  final SupabaseClient _client;
  ReviewRepository(this._client);

  /// Submit a review after a completed job
  Future<void> submitReview(Review review) async {
    // Save review
    await _client.from('reviews').insert({
      ...review.toMap(),
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Update the reviewee's aggregate rating
    await _updateUserRating(review.revieweeUid);
  }

  /// Fetch reviews for a user
  Stream<List<Review>> fetchReviewsForUser(String uid) {
    return _client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('revieweeUid', uid)
        .order('createdAt', ascending: false)
        .map((data) => data.map((json) => Review.fromMap(json, json['id'] as String)).toList());
  }

  /// Check if a review already exists for this job by this reviewer
  Future<bool> hasReviewed(String jobId, String reviewerUid) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('jobId', jobId)
        .eq('reviewerUid', reviewerUid)
        .limit(1);
    return (data as List).isNotEmpty;
  }

  /// Recalculate and store aggregate rating on user document
  Future<void> _updateUserRating(String uid) async {
    final reviews = await _client
        .from('reviews')
        .select()
        .eq('revieweeUid', uid);

    if ((reviews as List).isEmpty) return;

    double total = 0;
    for (var doc in reviews) {
      total += (doc['rating'] as num?)?.toDouble() ?? 0;
    }
    final avg = total / reviews.length;

    await _client.from('users').update({
      'averageRating': avg,
      'totalReviews': reviews.length,
    }).eq('uid', uid);
  }
}

// ─── Providers ───────────────────────────────────────

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(Supabase.instance.client);
});
