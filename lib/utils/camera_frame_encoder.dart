import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Encode a camera stream frame to a downscaled JPEG for server inference.
Future<Uint8List?> encodeCameraFrameToJpeg(
  CameraImage image, {
  int maxSide = 640,
  int quality = 70,
}) {
  final payload = _FramePayload.fromCameraImage(image, maxSide, quality);
  return compute(_encodeIsolate, payload);
}

enum _FrameFormat { yuv420, bgra8888, jpeg, unknown }

class _FramePayload {
  _FramePayload({
    required this.format,
    required this.width,
    required this.height,
    required this.planes,
    required this.maxSide,
    required this.quality,
  });

  factory _FramePayload.fromCameraImage(
    CameraImage image,
    int maxSide,
    int quality,
  ) {
    final _FrameFormat format;
    switch (image.format.group) {
      case ImageFormatGroup.yuv420:
        format = _FrameFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        format = _FrameFormat.bgra8888;
      case ImageFormatGroup.jpeg:
        format = _FrameFormat.jpeg;
      default:
        format = _FrameFormat.unknown;
    }

    return _FramePayload(
      format: format,
      width: image.width,
      height: image.height,
      planes: image.planes
          .map(
            (p) => _PlaneData(
              bytes: Uint8List.fromList(p.bytes),
              bytesPerRow: p.bytesPerRow,
              bytesPerPixel: p.bytesPerPixel,
            ),
          )
          .toList(),
      maxSide: maxSide,
      quality: quality,
    );
  }

  final _FrameFormat format;
  final int width;
  final int height;
  final List<_PlaneData> planes;
  final int maxSide;
  final int quality;
}

class _PlaneData {
  _PlaneData({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });

  final Uint8List bytes;
  final int bytesPerRow;
  final int? bytesPerPixel;
}

Uint8List? _encodeIsolate(_FramePayload args) {
  final converted = _payloadToRgb(args);
  if (converted == null) return null;

  img.Image sized = converted;
  final longest = sized.width > sized.height ? sized.width : sized.height;
  if (longest > args.maxSide) {
    final scale = args.maxSide / longest;
    sized = img.copyResize(
      sized,
      width: (sized.width * scale).round().clamp(1, args.maxSide),
      height: (sized.height * scale).round().clamp(1, args.maxSide),
      interpolation: img.Interpolation.linear,
    );
  }

  return Uint8List.fromList(img.encodeJpg(sized, quality: args.quality));
}

img.Image? _payloadToRgb(_FramePayload image) {
  try {
    switch (image.format) {
      case _FrameFormat.bgra8888:
        return _bgraToImage(image);
      case _FrameFormat.yuv420:
        return _yuv420ToImage(image);
      case _FrameFormat.jpeg:
      case _FrameFormat.unknown:
        return img.decodeImage(image.planes.first.bytes);
    }
  } catch (_) {
    return null;
  }
}

img.Image _bgraToImage(_FramePayload image) {
  final bytes = image.planes.first.bytes;
  final out = img.Image(width: image.width, height: image.height);
  var i = 0;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final b = bytes[i];
      final g = bytes[i + 1];
      final r = bytes[i + 2];
      out.setPixelRgb(x, y, r, g, b);
      i += 4;
    }
  }
  return out;
}

img.Image _yuv420ToImage(_FramePayload image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;
  final yRowStride = yPlane.bytesPerRow;
  final uvRowStride = uPlane.bytesPerRow;
  final uvPixelStride = uPlane.bytesPerPixel ?? 1;

  final out = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final yIndex = y * yRowStride + x;
      final uvIndex = (y >> 1) * uvRowStride + (x >> 1) * uvPixelStride;

      final yp = yBytes[yIndex];
      final up = uBytes[uvIndex];
      final vp = vBytes[uvIndex];

      var r = (yp + 1.370705 * (vp - 128)).round();
      var g = (yp - 0.337633 * (up - 128) - 0.698001 * (vp - 128)).round();
      var b = (yp + 1.732446 * (up - 128)).round();

      out.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    }
  }
  return out;
}
