import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:univ_tiaret/services/auth_service.dart';

class AuthNetworkImage extends StatefulWidget {
  final String? url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget placeholder;

  const AuthNetworkImage({
    super.key,
    required this.url,
    required this.placeholder,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  State<AuthNetworkImage> createState() => _AuthNetworkImageState();
}

class _AuthNetworkImageState extends State<AuthNetworkImage> {
  static const int _maxCacheEntries = 50;
  static final Map<String, Uint8List> _cache = {};
  static final Map<String, Future<Uint8List?>> _inflight = {};

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AuthNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() => _bytes = null);
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.url;
    if (url == null || url.isEmpty) return;

    final cached = _cache[url];
    if (cached != null) {
      if (mounted) setState(() => _bytes = cached);
      return;
    }

    final bytes = await _fetch(url);
    if (!mounted) return;
    if (bytes != null && widget.url == url) {
      setState(() => _bytes = bytes);
    }
  }

  Future<Uint8List?> _fetch(String url) {
    final existing = _inflight[url];
    if (existing != null) return existing;

    final future = _doFetch(url).then((bytes) {
      _inflight.remove(url);
      if (bytes != null) _putCache(url, bytes);
      return bytes;
    });
    _inflight[url] = future;
    return future;
  }

  Future<Uint8List?> _doFetch(String url) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {
      // ignore network errors, keep placeholder
    }
    return null;
  }

  static void _putCache(String url, Uint8List bytes) {
    if (_cache.length >= _maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = bytes;
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    if (url == null || url.isEmpty) return widget.placeholder;
    if (_bytes == null) return widget.placeholder;

    return Image.memory(
      _bytes!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (_, _, _) => widget.placeholder,
      gaplessPlayback: true,
    );
  }
}
