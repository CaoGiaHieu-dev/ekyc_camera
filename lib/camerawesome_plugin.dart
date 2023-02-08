import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'camerawesome_plugin.dart';
import 'pigeon.dart';
import 'src/logger.dart';
import 'src/orchestrator/models/sensor_type.dart';
import 'src/orchestrator/models/video_options.dart';

export 'src/builder/camera_awesome_builder.dart';
export 'src/orchestrator/analysis/analysis_controller.dart';
export 'src/orchestrator/models/models.dart';
export 'src/orchestrator/states/states.dart';

enum CameraRunningState { starting, started, stopping, stopped }

enum CameraPreviewFit { fitWidth, fitHeight, contain, cover }

class CamerawesomePlugin {
  static const EventChannel _orientationChannel =
      EventChannel('camerawesome/orientation');

  static const EventChannel _permissionsChannel =
      EventChannel('camerawesome/permissions');

  static const EventChannel _imagesChannel =
      EventChannel('camerawesome/images');

  static const EventChannel _luminosityChannel =
      EventChannel('camerawesome/luminosity');

  static Stream<CameraOrientations>? _orientationStream;

  static Stream<bool>? _permissionsStream;

  static Stream<SensorData>? _luminositySensorDataStream;

  static Stream<Map<String, dynamic>>? _imagesStream;

  static CameraRunningState currentState = CameraRunningState.stopped;

  static bool printLogs = false;

  static Future<bool?> checkIOSPermissions() async {
    final permissions = await CameraInterface().checkPermissions();
    return permissions.isEmpty;
  }

  static Future<bool> start() async {
    if (currentState == CameraRunningState.started ||
        currentState == CameraRunningState.starting) {
      return true;
    }
    currentState = CameraRunningState.starting;
    bool res = await CameraInterface().start();
    if (res) currentState = CameraRunningState.started;
    return res;
  }

  static Future<bool> stop() async {
    if (currentState == CameraRunningState.stopped ||
        currentState == CameraRunningState.stopping) {
      return true;
    }
    _orientationStream = null;
    currentState = CameraRunningState.stopping;
    bool res;
    try {
      res = await CameraInterface().stop();
    } catch (e) {
      return false;
    }
    currentState = CameraRunningState.stopped;
    return res;
  }

  static Stream<CameraOrientations>? getNativeOrientation() {
    _orientationStream ??= _orientationChannel
        .receiveBroadcastStream('orientationChannel')
        .transform(StreamTransformer<dynamic, CameraOrientations>.fromHandlers(
            handleData: (data, sink) {
      CameraOrientations? newOrientation;
      switch (data) {
        case 'LANDSCAPE_LEFT':
          newOrientation = CameraOrientations.landscape_left;
          break;
        case 'LANDSCAPE_RIGHT':
          newOrientation = CameraOrientations.landscape_right;
          break;
        case 'PORTRAIT_UP':
          newOrientation = CameraOrientations.portrait_up;
          break;
        case 'PORTRAIT_DOWN':
          newOrientation = CameraOrientations.portrait_down;
          break;
        default:
      }
      sink.add(newOrientation!);
    }));
    return _orientationStream;
  }

  static Stream<bool>? listenPermissionResult() {
    _permissionsStream ??= _permissionsChannel
        .receiveBroadcastStream('permissionsChannel')
        .transform(StreamTransformer<dynamic, bool>.fromHandlers(
            handleData: (data, sink) {
      sink.add(data);
    }));
    return _permissionsStream;
  }

  static Future<void> setupAnalysis({
    int width = 0,
    double? maxFramesPerSecond,
    required InputAnalysisImageFormat format,
    required bool autoStart,
  }) async {
    return CameraInterface().setupImageAnalysisStream(
        format.name, width, maxFramesPerSecond, autoStart);
  }

  static Stream<Map<String, dynamic>>? listenCameraImages() {
    _imagesStream ??=
        _imagesChannel.receiveBroadcastStream('imagesChannel').transform(
      StreamTransformer<dynamic, Map<String, dynamic>>.fromHandlers(
        handleData: (data, sink) {
          sink.add(Map<String, dynamic>.from(data));
        },
      ),
    );
    return _imagesStream;
  }

  static Future receivedImageFromStream() {
    return CameraInterface().receivedImageFromStream();
  }

  static Future<bool?> init(
    SensorConfig sensorConfig,
    bool enableImageStream, {
    CaptureMode captureMode = CaptureMode.photo,
    required ExifPreferences exifPreferences,
  }) async {
    return CameraInterface()
        .setupCamera(
          sensorConfig.sensor.name.toUpperCase(),
          sensorConfig.aspectRatio.name.toUpperCase(),
          sensorConfig.zoom,
          sensorConfig.flashMode.name.toUpperCase(),
          captureMode.name.toUpperCase(),
          enableImageStream,
          exifPreferences,
        )
        .then((value) => true);
  }

  static Future<List<Size>> getSizes() async {
    final availableSizes = await CameraInterface().availableSizes();
    return availableSizes
        .whereType<PreviewSize>()
        .map((e) => Size(e.width, e.height))
        .toList();
  }

  static Future<num?> getPreviewTexture() {
    return CameraInterface().getPreviewTextureId();
  }

  static Future<void> setPreviewSize(int width, int height) {
    return CameraInterface().setPreviewSize(
        PreviewSize(width: width.toDouble(), height: height.toDouble()));
  }

  static Future<void> refresh() {
    return CameraInterface().refresh();
  }

  static Future<PreviewSize> getEffectivPreviewSize() async {
    final ps = await CameraInterface().getEffectivPreviewSize();
    if (ps != null) {
      return PreviewSize(width: ps.width, height: ps.height);
    } else {
      return PreviewSize(width: 0, height: 0);
    }
  }

  static Future<void> setPhotoSize(int width, int height) {
    return CameraInterface().setPhotoSize(
      PreviewSize(
        width: width.toDouble(),
        height: height.toDouble(),
      ),
    );
  }

  static Future<Uint8List?> takePhoto() async {
    return CameraInterface().takePhoto();
  }

  static Future<void> recordVideo(
    String path, {
    CupertinoVideoOptions? cupertinoVideoOptions,
  }) {
    if (Platform.isAndroid) {
      return CameraInterface().recordVideo(path, null);
    } else {
      return CameraInterface().recordVideo(
        path,
        cupertinoVideoOptions != null
            ? VideoOptions(
                fileType: cupertinoVideoOptions.fileType.name,
                codec: cupertinoVideoOptions.codec.name,
              )
            : null,
      );
    }
  }

  static pauseVideoRecording() {
    CameraInterface().pauseVideoRecording();
  }

  static resumeVideoRecording() {
    return CameraInterface().resumeVideoRecording();
  }

  static stopRecordingVideo() {
    return CameraInterface().stopRecordingVideo();
  }

  static Future<void> setFlashMode(FlashMode flashMode) {
    return CameraInterface().setFlashMode(flashMode.name.toUpperCase());
  }

  static startAutoFocus() {
    return CameraInterface().handleAutoFocus();
  }

  static Future<void> focusOnPoint(
      {required PreviewSize previewSize, required Offset position}) {
    return CameraInterface()
        .focusOnPoint(previewSize, position.dx, position.dy);
  }

  static Future<void> setZoom(num zoom) {
    return CameraInterface().setZoom(zoom.toDouble());
  }

  static Future<void> setSensor(Sensors sensor, {String? deviceId}) {
    return CameraInterface().setSensor(sensor.name.toUpperCase(), deviceId);
  }

  static Future<void> setCaptureMode(CaptureMode captureMode) {
    return CameraInterface().setCaptureMode(captureMode.name.toUpperCase());
  }

  static Future<void> setAudioMode(bool enableAudio) {
    return CameraInterface().setRecordingAudioMode(enableAudio);
  }

  static Future<bool> setExifPreferences(ExifPreferences savedExifData) {
    return CameraInterface().setExifPreferences(savedExifData);
  }

  static Future<void> setBrightness(double brightness) {
    if (brightness < 0 || brightness > 1) {
      throw "Value must be between [0,1]";
    }
    return CameraInterface().setCorrection(brightness);
  }

  static Stream<SensorData>? listenLuminosityLevel() {
    if (!Platform.isAndroid) {
      throw "not available on this OS for now... only Android";
    }
    _luminositySensorDataStream ??= _luminosityChannel
        .receiveBroadcastStream('luminosityChannel')
        .transform(StreamTransformer<dynamic, SensorData>.fromHandlers(
            handleData: (data, sink) {
      sink.add(SensorData(data));
    }));
    return _luminositySensorDataStream;
  }

  static Future<num?> getMaxZoom() {
    return CameraInterface().getMaxZoom();
  }

  static Future<void> setAspectRatio(String ratio) {
    return CameraInterface().setAspectRatio(ratio.toUpperCase());
  }

  static Future<SensorDeviceData> getSensors() async {
    if (Platform.isAndroid) {
      return Future.value(SensorDeviceData());
    } else {
      final frontSensors = await CameraInterface().getFrontSensors();
      final backSensors = await CameraInterface().getBackSensors();

      final frontSensorsData = frontSensors
          .map(
            (data) => SensorTypeDevice(
              flashAvailable: data!.flashAvailable,
              iso: data.iso,
              name: data.name,
              uid: data.uid,
              sensorType: SensorType.values.firstWhere(
                (element) => element.name == data.sensorType.name,
              ),
            ),
          )
          .toList();
      final backSensorsData = backSensors
          .map(
            (data) => SensorTypeDevice(
              flashAvailable: data!.flashAvailable,
              iso: data.iso,
              name: data.name,
              uid: data.uid,
              sensorType: SensorType.values.firstWhere(
                (element) => element.name == data.sensorType.name,
              ),
            ),
          )
          .toList();

      return SensorDeviceData(
        ultraWideAngle: backSensorsData
            .where(
              (element) => element.sensorType == SensorType.ultraWideAngle,
            )
            .toList()
            .firstOrNull,
        telephoto: backSensorsData
            .where(
              (element) => element.sensorType == SensorType.telephoto,
            )
            .toList()
            .firstOrNull,
        wideAngle: backSensorsData
            .where(
              (element) => element.sensorType == SensorType.wideAngle,
            )
            .toList()
            .firstOrNull,
        trueDepth: frontSensorsData
            .where(
              (element) => element.sensorType == SensorType.trueDepth,
            )
            .toList()
            .firstOrNull,
      );
    }
  }

  static Future<List<CamerAwesomePermission>?> checkAndRequestPermissions(
      bool saveGpsLocation) async {
    try {
      if (Platform.isAndroid) {
        return CameraInterface()
            .requestPermissions(saveGpsLocation)
            .then((givenPermissions) {
          return givenPermissions
              .map((e) => CamerAwesomePermission.values
                  .firstWhere((element) => element.name == e))
              .toList();
        });
      } else if (Platform.isIOS) {
        return CamerawesomePlugin.checkIOSPermissions()
            .then((givenPermissions) => CamerAwesomePermission.values);
      }
    } catch (e) {
      printLog("failed to check permissions here...");

      debugPrint(e.toString());
    }
    return Future.value([]);
  }

  static Future<void> startAnalysis() {
    return CameraInterface().startAnalysis();
  }

  static Future<void> stopAnalysis() {
    return CameraInterface().stopAnalysis();
  }

  static Future<void> setFilter(AwesomeFilter filter) {
    return CameraInterface().setFilter(filter.matrix);
  }
}
