import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityResult> _connectivityController = StreamController<ConnectivityResult>.broadcast();

  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((result) {
      debugPrint('ConnectivityService: Connectivity changed to $result');
      _connectivityController.add(result);
    });
  }

  Future<bool> hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void dispose() {
    _connectivityController.close();
  }
}