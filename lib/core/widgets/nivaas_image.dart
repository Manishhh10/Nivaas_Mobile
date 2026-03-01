import 'package:flutter/material.dart';
import 'package:nivaas/core/api/api_client.dart';

class NivaasImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NivaasImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  static String fullUrl(String path) {
    if (path.isEmpty) return '';

    var normalized = path.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) return '';

    // Some responses include '/api/uploads/...' while static files are served
    // from '/uploads/...'. Normalize to avoid 404s.
    if (normalized.startsWith('/api/uploads/')) {
      normalized = normalized.replaceFirst('/api', '');
    } else if (normalized.startsWith('api/uploads/')) {
      normalized = normalized.replaceFirst('api/', '');
    }

    if (normalized.startsWith('data:image')) {
      return normalized;
    }

    // Build API origin from the base URL that actually connected.
    // Uses resolvedBaseUrl so images work on physical devices too.
    final origin = ApiClient.resolvedBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      final parsed = Uri.tryParse(normalized);
      final originUri = Uri.tryParse(origin);
      if (parsed != null && originUri != null) {
        final host = parsed.host.toLowerCase();
        if (host == 'localhost' || host == '127.0.0.1') {
          final fixedPath = parsed.path.startsWith('/api/uploads/')
              ? parsed.path.replaceFirst('/api', '')
              : parsed.path;
          final fixed = Uri(
            scheme: originUri.scheme,
            host: originUri.host,
            port: originUri.hasPort ? originUri.port : null,
            path: fixedPath,
            query: parsed.query.isNotEmpty ? parsed.query : null,
          );
          return fixed.toString();
        }
      }
      return normalized;
    }

    // Handle absolute-like local paths and relative upload paths.
    if (normalized.startsWith('/')) {
      return '$origin$normalized';
    }
    if (normalized.startsWith('uploads/')) {
      return '$origin/$normalized';
    }

    final uploadsIndex = normalized.indexOf('/uploads/');
    if (uploadsIndex >= 0) {
      return '$origin${normalized.substring(uploadsIndex)}';
    }
    final relativeUploadsIndex = normalized.indexOf('uploads/');
    if (relativeUploadsIndex >= 0) {
      return '$origin/${normalized.substring(relativeUploadsIndex)}';
    }

    return '$origin/$normalized';
  }

  @override
  Widget build(BuildContext context) {
    final url = fullUrl(imagePath);
    if (url.isEmpty) {
      return _placeholder();
    }

    Widget image = Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _loadingPlaceholder();
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.grey, size: 40),
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
