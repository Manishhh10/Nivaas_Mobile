import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // Stream to listen for connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  // Check current connectivity status
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((element) => element != ConnectivityResult.none);
  }

  // Start listening for connectivity changes
  void startListening(Function(List<ConnectivityResult>) onConnectivityChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        onConnectivityChanged(result);
      },
    );
  }

  // Stop listening
  void stopListening() {
    _subscription?.cancel();
  }
}