import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/general_header.dart';
import '../../led_house/providers/ledhouse_cliente_provider.dart';
import '../../vendedor/widgets/vendedor_mobile_wrapper.dart';
import '../providers/cheque_form_provider.dart';
import 'cheque_form_step1_screen.dart';
import 'cheque_form_step2_preview_screen.dart';

/// Orquestador del flujo de 2 pasos para registrar un Cheque Futurista.
/// Paso 1: Formulario de datos.
/// Paso 2: Preview / Confirmación antes de enviar.
class ChequeNuevoFlowScreen extends StatelessWidget {
  const ChequeNuevoFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ChequeFormProvider())],
      child: const _ChequeNuevoFlowContent(),
    );
  }
}

class _ChequeNuevoFlowContent extends StatefulWidget {
  const _ChequeNuevoFlowContent();

  @override
  State<_ChequeNuevoFlowContent> createState() =>
      _ChequeNuevoFlowContentState();
}

class _ChequeNuevoFlowContentState extends State<_ChequeNuevoFlowContent> {
  static const _redDark = Color(0xFF7F0000);
  static const _redMain = Color(0xFFB71C1C);

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await context.read<LedhouseClienteProvider>().fetchClientes();
    if (mounted) setState(() => _isLoading = false);
  }

  void _goToStep2() {
    FocusScope.of(context).unfocus();
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 1);
  }

  void _backToStep1() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 0);
  }

  void _handleBack() {
    if (_currentStep > 0) {
      _backToStep1();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MobileWrapper(
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Column(
            children: [
              GeneralHeader(
                title: 'Nuevo Cheque',
                subtitle: 'Cargando datos...',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.white,
                showBackButton: true,
                gradientColors: const [_redDark, _redMain],
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    return MobileWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Column(
          children: [
            // ── Header con stepper ────────────────────────────
            GeneralHeader(
              title: _currentStep == 0 ? 'Nuevo Cheque' : 'Confirmar Cheque',
              subtitle: _currentStep == 0
                  ? 'Paso 1 de 2 — Datos del cheque'
                  : 'Paso 2 de 2 — Revisa antes de guardar',
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.white,
              showBackButton: true,
              onBackPressed: _handleBack,
              gradientColors: const [_redDark, _redMain],
            ),
            // ── Stepper visual ────────────────────────────────
            _StepIndicator(currentStep: _currentStep),
            // ── Contenido por pasos ───────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ChequeFormStep1Screen(onNext: _goToStep2),
                  ChequeFormStep2PreviewScreen(
                    onBack: _backToStep1,
                    onSuccess: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indicador visual de 2 pasos con línea de progreso.
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  static const _red = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF8B0000),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Row(
        children: [
          _step(0, 'Datos', currentStep),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: currentStep >= 1
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
          _step(1, 'Confirmar', currentStep),
        ],
      ),
    );
  }

  Widget _step(int index, String label, int current) {
    final isActive = current >= index;
    final isCurrent = current == index;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.25),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isActive ? _red : Colors.white54,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
