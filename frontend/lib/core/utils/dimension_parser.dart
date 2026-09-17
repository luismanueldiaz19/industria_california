class DimensionParser {
  static double parse(String text) {
    if (text.isEmpty) return double.maxFinite;
    final regex = RegExp(r'(\d+)\s+(\d+)/(\d+)|(\d+)/(\d+)|(\d*\.\d+)|(\d+)');
    final match = regex.firstMatch(text);
    if (match != null) {
      if (match.group(1) != null &&
          match.group(2) != null &&
          match.group(3) != null) {
        return double.parse(match.group(1)!) +
            (double.parse(match.group(2)!) / double.parse(match.group(3)!));
      } else if (match.group(4) != null && match.group(5) != null) {
        return double.parse(match.group(4)!) / double.parse(match.group(5)!);
      } else if (match.group(6) != null) {
        return double.parse(match.group(6)!);
      } else if (match.group(7) != null) {
        return double.parse(match.group(7)!);
      }
    }
    return double.maxFinite;
  }
}
