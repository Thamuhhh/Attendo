class AppVersion {
  static const String current = '1.0.1';
  static const int buildNumber = 1;

  static bool isNewer(String remote) {
    final curParts = current.split('.').map(int.parse).toList();
    final remParts = remote.split('.').map(int.parse).toList();
    for (int i = 0; i < 3; i++) {
      final c = i < curParts.length ? curParts[i] : 0;
      final r = i < remParts.length ? remParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }
}