enum SensorType {
  wideAngle,

  ultraWideAngle,

  telephoto,

  trueDepth,

  unknown,
}

extension SensorTypeExt on SensorType {
  SensorType get defaultSensorType => SensorType.wideAngle;
}

class SensorTypeDevice {
  final SensorType sensorType;

  final String name;

  final num iso;

  final bool flashAvailable;

  final String uid;

  SensorTypeDevice({
    required this.sensorType,
    required this.name,
    required this.iso,
    required this.flashAvailable,
    required this.uid,
  });
}

class SensorDeviceData {
  SensorTypeDevice? wideAngle;

  SensorTypeDevice? ultraWideAngle;

  SensorTypeDevice? telephoto;

  SensorTypeDevice? trueDepth;

  SensorDeviceData({
    this.wideAngle,
    this.ultraWideAngle,
    this.telephoto,
    this.trueDepth,
  });

  int get availableBackSensors => [
        wideAngle,
        ultraWideAngle,
        telephoto,
      ].where((element) => element != null).length;

  int get availableFrontSensors => [
        trueDepth,
      ].where((element) => element != null).length;
}
