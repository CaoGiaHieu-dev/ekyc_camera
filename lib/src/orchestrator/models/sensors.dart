enum Sensors {
  back,
  front,
}

enum CameraAspectRatios {
  ratio_16_9,
  ratio_4_3,
  ratio_1_1,
}

extension CameraAspectRatiosExt on CameraAspectRatios {
  CameraAspectRatios get defaultRatio => CameraAspectRatios.ratio_4_3;
}
