// ignore_for_file: constant_identifier_names

import 'package:pigeon/pigeon.dart';

class PreviewSize {
  final double width;
  final double height;

  const PreviewSize(this.width, this.height);
}

class PreviewData {
  double? textureId;
  PreviewSize? size;
}

class ExifPreferences {
  bool saveGPSLocation;

  ExifPreferences({required this.saveGPSLocation});
}

class VideoOptions {
  String fileType;
  String codec;

  VideoOptions({
    required this.fileType,
    required this.codec,
  });
}

enum PigeonSensorType {
  wideAngle,

  ultraWideAngle,

  telephoto,

  trueDepth,
  unknown,
}

class PigeonSensorTypeDevice {
  final PigeonSensorType sensorType;

  final String name;

  final double iso;

  final bool flashAvailable;

  final String uid;

  PigeonSensorTypeDevice({
    required this.sensorType,
    required this.name,
    required this.iso,
    required this.flashAvailable,
    required this.uid,
  });
}

class PigeonSensorDeviceData {
  PigeonSensorTypeDevice? wideAngle;

  PigeonSensorTypeDevice? ultraWideAngle;

  PigeonSensorTypeDevice? telephoto;

  PigeonSensorTypeDevice? trueDepth;

  PigeonSensorDeviceData({
    this.wideAngle,
    this.ultraWideAngle,
    this.telephoto,
    this.trueDepth,
  });
}

enum CamerAwesomePermission {
  storage,
  camera,
  location,

  record_audio,
}

@HostApi()
abstract class CameraInterface {
  @async
  bool setupCamera(
    String sensor,
    String aspectRatio,
    double zoom,
    String flashMode,
    String captureMode,
    bool enableImageStream,
    ExifPreferences exifPreferences,
  );

  List<String> checkPermissions();

  @async
  List<String> requestPermissions(bool saveGpsLocation);

  int getPreviewTextureId();

  @async
  bool takePhoto(String path);

  @async
  void recordVideo(String path, VideoOptions? options);

  void pauseVideoRecording();

  void resumeVideoRecording();

  void receivedImageFromStream();

  @async
  bool stopRecordingVideo();

  List<PigeonSensorTypeDevice> getFrontSensors();

  List<PigeonSensorTypeDevice> getBackSensors();

  bool start();

  bool stop();

  void setFlashMode(String mode);

  void handleAutoFocus();

  void focusOnPoint(PreviewSize previewSize, double x, double y);

  void setZoom(double zoom);

  void setSensor(String sensor, String? deviceId);

  void setCorrection(double brightness);

  double getMaxZoom();

  void setCaptureMode(String mode);

  @async
  bool setRecordingAudioMode(bool enableAudio);

  List<PreviewSize> availableSizes();

  void refresh();

  PreviewSize? getEffectivPreviewSize();

  void setPhotoSize(PreviewSize size);

  void setPreviewSize(PreviewSize size);

  void setAspectRatio(String aspectRatio);

  void setupImageAnalysisStream(
    String format,
    int width,
    double? maxFramesPerSecond,
    bool autoStart,
  );

  @async
  bool setExifPreferences(ExifPreferences exifPreferences);

  void startAnalysis();

  void stopAnalysis();

  void setFilter(List<double> matrix);
}
