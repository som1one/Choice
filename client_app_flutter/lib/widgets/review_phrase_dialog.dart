import 'package:flutter/material.dart';

class ReviewPhraseSelection {
  final int grade;
  final int criterionId;
  final String text;

  const ReviewPhraseSelection({
    required this.grade,
    required this.criterionId,
    required this.text,
  });
}

Future<ReviewPhraseSelection?> showReviewPhraseDialog({
  required BuildContext context,
  required String title,
  required List<Map<String, dynamic>> phrases,
}) {
  return showDialog<ReviewPhraseSelection>(
    context: context,
    builder: (context) => _ReviewPhraseDialog(
      title: title,
      phrases: phrases,
    ),
  );
}

class _ReviewPhraseDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> phrases;

  const _ReviewPhraseDialog({
    required this.title,
    required this.phrases,
  });

  @override
  State<_ReviewPhraseDialog> createState() => _ReviewPhraseDialogState();
}

class _ReviewPhraseDialogState extends State<_ReviewPhraseDialog> {
  int _selectedGrade = 5;
  int? _selectedCriterionId;
  String? _selectedText;

  List<Map<String, dynamic>> get _filteredPhrases {
    final result = widget.phrases.where((item) {
      final grade = int.tryParse(item['grade']?.toString() ?? '');
      final isActive = item['is_active'] != false;
      return grade == _selectedGrade && isActive;
    }).toList();
    result.sort((a, b) {
      final aOrder = int.tryParse(a['sort_order']?.toString() ?? '') ?? 0;
      final bOrder = int.tryParse(b['sort_order']?.toString() ?? '') ?? 0;
      return aOrder.compareTo(bOrder);
    });
    return result;
  }

  void _selectGrade(int grade) {
    setState(() {
      _selectedGrade = grade;
      _selectedCriterionId = null;
      _selectedText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final phrases = _filteredPhrases;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Выберите оценку',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: List.generate(5, (index) {
                final grade = index + 1;
                final selected = _selectedGrade == grade;
                return IconButton(
                  onPressed: () => _selectGrade(grade),
                  icon: Icon(
                    selected ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  tooltip: '$grade',
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              'Фраза для $_selectedGrade ${_selectedGrade == 1 ? 'звезды' : _selectedGrade < 5 ? 'звезд' : 'звезд'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (phrases.isEmpty)
              const Text(
                'Для этой оценки пока нет доступных фраз.',
                style: TextStyle(color: Colors.grey),
              )
            else
              SizedBox(
                width: double.maxFinite,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: SingleChildScrollView(
                    child: Column(
                      children: phrases.map((phrase) {
                        final id = int.tryParse(phrase['id']?.toString() ?? '');
                        final text = (phrase['text'] ?? '').toString();
                        return RadioListTile<int>(
                          value: id ?? -1,
                          groupValue: _selectedCriterionId,
                          title: Text(text),
                          onChanged: id == null
                              ? null
                              : (_) {
                                  setState(() {
                                    _selectedCriterionId = id;
                                    _selectedText = text;
                                  });
                                },
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: _selectedCriterionId == null || _selectedText == null
              ? null
              : () => Navigator.pop(
                    context,
                    ReviewPhraseSelection(
                      grade: _selectedGrade,
                      criterionId: _selectedCriterionId!,
                      text: _selectedText!,
                    ),
                  ),
          child: const Text('Отправить'),
        ),
      ],
    );
  }
}
