import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/storage_service.dart';
import '../../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'kickster_button.dart';

/// Componente de upload de imagens (logos, badges, fotos) no padrao Kickster,
/// integrado com o Firebase Storage e compativel com Flutter Web.
class KicksterImageUploader extends ConsumerStatefulWidget {
  final String label;
  final String? currentImageUrl;
  final ValueChanged<String> onUploaded;
  final VoidCallback onRemoved;
  final String helperText;
  final int maxSizeBytes;

  const KicksterImageUploader({
    super.key,
    required this.label,
    required this.currentImageUrl,
    required this.onUploaded,
    required this.onRemoved,
    this.helperText = 'PNG, JPG ou WebP (máx. 5MB)',
    this.maxSizeBytes = 5 * 1024 * 1024, // 5MB
  });

  @override
  ConsumerState<KicksterImageUploader> createState() =>
      _KicksterImageUploaderState();
}

class _KicksterImageUploaderState extends ConsumerState<KicksterImageUploader> {
  bool _isUploading = false;
  double _progress = 0.0;
  String? _errorMessage;

  Future<void> _pickAndUpload() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;
      final Uint8List? bytes = pickedFile.bytes;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _errorMessage = 'Não foi possível ler o arquivo selecionado.';
        });
        return;
      }

      if (bytes.lengthInBytes > widget.maxSizeBytes) {
        final maxMb = (widget.maxSizeBytes / (1024 * 1024)).round();
        setState(() {
          _errorMessage = 'O arquivo selecionado excede o limite máximo de ${maxMb}MB.';
        });
        return;
      }

      setState(() {
        _isUploading = true;
        _progress = 0.05;
      });

      final storageService = ref.read(storageServiceProvider);
      final downloadUrl = await storageService.uploadOrganizationLogo(
        bytes: bytes,
        filename: pickedFile.name,
        onProgress: (p) {
          if (mounted) {
            setState(() {
              _progress = p.clamp(0.0, 1.0);
            });
          }
        },
      );

      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _progress = 1.0;
      });

      widget.onUploaded(downloadUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = e is StorageServiceException
            ? e.message
            : 'Falha ao enviar imagem. Verifique a conexão e tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.currentImageUrl != null &&
        widget.currentImageUrl!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: AppTextStyles.fieldLabel.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.helperText.isNotEmpty)
              Text(
                widget.helperText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Container de Upload / Exibicao
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _errorMessage != null
                  ? AppColors.danger
                  : AppColors.line,
              width: _errorMessage != null ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isUploading
              ? _buildUploadingState()
              : hasImage
                  ? _buildPreviewState(widget.currentImageUrl!.trim())
                  : _buildEmptyState(),
        ),

        // Mensagem de Erro Inline
        if (_errorMessage != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _pickAndUpload,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.line.withValues(alpha: 0.8),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Clique para selecionar o logotipo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'O arquivo será salvo com segurança no Firebase Storage',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState() {
    final percent = (_progress * 100).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Enviando para o Firebase Storage...',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewState(String imageUrl) {
    return Row(
      children: [
        // Miniatura da Imagem
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Informacoes e Acoes
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'Logo salvo no Firebase Storage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                imageUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Botoes de Acao
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KicksterButton(
              label: 'Substituir',
              icon: Icons.refresh,
              variant: KicksterButtonVariant.outline,
              onPressed: _pickAndUpload,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remover logotipo',
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: () {
                widget.onRemoved();
              },
            ),
          ],
        ),
      ],
    );
  }
}
