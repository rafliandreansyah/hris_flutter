import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/core/utils/permission_util.dart';
import 'package:hris_flutter/core/widgets/in_app_camera_capture_screen.dart';

/// Pintu tunggal pengambilan foto dari kamera di seluruh aplikasi.
///
/// Memakai kamera in-app ([InAppCameraCaptureScreen]) alih-alih
/// `ImagePicker(source: camera)` agar aplikasi tidak dipindah ke background
/// dan dibunuh OS pada perangkat RAM kecil (tanpa log error).
class CameraCaptureUtil {
  CameraCaptureUtil._();

  /// Hook pengujian untuk menggantikan kamera asli.
  @visibleForTesting
  static Future<XFile?> Function({required CameraLensDirection lens})?
      testHandler;

  static Future<XFile?> capture(
    BuildContext context, {
    CameraLensDirection lens = CameraLensDirection.back,
    String title = 'Ambil Foto',
  }) async {
    if (testHandler != null) return testHandler!(lens: lens);

    final permission = await PermissionUtil.requestCameraPermission(
      context: context,
    );
    if (!permission.isGranted) return null;
    if (!context.mounted) return null;

    return Navigator.of(context, rootNavigator: true).push<XFile>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            InAppCameraCaptureScreen(initialLens: lens, title: title),
      ),
    );
  }
}
