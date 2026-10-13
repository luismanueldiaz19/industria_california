import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/themes/app_theme.dart';
import '../models/cxc_alerta_model.dart';

class AlertaEvidenciaVisorDialog extends StatefulWidget {
  final List<EvidenciaModel> evidencias;
  final int initialIndex;
  final String? titulo;

  const AlertaEvidenciaVisorDialog({
    super.key,
    required this.evidencias,
    this.initialIndex = 0,
    this.titulo,
  });

  static Future<void> show({
    required BuildContext context,
    required List<EvidenciaModel> evidencias,
    int initialIndex = 0,
    String? titulo,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (_) => AlertaEvidenciaVisorDialog(
        evidencias: evidencias,
        initialIndex: initialIndex,
        titulo: titulo,
      ),
    );
  }

  @override
  State<AlertaEvidenciaVisorDialog> createState() =>
      _AlertaEvidenciaVisorDialogState();
}

class _AlertaEvidenciaVisorDialogState
    extends State<AlertaEvidenciaVisorDialog> {
  late final List<EvidenciaModel> _images;
  late int _currentIndex;
  final TransformationController _transformationController =
      TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    final imagesOnly = widget.evidencias.where((e) => e.isImage).toList();
    _images = imagesOnly.isNotEmpty ? imagesOnly : widget.evidencias;

    if (widget.initialIndex >= 0 && widget.initialIndex < widget.evidencias.length) {
      final selectedEv = widget.evidencias[widget.initialIndex];
      final imgIdx = _images.indexOf(selectedEv);
      _currentIndex = imgIdx >= 0 ? imgIdx : 0;
    } else {
      _currentIndex = 0;
    }

    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.05) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _zoomIn() {
    final current = _transformationController.value.getMaxScaleOnAxis();
    if (current < 8.0) {
      final matrix = _transformationController.value.clone();
      matrix.multiply(Matrix4.diagonal3Values(1.25, 1.25, 1.0));
      _transformationController.value = matrix;
    }
  }

  void _zoomOut() {
    final current = _transformationController.value.getMaxScaleOnAxis();
    if (current > 0.4) {
      final matrix = _transformationController.value.clone();
      matrix.multiply(Matrix4.diagonal3Values(0.8, 0.8, 1.0));
      _transformationController.value = matrix;
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
    });
  }

  void _toggleDoubleTapZoom() {
    final current = _transformationController.value.getMaxScaleOnAxis();
    if (current > 1.2) {
      _resetZoom();
    } else {
      final matrix = Matrix4.diagonal3Values(2.5, 2.5, 1.0);
      _transformationController.value = matrix;
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _resetZoom();
      });
    }
  }

  void _goToNext() {
    if (_currentIndex < _images.length - 1) {
      setState(() {
        _currentIndex++;
        _resetZoom();
      });
    }
  }

  Future<void> _abrirEnNavegador(String fullUrl) async {
    if (fullUrl.isEmpty) return;
    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir en navegador: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Dialog(
        backgroundColor: AppTheme.darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppTheme.darkBorderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 36),
              const SizedBox(height: 12),
              const Text(
                'No hay imágenes disponibles para visualizar',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    }

    final currentEv = _images[_currentIndex];
    final totalImages = _images.length;
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: screenSize.width * 0.94,
        height: screenSize.height * 0.92,
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 850),
        decoration: BoxDecoration(
          color: const Color(0xF2101319),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorderColor.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── HEADER ──
                _buildHeader(currentEv, totalImages),

                // ── CUERPO PRINCIPAL CON INTERACTIVE VIEWER ──
                Expanded(
                  child: Stack(
                    children: [
                      // Canvas interactivo para zoom y arrastre
                      Positioned.fill(
                        child: ClipRect(
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.3,
                            maxScale: 8.0,
                            boundaryMargin: const EdgeInsets.all(300),
                            clipBehavior: Clip.hardEdge,
                            child: Center(
                              child: GestureDetector(
                                onDoubleTap: _toggleDoubleTapZoom,
                                child: Image.network(
                                  currentEv.fullUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    final total = progress.expectedTotalBytes;
                                    final loaded = progress.cumulativeBytesLoaded;
                                    final perc = total != null && total > 0
                                        ? (loaded / total)
                                        : null;
                                    return Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 42,
                                            height: 42,
                                            child: CircularProgressIndicator(
                                              value: perc,
                                              color: AppTheme.ledhouseBlue,
                                              strokeWidth: 3,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Text(
                                            perc != null
                                                ? 'Cargando imagen ${(perc * 100).toInt()}%...'
                                                : 'Cargando imagen optimizada...',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.broken_image_rounded,
                                              color: Colors.redAccent,
                                              size: 48,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'No se pudo cargar la imagen:\n${currentEv.nombreArchivo}',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            OutlinedButton.icon(
                                              onPressed: () => setState(() {}),
                                              icon: const Icon(
                                                Icons.refresh,
                                                size: 14,
                                                color: Colors.white70,
                                              ),
                                              label: const Text(
                                                'Reintentar',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Botón previo lateral (si hay múltiples imágenes)
                      if (_currentIndex > 0)
                        Positioned(
                          left: 14,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _buildNavArrowButton(
                              icon: Icons.chevron_left_rounded,
                              tooltip: 'Imagen anterior',
                              onPressed: _goToPrevious,
                            ),
                          ),
                        ),

                      // Botón siguiente lateral (si hay múltiples imágenes)
                      if (_currentIndex < _images.length - 1)
                        Positioned(
                          right: 14,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _buildNavArrowButton(
                              icon: Icons.chevron_right_rounded,
                              tooltip: 'Siguiente imagen',
                              onPressed: _goToNext,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── MINIATURAS INFERIORES Y BARRA DE ESTADO ──
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EvidenciaModel currentEv, int totalImages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        border: Border(
          bottom: BorderSide(color: AppTheme.darkBorderColor),
        ),
      ),
      child: Row(
        children: [
          // Icono y datos del archivo
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blueAccent.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.photo_size_select_actual_outlined,
              color: Colors.blueAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentEv.nombreArchivo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (totalImages > 1) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkInputColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.darkBorderColor),
                        ),
                        child: Text(
                          '${_currentIndex + 1} de $totalImages',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkInputColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Zoom: ${(_currentScale * 100).toInt()}%',
                        style: TextStyle(
                          color: (_currentScale - 1.0).abs() < 0.05
                              ? Colors.grey.shade400
                              : AppTheme.ledhouseBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ── HERRAMIENTAS DE ZOOM E INTERACCIÓN ──
          _buildActionButton(
            icon: Icons.zoom_out_rounded,
            tooltip: 'Alejar zoom (-)',
            onPressed: _zoomOut,
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.aspect_ratio_rounded,
            tooltip: 'Restablecer escala (1:1)',
            onPressed: _resetZoom,
          ),
          const SizedBox(width: 4),
          _buildActionButton(
            icon: Icons.zoom_in_rounded,
            tooltip: 'Acercar zoom (+)',
            onPressed: _zoomIn,
          ),
          const SizedBox(width: 10),
          Container(
            height: 22,
            width: 1,
            color: AppTheme.darkBorderColor,
          ),
          const SizedBox(width: 10),

          // Abrir en pestaña externa / descargar
          _buildActionButton(
            icon: Icons.open_in_new_rounded,
            tooltip: 'Abrir imagen en pestaña externa',
            onPressed: () => _abrirEnNavegador(currentEv.fullUrl),
          ),
          const SizedBox(width: 4),

          // Cerrar modal
          _buildActionButton(
            icon: Icons.close_rounded,
            tooltip: 'Cerrar visor (Esc)',
            isClose: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isClose = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isClose
                ? Colors.redAccent.withValues(alpha: 0.15)
                : AppTheme.darkInputColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isClose
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : AppTheme.darkBorderColor,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isClose ? Colors.redAccent : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildNavArrowButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xCC1A1E29),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final hasMultiple = _images.length > 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCardColor,
        border: Border(
          top: BorderSide(color: AppTheme.darkBorderColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tira de miniaturas si hay más de 1 imagen
          if (hasMultiple) ...[
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _images.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final ev = _images[index];
                  final isSelected = index == _currentIndex;

                  return InkWell(
                    onTap: () {
                      if (_currentIndex != index) {
                        setState(() {
                          _currentIndex = index;
                          _resetZoom();
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.ledhouseBlue
                              : AppTheme.darkBorderColor,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.ledhouseBlue
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          ev.fullUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 120,
                          cacheHeight: 120,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 16,
                              color: Colors.white38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Barra informativa compacta
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mouse_outlined,
                size: 12,
                color: Colors.white38,
              ),
              const SizedBox(width: 6),
              const Text(
                'Rueda del ratón o botones para acercar/alejar • Arrastra para mover • Doble clic para zoom rápido',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
