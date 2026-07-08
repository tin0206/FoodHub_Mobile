import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/ai.dart';
import 'package:foodhub_mobile/services/ai_service.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
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
        imageFormatGroup: ImageFormatGroup.jpeg,
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initError = 'Unable to start camera. Check permissions.';
        _isInitializing = false;
      });
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

        if (result.ingredients.isEmpty) {
          _showSnack('No ingredients detected. Try another photo.');
          return;
        }

        final selected = await showModalBottomSheet<List<String>>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          backgroundColor: const Color(0xFF0B1B38),
          builder: (context) => _DetectedIngredientsSheet(
            initialItems: result.ingredients,
            sourceName: filename,
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
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      await _processBytes(bytes, file.name);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          else if (_initError != null)
            _ErrorView(message: _initError!, onClose: () => Navigator.pop(context))
          else if (_controller != null && _controller!.value.isInitialized)
            CameraPreview(_controller!)
          else
            const Center(
              child: Text(
                'Camera unavailable',
                style: TextStyle(color: Colors.white),
              ),
            ),

          if (!_isInitializing && _initError == null) ...[
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
                          icon: const Icon(Icons.close_rounded, color: Colors.white),
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
                      _hintText,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: _isProcessing ? null : _pickFromGallery,
                          icon: Icon(
                            Icons.photo_library_outlined,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 28,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isProcessing ? null : _capturePhoto,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
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
                        const SizedBox(width: 48),
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white54, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

class _DetectedIngredientsSheet extends StatefulWidget {
  const _DetectedIngredientsSheet({
    required this.initialItems,
    required this.sourceName,
  });

  final List<String> initialItems;
  final String sourceName;

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
    return SafeArea(
      child: Padding(
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
            const SizedBox(height: 10),
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
    );
  }
}
