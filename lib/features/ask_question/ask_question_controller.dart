class AskQuestionController {
  String? validateQuestion(String value) {
    if (value.trim().isEmpty) {
      return 'Question cannot be empty';
    }
    if (value.trim().length < 10) {
      return 'Question must be at least 10 characters';
    }
    return null;
  }

  void submitQuestion(String question) {
    // later: API / database logic
  }
}
