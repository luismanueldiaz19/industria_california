import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../led_house/providers/ledhouse_cliente_provider.dart';
import '../providers/cheque_form_provider.dart';
import '../../vendedor/widgets/pedido_cliente_selector.dart';

/// Paso 1: Formulario de datos del cheque futurista.
/// El vendedor es siempre el usuario autenticado (read-only).
class ChequeFormStep1Screen extends StatefulWidget {
  final VoidCallback onNext;
  const ChequeFormStep1Screen({super.key, required this.onNext});

  @override
  State<ChequeFormStep1Screen> createState() => _ChequeFormStep1ScreenState();
}

class _ChequeFormStep1ScreenState extends State<ChequeFormStep1Screen> {
  static const _red = Color(0xFFB71C1C);
  final _numChequeCtrl = TextEditingController();
  final _numPedidoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _comentarioCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with form data in case we are returning from Step 2
    final form = context.read<ChequeFormProvider>();
    _numChequeCtrl.text = form.numCheque;
    _numPedidoCtrl.text = form.numPedido;
    _montoCtrl.text = form.monto;
    _comentarioCtrl.text = form.comentario;
  }

  @override
  void dispose() {
    _numChequeCtrl.dispose();
    _numPedidoCtrl.dispose();
    _montoCtrl.dispose();
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ChequeFormProvider>();
    final auth = context.watch<AuthProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cliente ───────────────────────────────────────
          _sectionLabel('Cliente *', Icons.person_outline),
          const SizedBox(height: 8),
          PedidoClienteSelector(
            selected: form.cliente,
            onChanged: (c) => context.read<ChequeFormProvider>().setCliente(c),
          ),
          const SizedBox(height: 20),

          // ── Vendedor (usuario logueado — solo lectura) ────
          _sectionLabel('Vendedor', Icons.badge_outlined),
          const SizedBox(height: 8),
          _VendedorReadOnly(
            name: auth.name ?? auth.username ?? 'Usuario',
            username: auth.username ?? '',
          ),
          const SizedBox(height: 20),

          // ── Número de Cheque (Obligatorio) ────────────────
          _sectionLabel('N° de Cheque *', Icons.numbers),
          const SizedBox(height: 8),
          _inputField(
            controller: _numChequeCtrl,
            hint: 'Ej: 123456789',
            icon: Icons.tag,
            onChanged: (v) =>
                context.read<ChequeFormProvider>().setNumCheque(v),
          ),
          const SizedBox(height: 20),

          // ── Número de Pedido (opcional) ───────────────────
          _sectionLabel('N° de Pedido', Icons.tag, optional: true),
          const SizedBox(height: 8),
          _inputField(
            controller: _numPedidoCtrl,
            hint: 'Ej: PED-0042',
            icon: Icons.receipt_long_outlined,
            onChanged: (v) =>
                context.read<ChequeFormProvider>().setNumPedido(v),
          ),
          const SizedBox(height: 20),

          // ── Monto (Obligatorio) ───────────────────────────
          _sectionLabel('Monto *', Icons.attach_money),
          const SizedBox(height: 8),
          _inputField(
            controller: _montoCtrl,
            hint: 'Ej: 1500.00',
            icon: Icons.monetization_on_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            onChanged: (v) => context.read<ChequeFormProvider>().setMonto(v),
          ),
          const SizedBox(height: 20),

          // ── Estado ────────────────────────────────────────
          _sectionLabel('Estado', Icons.flag_outlined),
          const SizedBox(height: 8),
          _EstadoSelector(
            selected: form.estado,
            onChanged: (v) => context.read<ChequeFormProvider>().setEstado(v),
          ),
          const SizedBox(height: 20),

          // ── Comentario (opcional) ─────────────────────────
          _sectionLabel('Comentario', Icons.comment_outlined, optional: true),
          const SizedBox(height: 8),
          _inputField(
            controller: _comentarioCtrl,
            hint: 'Escribe un comentario libre...',
            icon: Icons.chat_bubble_outline,
            maxLines: 3,
            onChanged: (v) =>
                context.read<ChequeFormProvider>().setComentario(v),
          ),
          const SizedBox(height: 20),

          // ── Documentos / Fotos (opcional) ─────────────────
          _sectionLabel(
            'Documentos Adjuntos',
            Icons.attach_file,
            optional: true,
          ),
          const SizedBox(height: 8),
          _ImageUploader(picker: _picker),
          const SizedBox(height: 32),

          // ── Botón Siguiente ───────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: form.isFormValid ? widget.onNext : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text(
                'Revisar y Confirmar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),

          if (!form.isFormValid) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Selecciona un cliente y define un número de cheque y monto válidos (*)',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, IconData icon, {bool optional = false}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFB71C1C)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E2F4C),
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 4),
          Text(
            '(Opcional)',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade500),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

// ── Vendedor Read-Only ────────────────────────────────────────────────────────

class _VendedorReadOnly extends StatelessWidget {
  final String name;
  final String username;

  const _VendedorReadOnly({required this.name, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFB71C1C).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFB71C1C).withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFB71C1C).withValues(alpha: 0.12),
          radius: 16,
          child: const Icon(Icons.badge, color: Color(0xFFB71C1C), size: 18),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Color(0xFF1E2F4C),
          ),
        ),
        subtitle: Text('@$username', style: const TextStyle(fontSize: 11)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFB71C1C).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Tú',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFB71C1C),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Selector de Estado ────────────────────────────────────────────────────────

class _EstadoSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _EstadoSelector({required this.selected, required this.onChanged});

  static const _estados = [
    _EstadoOption('pendiente', 'Pendiente', Color(0xFFFF9800)),
    _EstadoOption('depositado', 'Depositado', Color(0xFF4CAF50)),
    _EstadoOption('cancelado', 'Cancelado', Colors.grey),
    _EstadoOption('vencido', 'Vencido', Color(0xFFB71C1C)),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _estados
          .map((e) => _buildChip(e, selected == e.value))
          .toList(),
    );
  }

  Widget _buildChip(_EstadoOption opt, bool isSelected) {
    return GestureDetector(
      onTap: () => onChanged(opt.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? opt.color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? opt.color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: opt.color.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Icon(Icons.check_circle, size: 13, color: opt.color),
            if (isSelected) const SizedBox(width: 4),
            Text(
              opt.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? opt.color : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoOption {
  final String value;
  final String label;
  final Color color;
  const _EstadoOption(this.value, this.label, this.color);
}

// ── Uploader de Imágenes ──────────────────────────────────────────────────────

class _ImageUploader extends StatelessWidget {
  final ImagePicker picker;
  const _ImageUploader({required this.picker});

  static const _red = Color(0xFFB71C1C);

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final form = context.read<ChequeFormProvider>();

    // Si es galería, permitimos selección múltiple
    if (source == ImageSource.gallery) {
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isNotEmpty) {
        form.addArchivos(images);
      }
    } else {
      // Si es cámara, solo permite una foto a la vez
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        form.addArchivos([image]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = context.watch<ChequeFormProvider>();
    final archivos = form.archivos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (archivos.isNotEmpty) ...[
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: archivos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final file = archivos[i];
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        image: DecorationImage(
                          image: FileImage(File(file.path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cancel,
                            size: 20,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        onPressed: () => form.removeArchivo(i),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(context, ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  size: 18,
                  color: _red,
                ),
                label: const Text(
                  'Cámara',
                  style: TextStyle(color: _red, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(context, ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.photo_library_outlined,
                  size: 18,
                  color: _red,
                ),
                label: const Text(
                  'Galería',
                  style: TextStyle(color: _red, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
