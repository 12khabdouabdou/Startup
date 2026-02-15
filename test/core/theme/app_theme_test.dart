import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fill_exchange/core/theme/app_theme.dart';
import 'package:fill_exchange/core/constants/app_colors.dart';

void main() {
  group('AppTheme', () {
    final theme = AppTheme.lightTheme;

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
    });

    test('primary color is forest green', () {
      expect(theme.colorScheme.primary, AppColors.primary);
    });

    test('scaffold background is cream', () {
      expect(theme.scaffoldBackgroundColor, AppColors.surface);
    });

    test('card shape has 12 radius', () {
      final cardTheme = theme.cardTheme;
      final shape = cardTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(12));
    });

    test('chip shape has 20 radius', () {
      final chipTheme = theme.chipTheme;
      final shape = chipTheme.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
    });

    test('elevated button minimum height is 56', () {
      final buttonTheme = theme.elevatedButtonTheme;
      final style = buttonTheme.style!;
      final minSize = style.minimumSize!.resolve({});
      expect(minSize!.height, 56.0);
    });

    test('app bar uses primary color', () {
      final appBarTheme = theme.appBarTheme;
      expect(appBarTheme.backgroundColor, AppColors.primary);
      expect(appBarTheme.foregroundColor, Colors.white);
    });
  });
}
