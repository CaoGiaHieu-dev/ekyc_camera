import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/builder/awesome_camera_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../orchestrator/camera_context.dart';

typedef OnMediaTap = Function(MediaCapture mediaCapture)?;

typedef OnPermissionsResult = void Function(bool result);

typedef OnImageForAnalysis = Future Function(AnalysisImage image);

class CameraAwesomeBuilder extends StatefulWidget {
  final Sensors sensor;

  final FlashMode flashMode;

  final double zoom;

  final CameraAspectRatios aspectRatio;

  final ExifPreferences? exifPreferences;

  final AwesomeFilter? filter;

  final CameraPreviewFit previewFit;

  final bool enableAudio;

  final SaveConfig saveConfig;

  final OnMediaTap onMediaTap;

  final Widget? progressIndicator;

  final OnImageForAnalysis? onImageForAnalysis;

  final AnalysisConfig? imageAnalysisConfig;

  const CameraAwesomeBuilder._({
    required this.sensor,
    required this.flashMode,
    required this.zoom,
    required this.aspectRatio,
    required this.exifPreferences,
    required this.enableAudio,
    required this.progressIndicator,
    required this.saveConfig,
    required this.onMediaTap,
    required this.previewFit,
    required this.filter,
    this.onImageForAnalysis,
    this.imageAnalysisConfig,
  });

  const CameraAwesomeBuilder.awesome({
    Sensors sensor = Sensors.back,
    FlashMode flashMode = FlashMode.none,
    double zoom = 0.0,
    CameraAspectRatios aspectRatio = CameraAspectRatios.ratio_4_3,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required SaveConfig saveConfig,
    Function(MediaCapture)? onMediaTap,
    AwesomeFilter? filter,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
    CameraPreviewFit? previewFit,
  }) : this._(
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          aspectRatio: aspectRatio,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          filter: filter,
          saveConfig: saveConfig,
          onMediaTap: onMediaTap,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
          previewFit: previewFit ?? CameraPreviewFit.cover,
        );

  const CameraAwesomeBuilder.custom({
    CaptureMode initialCaptureMode = CaptureMode.photo,
    Sensors sensor = Sensors.back,
    FlashMode flashMode = FlashMode.none,
    double zoom = 0.0,
    CameraAspectRatios aspectRatio = CameraAspectRatios.ratio_4_3,
    ExifPreferences? exifPreferences,
    bool enableAudio = true,
    Widget? progressIndicator,
    required SaveConfig saveConfig,
    AwesomeFilter? filter,
    OnImageForAnalysis? onImageForAnalysis,
    AnalysisConfig? imageAnalysisConfig,
    CameraPreviewFit? previewFit,
  }) : this._(
          sensor: sensor,
          flashMode: flashMode,
          zoom: zoom,
          aspectRatio: aspectRatio,
          exifPreferences: exifPreferences,
          enableAudio: enableAudio,
          progressIndicator: progressIndicator,
          saveConfig: saveConfig,
          onMediaTap: null,
          filter: filter,
          onImageForAnalysis: onImageForAnalysis,
          imageAnalysisConfig: imageAnalysisConfig,
          previewFit: previewFit ?? CameraPreviewFit.cover,
        );

  @override
  State<StatefulWidget> createState() {
    return _CameraWidgetBuilder();
  }
}

class _CameraWidgetBuilder extends State<CameraAwesomeBuilder>
    with WidgetsBindingObserver {
  late CameraContext _cameraContext;
  final _cameraPreviewKey = GlobalKey<AwesomeCameraPreviewState>();

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraContext.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CameraAwesomeBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.didChangeDependencies();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _cameraContext.state
            .when(onVideoRecordingMode: (mode) => mode.stopRecording());
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _cameraContext = CameraContext.create(
      SensorConfig(
        sensor: widget.sensor,
        flash: widget.flashMode,
        currentZoom: widget.zoom,
        aspectRatio: widget.aspectRatio,
      ),
      filter: widget.filter ?? AwesomeFilter.None,
      initialCaptureMode: widget.saveConfig.initialCaptureMode,
      saveConfig: widget.saveConfig,
      onImageForAnalysis: widget.onImageForAnalysis,
      analysisConfig: widget.imageAnalysisConfig,
      exifPreferences:
          widget.exifPreferences ?? ExifPreferences(saveGPSLocation: false),
    );

    _cameraContext.state.when(onPreparingCamera: (mode) => mode.start());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CameraState>(
      stream: _cameraContext.state$,
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data!.captureMode == null ||
            snapshot.requireData is PreparingCameraState) {
          return widget.progressIndicator ??
              Center(
                child: Platform.isIOS
                    ? const CupertinoActivityIndicator()
                    : const CircularProgressIndicator(),
              );
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: AwesomeCameraPreview(
                key: _cameraPreviewKey,
                previewFit: widget.previewFit,
                state: snapshot.requireData,
              ),
            ),
          ],
        );
      },
    );
  }
}
