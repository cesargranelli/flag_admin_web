import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'kickster_modal.dart';

/// Campo de upload de imagem com avatar circular e popup de opções.
///
/// Exibe um avatar circular 100×100 com imagem ou placeholder, e um ícone de
/// edição sobreposto (32×32, fundo azul primary, borda branca). Ao tocar no
/// ícone ou na área vazia, abre um popup com opções:
///   • Escolher do arquivo (FilePicker)
///   • Tirar foto (FilePicker no Web)
///   • Excluir foto (quando há imagem)
///
/// O upload é feito via [ApiClient.uploadBytes] (multipart) e a URL retornada
/// pelo backend é repassada ao formulário através de [onUrlChanged].
///
/// Segue o design system Kickster (Figma avatar + modal com cards).
class ImageUploadField extends StatefulWidget {
  const ImageUploadField({
    super.key,
    required this.label,
    required this.apiClient,
    this.imageUrl,
    required this.onUrlChanged,
    this.enabled = true,
  });

  /// Rótulo exibido acima do avatar (para acessibilidade / screen readers).
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

  bool get _hasImage =>
      widget.imageUrl != null && widget.imageUrl!.isNotEmpty;

  // ── File picking + upload ──────────────────────────────────────────────

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

  // ── Popup de opções ────────────────────────────────────────────────────

  void _openOptionsDialog() {
    if (!widget.enabled) return;

    showDialog<void>(
      context: context,
      builder: (_) => _ImageOptionsDialog(
        hasImage: _hasImage,
        onPickFile: () {
          Navigator.of(context).pop();
          _pickAndUpload();
        },
        onTakePhoto: () {
          Navigator.of(context).pop();
          if (kIsWeb) {
            // No Web, câmera nativa não disponível — abre FilePicker como
            // alternativa (o usuário pode tirar foto pela câmera do browser
            // ao selecionar arquivo).
            _pickAndUpload();
          } else {
            _pickAndUpload();
          }
        },
        onDelete: () {
          Navigator.of(context).pop();
          _removeImage();
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rótulo para acessibilidade.
        Text(
          widget.label,
          style: AppTextStyles.fieldLabel.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        // Avatar com overlay de edição.
        Center(child: _buildAvatar()),
        if (_uploading) ...[
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar circular (imagem ou placeholder).
          GestureDetector(
            onTap: widget.enabled && !_hasImage ? _openOptionsDialog : null,
            child: _hasImage ? _buildImageAvatar() : _buildPlaceholder(),
          ),
          // Ícone de edição sobreposto (bottom-right).
          if (widget.enabled)
            Positioned(
              bottom: 0,
              right: 0,
              child: _EditBadge(onTap: _openOptionsDialog),
            ),
          // Indicador de upload sobre o avatar.
          if (_uploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.4),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          AppConfig.resolveImageUrl(widget.imageUrl!),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          // Exibe placeholder enquanto a primeira frame não é pintada.
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return _buildPlaceholder();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.grayFill,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.grayFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.disabled,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: AppColors.grayFill,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline,
        color: AppColors.textSecondary,
        size: 40,
      ),
    );
  }
}

// ── Ícone de edição circular (azul + borda branca) ──────────────────────

/// Badge circular de edição no canto inferior direito do avatar.
/// Segue o Figma: 32×32, fundo `AppColors.primary`, borda branca 3px,
/// ícone `Icons.edit` branco tamanho 18.
class _EditBadge extends StatelessWidget {
  const _EditBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: const Icon(Icons.edit, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

// ── Dialog de opções (Figma "Change picture popup") ─────────────────────

/// Modal com as opções de troca de imagem, seguindo o estilo do Figma:
/// cards 296×60, bg #F5F5F5, border-radius 8, ícone + texto.
class _ImageOptionsDialog extends StatelessWidget {
  const _ImageOptionsDialog({
    required this.hasImage,
    required this.onPickFile,
    required this.onTakePhoto,
    required this.onDelete,
  });

  final bool hasImage;
  final VoidCallback onPickFile;
  final VoidCallback onTakePhoto;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return kicksterModalDialog(
      title: const Text('Alterar foto'),
      content: SizedBox(
        width: 296,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _OptionCard(
              icon: Icons.upload_file,
              label: 'Escolher do arquivo',
              onTap: onPickFile,
            ),
            const SizedBox(height: 8),
            _OptionCard(
              icon: Icons.photo_camera,
              label: 'Tirar foto',
              onTap: onTakePhoto,
            ),
            if (hasImage) ...[
              const SizedBox(height: 8),
              _OptionCard(
                icon: Icons.delete_outline,
                label: 'Excluir foto',
                onTap: onDelete,
                danger: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card de opção no popup: fundo #F5F5F5, border-radius 8, ícone + texto.
/// Segue o estilo do Figma (296×60, Body text style/Medium/Bold 14px).
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final textColor = danger ? AppColors.danger : AppColors.textPrimary;
    final iconColor = danger ? AppColors.danger : AppColors.textPrimary;

    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 21, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
