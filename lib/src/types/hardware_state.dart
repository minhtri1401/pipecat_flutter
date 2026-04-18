// lib/src/types/hardware_state.dart
import 'media_device_info.dart';

/// The current state of hardware devices.
class HardwareState {
  const HardwareState({
    this.availableMics = const [],
    this.availableCams = const [],
    this.availableSpeakers = const [],
    this.selectedMic,
    this.selectedCam,
    this.selectedSpeaker,
    this.isMicEnabled = false,
    this.isCamEnabled = false,
  });

  final List<MediaDeviceInfo> availableMics;
  final List<MediaDeviceInfo> availableCams;
  final List<MediaDeviceInfo> availableSpeakers;
  final MediaDeviceInfo? selectedMic;
  final MediaDeviceInfo? selectedCam;
  final MediaDeviceInfo? selectedSpeaker;
  final bool isMicEnabled;
  final bool isCamEnabled;

  /// Creates a copy with the given fields replaced.
  ///
  /// For nullable fields (selectedMic, selectedCam, selectedSpeaker),
  /// pass a callback to set the value, e.g.:
  /// ```dart
  /// state.copyWith(selectedMic: () => null)  // clears selected mic
  /// state.copyWith(selectedMic: () => newMic) // sets selected mic
  /// ```
  /// Omitting the parameter keeps the current value.
  HardwareState copyWith({
    List<MediaDeviceInfo>? availableMics,
    List<MediaDeviceInfo>? availableCams,
    List<MediaDeviceInfo>? availableSpeakers,
    MediaDeviceInfo? Function()? selectedMic,
    MediaDeviceInfo? Function()? selectedCam,
    MediaDeviceInfo? Function()? selectedSpeaker,
    bool? isMicEnabled,
    bool? isCamEnabled,
  }) {
    return HardwareState(
      availableMics: availableMics ?? this.availableMics,
      availableCams: availableCams ?? this.availableCams,
      availableSpeakers: availableSpeakers ?? this.availableSpeakers,
      selectedMic: selectedMic != null ? selectedMic() : this.selectedMic,
      selectedCam: selectedCam != null ? selectedCam() : this.selectedCam,
      selectedSpeaker: selectedSpeaker != null ? selectedSpeaker() : this.selectedSpeaker,
      isMicEnabled: isMicEnabled ?? this.isMicEnabled,
      isCamEnabled: isCamEnabled ?? this.isCamEnabled,
    );
  }
}
