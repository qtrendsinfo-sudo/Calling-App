import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../errors/app_exception.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

abstract class PermissionService {
  Future<bool> requestMicrophonePermission();
  Future<bool> requestCameraPermission();
  Future<bool> requestNotificationPermission();
  Future<bool> hasMicrophonePermission();
  Future<bool> hasCameraPermission();
  Future<bool> openAppSettings();
}

class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isPermanentlyDenied) {
      throw const PermissionException(
        permissionName: 'Microphone',
        message: 'Microphone access is permanently denied. Please enable it in system settings.',
      );
    }
    return status.isGranted;
  }

  @override
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      throw const PermissionException(
        permissionName: 'Camera',
        message: 'Camera access is permanently denied. Please enable it in system settings.',
      );
    }
    return status.isGranted;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  @override
  Future<bool> hasMicrophonePermission() async {
    return await Permission.microphone.isGranted;
  }

  @override
  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  @override
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
