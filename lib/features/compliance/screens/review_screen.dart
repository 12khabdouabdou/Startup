import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repositories/review_repository.dart';
import '../../auth/repositories/auth_repository.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final String jobId;
  final String revieweeUid;
  final String revieweeName;

  const ReviewScreen({
    super.key,
    required this.jobId,
    required this.revieweeUid,
    required this.revieweeName,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.id;
    if (uid == null) return;
    final exists = await ref.read(reviewRepositoryProvider).hasReviewed(widget.jobId, uid);
    if (mounted) setState(() => _alreadyReviewed = exists);
  }

  Future<void> _submitReview() async {
    final uid = ref.read(authRepositoryProvider).currentUser?.id;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(reviewRepositoryProvider).submitReview(
        Review(
          id: '',
          jobId: widget.jobId,
          reviewerUid: uid,
          revieweeUid: widget.revieweeUid,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Review submitted! Thank you.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const forestGreen = Color(0xFF2E7D32);
    const alertGold = Color(0xFFFBC02D);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Rate Experience')),
      body: _alreadyReviewed
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(color: forestGreen.withOpacity(0.1), shape: BoxShape.circle),
                     child: const Icon(Icons.check_circle_outline, color: forestGreen, size: 48),
                   ),
                  const SizedBox(height: 24),
                  const Text('Feedback Received', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('You have already reviewed this load.', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),
                  TextButton(onPressed: () => context.pop(), child: const Text('Back to Activity', style: TextStyle(color: forestGreen, fontWeight: FontWeight.bold))),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'RELIABILITY & QUALITY',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How was your work with\n${widget.revieweeName}?',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      final isSelected = _rating >= starValue;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 52,
                            color: isSelected ? alertGold : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _ratingLabel.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Comment
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('NOTES (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Share any details about the pickup/drop-off...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 48),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReview,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: forestGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                          : const Text('Submit Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String get _ratingLabel {
    if (_rating >= 5) return 'Excellent — Highly Recommend';
    if (_rating >= 4) return 'Great — No Issues';
    if (_rating >= 3) return 'Satisfactory';
    if (_rating >= 2) return 'Poor — Multiple Issues';
    return 'Very Poor';
  }
}
