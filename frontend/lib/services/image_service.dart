// services/image_service.dart
import 'package:flutter/material.dart';
import 'dart:io';

class ImageService {
  static const String baseUrl = 'http://10.0.2.2:5000/uploads/';
  
  static String getImageUrl(String filename) {
    return '$baseUrl$filename';
  }
  
  static Widget buildImageNetwork(String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? Container(
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
  
  static Future<List<String>> compressImages(List<File> images) async {
    // Implement image compression if needed
    return images.map((file) => file.path).toList();
  }
}