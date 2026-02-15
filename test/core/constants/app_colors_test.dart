import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_exchange/core/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    test('defines forest green as primary', () {
      expect(AppColors.primary, const Color(0xFF2E7D32));
    });

    test('defines cream as surface', () {
      expect(AppColors.surface, const Color(0xFFF5F0E8));
    });

    test('defines success, warning, error colors correctly', () {
      expect(AppColors.success, const Color(0xFF4CAF50));
      expect(AppColors.warning, const Color(0xFFFF9800));
      expect(AppColors.error, const Color(0xFFF44336));
    });
  });
}
