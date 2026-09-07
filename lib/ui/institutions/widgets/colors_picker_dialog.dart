import 'package:flutter/material.dart';
import 'package:flag_admin_web/src/core/theme/app_colors.dart';

/// Diálogo para seleção e edição de cores da agremiação.
class ColorsPickerDialog extends StatefulWidget {
  final List<String> initial;

  const ColorsPickerDialog({super.key, required this.initial});

  @override
  State<ColorsPickerDialog> createState() => _ColorsPickerDialogState();
}

class _ColorsPickerDialogState extends State<ColorsPickerDialog> {
  late List<String> colors;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    colors = List.from(widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isHex(String s) => RegExp(r'^#([0-9a-fA-F]{6})$').hasMatch(s);

  Color _hexToColor(String h) =>
      Color(int.parse(h.substring(1), radix: 16) + 0xFF000000);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cores da Agremiação',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, colors),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (colors.isNotEmpty)
              Row(
                children: colors
                    .take(4)
                    .map((e) => Container(
                          width: 40,
                          height: 40,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: _isHex(e) ? _hexToColor(e) : AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black12),
                          ),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 16),
            ...colors.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isHex(e.value)
                              ? _hexToColor(e.value)
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.value)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => setState(() => colors.removeAt(e.key)),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '#RRGGBB (ex: #FF0000)',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () {
                    if (colors.length >= 6) return;
                    final v = _controller.text.trim();
                    if (_isHex(v)) {
                      setState(() => colors.add(v.toUpperCase()));
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context, colors),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
