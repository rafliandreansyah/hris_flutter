import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum LivenessStatus {
  noFace,
  outsideOval,
  moving,
  tooFar,
  tooClose,
  tilt,
  multipleFaces,
  holding,
  success,
}

class LivenessCameraScreen extends StatefulWidget {
  final String title;

  const LivenessCameraScreen({
    super.key,
    this.title = 'Verifikasi Wajah Liveness AI',
  });

  @override
  State<LivenessCameraScreen> createState() => _LivenessCameraScreenState();
}

class _LivenessCameraScreenState extends State<LivenessCameraScreen>
    with SingleTickerProviderStateMixin {
  static const int _requiredHoldMs = 2000;

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _cameraIndex = 0;

  late final FaceDetector _faceDetector;
  bool _isProcessing = false;
  bool _isCaptured = false;
  bool _isProcessingCapture = false;

  LivenessStatus _status = LivenessStatus.noFace;
  String _statusMessage = 'Posisikan wajah Anda di dalam bingkai oval';
  double _distanceRatio = 0.5;
  double _holdProgress = 0.0;

  DateTime? _validHoldStartTime;
  Offset? _prevFaceCenter;
  double? _prevYaw;
  double? _prevRoll;
  double? _prevFaceHeight;

  bool _flashVisible = false;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamera tidak ditemukan di perangkat.')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      if (_cameraIndex == -1) _cameraIndex = 0;

      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      await controller.startImageStream(_processCameraFrame);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Failed to initialize CameraController: $e');
    }
  }

  void _processCameraFrame(CameraImage image) async {
    if (_isProcessing || _isCaptured || !mounted) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted || _isCaptured) {
        _isProcessing = false;
        return;
      }

      _evaluateFace(faces, image);
    } catch (e) {
      debugPrint('Error processing frame with ML Kit: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void _evaluateFace(List<Face> faces, CameraImage image) {
    if (faces.isEmpty) {
      _prevFaceCenter = null;
      _updateStatus(
        LivenessStatus.noFace,
        'Posisikan wajah Anda di dalam bingkai oval',
        0.5,
        shouldResetHold: true,
      );
      return;
    }

    if (faces.length > 1) {
      _prevFaceCenter = null;
      _updateStatus(
        LivenessStatus.multipleFaces,
        'Hanya satu wajah yang diperbolehkan di kamera',
        0.5,
        shouldResetHold: true,
      );
      return;
    }

    final face = faces.first;

    final yaw = face.headEulerAngleY ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;
    if (yaw.abs() > 14.0) {
      _prevFaceCenter = null;
      _updateStatus(
        LivenessStatus.tilt,
        'Tatap lurus ke depan (jangan menoleh)',
        0.5,
        shouldResetHold: true,
      );
      return;
    }
    if (roll.abs() > 14.0) {
      _prevFaceCenter = null;
      _updateStatus(
        LivenessStatus.tilt,
        'Tegakkan posisi kepala Anda',
        0.5,
        shouldResetHold: true,
      );
      return;
    }

    final mediaQuery = MediaQuery.maybeOf(context);
    final screenSize = mediaQuery?.size ?? const Size(390, 844);
    final ovalWidth = screenSize.width * 0.72;
    final ovalHeight = screenSize.width * 0.98;
    final ovalCenter = Offset(screenSize.width / 2, screenSize.height * 0.44);
    final ovalRect = Rect.fromCenter(
      center: ovalCenter,
      width: ovalWidth,
      height: ovalHeight,
    );

    final camera = _cameras[_cameraIndex];
    final rotation = _getImageRotation(camera.sensorOrientation);
    final bool isRotated = rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final double frameWidth =
        isRotated ? image.height.toDouble() : image.width.toDouble();
    final double frameHeight =
        isRotated ? image.width.toDouble() : image.height.toDouble();

    final previewW = _cameraController?.value.previewSize?.height ?? frameWidth;
    final previewH = _cameraController?.value.previewSize?.width ?? frameHeight;
    final scale = math.max(
      screenSize.width / previewW,
      screenSize.height / previewH,
    );
    final scaledWidth = previewW * scale;
    final scaledHeight = previewH * scale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;

    final bool isFront = camera.lensDirection == CameraLensDirection.front;
    final double screenFaceLeft;
    final double screenFaceRight;
    if (isFront) {
      screenFaceLeft = screenSize.width - (face.boundingBox.right * scale + offsetX);
      screenFaceRight = screenSize.width - (face.boundingBox.left * scale + offsetX);
    } else {
      screenFaceLeft = face.boundingBox.left * scale + offsetX;
      screenFaceRight = face.boundingBox.right * scale + offsetX;
    }
    final double screenFaceTop = face.boundingBox.top * scale + offsetY;
    final double screenFaceBottom = face.boundingBox.bottom * scale + offsetY;

    final screenFaceCenter = Offset(
      (screenFaceLeft + screenFaceRight) / 2,
      (screenFaceTop + screenFaceBottom) / 2,
    );
    final screenFaceRect = Rect.fromLTRB(
      screenFaceLeft,
      screenFaceTop,
      screenFaceRight,
      screenFaceBottom,
    );

    final effectiveFaceHeight = screenFaceRect.height;
    final effectiveFaceWidth = screenFaceRect.width;
    final faceSize = math.sqrt(effectiveFaceHeight * effectiveFaceWidth);
    final ovalSize = math.sqrt(ovalHeight * ovalWidth);
    final faceScaleRatio = faceSize / ovalSize;

    // Continuous dynamic gauge calculation (0.0 = Jauh, 0.5 = Optimal, 1.0 = Dekat)
    final double targetGaugeRatio;
    if (faceScaleRatio <= 0.60) {
      targetGaugeRatio =
          0.5 * ((faceScaleRatio - 0.28) / (0.60 - 0.28)).clamp(0.0, 1.0);
    } else {
      targetGaugeRatio = 0.5 +
          0.5 * ((faceScaleRatio - 0.60) / (0.88 - 0.60)).clamp(0.0, 1.0);
    }
    _distanceRatio = (_distanceRatio * 0.70) + (targetGaugeRatio * 0.30);

    if (faceScaleRatio < 0.44) {
      _prevFaceCenter = null;
      _updateStatus(
        LivenessStatus.tooFar,
        'Dekatkan wajah Anda ke kamera',
        _distanceRatio,
        shouldResetHold: true,
      );
      return;
    }

    if (faceScaleRatio > 0.80) {
      _prevFaceCenter = null;
      _updateStatus(
        LivenessStatus.tooClose,
        'Mundurkan wajah Anda sedikit',
        _distanceRatio,
        shouldResetHold: true,
      );
      return;
    }

    final rx = ovalWidth / 2;
    final ry = ovalHeight / 2;
    final dx = (screenFaceCenter.dx - ovalCenter.dx) / rx;
    final dy = (screenFaceCenter.dy - ovalCenter.dy) / ry;
    final centerDistSq = dx * dx + dy * dy;

    final bool isCenterInside = centerDistSq <= 0.38;
    final bool isBoundsInside = screenFaceRect.left >= ovalRect.left - 24 &&
        screenFaceRect.right <= ovalRect.right + 24 &&
        screenFaceRect.top >= ovalRect.top - 24 &&
        screenFaceRect.bottom <= ovalRect.bottom + 24;

    if (!isCenterInside || !isBoundsInside) {
      _prevFaceCenter = null;
      _updateStatus(
        LivenessStatus.outsideOval,
        'Posisikan wajah Anda pas di dalam bingkai oval',
        _distanceRatio,
        shouldResetHold: true,
      );
      return;
    }

    if (_prevFaceCenter != null) {
      final moveDistance = (screenFaceCenter - _prevFaceCenter!).distance;
      final yawDiff = (yaw - (_prevYaw ?? yaw)).abs();
      final rollDiff = (roll - (_prevRoll ?? roll)).abs();
      final sizeDiff = ((screenFaceRect.height -
                  (_prevFaceHeight ?? screenFaceRect.height)) /
              ovalHeight)
          .abs();

      if (moveDistance > 16.0 ||
          yawDiff > 5.5 ||
          rollDiff > 5.5 ||
          sizeDiff > 0.06) {
        _prevFaceCenter = screenFaceCenter;
        _prevYaw = yaw;
        _prevRoll = roll;
        _prevFaceHeight = screenFaceRect.height;
        _updateStatus(
          LivenessStatus.moving,
          'Gerakan terdeteksi! Tahan posisi jangan bergerak...',
          _distanceRatio,
          shouldResetHold: true,
        );
        return;
      }
    }

    _prevFaceCenter = screenFaceCenter;
    _prevYaw = yaw;
    _prevRoll = roll;
    _prevFaceHeight = screenFaceRect.height;

    final now = DateTime.now();
    _validHoldStartTime ??= now;
    final elapsedMs = now.difference(_validHoldStartTime!).inMilliseconds;
    _holdProgress = (elapsedMs / _requiredHoldMs).clamp(0.0, 1.0);

    final remainingSec = math
        .max(0.0, (_requiredHoldMs - elapsedMs) / 1000.0)
        .toStringAsFixed(1);

    _status = LivenessStatus.holding;
    _statusMessage = 'Tahan posisi... ${remainingSec}s';

    if (elapsedMs >= _requiredHoldMs && !_isCaptured) {
      _status = LivenessStatus.success;
      _statusMessage = 'Wajah Valid! Mengambil foto...';
      _triggerAutoCapture();
    }

    setState(() {});
  }

  void _updateStatus(
    LivenessStatus status,
    String message,
    double distance, {
    bool shouldResetHold = false,
  }) {
    _status = status;
    _statusMessage = message;
    _distanceRatio = distance;

    if (shouldResetHold) {
      _holdProgress = 0.0;
      _validHoldStartTime = null;
    }
    setState(() {});
  }

  Future<void> _triggerAutoCapture() async {
    _isCaptured = true;
    HapticFeedback.heavyImpact();

    setState(() {
      _flashVisible = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 90));
      if (mounted) {
        setState(() {
          _flashVisible = false;
          _isProcessingCapture = true;
        });
      }

      await _cameraController?.stopImageStream();
      final xfile = await _cameraController?.takePicture();

      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;

      if (xfile != null) {
        Navigator.of(context).pop(File(xfile.path));
      } else {
        Navigator.of(context).pop(null);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) Navigator.of(context).pop(null);
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    final rotation = _getImageRotation(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        (Platform.isAndroid
            ? InputImageFormat.nv21
            : InputImageFormat.bgra8888);

    if (image.planes.length == 1) {
      final plane = image.planes.first;
      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    }

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  InputImageRotation? _getImageRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Color _getBorderColor() {
    switch (_status) {
      case LivenessStatus.holding:
      case LivenessStatus.success:
        return AppColors.success;
      case LivenessStatus.tooFar:
      case LivenessStatus.tooClose:
      case LivenessStatus.outsideOval:
        return AppColors.warning;
      case LivenessStatus.moving:
      case LivenessStatus.tilt:
      case LivenessStatus.multipleFaces:
        return const Color(0xFFEA580C);
      case LivenessStatus.noFace:
        return Colors.white.withValues(alpha: 0.45);
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case LivenessStatus.holding:
      case LivenessStatus.success:
        return LucideIcons.checkCircle2;
      case LivenessStatus.outsideOval:
        return LucideIcons.scan;
      case LivenessStatus.moving:
        return LucideIcons.move;
      case LivenessStatus.tooFar:
        return LucideIcons.zoomIn;
      case LivenessStatus.tooClose:
        return LucideIcons.zoomOut;
      case LivenessStatus.tilt:
        return LucideIcons.smartphoneNfc;
      case LivenessStatus.multipleFaces:
        return LucideIcons.users;
      case LivenessStatus.noFace:
        return LucideIcons.scanFace;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final ovalWidth = screenSize.width * 0.72;
    final ovalHeight = screenSize.width * 0.98;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ??
                      screenSize.width,
                  height: _cameraController!.value.previewSize?.width ??
                      screenSize.height,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          CustomPaint(
            size: screenSize,
            painter: _OvalOverlayPainter(
              ovalWidth: ovalWidth,
              ovalHeight: ovalHeight,
              borderColor: _getBorderColor(),
              progress: _holdProgress,
              isHolding: _status == LivenessStatus.holding ||
                  _status == LivenessStatus.success,
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(null),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        widget.title,
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DistanceGauge(ratio: _distanceRatio),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _getBorderColor().withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _getBorderColor().withValues(alpha: 0.25),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: _getBorderColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _statusMessage,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_flashVisible)
            AnimatedOpacity(
              opacity: _flashVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 90),
              child: Container(color: Colors.white),
            ),

          if (_isProcessingCapture)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.brandTeal,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Memproses foto...',
                        style: AppTypography.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DistanceGauge extends StatelessWidget {
  final double ratio;

  const _DistanceGauge({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final clampedRatio = ratio.clamp(0.0, 1.0);
    final isOptimal = clampedRatio >= 0.35 && clampedRatio <= 0.65;
    final dotColor = isOptimal ? AppColors.success : AppColors.warning;

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOptimal
              ? AppColors.success.withValues(alpha: 0.35)
              : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jauh',
                style: AppTypography.labelSmall.copyWith(
                  color: clampedRatio < 0.35
                      ? AppColors.warning
                      : Colors.white60,
                  fontSize: 10,
                  fontWeight: clampedRatio < 0.35
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              Text(
                'Optimal',
                style: AppTypography.labelSmall.copyWith(
                  color: isOptimal ? AppColors.success : Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Dekat',
                style: AppTypography.labelSmall.copyWith(
                  color: clampedRatio > 0.65
                      ? AppColors.warning
                      : Colors.white60,
                  fontSize: 10,
                  fontWeight: clampedRatio > 0.65
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.warning,
                      AppColors.success,
                      AppColors.warning,
                    ],
                    stops: [0.15, 0.50, 0.85],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 2,
                  height: 9,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 100),
                alignment: Alignment(
                  (clampedRatio * 2) - 1,
                  0.0,
                ),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OvalOverlayPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final Color borderColor;
  final double progress;
  final bool isHolding;

  _OvalOverlayPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.borderColor,
    required this.progress,
    this.isHolding = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.44);
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final ovalPath = Path()..addOval(ovalRect);
    final cutoutPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      ovalPath,
    );

    final darkPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cutoutPath, darkPaint);

    final borderPaint = Paint()
      ..color = borderColor.withValues(alpha: isHolding ? 0.35 : 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(ovalRect, borderPaint);

    if (progress > 0.0) {
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      final glowPaint = Paint()
        ..color = AppColors.brandTeal.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawArc(
        ovalRect,
        -math.pi / 2,
        sweepAngle,
        false,
        glowPaint,
      );

      final progressPaint = Paint()
        ..shader = const SweepGradient(
          startAngle: 0.0,
          endAngle: 2 * math.pi,
          colors: [
            AppColors.brandTeal,
            AppColors.success,
            AppColors.brandTeal,
          ],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(ovalRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        ovalRect,
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OvalOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.progress != progress ||
        oldDelegate.isHolding != isHolding;
  }
}
