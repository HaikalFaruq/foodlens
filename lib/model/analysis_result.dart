class AnalysisResult {
  final String label;
  final double confidence;
  final List<MapEntry<String, double>>? topK;

  const AnalysisResult({
    required this.label,
    required this.confidence,
    this.topK,
  });
}
