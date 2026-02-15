import 'package:flutter_test/flutter_test.dart';
import 'package:fill_exchange/core/services/offline_queue.dart';

// QueuedActionAdapter is in offline_queue.dart part file, so we can access via QueuedAction if exported,
// OR we need to recreate registration if not public.
// But QueuedActionAdapter class is generated in .g.dart.
// We can use it if we import the file.

void main() async {
  // Hive setup for testing is tricky without mock path provider or pure dart hive.
  // Using generic test:
  test('QueuedAction model properties', () {
    final now = DateTime.now();
    final action = QueuedAction(
      id: '123',
      type: 'test',
      payload: '{}',
      createdAt: now,
    );
    expect(action.id, '123');
    expect(action.status, 'pending');
  });

  // Further tests require actual Hive box which needs file system access or mocks.
  // Placeholder for integration test:
  // test('enqueue adds to box', ...);
}
