import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/config/api_config.dart';
import 'package:foodhub_mobile/l10n/app_strings.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/ai_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:image_picker/image_picker.dart';

class AiCaptureScreen extends StatefulWidget {
  const AiCaptureScreen({super.key});

  static Future<AiCaptureResult?> show(BuildContext context) {
    final lang = LangScope.of(context);
    return Navigator.of(context).push<AiCaptureResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LangScope(
          lang: lang,
          child: const AiCaptureScreen(),
        ),
      ),
    );
  }

  @override
  State<AiCaptureScreen> createState() => _AiCaptureScreenState();
}

class _AiCaptureScreenState extends State<AiCaptureScreen> {
  final AiService _aiService = AiService();
  final ImagePicker _galleryPicker = ImagePicker();
  final List<String> _accumulatedIngredients = [];

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  AiCaptureMode _mode = AiCaptureMode.ingredients;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _initError;

  ImageFormatGroup get _preferredFormat {
    if (kIsWeb) return ImageFormatGroup.jpeg;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return ImageFormatGroup.bgra8888;
    }
    return ImageFormatGroup.yuv420;
  }

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _initError = S.of(context).noCameraFound;
          _isInitializing = false;
        });
        return;
      }

      final backCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: _preferredFormat,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = S.of(context).cameraInitError;
        _isInitializing = false;
      });
      debugPrint('Camera init failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Color get _accentColor => _mode == AiCaptureMode.ingredients
      ? const Color(0xFF059669)
      : const Color(0xFFA855F7);

  Future<void> _processBytes(List<int> bytes, String filename) async {
    setState(() => _isProcessing = true);

    try {
      if (_mode == AiCaptureMode.ingredients) {
        final result = await _aiService.detectIngredients(
          bytes: bytes,
          filename: filename,
          language: LangScope.of(context),
        );

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (result.ingredients.isEmpty && result.detections.isEmpty) {
          _showSnack(S.of(context).noIngredientsDetected);
          return;
        }

        final lang = LangScope.of(context);
        final selected = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: const Color(0xFF0B1B38),
          builder: (ctx) => LangScope(
            lang: lang,
            child: _DetectedIngredientsSheet(
            initialItems: result.ingredients.isNotEmpty
                ? result.ingredients
                : result.detections.map((d) => d.label).toSet().toList(),
            sourceName: filename,
            captureBytes: Uint8List.fromList(bytes),
            annotatedImageUrl: result.annotatedImageUrl,
            annotatedImageBytes: result.annotatedImageBytes,
            imageUrl: result.imageUrl,
            detections: result.detections,
          ),
          ),
        );

        if (!mounted || selected == null || selected.isEmpty) return;

        setState(() {
          for (final item in selected) {
            if (!_accumulatedIngredients.contains(item)) {
              _accumulatedIngredients.add(item);
            }
          }
        });
      } else {
        final result = await _aiService.recognizeDish(
          bytes: bytes,
          filename: filename,
        );

        if (!mounted) return;
        setState(() => _isProcessing = false);
        Navigator.of(context).pop(AiCaptureDishResult(result));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSnack(
        _mode == AiCaptureMode.ingredients
            ? S.of(context).ingredientsDetectionFailed
            : S.of(context).dishRecognitionFailed,
      );
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isProcessing) {
      return;
    }

    try {
      final xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();
      await _processBytes(bytes, xFile.name);
    } catch (_) {
      if (!mounted) return;
      _showSnack(S.of(context).capturePhotoFailed);
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isProcessing) return;

    final file = await _galleryPicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 1600,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    await _processBytes(bytes, file.name);
  }

  void _showSnack(String message) {
    showErrorToast(context, message);
  }

  void _finishIngredients() {
    if (_accumulatedIngredients.isEmpty) {
      _showSnack(S.of(context).scanAtLeastOneIngredient);
      return;
    }
    Navigator.of(context).pop(
      AiCaptureIngredientsResult(List<String>.from(_accumulatedIngredients)),
    );
  }

  bool get _cameraReady =>
      _controller != null && _controller!.value.isInitialized;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isInitializing)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          else if (_cameraReady)
            CameraPreview(_controller!)
          else
            _CameraUnavailableBackdrop(
              message: _initError ?? s.cameraUnavailable,
            ),

          if (!_isInitializing) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0, 0.35, 1],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        if (_mode == AiCaptureMode.ingredients &&
                            _accumulatedIngredients.isNotEmpty)
                          TextButton(
                            onPressed: _finishIngredients,
                            child: Text(
                              s.doneWithCount(_accumulatedIngredients.length),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _cameraReady
                          ? (_mode == AiCaptureMode.ingredients
                              ? s.pointAtIngredients
                              : s.frameFullDish)
                          : s.uploadFromGalleryHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ModeToggle(
                    mode: _mode,
                    onChanged: _isProcessing
                        ? null
                        : (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 20),
                  if (_mode == AiCaptureMode.ingredients &&
                      _accumulatedIngredients.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: _accumulatedIngredients
                            .map(
                              (item) => Chip(
                                label: Text(
                                  item,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_cameraReady) ...[
                          IconButton(
                            onPressed:
                                _isProcessing ? null : _pickFromGallery,
                            tooltip: s.uploadFromGalleryTooltip,
                            icon: Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 28),
                          GestureDetector(
                            onTap: _isProcessing ? null : _capturePhoto,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: _isProcessing
                                        ? Colors.white38
                                        : _accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 76),
                        ] else
                          FilledButton.icon(
                            onPressed:
                                _isProcessing ? null : _pickFromGallery,
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                            ),
                            icon: const Icon(Icons.upload_rounded, size: 20),
                            label: Text(s.uploadPhoto),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: _accentColor),
                    const SizedBox(height: 12),
                    Text(
                      _mode == AiCaptureMode.ingredients
                          ? s.detectingIngredients
                          : s.recognizingDish,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final AiCaptureMode mode;
  final ValueChanged<AiCaptureMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: s.ingredientDetectMode,
            selected: mode == AiCaptureMode.ingredients,
            color: const Color(0xFF059669),
            onTap: onChanged == null
                ? null
                : () => onChanged!(AiCaptureMode.ingredients),
          ),
          _ModeButton(
            label: s.dishDetectMode,
            selected: mode == AiCaptureMode.dish,
            color: const Color(0xFFA855F7),
            onTap: onChanged == null
                ? null
                : () => onChanged!(AiCaptureMode.dish),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraUnavailableBackdrop extends StatelessWidget {
  const _CameraUnavailableBackdrop({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B1220),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 160),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 8),
              Text(
                S.of(context).useUploadButtonHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectedIngredientsSheet extends StatefulWidget {
  const _DetectedIngredientsSheet({
    required this.initialItems,
    required this.sourceName,
    required this.captureBytes,
    this.annotatedImageUrl = '',
    this.annotatedImageBytes,
    this.imageUrl = '',
    this.detections = const [],
  });

  final List<String> initialItems;
  final String sourceName;
  final Uint8List captureBytes;
  final String annotatedImageUrl;
  final Uint8List? annotatedImageBytes;
  final String imageUrl;
  final List<DetectionItemModel> detections;

  @override
  State<_DetectedIngredientsSheet> createState() =>
      _DetectedIngredientsSheetState();
}

class _DetectedIngredientsSheetState extends State<_DetectedIngredientsSheet> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialItems.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).confirmDetectedIngredients,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.sourceName,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _AnnotatedResultImage(
                  captureBytes: widget.captureBytes,
                  annotatedImageUrl: widget.annotatedImageUrl,
                  annotatedImageBytes: widget.annotatedImageBytes,
                  imageUrl: widget.imageUrl,
                  detections: widget.detections,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.initialItems.map(
                (item) => CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item,
                    style: const TextStyle(color: Color(0xFFF8FAFC)),
                  ),
                  activeColor: const Color(0xFF059669),
                  value: _selected.contains(item),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(item);
                      } else {
                        _selected.remove(item);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected.toList()),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(S.of(context).addSelected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotatedResultImage extends StatefulWidget {
  const _AnnotatedResultImage({
    required this.captureBytes,
    this.annotatedImageUrl = '',
    this.annotatedImageBytes,
    this.imageUrl = '',
    this.detections = const [],
  });

  final Uint8List captureBytes;
  final String annotatedImageUrl;
  final Uint8List? annotatedImageBytes;
  final String imageUrl;
  final List<DetectionItemModel> detections;

  @override
  State<_AnnotatedResultImage> createState() => _AnnotatedResultImageState();
}

enum _AnnotatedSource { url, base64, overlay }

class _AnnotatedResultImageState extends State<_AnnotatedResultImage> {
  double? _captureAspect;
  bool _annotatedUrlFailed = false;

  @override
  void initState() {
    super.initState();
    _decodeCaptureAspect();
  }

  Future<void> _decodeCaptureAspect() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.captureBytes);
      final frame = await codec.getNextFrame();
      final w = frame.image.width;
      final h = frame.image.height;
      frame.image.dispose();
      if (!mounted || w <= 0 || h <= 0) return;
      setState(() => _captureAspect = w / h);
    } catch (_) {
      // Fallback overlay uses fitWidth without AspectRatio if decode fails.
    }
  }

  _AnnotatedSource get _source {
    final resolved = ApiConfig.resolveImageUrl(widget.annotatedImageUrl);
    if (resolved.isNotEmpty && !_annotatedUrlFailed) {
      return _AnnotatedSource.url;
    }
    if (widget.annotatedImageBytes != null &&
        widget.annotatedImageBytes!.isNotEmpty) {
      return _AnnotatedSource.base64;
    }
    return _AnnotatedSource.overlay;
  }

  @override
  Widget build(BuildContext context) {
    final source = _source;
    Widget image;
    switch (source) {
      case _AnnotatedSource.url:
        image = Image.network(
          ApiConfig.resolveImageUrl(widget.annotatedImageUrl),
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_annotatedUrlFailed) {
                setState(() => _annotatedUrlFailed = true);
              }
            });
            return _localPhotoWithBoxes();
          },
        );
      case _AnnotatedSource.base64:
        image = Image.memory(
          widget.annotatedImageBytes!,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          errorBuilder: (_, __, ___) => _localPhotoWithBoxes(),
        );
      case _AnnotatedSource.overlay:
        image = _localPhotoWithBoxes();
    }

    return image;
  }

  Widget _localPhotoWithBoxes() {
    // Size stack to decoded capture aspect so normalized boxes map to pixels,
    // not a letterboxed/fill mismatch.
    final photo = Image.memory(
      widget.captureBytes,
      width: double.infinity,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) {
        final resolved = ApiConfig.resolveImageUrl(widget.imageUrl);
        if (resolved.isEmpty) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white38,
              ),
            ),
          );
        }
        return Image.network(
          resolved,
          width: double.infinity,
          fit: BoxFit.fitWidth,
        );
      },
    );

    final stack = Stack(
      fit: StackFit.passthrough,
      children: [
        photo,
        if (widget.detections.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: _DetectionOverlayPainter(
                detections: widget.detections,
                accent: const Color(0xFF059669),
              ),
            ),
          ),
      ],
    );

    final aspect = _captureAspect;
    if (aspect == null || aspect <= 0) {
      return ColoredBox(color: const Color(0xFF0F172A), child: stack);
    }

    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: AspectRatio(aspectRatio: aspect, child: stack),
    );
  }
}

class _DetectionOverlayPainter extends CustomPainter {
  _DetectionOverlayPainter({
    required this.detections,
    required this.accent,
  });

  final List<DetectionItemModel> detections;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = accent;

    final labelBg = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.92);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final det in detections) {
      if (det.bbox.length != 4) continue;
      final rect = Rect.fromLTRB(
        det.bbox[0] * size.width,
        det.bbox[1] * size.height,
        det.bbox[2] * size.width,
        det.bbox[3] * size.height,
      );
      canvas.drawRect(rect, stroke);

      final title =
          '${det.label} ${(det.confidence * 100).clamp(0, 100).toStringAsFixed(0)}%';
      textPainter.text = TextSpan(
        text: title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
      );
      textPainter.layout(maxWidth: size.width);

      final labelTop = (rect.top - textPainter.height - 4).clamp(0.0, size.height);
      final labelLeft = rect.left.clamp(0.0, size.width - textPainter.width);
      final bgRect = Rect.fromLTWH(
        labelLeft,
        labelTop,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
        labelBg,
      );
      textPainter.paint(canvas, Offset(labelLeft + 4, labelTop + 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionOverlayPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.accent != accent;
  }
}
