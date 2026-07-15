import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/ai_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:image_picker/image_picker.dart';

class AiCaptureScreen extends StatefulWidget {
  const AiCaptureScreen({super.key});

  static Future<AiCaptureResult?> show(BuildContext context) {
    return Navigator.of(context).push<AiCaptureResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const AiCaptureScreen(),
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
          _initError = 'No camera found on this device.';
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
        _initError = 'Unable to start camera. Check permissions.';
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

  String get _hintText => _mode == AiCaptureMode.ingredients
      ? 'Point at ingredients'
      : 'Frame the full dish';

  Future<void> _processBytes(List<int> bytes, String filename) async {
    setState(() => _isProcessing = true);

    try {
      if (_mode == AiCaptureMode.ingredients) {
        final result = await _aiService.detectIngredients(
          bytes: bytes,
          filename: filename,
        );

        if (!mounted) return;
        setState(() => _isProcessing = false);

        if (result.ingredients.isEmpty && result.detections.isEmpty) {
          _showSnack('No ingredients detected. Try another photo.');
          return;
        }

        final selected = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: const Color(0xFF0B1B38),
          builder: (context) => _DetectedIngredientsSheet(
            initialItems: result.ingredients.isNotEmpty
                ? result.ingredients
                : result.detections.map((d) => d.label).toSet().toList(),
            sourceName: filename,
            captureBytes: Uint8List.fromList(bytes),
            annotatedImageBytes: result.annotatedImageBytes,
            imageUrl: result.imageUrl,
            detections: result.detections,
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
            ? 'Ingredients detection failed.'
            : 'Dish recognition failed. Please try another photo.',
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
      _showSnack('Failed to capture photo.');
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
      _showSnack('Scan at least one ingredient or tap close.');
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
              message: _initError ?? 'Camera unavailable',
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
                              'Done (${_accumulatedIngredients.length})',
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
                          ? _hintText
                          : 'Upload a photo from your gallery',
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
                            tooltip: 'Upload from gallery',
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
                            label: const Text('Upload photo'),
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
                          ? 'Detecting ingredients...'
                          : 'Recognizing dish...',
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
            label: 'Ingredient detect',
            selected: mode == AiCaptureMode.ingredients,
            color: const Color(0xFF059669),
            onTap: onChanged == null
                ? null
                : () => onChanged!(AiCaptureMode.ingredients),
          ),
          _ModeButton(
            label: 'Dish detect',
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
                'Use the upload button below to choose a photo.',
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
    this.annotatedImageBytes,
    this.imageUrl = '',
    this.detections = const [],
  });

  final List<String> initialItems;
  final String sourceName;
  final Uint8List captureBytes;
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
              const Text(
                'Confirm detected ingredients',
                style: TextStyle(
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
                  child: const Text('Add selected'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnotatedResultImage extends StatelessWidget {
  const _AnnotatedResultImage({
    required this.captureBytes,
    this.annotatedImageBytes,
    this.imageUrl = '',
    this.detections = const [],
  });

  final Uint8List captureBytes;
  final Uint8List? annotatedImageBytes;
  final String imageUrl;
  final List<DetectionItemModel> detections;

  @override
  Widget build(BuildContext context) {
    // Prefer server-annotated JPEG when present.
    if (annotatedImageBytes != null && annotatedImageBytes!.isNotEmpty) {
      return Image.memory(
        annotatedImageBytes!,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (_, __, ___) => _localPhotoWithBoxes(),
      );
    }

    // Always fall back to the photo just captured/picked (reliable on web).
    return _localPhotoWithBoxes();
  }

  Widget _localPhotoWithBoxes() {
    // Stack sizes to the photo; boxes map 0..1 onto the full image (no cover-crop).
    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.memory(
            captureBytes,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (_, __, ___) {
              if (imageUrl.isEmpty) {
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
                imageUrl,
                width: double.infinity,
                fit: BoxFit.fitWidth,
              );
            },
          ),
          if (detections.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: _DetectionOverlayPainter(
                  detections: detections,
                  accent: const Color(0xFF059669),
                ),
              ),
            ),
        ],
      ),
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
