// lib/src/types/pipecat_metrics.dart

/// A single metric data point.
class PipecatMetricsData {
  const PipecatMetricsData({
    required this.processor,
    required this.value,
  });

  final String processor;
  final double value;

  Map<String, dynamic> toMap() => {
    'processor': processor,
    'value': value,
  };

  factory PipecatMetricsData.fromMap(Map<String, dynamic> map) =>
      PipecatMetricsData(
        processor: map['processor'] as String,
        value: (map['value'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PipecatMetricsData && other.processor == processor && other.value == value;

  @override
  int get hashCode => Object.hash(processor, value);
}

/// Metrics data from the Pipecat pipeline.
class PipecatMetrics {
  const PipecatMetrics({
    this.processing,
    this.ttfb,
    this.characters,
  });

  final List<PipecatMetricsData>? processing;
  final List<PipecatMetricsData>? ttfb;
  final List<PipecatMetricsData>? characters;

  Map<String, dynamic> toMap() => {
    'processing': processing?.map((e) => e.toMap()).toList(),
    'ttfb': ttfb?.map((e) => e.toMap()).toList(),
    'characters': characters?.map((e) => e.toMap()).toList(),
  };

  factory PipecatMetrics.fromMap(Map<String, dynamic> map) => PipecatMetrics(
    processing: (map['processing'] as List<dynamic>?)
        ?.map((e) => PipecatMetricsData.fromMap(e as Map<String, dynamic>))
        .toList(),
    ttfb: (map['ttfb'] as List<dynamic>?)
        ?.map((e) => PipecatMetricsData.fromMap(e as Map<String, dynamic>))
        .toList(),
    characters: (map['characters'] as List<dynamic>?)
        ?.map((e) => PipecatMetricsData.fromMap(e as Map<String, dynamic>))
        .toList(),
  );
}
