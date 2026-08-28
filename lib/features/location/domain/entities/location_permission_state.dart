enum LocationPermissionState {
  granted,
  denied,
  permanentlyDenied,
  unableToDetermine;

  bool get isGranted => this == LocationPermissionState.granted;
  bool get isDenied =>
      this == LocationPermissionState.denied ||
      this == LocationPermissionState.permanentlyDenied;
  bool get isPermanentlyDenied =>
      this == LocationPermissionState.permanentlyDenied;
}
