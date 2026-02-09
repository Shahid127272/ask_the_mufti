import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final QuestionModel question;

  const AnswerQuestionScreen({
    super.key,
    required this.question,
  });

  @override
  State<AnswerQuestionScreen> createState() => _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState extends State<AnswerQuestionScreen> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  final _referenceController = TextEditingController();

  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _loading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  /// 🖼️ Pick image (optional – future use)
  Future<void> _pickImage() async {
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null && mounted) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  /// 📤 Submit answer
  Future<void> _submit({required bool publish}) async {
    if (_subjectController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject aur answer dono zaroori hain'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await _service.submitAnswer(
        questionId: widget.question.id,
        answerText: '''
${_subjectController.text.trim()}

${_bodyController.text.trim()}

${_referenceController.text.trim()}
''',
        publish: publish,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            publish
                ? 'Answer publish ho gaya'
                : 'Answer save ho gaya',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Answer submit nahi ho saka'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Answer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ❓ Question
            Text(
              q.questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            /// 📝 SUBJECT
            const Text(
              'Subject',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                hintText: 'Jawab ka subject / heading',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 16),

            /// ✍️ ANSWER BODY
            const Text(
              'Answer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _bodyController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Mukammal jawab yahan likhein…',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// 📚 REFERENCE
            const Text(
              'Reference (optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _referenceController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Quran / Hadith / Fiqh reference',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            /// 🖼️ IMAGE (OPTIONAL)
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label:
                  const Text('Upload Image (optional)'),
                ),
                const SizedBox(width: 12),
                if (_image != null)
                  const Text(
                    'Image selected',
                    style: TextStyle(fontSize: 12),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            /// 🔘 ACTIONS
            if (_loading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          _submit(publish: false),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _submit(publish: true),
                      child: const Text('Publish'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
