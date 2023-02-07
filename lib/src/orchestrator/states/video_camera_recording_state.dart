import 'dart:ui';

import '../../../camerawesome_plugin.dart';
import '../../../pigeon.dart';
import '../../logger.dart';

import '../camera_context.dart';

class VideoRecordingCameraState extends CameraState {
  VideoRecordingCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
  }) : super(cameraContext);

  factory VideoRecordingCameraState.from(CameraContext orchestrator) =>
      VideoRecordingCameraState(
        cameraContext: orchestrator,
        filePathBuilder: orchestrator.saveConfig.videoPathBuilder!,
      );

  final FilePathBuilder filePathBuilder;

  @override
  void setState(CaptureMode captureMode) {
    printLog(''' 
      warning: You must stop recording before changing state.  
    ''');
  }

  @override
  CaptureMode get captureMode => CaptureMode.video;

  Future<void> pauseRecording(MediaCapture currentCapture) async {
    if (!currentCapture.isVideo) {
      throw "Trying to pause a video while currentCapture is not a video (${currentCapture.filePath})";
    }
    if (currentCapture.status != MediaCaptureStatus.capturing) {
      throw "Trying to pause a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
    }
    await CamerawesomePlugin.pauseVideoRecording();
    _mediaCapture = MediaCapture.capturing(
        filePath: currentCapture.filePath, videoState: VideoState.paused);
  }

  Future<void> resumeRecording(MediaCapture currentCapture) async {
    if (!currentCapture.isVideo) {
      throw "Trying to pause a video while currentCapture is not a video (${currentCapture.filePath})";
    }
    if (currentCapture.status != MediaCaptureStatus.capturing) {
      throw "Trying to pause a media capture in status ${currentCapture.status} instead of ${MediaCaptureStatus.capturing}";
    }
    await CamerawesomePlugin.resumeVideoRecording();
    _mediaCapture = MediaCapture.capturing(
        filePath: currentCapture.filePath, videoState: VideoState.resumed);
  }

  Future<void> stopRecording() async {
    var currentCapture = cameraContext.mediaCaptureController.value;
    if (currentCapture == null) {
      return;
    }
    await CamerawesomePlugin.stopRecordingVideo();
    _mediaCapture = MediaCapture.success(filePath: currentCapture.filePath);
    await CamerawesomePlugin.setCaptureMode(CaptureMode.video);
    cameraContext.changeState(VideoCameraState.from(cameraContext));
  }

  Future<void> enableAudio(bool enableAudio) async {
    printLog(''' 
      warning: EnableAudio has no effect when recording 
    ''');
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
