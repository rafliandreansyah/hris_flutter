import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/widgets/app_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Layar kamera in-app (CameraX di Android) untuk mengambil satu foto.
///
/// Berbeda dengan `ImagePicker(source: camera)` yang membuka aplikasi kamera
/// bawaan (aplikasi kita jadi background dan rawan dimatikan OS pada RAM kecil),
/// layar ini membuat aplikasi tetap di foreground. Controller dilepas saat
/// aplikasi tidak aktif dan segera setelah foto diambil untuk menghemat memori.
///
/// Mengembalikan [XFile] lewat `Navigator.pop`, atau `null` bila dibatalkan.
class InAppCameraCaptureScreen extends StatefulWidget {
  final CameraLensDirection initialLens;
  final String title;

  const InAppCameraCaptureScreen({
    super.key,
    this.initialLens = CameraLensDirection.back,
    this.title = 'Ambil Foto',
  });

  @override
  State<InAppCameraCaptureScreen> createState() =>
      _InAppCameraCaptureScreenState();
}

class _InAppCameraCaptureScreenState extends State<InAppCameraCaptureScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  late CameraLensDirection _lens;
  XFile? _captured;
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _lens = widget.initialLens;
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _releaseController();
    } else if (state == AppLifecycleState.resumed &&
        _captured == null &&
        _controller == null) {
      _startCamera();
    }
  }

  Future<void> _releaseController() async {
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() {});
    await controller?.dispose();
  }

  CameraDescription? _pickCamera() {
    for (final c in _cameras) {
      if (c.lensDirection == _lens) return c;
    }
    return _cameras.isEmpty ? null : _cameras.first;
  }

  Future<void> _startCamera() async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
      final description = _pickCamera();
      if (description == null) {
        if (mounted) {
          setState(() => _errorMessage = 'Kamera tidak ditemukan di perangkat.');
        }
        return;
      }

      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted || _controller != controller) return;
      setState(() => _errorMessage = null);
    } catch (e) {
      debugPrint('[InAppCamera] Gagal menginisialisasi kamera: $e');
      if (mounted) {
        setState(() {
          _controller = null;
          _errorMessage = 'Tidak dapat membuka kamera. Silakan coba lagi.';
        });
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_isBusy) return;
    _lens = _lens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _releaseController();
    await _startCamera();
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (_isBusy || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _isBusy = true);
    try {
      final file = await controller.takePicture();
      // Lepas kamera sebelum preview/kompres agar memori kembali lega.
      await _releaseController();
      if (!mounted) return;
      setState(() => _captured = file);
    } catch (e) {
      debugPrint('[InAppCamera] Gagal mengambil foto: $e');
      if (mounted) {
        setState(() => _errorMessage = 'Gagal mengambil foto. Silakan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _retake() async {
    setState(() => _captured = null);
    await _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    final captured = _captured;
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.title,
            style: AppTypography.titleMedium.copyWith(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.x),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(child: _buildViewport(captured)),
              _buildControls(captured),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewport(XFile? captured) {
    if (captured != null) {
      return Center(
        child: Image.file(
          File(captured.path),
          fit: BoxFit.contain,
          cacheWidth: 1280,
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: AppLoadingIndicator(color: AppColors.brandTeal),
      );
    }
    return Center(child: CameraPreview(controller));
  }

  Widget _buildControls(XFile? captured) {
    if (captured != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Ulangi',
                variant: AppButtonVariant.outlined,
                leadingIcon: LucideIcons.rotateCcw,
                height: 50,
                foregroundColor: Colors.white,
                borderColor: Colors.white54,
                onPressed: _retake,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                text: 'Gunakan Foto',
                leadingIcon: LucideIcons.check,
                height: 50,
                onPressed: () => Navigator.of(context).pop(captured),
              ),
            ),
          ],
        ),
      );
    }

    final canFlip = _cameras.length > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48),
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isBusy ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: canFlip
                ? IconButton(
                    icon: const Icon(
                      LucideIcons.switchCamera,
                      color: Colors.white,
                    ),
                    onPressed: _flipCamera,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
