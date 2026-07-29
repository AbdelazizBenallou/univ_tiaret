import 'dart:io';
import 'package:flutter/material.dart';


class ImageViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const ImageViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  final TransformationController _transformationController =
      TransformationController();
  bool _showAppBar = true;
  double _currentScale = 1.0;
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _loadImageSize() {
    final file = File(widget.filePath);
    if (!file.existsSync()) return;
    final bytes = file.readAsBytesSync();
    final image = decodeImageFromList(bytes);
    image.then((img) {
      if (mounted) {
        setState(() => _imageSize = Size(img.width.toDouble(), img.height.toDouble()));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitToWidth();
        });
      }
    });
  }

  void _fitToWidth() {
    if (_imageSize == Size.zero) return;
    final view = context.size;
    if (view == null) return;
    final scaleX = view.width / _imageSize.width;
    final scaleY = view.height / _imageSize.height;
    final fitScale = scaleX < scaleY ? scaleX : scaleY;
    final scale = fitScale.clamp(0.1, 1.0);
    _transformationController.value =
        Matrix4.diagonal3Values(scale, scale, 1.0);
    setState(() => _currentScale = scale);
  }

  void _toggleAppBar() {
    setState(() => _showAppBar = !_showAppBar);
  }

  void _resetZoom() {
    _fitToWidth();
  }

  void _zoomIn() {
    final newScale = (_currentScale * 1.5).clamp(0.1, 5.0);
    _transformationController.value =
        Matrix4.diagonal3Values(newScale, newScale, 1.0);
    setState(() => _currentScale = newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale / 1.5).clamp(0.1, 5.0);
    _transformationController.value =
        Matrix4.diagonal3Values(newScale, newScale, 1.0);
    setState(() => _currentScale = newScale);
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(
                widget.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              actions: [
                Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 4),
                    child: Text(
                      '${(_currentScale * 100).round()}%',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _resetZoom,
                  icon: Icon(Icons.fit_screen_rounded, size: 22),
                  tooltip: 'Fit to screen',
                ),
                IconButton(
                  onPressed: _zoomOut,
                  icon: Icon(Icons.zoom_out_rounded, size: 22),
                  tooltip: 'Zoom out',
                ),
                IconButton(
                  onPressed: _zoomIn,
                  icon: Icon(Icons.zoom_in_rounded, size: 22),
                  tooltip: 'Zoom in',
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 5.0,
          constrained: false,
          onInteractionUpdate: (details) {
            final scale =
                _transformationController.value.getMaxScaleOnAxis();
            if ((_currentScale - scale).abs() > 0.01) {
              setState(() => _currentScale = scale);
            }
          },
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (ctx, error, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
