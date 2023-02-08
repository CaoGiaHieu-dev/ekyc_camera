import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:photofilters/photofilters.dart';
import 'package:rxdart/rxdart.dart';

import '../../../camerawesome_plugin.dart';
import '../../../pigeon.dart';
import '../camera_context.dart';

class PhotoFilterModel {
  PhotoFilterModel(this.path, this.imageFile, this.filter);

  final String path;
  final File imageFile;
  final Filter filter;
}

class PhotoCameraState extends CameraState {
  Isolate? photoFilterIsolate;

  PhotoCameraState({
    required CameraContext cameraContext,
    required this.filePathBuilder,
    required this.exifPreferences,
  }) : super(cameraContext) {
    _saveGpsLocationController =
        BehaviorSubject.seeded(exifPreferences.saveGPSLocation);
    saveGpsLocation$ = _saveGpsLocationController.stream;
  }

  factory PhotoCameraState.from(CameraContext orchestrator) => PhotoCameraState(
        cameraContext: orchestrator,
        filePathBuilder: orchestrator.saveConfig.photoPathBuilder!,
        exifPreferences: orchestrator.exifPreferences,
      );

  final FilePathBuilder filePathBuilder;

  final ExifPreferences exifPreferences;

  late final BehaviorSubject<bool> _saveGpsLocationController;
  late final Stream<bool> saveGpsLocation$;

  bool get saveGpsLocation => _saveGpsLocationController.value;

  Future<void> shouldSaveGpsLocation(bool saveGPS) async {
    final isGranted = await CamerawesomePlugin.setExifPreferences(
      ExifPreferences(saveGPSLocation: saveGPS),
    );

    if (isGranted) {
      exifPreferences.saveGPSLocation = saveGPS;
      _saveGpsLocationController.sink.add(saveGPS);
    }
  }

  @override
  CaptureMode get captureMode => CaptureMode.photo;

  Future<String> takePhoto() async {
    String path = await filePathBuilder();
    if (!path.endsWith(".jpg")) {
      throw ("You can only capture .jpg files with CamerAwesome");
    }
    _mediaCapture = MediaCapture.capturing(filePath: path);
    try {
      final succeeded = await CamerawesomePlugin.takePhoto();
      if (succeeded != null) {
        if (Platform.isIOS && filter.id != AwesomeFilter.None.id) {
          photoFilterIsolate?.kill(priority: Isolate.immediate);

          ReceivePort port = ReceivePort();
          photoFilterIsolate = await Isolate.spawn<PhotoFilterModel>(
            applyFilter,
            PhotoFilterModel(path, File(path), filter.output),
            onExit: port.sendPort,
          );
          await port.first;

          photoFilterIsolate?.kill(priority: Isolate.immediate);
        }

        _mediaCapture = MediaCapture.success(filePath: path);
      } else {
        _mediaCapture = MediaCapture.failure(filePath: path);
      }
    } on Exception catch (e) {
      _mediaCapture = MediaCapture.failure(filePath: path, exception: e);
    }
    return path;
  }

  set _mediaCapture(MediaCapture media) {
    if (!cameraContext.mediaCaptureController.isClosed) {
      cameraContext.mediaCaptureController.add(media);
    }
  }

  @override
  void setState(CaptureMode captureMode) {
    if (captureMode == CaptureMode.photo) {
      return;
    }
    cameraContext.changeState(captureMode.toCameraState(cameraContext));
  }

  @override
  void dispose() {
    _saveGpsLocationController.close();
  }

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

Future<File> applyFilter(PhotoFilterModel model) async {
  final img.Image? image = img.decodeJpg(model.imageFile.readAsBytesSync());
  if (image == null) {
    throw MediaCapture.failure(
      exception: Exception("could not decode image"),
      filePath: model.path,
    );
  }

  final pixels = image.getBytes();
  model.filter.apply(pixels, image.width, image.height);
  final img.Image out = img.Image.fromBytes(
    image.width,
    image.height,
    pixels,
  );

  final List<int>? encodedImage = img.encodeNamedImage(out, model.path);
  if (encodedImage == null) {
    throw MediaCapture.failure(
      exception: Exception("could not encode image"),
      filePath: model.path,
    );
  }

  model.imageFile.writeAsBytesSync(encodedImage);
  return model.imageFile;
}
