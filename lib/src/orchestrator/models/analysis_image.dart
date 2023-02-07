import 'dart:typed_data';
import 'dart:ui';

enum InputAnalysisImageFormat { yuv_420, bgra8888, jpeg, nv21, unknown }

enum InputAnalysisImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg
}

InputAnalysisImageFormat inputAnalysisImageFormatParser(String value) {
  switch (value) {
    case 'yuv420':
      return InputAnalysisImageFormat.yuv_420;
    case 'bgra8888':
      return InputAnalysisImageFormat.bgra8888;
    case 'jpeg':
      return InputAnalysisImageFormat.jpeg;
    case 'nv21':
      return InputAnalysisImageFormat.nv21;
  }
  return InputAnalysisImageFormat.unknown;
}

class AnalysisConfig {
  final InputAnalysisImageFormat outputFormat;

  final int width;

  final double? maxFramesPerSecond;

  final bool autoStart;

  AnalysisConfig({
    this.outputFormat = InputAnalysisImageFormat.nv21,
    this.width = 500,
    this.maxFramesPerSecond,
    this.autoStart = true,
  });
}

class AnalysisParams {
  InputAnalysisImageFormat format;
  int? width;
  int? height;

  AnalysisParams({
    required this.format,
    this.width,
    this.height,
  });
}

class AnalysisImage {
  int height;
  int width;
  List<ImagePlane> planes;
  InputAnalysisImageFormat format;
  Uint8List? nv21Image;
  Uint8List? displayImage;
  InputAnalysisImageRotation rotation;
  Rect? cropRect;

  AnalysisImage({
    required this.height,
    required this.width,
    required this.planes,
    required this.format,
    required this.rotation,
    this.displayImage,
    this.nv21Image,
    this.cropRect,
  });

  factory AnalysisImage.from(Map<String, dynamic> map) {
    return AnalysisImage(
      height: map["height"],
      width: map["width"],
      displayImage: map['displayImage'],
      planes: (map["planes"] as List<dynamic>)
          .map((e) => ImagePlane.from(Map<String, dynamic>.from(e)))
          .toList(),
      rotation: InputAnalysisImageRotation.values.byName(map["rotation"]),
      format: inputAnalysisImageFormatParser(map["format"]),
      nv21Image: map.containsKey("nv21Image") ? map["nv21Image"] : null,
      cropRect: map.containsKey("cropRect")
          ? Rect.fromLTRB(
              map["cropRect"]["left"].toDouble(),
              map["cropRect"]["top"].toDouble(),
              map["cropRect"]["right"].toDouble(),
              map["cropRect"]["bottom"].toDouble(),
            )
          : null,
    );
  }
}

class ImagePlane {
  Uint8List bytes;
  int bytesPerRow;
  int? height;
  int? width;

  ImagePlane({
    required this.bytes,
    required this.bytesPerRow,
    required this.height,
    required this.width,
  });

  factory ImagePlane.from(Map<String, dynamic> map) {
    return ImagePlane(
      bytes: map["bytes"],
      bytesPerRow: map["bytesPerRow"] ?? map["rowStride"],
      height: map["height"],
      width: map["width"],
    );
  }
}
