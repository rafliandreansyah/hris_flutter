import 'package:hris_flutter/core/widgets/app_loading_indicator.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/app/config/app_design.dart';
import 'package:hris_flutter/app/config/app_typography.dart';
import 'package:hris_flutter/core/utils/app_dialog_util.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum LivenessStatus {
  noFace,
  outsideCircle,
  moving,
  tooFar,
  tooClose,
  tilt,
  multipleFaces,
  holding,
  success,
}

/// Lingkaran panduan wajah; dipakai bersama oleh deteksi dan painter.
/// Ruang atas (header + instruksi) dan bawah (checklist) disisihkan agar tidak bertabrakan di HP kecil.
Rect _circleRect(MediaQueryData mq) {
  final top = mq.padding.top + 214;
  final bottom = mq.size.height - mq.padding.bottom - 150;
  final radius = math.max(
    0.0,
    math.min(mq.size.width * 0.39, (bottom - top) / 2),
  );
  return Rect.fromCircle(
    center: Offset(mq.size.width / 2, (top + bottom) / 2),
    radius: radius,
  );
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
  static const Duration _holdDuration = Duration(milliseconds: 1200);

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  int _cameraIndex = 0;

  late final FaceDetector _faceDetector;
  late final AnimationController _holdController;
  bool _isProcessing = false;
  bool _isCaptured = false;
  bool _isProcessingCapture = false;

  LivenessStatus _status = LivenessStatus.noFace;
  String _statusMessage = 'Posisikan wajah Anda di dalam lingkaran';
  bool _faceOk = false;
  bool _distanceOk = false;
  bool _alignOk = false;
  int _invalidStreak = 0;

  Offset? _prevFaceCenter;
  double? _prevYaw;
  double? _prevRoll;
  double? _prevFaceHeight;

  bool _flashVisible = false;
  bool _reduceMotion = false;

  bool get _isHolding =>
      _status == LivenessStatus.holding || _status == LivenessStatus.success;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
        minFaceSize: 0.15,
      ),
    );
    _holdController = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_isCaptured) {
          _triggerAutoCapture();
        }
      });

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          await AppDialogUtil.showError(
            context,
            message: 'Kamera tidak ditemukan di perangkat.',
          );
          if (mounted) Navigator.of(context).pop();
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
    if (faces.isEmpty || faces.length > 1) {
      _prevFaceCenter = null;
      _applyResult(
        faces.isEmpty ? LivenessStatus.noFace : LivenessStatus.multipleFaces,
        faces.isEmpty
            ? 'Posisikan wajah Anda di dalam lingkaran'
            : 'Hanya satu wajah yang diperbolehkan',
        faceOk: false,
        distanceOk: false,
        alignOk: false,
        immediate: true,
      );
      return;
    }

    final face = faces.first;
    final yaw = face.headEulerAngleY ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    final mq =
        MediaQuery.maybeOf(context) ??
        const MediaQueryData(size: Size(390, 844));
    final screenSize = mq.size;
    final circle = _circleRect(mq);

    final camera = _cameras[_cameraIndex];
    final rotation = _getImageRotation(camera.sensorOrientation);
    final bool isRotated =
        rotation == InputImageRotation.rotation90deg ||
        rotation == InputImageRotation.rotation270deg;
    final double frameWidth = isRotated
        ? image.height.toDouble()
        : image.width.toDouble();
    final double frameHeight = isRotated
        ? image.width.toDouble()
        : image.height.toDouble();

    final previewW = _cameraController?.value.previewSize?.height ?? frameWidth;
    final previewH = _cameraController?.value.previewSize?.width ?? frameHeight;
    final scale = math.max(
      screenSize.width / previewW,
      screenSize.height / previewH,
    );
    final offsetX = (screenSize.width - previewW * scale) / 2;
    final offsetY = (screenSize.height - previewH * scale) / 2;

    final box = face.boundingBox;
    final bool isFront = camera.lensDirection == CameraLensDirection.front;
    final faceRect = Rect.fromLTRB(
      isFront
          ? screenSize.width - (box.right * scale + offsetX)
          : box.left * scale + offsetX,
      box.top * scale + offsetY,
      isFront
          ? screenSize.width - (box.left * scale + offsetX)
          : box.right * scale + offsetX,
      box.bottom * scale + offsetY,
    );

    final faceScaleRatio =
        math.sqrt(faceRect.width * faceRect.height) / circle.width;
    final bool tooFar = faceScaleRatio < 0.45;
    final bool tooClose = faceScaleRatio > 0.85;

    final dx = (faceRect.center.dx - circle.center.dx) / (circle.width / 2);
    final dy = (faceRect.center.dy - circle.center.dy) / (circle.height / 2);
    final bool isCentered =
        dx * dx + dy * dy <= 0.36 &&
        circle.inflate(24).contains(faceRect.topLeft) &&
        circle.inflate(24).contains(faceRect.bottomRight);

    final bool isStraight = yaw.abs() <= 14.0 && roll.abs() <= 14.0;

    bool isSteady = true;
    if (_prevFaceCenter != null) {
      final moveDistance = (faceRect.center - _prevFaceCenter!).distance;
      final yawDiff = (yaw - (_prevYaw ?? yaw)).abs();
      final rollDiff = (roll - (_prevRoll ?? roll)).abs();
      final sizeDiff =
          ((faceRect.height - (_prevFaceHeight ?? faceRect.height)) /
                  circle.height)
              .abs();
      isSteady =
          moveDistance <= 28.0 &&
          yawDiff <= 8.0 &&
          rollDiff <= 8.0 &&
          sizeDiff <= 0.10;
    }
    _prevFaceCenter = faceRect.center;
    _prevYaw = yaw;
    _prevRoll = roll;
    _prevFaceHeight = faceRect.height;

    final distanceOk = !tooFar && !tooClose;
    final alignOk = isCentered && isStraight && isSteady;

    final LivenessStatus status;
    final String message;
    if (tooFar) {
      status = LivenessStatus.tooFar;
      message = 'Dekatkan wajah Anda ke kamera';
    } else if (tooClose) {
      status = LivenessStatus.tooClose;
      message = 'Mundurkan wajah Anda sedikit';
    } else if (!isCentered) {
      status = LivenessStatus.outsideCircle;
      message = _directionHint(dx, dy);
    } else if (yaw.abs() > 14.0) {
      status = LivenessStatus.tilt;
      message = 'Tatap lurus ke depan, jangan menoleh';
    } else if (roll.abs() > 14.0) {
      status = LivenessStatus.tilt;
      message = 'Tegakkan posisi kepala Anda';
    } else if (!isSteady) {
      status = LivenessStatus.moving;
      message = 'Tahan posisi, jangan bergerak';
    } else {
      status = LivenessStatus.holding;
      message = 'Posisi pas! Tahan sebentar...';
    }

    _applyResult(
      status,
      message,
      faceOk: true,
      distanceOk: distanceOk,
      alignOk: alignOk,
    );
  }

  String _directionHint(double dx, double dy) {
    if (dx.abs() >= dy.abs()) {
      return dx > 0 ? 'Geser wajah ke kiri' : 'Geser wajah ke kanan';
    }
    return dy > 0 ? 'Naikkan wajah sedikit' : 'Turunkan wajah sedikit';
  }

  /// Frame valid memajukan ring; frame gagal me-reset ring ke 0.
  /// Kegagalan ringan perlu 2 frame berturut-turut agar getaran kecil tidak me-reset.
  void _applyResult(
    LivenessStatus status,
    String message, {
    required bool faceOk,
    required bool distanceOk,
    required bool alignOk,
    bool immediate = false,
  }) {
    if (_isCaptured) return;

    if (status == LivenessStatus.holding) {
      _invalidStreak = 0;
      if (!_isHolding) HapticFeedback.selectionClick();
      if (!_holdController.isAnimating && _holdController.value < 1.0) {
        _holdController.forward();
      }
    } else {
      _invalidStreak++;
      if (!immediate && _invalidStreak < 2) return;
      _holdController.value = 0.0;
    }

    setState(() {
      _status = status;
      _statusMessage = message;
      _faceOk = faceOk;
      _distanceOk = distanceOk;
      _alignOk = alignOk;
    });
  }

  Future<void> _triggerAutoCapture() async {
    _isCaptured = true;
    HapticFeedback.heavyImpact();

    setState(() {
      _status = LivenessStatus.success;
      _statusMessage = 'Berhasil! Mengambil foto...';
      _flashVisible = !_reduceMotion;
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

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
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
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _holdController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_status) {
      case LivenessStatus.holding:
      case LivenessStatus.success:
        return AppColors.success;
      case LivenessStatus.tooFar:
      case LivenessStatus.tooClose:
      case LivenessStatus.outsideCircle:
        return AppColors.warning;
      case LivenessStatus.moving:
      case LivenessStatus.tilt:
      case LivenessStatus.multipleFaces:
        return AppColors.errorRed;
      case LivenessStatus.noFace:
        return Colors.white;
    }
  }

  IconData _getStatusIcon() {
    switch (_status) {
      case LivenessStatus.holding:
      case LivenessStatus.success:
        return LucideIcons.circleCheck;
      case LivenessStatus.outsideCircle:
        return LucideIcons.move;
      case LivenessStatus.moving:
        return LucideIcons.hand;
      case LivenessStatus.tooFar:
        return LucideIcons.zoomIn;
      case LivenessStatus.tooClose:
        return LucideIcons.zoomOut;
      case LivenessStatus.tilt:
        return LucideIcons.rotateCcw;
      case LivenessStatus.multipleFaces:
        return LucideIcons.users;
      case LivenessStatus.noFace:
        return LucideIcons.scanFace;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenSize = mq.size;
    final circle = _circleRect(mq);
    final statusColor = _getStatusColor();
    _reduceMotion = mq.disableAnimations;
    final fade = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Scaffold(
      backgroundColor: Colors.black,
      // Overlay text has fixed room around the circle; cap scaling so it never overlaps.
      body: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_cameraController != null &&
                _cameraController!.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width:
                        _cameraController!.value.previewSize?.height ??
                        screenSize.width,
                    height:
                        _cameraController!.value.previewSize?.width ??
                        screenSize.height,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              )
            else
              const Center(
                child: AppLoadingIndicator(color: AppColors.primary),
              ),

            AnimatedBuilder(
              animation: _holdController,
              builder: (context, _) => Semantics(
                label: 'Progres verifikasi wajah',
                value: '${(_holdController.value * 100).round()}%',
                child: CustomPaint(
                  size: screenSize,
                  painter: _CircleOverlayPainter(
                    circle: circle,
                    statusColor: statusColor,
                    progress: _holdController.value,
                    isHolding: _isHolding,
                    showGlow: !_reduceMotion,
                  ),
                ),
              ),
            ),

            // Header
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Tutup',
                        icon: const Icon(LucideIcons.x, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(null),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: AppRadius.borderFull,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxxl),
                    ],
                  ),
                ),
              ),
            ),

            // Status pill + instruction above the circle
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: screenSize.height - circle.top + AppSpacing.lg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: fade,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md - 4,
                      vertical: AppSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: AppRadius.borderFull,
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            _getStatusIcon(),
                            color: statusColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Text(
                          _isHolding ? 'Posisi Pas' : 'Belum Pas',
                          style: AppTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),
                  Semantics(
                    liveRegion: true,
                    child: AnimatedSwitcher(
                      duration: fade,
                      child: Text(
                        _statusMessage,
                        key: ValueKey(_statusMessage),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Requirement checklist below the circle
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              top: circle.bottom + AppSpacing.xl,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.72),
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RequirementItem(label: 'Wajah terdeteksi', ok: _faceOk),
                    const SizedBox(height: AppSpacing.sm),
                    _RequirementItem(label: 'Jarak pas', ok: _distanceOk),
                    const SizedBox(height: AppSpacing.sm),
                    _RequirementItem(label: 'Di tengah & lurus', ok: _alignOk),
                  ],
                ),
              ),
            ),

            if (_status == LivenessStatus.success)
              Positioned.fromRect(
                rect: circle,
                child: const Center(
                  child: Icon(
                    LucideIcons.circleCheck,
                    color: AppColors.success,
                    size: 72,
                    semanticLabel: 'Wajah berhasil diverifikasi',
                  ),
                ),
              ),

            if (_flashVisible) Container(color: Colors.white),

            if (_isProcessingCapture)
              Container(
                color: Colors.black.withValues(alpha: 0.65),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const AppLoadingIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String label;
  final bool ok;

  const _RequirementItem({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: '$label: ${ok ? 'terpenuhi' : 'belum terpenuhi'}',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(
              ok ? LucideIcons.circleCheck : LucideIcons.circle,
              color: ok ? AppColors.success : Colors.white,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: ok ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleOverlayPainter extends CustomPainter {
  final Rect circle;
  final Color statusColor;
  final double progress;
  final bool isHolding;
  final bool showGlow;

  _CircleOverlayPainter({
    required this.circle,
    required this.statusColor,
    required this.progress,
    required this.isHolding,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cutoutPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addOval(circle),
    );
    canvas.drawPath(
      cutoutPath,
      Paint()..color = Colors.black.withValues(alpha: 0.65),
    );

    // Track
    canvas.drawOval(
      circle,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    // Status ring
    canvas.drawOval(
      circle,
      Paint()
        ..color = statusColor.withValues(alpha: isHolding ? 0.35 : 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    if (progress <= 0.0) return;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    if (showGlow) {
      canvas.drawArc(
        circle,
        -math.pi / 2,
        sweepAngle,
        false,
        Paint()
          ..color = AppColors.success.withValues(alpha: 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawArc(
      circle,
      -math.pi / 2,
      sweepAngle,
      false,
      Paint()
        ..shader = const SweepGradient(
          colors: [AppColors.brandTeal, AppColors.success, AppColors.brandTeal],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(circle)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleOverlayPainter oldDelegate) {
    return oldDelegate.circle != circle ||
        oldDelegate.statusColor != statusColor ||
        oldDelegate.progress != progress ||
        oldDelegate.isHolding != isHolding ||
        oldDelegate.showGlow != showGlow;
  }
}
