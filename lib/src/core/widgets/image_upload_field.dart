import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Campo de upload de imagem com preview e botão de seleção.
///
/// Exibe um placeholder com borda tracejada quando não há imagem e um preview
/// quando uma URL é fornecida. O upload é feito via [ApiClient.uploadBytes]
/// (multipart) e a URL retornada pelo backend é repassada ao formulário
/// através de [onUrlChanged].
///
/// Segue o design system Kickster (raio 24, fundo surface, borda fieldBorder).
class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.label,
    required this.apiClient,
    this.imageUrl,
    required this.onUrlChanged,
    this.enabled = true,
  });

  /// Rótulo exibido acima do campo.
  final String label;

  /// Cliente HTTP para realizar o upload multipart.
  final ApiClient apiClient;

  /// URL da imagem atual (pode ser nula se nenhuma imagem foi selecionada).
  final String? imageUrl;

  /// Callback chamado quando a URL da imagem muda (upload concluído ou
  /// remoção). Passa `null` quando a imagem é removida.
  final ValueChanged<String?> onUrlChanged;

  /// Se false, o campo fica desabilitado (upload e remoção bloqueados).
  final bool enabled;

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('imageUrl', imageUrl))
      ..add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true));
  }
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    if (!widget.enabled || _uploading) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível ler o arquivo selecionado.'),
          ),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      final url = await widget.apiClient.uploadBytes(bytes, file.name);
      if (mounted) widget.onUrlChanged(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao enviar imagem: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removeImage() {
    if (!widget.enabled) return;
    widget.onUrlChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _fieldDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
            _buildPreview()
          else
            _buildPlaceholder(),
          if (_uploading) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Enviando...',
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            widget.imageUrl!,
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.grayFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.disabled,
                size: 40,
              ),
            ),
          ),
        ),
        if (widget.enabled)
          Positioned(
            top: 4,
            right: 4,
            child: _ActionBadge(
              icon: Icons.close,
              onTap: _removeImage,
              tooltip: 'Remover imagem',
            ),
          ),
        if (widget.enabled)
          Positioned(
            bottom: 4,
            right: 4,
            child: _ActionBadge(
              icon: Icons.edit,
              onTap: _pickAndUpload,
              tooltip: 'Trocar imagem',
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return InkWell(
      onTap: widget.enabled ? _pickAndUpload : null,
      borderRadius: BorderRadius.circular(12),
      child: DashedBorder(
        radius: 12,
        color: AppColors.disabled,
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_a_photo_outlined,
                  size: 32,
                  color: AppColors.disabled,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecionar\nimagem',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fieldLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      labelText: widget.label,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(12),
      labelStyle: AppTextStyles.paragraph.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.grayLabel,
      ),
      floatingLabelStyle: AppTextStyles.fieldLabel.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      border: _border(AppColors.fieldBorder),
      enabledBorder: _border(AppColors.fieldBorder),
      focusedBorder: _border(AppColors.primary, width: 2),
      disabledBorder: _border(AppColors.disabled),
      errorBorder: _border(AppColors.danger),
      focusedErrorBorder: _border(AppColors.danger, width: 2),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

/// Botão circular de ação sobreposto ao preview da imagem.
class _ActionBadge extends StatelessWidget {
  const _ActionBadge({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Widget auxiliar que desenha uma borda tracejada (dashed) ao redor do filho.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.child,
    this.radius = 12,
    this.color = AppColors.disabled,
  });

  final Widget child;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);

    // Simula borda tracejada: 6px linha, 4px espaço.
    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;
    const dashLen = 6.0;
    const gapLen = 4.0;
    double distance = 0;

    while (distance < totalLength) {
      final start = metrics.getTangentForOffset(distance)!.position;
      final endDist = (distance + dashLen).clamp(0.0, totalLength);
      final end = metrics.getTangentForOffset(endDist)!.position;
      canvas.drawLine(start, end, paint);
      distance += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
