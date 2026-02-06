import 'dart:async';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';

class QuestionsListController {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  StreamSubscription? _subscription;

  final List<QuestionModel> _questions = [];
  List<QuestionModel> get questions => _questions;

  void startListening(void Function() onUpdate) {
    _subscription =
        _service.streamPublishedQuestions().listen((data) {
          _questions
            ..clear()
            ..addAll(data);
          onUpdate();
        });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
