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
      jobId: (data['job_id'] ?? data['jobId']) as String? ?? '',
      reviewerUid: (data['reviewer_uid'] ?? data['reviewerUid']) as String? ?? '',
      revieweeUid: (data['reviewee_uid'] ?? data['revieweeUid']) as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      createdAt: (data['created_at'] is String)
          ? DateTime.parse(data['created_at'] as String)
          : (data['createdAt'] is String)
              ? DateTime.parse(data['createdAt'] as String)
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'job_id': jobId,
    'reviewer_uid': reviewerUid,
    'reviewee_uid': revieweeUid,
    'rating': rating,
    'comment': comment,
    'created_at': createdAt.toIso8601String(),
  };
}

class ReviewRepository {
  final SupabaseClient _client;
  ReviewRepository(this._client);

  /// Submit a review after a completed job.
  /// Rating aggregation is handled automatically by a database trigger
  /// (trg_update_user_rating) — no client-side calculation needed.
  Future<void> submitReview(Review review) async {
    await _client.from('reviews').insert(review.toMap());
  }

  /// Fetch reviews for a user
  Stream<List<Review>> fetchReviewsForUser(String uid) {
    return _client
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('reviewee_uid', uid)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Review.fromMap(json, json['id'] as String)).toList());
  }

  /// Check if a review already exists for this job by this reviewer
  Future<bool> hasReviewed(String jobId, String reviewerUid) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('job_id', jobId)
        .eq('reviewer_uid', reviewerUid)
        .limit(1);
    return (data as List).isNotEmpty;
  }
}

// ─── Providers ───────────────────────────────────────

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(Supabase.instance.client);
});
