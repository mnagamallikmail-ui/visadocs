import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

/// Metadata associated with an inspection photo captured in the field.
class InspectionPhotoMetadata {
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? appraiserId;
  final String? referenceNumber;
  final String? stage;

  const InspectionPhotoMetadata({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    required this.timestamp,
    this.appraiserId,
    this.referenceNumber,
    this.stage,
  });

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'fileName': fileName,
        'fileSizeBytes': fileSizeBytes,
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
        'appraiserId': appraiserId,
        'referenceNumber': referenceNumber,
        'stage': stage,
      };

  String get formattedGps {
    if (latitude == null || longitude == null) return 'GPS Unavailable';
    return '${latitude!.toStringAsFixed(6)}°, ${longitude!.toStringAsFixed(6)}° (±${accuracy?.toStringAsFixed(1) ?? "0"}m)';
  }

  String get formattedTimestamp {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')} UTC';
  }
}

/// Service providing Camera-First photo capture with automatic GPS and timestamp tagging.
class InspectionPhotoService {
  InspectionPhotoService._();
  static final InspectionPhotoService instance = InspectionPhotoService._();

  final ImagePicker _picker = ImagePicker();

  /// Captures a photo using the device camera and attaches real-time GPS coordinates.
  Future<InspectionPhotoMetadata?> captureInspectionPhoto({
    String? appraiserId,
    String? referenceNumber,
    String? stage,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (photo == null) return null;

      Position? position;
      if (!kIsWeb) {
        position = await _getCurrentLocation();
      }

      int size = 0;
      if (!kIsWeb) {
        size = await File(photo.path).length();
      } else {
        size = await photo.length();
      }

      return InspectionPhotoMetadata(
        filePath: photo.path,
        fileName: photo.name,
        fileSizeBytes: size,
        latitude: position?.latitude,
        longitude: position?.longitude,
        altitude: position?.altitude,
        accuracy: position?.accuracy,
        timestamp: DateTime.now().toUtc(),
        appraiserId: appraiserId,
        referenceNumber: referenceNumber,
        stage: stage,
      );
    } catch (e) {
      debugPrint('[InspectionPhotoService] Error capturing photo: $e');
      return null;
    }
  }

  /// Selects one or more existing inspection photos from the device gallery.
  Future<List<InspectionPhotoMetadata>> pickGalleryPhotos({
    String? appraiserId,
    String? referenceNumber,
    String? stage,
  }) async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (photos.isEmpty) return [];

      Position? position;
      if (!kIsWeb) {
        position = await _getCurrentLocation();
      }

      final List<InspectionPhotoMetadata> results = [];
      for (final photo in photos) {
        int size = 0;
        if (!kIsWeb) {
          size = await File(photo.path).length();
        } else {
          size = await photo.length();
        }

        results.add(
          InspectionPhotoMetadata(
            filePath: photo.path,
            fileName: photo.name,
            fileSizeBytes: size,
            latitude: position?.latitude,
            longitude: position?.longitude,
            altitude: position?.altitude,
            accuracy: position?.accuracy,
            timestamp: DateTime.now().toUtc(),
            appraiserId: appraiserId,
            referenceNumber: referenceNumber,
            stage: stage,
          ),
        );
      }

      return results;
    } catch (e) {
      debugPrint('[InspectionPhotoService] Error picking photos: $e');
      return [];
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await Geolocator.getLastKnownPosition();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await Geolocator.getLastKnownPosition();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      debugPrint('[InspectionPhotoService] Location acquisition error: $e');
      return null;
    }
  }
}

