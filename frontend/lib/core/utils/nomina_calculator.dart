/// Calculadora oficial de retenciones y deducciones laborales según la normativa de la República Dominicana
/// (Ley 87-01 de Seguridad Social y Código Tributario DGII para Retención de Asalariados).
///
/// Soporta configuración dinámica sincronizada desde el backend (Base de Datos) para que
/// cambios tributarios o reformas de la DGII / TSS NO requieran recompilar la aplicación.
class NominaCalculator {
  // Constantes de Ley por defecto (Fallback legal vigente)
  static const double tasaAfpDefault = 0.0287; // 2.87% AFP
  static const double tasaArsDefault = 0.0304; // 3.04% ARS (SFS)

  // Configuración dinámica sincronizada en caliente
  static List<TramoIsrModel>? _tramosDinamicos;
  static double _tasaAfpDinamica = tasaAfpDefault;
  static double _tasaArsDinamica = tasaArsDefault;

  /// Tasa AFP activa (dinámica o por defecto)
  static double get tasaAfp => _tasaAfpDinamica;

  /// Tasa ARS activa (dinámica o por defecto)
  static double get tasaArs => _tasaArsDinamica;

  /// Tasa TSS total activa
  static double get tasaTssTotal => _tasaAfpDinamica + _tasaArsDinamica;

  // Tramos DGII Mensuales Oficiales por Defecto (Año Base)
  static const double tramo1Mensual = 34685.00; // Exento hasta RD$34,685.00
  static const double tramo2Mensual =
      52027.42; // RD$34,685.01 a RD$52,027.42 (15%)
  static const double tramo3Mensual =
      72260.25; // RD$52,027.43 a RD$72,260.25 (20%)

  static const double baseImpuestoTramo2Mensual = 2601.33; // RD$31,216 / 12
  static const double baseImpuestoTramo3Mensual = 6648.00; // RD$79,776 / 12

  /// Sincroniza dinámicamente las escalas de la DGII y tasas TSS desde la API sin recompilar
  static void setConfiguracionDinamica({
    required List<TramoIsrModel> tramos,
    double? tasaAfp,
    double? tasaArs,
  }) {
    _tramosDinamicos = List.from(tramos)
      ..sort((a, b) => a.desdeMensual.compareTo(b.desdeMensual));
    if (tasaAfp != null && tasaAfp > 0) _tasaAfpDinamica = tasaAfp;
    if (tasaArs != null && tasaArs > 0) _tasaArsDinamica = tasaArs;
  }

  /// Calcula el aporte a la AFP del trabajador
  static double calcularAfp(double salario, {bool aplica = true}) {
    if (!aplica || salario <= 0) return 0.0;
    return double.parse((salario * _tasaAfpDinamica).toStringAsFixed(2));
  }

  /// Calcula el aporte al SFS / ARS del trabajador
  static double calcularArs(double salario, {bool aplica = true}) {
    if (!aplica || salario <= 0) return 0.0;
    return double.parse((salario * _tasaArsDinamica).toStringAsFixed(2));
  }

  /// Calcula el total de TSS del trabajador
  static double calcularTssTotal(
    double salario, {
    bool aplicaAfp = true,
    bool aplicaArs = true,
  }) {
    return calcularAfp(salario, aplica: aplicaAfp) +
        calcularArs(salario, aplica: aplicaArs);
  }

  /// Calcula la retención mensual del Impuesto Sobre la Renta (ISR) para personas físicas asalariadas.
  /// Deduce previamente la TSS obligatoria sobre el salario bruto mensual y aplica los tramos dinámicos.
  static double calcularIsrMensual({
    required double salarioMensual,
    bool aplicaAfp = true,
    bool aplicaArs = true,
    bool aplicaIsr = true,
  }) {
    if (!aplicaIsr || salarioMensual <= 0) return 0.0;

    // 1. Renta Neta Imponible Mensual = Salario Mensual - TSS deducida
    final tss = calcularTssTotal(
      salarioMensual,
      aplicaAfp: aplicaAfp,
      aplicaArs: aplicaArs,
    );
    final rentaNetaMensual = salarioMensual - tss;

    // 2. Si hay tramos dinámicos configurados desde la base de datos, iterar sobre ellos
    if (_tramosDinamicos != null && _tramosDinamicos!.isNotEmpty) {
      for (final tramo in _tramosDinamicos!) {
        final hasta = tramo.hastaMensual ?? double.infinity;
        if (rentaNetaMensual >= tramo.desdeMensual &&
            rentaNetaMensual <= hasta) {
          final excedente = (rentaNetaMensual - tramo.excedenteDesdeMensual)
              .clamp(0.0, double.infinity);
          final impuesto =
              tramo.impuestoBaseMensual +
              (excedente * (tramo.tasaPorcentaje / 100.0));
          return double.parse(impuesto.toStringAsFixed(2));
        }
      }
    }

    // 3. Fallback legal de contingencia (Escala oficial 2026)
    if (rentaNetaMensual <= tramo1Mensual) {
      return 0.0; // Exento
    }

    if (rentaNetaMensual <= tramo2Mensual) {
      final excedente = rentaNetaMensual - tramo1Mensual;
      return double.parse((excedente * 0.15).toStringAsFixed(2));
    }

    if (rentaNetaMensual <= tramo3Mensual) {
      final excedente = rentaNetaMensual - tramo2Mensual;
      final impuesto = baseImpuestoTramo2Mensual + (excedente * 0.20);
      return double.parse(impuesto.toStringAsFixed(2));
    }

    // Más de tramo 3 mensual (> RD$ 72,260.25)
    final excedente = rentaNetaMensual - tramo3Mensual;
    final impuesto = baseImpuestoTramo3Mensual + (excedente * 0.25);
    return double.parse(impuesto.toStringAsFixed(2));
  }

  /// Calcula la retención de ISR para nómina quincenal (la mitad de la retención mensual calculada)
  static double calcularIsrQuincenal({
    required double salarioMensual,
    bool aplicaAfp = true,
    bool aplicaArs = true,
    bool aplicaIsr = true,
  }) {
    final isrMensual = calcularIsrMensual(
      salarioMensual: salarioMensual,
      aplicaAfp: aplicaAfp,
      aplicaArs: aplicaArs,
      aplicaIsr: aplicaIsr,
    );
    return double.parse((isrMensual / 2).toStringAsFixed(2));
  }

  /// Estructura resumen de un cálculo previo completo para consulta rápida en UI
  static SimulacionNomina simularPeriodo({
    required double salarioMensual,
    required bool esQuincenal,
    bool aplicaAfp = true,
    bool aplicaArs = true,
    bool aplicaIsr = true,
  }) {
    final salarioPeriodo = esQuincenal ? salarioMensual / 2 : salarioMensual;
    final afp = calcularAfp(salarioPeriodo, aplica: aplicaAfp);
    final ars = calcularArs(salarioPeriodo, aplica: aplicaArs);
    final tss = afp + ars;

    final isr = esQuincenal
        ? calcularIsrQuincenal(
            salarioMensual: salarioMensual,
            aplicaAfp: aplicaAfp,
            aplicaArs: aplicaArs,
            aplicaIsr: aplicaIsr,
          )
        : calcularIsrMensual(
            salarioMensual: salarioMensual,
            aplicaAfp: aplicaAfp,
            aplicaArs: aplicaArs,
            aplicaIsr: aplicaIsr,
          );

    final totalDeduccionesLey = tss + isr;
    final salarioNeto = salarioPeriodo - totalDeduccionesLey;

    return SimulacionNomina(
      salarioBruto: salarioPeriodo,
      salarioMensual: salarioMensual,
      afp: afp,
      ars: ars,
      totalTss: tss,
      rentaNetaImponible: salarioPeriodo - tss,
      isr: isr,
      totalDeduccionesLey: totalDeduccionesLey,
      salarioNeto: salarioNeto,
    );
  }
}

/// Modelo de un tramo de la escala progresiva DGII
class TramoIsrModel {
  final int anio;
  final double desdeMensual;
  final double? hastaMensual;
  final double tasaPorcentaje;
  final double impuestoBaseMensual;
  final double excedenteDesdeMensual;
  final String? descripcion;

  const TramoIsrModel({
    required this.anio,
    required this.desdeMensual,
    this.hastaMensual,
    required this.tasaPorcentaje,
    required this.impuestoBaseMensual,
    required this.excedenteDesdeMensual,
    this.descripcion,
  });

  factory TramoIsrModel.fromJson(Map<String, dynamic> json) {
    return TramoIsrModel(
      anio: json['anio'] is int
          ? json['anio'] as int
          : int.tryParse(json['anio'].toString()) ?? 2026,
      desdeMensual:
          double.tryParse(json['desde_mensual']?.toString() ?? '0') ?? 0.0,
      hastaMensual: json['hasta_mensual'] != null
          ? double.tryParse(json['hasta_mensual'].toString())
          : null,
      tasaPorcentaje:
          double.tryParse(json['tasa_porcentaje']?.toString() ?? '0') ?? 0.0,
      impuestoBaseMensual:
          double.tryParse(json['impuesto_base_mensual']?.toString() ?? '0') ??
          0.0,
      excedenteDesdeMensual:
          double.tryParse(json['excedente_desde_mensual']?.toString() ?? '0') ??
          0.0,
      descripcion: json['descripcion'] as String?,
    );
  }
}

class SimulacionNomina {
  final double salarioBruto;
  final double salarioMensual;
  final double afp;
  final double ars;
  final double totalTss;
  final double rentaNetaImponible;
  final double isr;
  final double totalDeduccionesLey;
  final double salarioNeto;

  const SimulacionNomina({
    required this.salarioBruto,
    required this.salarioMensual,
    required this.afp,
    required this.ars,
    required this.totalTss,
    required this.rentaNetaImponible,
    required this.isr,
    required this.totalDeduccionesLey,
    required this.salarioNeto,
  });
}
