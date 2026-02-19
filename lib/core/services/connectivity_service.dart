import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

enum ConnectivityStatus { online, slow, offline }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityStatus> get statusStream async* {
    await for (final results in _connectivity.onConnectivityChanged) {
      final status = _mapResults(results);
      log.i('[CONNECTIVITY] Status changed to: ${status.name}');
      yield status;
    }
  }

  Future<ConnectivityStatus> checkStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }

  ConnectivityStatus _mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return ConnectivityStatus.offline;
    }

    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityStatus.online;
    }

    if (results.contains(ConnectivityResult.mobile)) {
      // Potentially can check additional metrics here (using internet_connection_checker possibly)
      // For now, treat mobile as "online" but maybe indicate "slow" in UI if desired later.
      // AC just says "ConnectivityStatus enum: online, slow, offline".
      // I'll return online for now and leave a comment.
      return ConnectivityStatus.online;
    }

    return ConnectivityStatus.offline;
  }
}

final connectivityServiceProvider = StateProvider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStreamProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.statusStream;
});
