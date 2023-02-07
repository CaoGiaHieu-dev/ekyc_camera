import 'package:flutter/foundation.dart';

import '../../../camerawesome_plugin.dart';
import '../../../pigeon.dart';
import '../camera_context.dart';
import '../models/sensor_type.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPhotoMode = Function(PhotoCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

typedef OnVideoRecordingMode = Function(VideoRecordingCameraState);

abstract class CameraState {
  @protected
  CameraContext cameraContext;

  CameraState(this.cameraContext);

  abstract final CaptureMode? captureMode;

  when({
    OnVideoMode? onVideoMode,
    OnPhotoMode? onPhotoMode,
    OnPreparingCamera? onPreparingCamera,
    OnVideoRecordingMode? onVideoRecordingMode,
  }) {
    if (this is VideoCameraState && onVideoMode != null) {
      return onVideoMode(this as VideoCameraState);
    }
    if (this is PhotoCameraState && onPhotoMode != null) {
      return onPhotoMode(this as PhotoCameraState);
    }
    if (this is PreparingCameraState && onPreparingCamera != null) {
      return onPreparingCamera(this as PreparingCameraState);
    }
    if (this is VideoRecordingCameraState && onVideoRecordingMode != null) {
      return onVideoRecordingMode(this as VideoRecordingCameraState);
    }
  }

  void dispose();

  Stream<MediaCapture?> get captureState$ => cameraContext.captureState$;

  void switchCameraSensor() {
    final previous = cameraContext.sensorConfig;
    final next = SensorConfig(
      sensor: previous.sensor == Sensors.back ? Sensors.front : Sensors.back,
    );
    cameraContext.setSensorConfig(next);
  }

  void setSensorType(SensorType type, String deviceId) {
    final next = SensorConfig(
      captureDeviceId: deviceId,
      sensor: type == SensorType.trueDepth ? Sensors.front : Sensors.back,
      type: type,
    );
    cameraContext.setSensorConfig(next);
  }

  void toggleFilterSelector() {
    cameraContext.toggleFilterSelector();
  }

  Future<void> setFilter(AwesomeFilter newFilter) {
    return cameraContext.setFilter(newFilter);
  }

  SensorConfig get sensorConfig => cameraContext.sensorConfig;

  Stream<SensorConfig> get sensorConfig$ => cameraContext.sensorConfig$;

  Stream<bool> get filterSelectorOpened$ => cameraContext.filterSelectorOpened$;

  Stream<AwesomeFilter> get filter$ => cameraContext.filter$;

  AwesomeFilter get filter => cameraContext.filterController.value;

  void setState(CaptureMode captureMode);

  SaveConfig get saveConfig => cameraContext.saveConfig;

  Future<PreviewSize> previewSize() {
    return cameraContext.previewSize();
  }

  Future<SensorDeviceData> getSensors() {
    return cameraContext.getSensors();
  }

  Future<int?> textureId() {
    return cameraContext.textureId();
  }

  AnalysisController? get analysisController =>
      cameraContext.analysisController;
}
