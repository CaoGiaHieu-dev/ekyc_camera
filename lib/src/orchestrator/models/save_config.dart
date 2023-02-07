import 'capture_modes.dart';

typedef FilePathBuilder = Future<String> Function();

class SaveConfig {
  final FilePathBuilder? photoPathBuilder;
  final FilePathBuilder? videoPathBuilder;
  final List<CaptureMode> captureModes;
  final CaptureMode initialCaptureMode;

  SaveConfig._({
    this.photoPathBuilder,
    this.videoPathBuilder,
    required this.captureModes,
    required this.initialCaptureMode,
  });

  SaveConfig.photo({required FilePathBuilder pathBuilder})
      : this._(
          photoPathBuilder: pathBuilder,
          captureModes: [CaptureMode.photo],
          initialCaptureMode: CaptureMode.photo,
        );

  SaveConfig.video({required FilePathBuilder pathBuilder})
      : this._(
          videoPathBuilder: pathBuilder,
          captureModes: [CaptureMode.video],
          initialCaptureMode: CaptureMode.video,
        );

  SaveConfig.photoAndVideo({
    required FilePathBuilder photoPathBuilder,
    required FilePathBuilder videoPathBuilder,
    CaptureMode initialCaptureMode = CaptureMode.photo,
  }) : this._(
          photoPathBuilder: photoPathBuilder,
          videoPathBuilder: videoPathBuilder,
          captureModes: [CaptureMode.photo, CaptureMode.video],
          initialCaptureMode: initialCaptureMode,
        );
}
