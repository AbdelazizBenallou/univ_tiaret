import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:univ_tiaret/constants.dart';

enum NetworkStatus { online, offline, checking }

class ConnectivityNotifier extends StateNotifier<NetworkStatus> {
  Timer? _timer;

  ConnectivityNotifier() : super(NetworkStatus.checking) {
    check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => check());
  }

  Future<void> check() async {
    try {
      final uri = Uri.parse(apiBaseUrl);
      final socket = await Socket.connect(uri.host, uri.hasPort ? uri.port : 443)
          .timeout(const Duration(seconds: 3));
      socket.destroy();
      state = NetworkStatus.online;
    } catch (_) {
      state = NetworkStatus.offline;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, NetworkStatus>((ref) {
  return ConnectivityNotifier();
});
