import 'dart:ui';

import '../../../camerawesome_plugin.dart';
import '../../../pigeon.dart';

import '../camera_context.dart';

class VideoCameraState extends CameraState {
  VideoCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
  }) : super(cameraContext);

  factory VideoCameraState.from(CameraContext cameraContext) =>
      VideoCameraState(
        cameraContext: cameraContext,
        filePathBuilder: cameraContext.saveConfig.videoPathBuilder!,
      );

  final FilePathBuilder filePathBuilder;

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.video) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  CaptureMode get captureMode => CaptureMode.video;

  Future<String> startRecording() async {
    String filePath = await filePathBuilder();
    _mediaCapture = MediaCapture.capturing(
        filePath: filePath, videoState: VideoState.started);
    try {
      await CamerawesomePlugin.recordVideo(filePath);
    } on Exception catch (e) {
      _mediaCapture = MediaCapture.failure(filePath: filePath, exception: e);
    }
    cameraContext.changeState(VideoRecordingCameraState.from(cameraContext));
    return filePath;
  }

  Future<void> enableAudio(bool enableAudio) {
    return CamerawesomePlugin.setAudioMode(enableAudio);
  }

  set _mediaCapture(MediaCapture media) {
    if (!cameraContext.mediaCaptureController.isClosed) {
      cameraContext.mediaCaptureController.add(media);
    }
  }

  @override
  void dispose() {}

  focus() {
    cameraContext.focus();
  }

  Future<void> focusOnPoint({
    required Offset flutterPosition,
    required PreviewSize pixelPreviewSize,
    required PreviewSize flutterPreviewSize,
  }) {
    return cameraContext.focusOnPoint(
      flutterPosition: flutterPosition,
      pixelPreviewSize: pixelPreviewSize,
      flutterPreviewSize: flutterPreviewSize,
    );
  }
}
