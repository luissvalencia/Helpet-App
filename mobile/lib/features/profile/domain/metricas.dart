class Metricas {
  Metricas({
    required this.totalEmbeddings,
    required this.totalCoincidencias,
    required this.coincidenciasPendientes,
    required this.coincidenciasDescartadas,
    required this.similitudPromedio,
    required this.similitudMinima,
    required this.similitudMaxima,
    required this.umbralActual,
    required this.reportesActivos,
    required this.reportesCerrados,
  });

  factory Metricas.fromJson(Map<String, dynamic> json) {
    return Metricas(
      totalEmbeddings: json['totalEmbeddings'] as int,
      totalCoincidencias: json['totalCoincidencias'] as int,
      coincidenciasPendientes: json['coincidenciasPendientes'] as int,
      coincidenciasDescartadas: json['coincidenciasDescartadas'] as int,
      similitudPromedio: (json['similitudPromedio'] as num).toDouble(),
      similitudMinima: (json['similitudMinima'] as num).toDouble(),
      similitudMaxima: (json['similitudMaxima'] as num).toDouble(),
      umbralActual: (json['umbralActual'] as num).toDouble(),
      reportesActivos: json['reportesActivos'] as int,
      reportesCerrados: json['reportesCerrados'] as int,
    );
  }

  final int totalEmbeddings;
  final int totalCoincidencias;
  final int coincidenciasPendientes;
  final int coincidenciasDescartadas;
  final double similitudPromedio;
  final double similitudMinima;
  final double similitudMaxima;
  final double umbralActual;
  final int reportesActivos;
  final int reportesCerrados;

  double get tasaDescarte =>
      totalCoincidencias == 0 ? 0 : coincidenciasDescartadas / totalCoincidencias * 100;
}
