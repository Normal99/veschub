/// VESC COMM packet identifiers.
///
/// These mirror the `COMM_PACKET_ID` enum in the VESC bldc firmware
/// (bldc_uartcomm_if.h / datatypes.h). Only the subset needed for telemetry
/// and basic control is enumerated here; the rest can be added as features land.
library;

enum CommPacketId {
  getValues(0),
  setDuty(1),
  setCurrent(2),
  setCurrentBrake(3),
  setRpm(4),
  setPos(5),
  setHandbrakeRel(6),
  setHandbrakeRelUi(7),
  getFirmwareVersion(24),
  getValuesSelective(49),
  getValuesSelectiveSetup(50);

  final int code;

  const CommPacketId(this.code);

  static CommPacketId fromCode(int code) {
    return CommPacketId.values.firstWhere(
      (e) => e.code == code,
      orElse: () =>
          throw ArgumentError.value(code, 'code', 'Unknown CommPacketId'),
    );
  }
}
