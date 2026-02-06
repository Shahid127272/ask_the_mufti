import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/questions_firestore_service.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();

  final _questionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _customSubCategoryController = TextEditingController();

  final _service = QuestionsFirestoreService();

  String? _selectedCategory;
  String? _selectedSubCategory;

  final Map<String, List<String>> categories = {
    'Aqaaid': [
      'Tawheed',
      'Risalat',
      'Aakhirat',
      'Shafa‘at',
    ],
    'Ibaadaat': [
      'Salah',
      'Roza',
      'Zakah',
      'Hajj',
    ],
    'Muamalaat': [
      'Buyu‘',
      'Qarz',
      'Rahn',
    ],
    'Munakahaat': [
      'Nikah',
      'Talaq',
      'Khula',
    ],
    'Other': [],
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final category = _selectedCategory == 'Other'
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    final subCategory = _selectedCategory == 'Other'
        ? _customSubCategoryController.text.trim()
        : _selectedSubCategory;

    await _service.addQuestion(
      questionText: _questionController.text.trim(),
      userId: uid,
      category: category,
      subCategory: subCategory,
    );

    if (!mounted) return;

    _questionController.clear();
    _customCategoryController.clear();
    _customSubCategoryController.clear();

    setState(() {
      _selectedCategory = null;
      _selectedSubCategory = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Question submitted successfully')),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _customCategoryController.dispose();
    _customSubCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subCategories =
    _selectedCategory != null ? categories[_selectedCategory] ?? [] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask The Mufti'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// CATEGORY
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(),
                ),
                initialValue: _selectedCategory,
                items: categories.keys
                    .map<DropdownMenuItem<String>>(
                      (c) => DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  ),
                )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCategory = v;
                    _selectedSubCategory = null;
                  });
                },
                validator: (v) =>
                v == null || v.isEmpty ? 'Category is required' : null,
              ),

              const SizedBox(height: 12),

              /// OTHER CATEGORY INPUT
              if (_selectedCategory == 'Other') ...[
                TextFormField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Category',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Enter category' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customSubCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Enter Sub-category',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Enter sub-category' : null,
                ),
              ]

              /// NORMAL SUB-CATEGORY
              else if (subCategories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Select Sub-category',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: _selectedSubCategory,
                  items: subCategories
                      .map<DropdownMenuItem<String>>(
                        (s) => DropdownMenuItem<String>(
                      value: s,
                      child: Text(s),
                    ),
                  )
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedSubCategory = v;
                    });
                  },
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Sub-category required' : null,
                ),
              ],

              const SizedBox(height: 12),

              /// QUESTION
              TextFormField(
                controller: _questionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Your Question',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your question' : null,
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Submit Question'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
