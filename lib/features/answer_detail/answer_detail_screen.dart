import 'package:flutter/material.dart';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';

class AnswerDetailScreen extends StatefulWidget {
  final QuestionModel question;

  const AnswerDetailScreen({
    super.key,
    required this.question,
  });

  @override
  State<AnswerDetailScreen> createState() => _AnswerDetailScreenState();
}

class _AnswerDetailScreenState extends State<AnswerDetailScreen> {
  final _answerController = TextEditingController();
  final _service = QuestionsFirestoreService();
  bool _publish = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _answerController.text = widget.question.answer ?? '';
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    await _service.updateAnswer(
      questionId: widget.question.id,
      answer: _answerController.text.trim(),
      publish: _publish,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Answer saved')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answer Question')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.questionText, // ✅ UPDATED
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _answerController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Answer',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            SwitchListTile(
              title: const Text('Publish answer'),
              value: _publish,
              onChanged: (v) => setState(() => _publish = v),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Save Answer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
