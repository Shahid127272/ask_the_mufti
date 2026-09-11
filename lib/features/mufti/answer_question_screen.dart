import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/categories_data.dart';
import '../../core/role_view_controller.dart';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';

class AnswerQuestionScreen extends StatefulWidget {
  final QuestionModel question;

  const AnswerQuestionScreen({
    super.key,
    required this.question,
  });

  @override
  State<AnswerQuestionScreen> createState() =>
      _AnswerQuestionScreenState();
}

class _AnswerQuestionScreenState
    extends State<AnswerQuestionScreen> {

  final _questionController =
  TextEditingController();

  final _subjectController =
  TextEditingController();

  final _bodyController =
  TextEditingController();

  final _referenceController =
  TextEditingController();

  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  final ImagePicker _picker =
  ImagePicker();

  File? _image;

  bool _loading = false;
  bool _markingPending = false;
  bool _claiming = false;
  bool _unclaiming = false;

  String? _category;
  String? _subCategory;

  // =========================================================
  // CLAIM STATE
  // =========================================================

  String? _claimedByUid;
  Timestamp? _claimExpiresAt;

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
  _questionSubscription;

  Timer? _claimExpiryTimer;

  @override
  void initState() {
    super.initState();

    _questionController.text =
        widget.question.questionText;

    _claimedByUid =
        widget.question.claimedByUid;

    _claimExpiresAt =
        widget.question.claimExpiresAt;

    // Live claim updates.
    _startQuestionListener();

    // NEW → PENDING.
    _prepareQuestion();

    // Expiry UI refresh.
    _claimExpiryTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        if (mounted &&
            _claimExpiresAt != null) {
          setState(() {});
        }
      },
    );
  }

  // =========================================================
  // LIVE QUESTION / CLAIM LISTENER
  // =========================================================
  //
  // Agar kisi doosre Mufti ne question CLAIM kiya,
  // to isi screen par bhi immediately CLAIMED show hoga.
  //
  // Agar claim unclaim hua,
  // to CLAIM dobara show hoga.
  // =========================================================

  void _startQuestionListener() {
    _questionSubscription =
        FirebaseFirestore.instance
            .collection('questions')
            .doc(widget.question.id)
            .snapshots()
            .listen(
              (snapshot) {
            if (!snapshot.exists ||
                !mounted) {
              return;
            }

            final latest =
            QuestionModel.fromFirestore(
              snapshot,
            );

            setState(() {
              _claimedByUid =
                  latest.claimedByUid;

              _claimExpiresAt =
                  latest.claimExpiresAt;
            });
          },
          onError: (error) {
            debugPrint(
              'Question claim listener error: $error',
            );
          },
        );
  }

  // =========================================================
  // NEW → PENDING
  // =========================================================
  //
  // Question open karne se sirf:
  //
  // NEW → PENDING
  //
  // hoga.
  //
  // OPEN karne wale Mufti ko CLAIM automatically nahi milega.
  // =========================================================

  Future<void> _prepareQuestion() async {
    if (widget.question.status != 'new') {
      return;
    }

    if (mounted) {
      setState(() {
        _markingPending = true;
      });
    }

    try {
      await _service.markAsPending(
        widget.question.id,
      );
    } catch (e) {
      debugPrint(
        'Mark as pending error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _markingPending = false;
        });
      }
    }
  }

  // =========================================================
  // CURRENT USER
  // =========================================================

  String? get _currentUid {
    return FirebaseAuth
        .instance
        .currentUser
        ?.uid;
  }

  // =========================================================
  // CLAIM STATUS
  // =========================================================

  bool get _hasClaim {
    return _claimedByUid != null &&
        _claimedByUid!.isNotEmpty;
  }

  bool get _isClaimedByMe {
    final uid = _currentUid;

    if (uid == null) {
      return false;
    }

    return _claimedByUid == uid;
  }

  bool get _claimExpired {
    if (_claimExpiresAt == null) {
      return false;
    }

    return !_claimExpiresAt!
        .toDate()
        .isAfter(DateTime.now());
  }

  bool get _hasActiveClaim {
    return _hasClaim &&
        !_claimExpired;
  }

  // =========================================================
  // CLAIM QUESTION
  // =========================================================

  Future<void> _claimQuestion() async {
    if (_claiming ||
        _loading) {
      return;
    }

    setState(() {
      _claiming = true;
    });

    try {
      await _service.claimQuestion(
        widget.question.id,
      );

      // Latest question fetch.
      final latest =
      await _service.getQuestion(
        widget.question.id,
      );

      if (!mounted) {
        return;
      }

      if (latest != null) {
        setState(() {
          _claimedByUid =
              latest.claimedByUid;

          _claimExpiresAt =
              latest.claimExpiresAt;
        });
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Question claimed successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _claiming = false;
        });
      }
    }
  }

  // =========================================================
  // UNCLAIM QUESTION
  // =========================================================

  Future<void> _unclaimQuestion() async {
    if (_unclaiming ||
        _loading) {
      return;
    }

    setState(() {
      _unclaiming = true;
    });

    try {
      await _service.unclaimQuestion(
        widget.question.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _claimedByUid = null;
        _claimExpiresAt = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Question unclaimed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _unclaiming = false;
        });
      }
    }
  }

  // =========================================================
  // PICK IMAGE
  // =========================================================

  Future<void> _pickImage() async {
    final XFile? picked =
    await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null &&
        mounted) {
      setState(() {
        _image =
            File(picked.path);
      });
    }
  }

  // =========================================================
  // SUBMIT ANSWER
  // =========================================================

  Future<void> _submit() async {
    final questionText =
    _questionController.text.trim();

    final subject =
    _subjectController.text.trim();

    final body =
    _bodyController.text.trim();

    final reference =
    _referenceController.text.trim();

    if (questionText.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Sawal khali nahi ho sakta',
          ),
        ),
      );

      return;
    }

    if (subject.isEmpty ||
        body.isEmpty ||
        _category == null ||
        _subCategory == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Sab zaroori fields fill karo',
          ),
        ),
      );

      return;
    }

    final roleController =
    context.read<
        RoleViewController>();

    final realRole =
        roleController.realRole;

    final isOwnerOrAdmin =
        realRole == 'owner' ||
            realRole == 'admin';

    // =======================================================
    // MUFTI CLAIM CHECK
    // =======================================================

    if (!isOwnerOrAdmin) {
      final uid = _currentUid;

      if (uid == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Please login first.',
            ),
          ),
        );

        return;
      }

      if (!_hasClaim ||
          !_isClaimedByMe) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Answer dene se pehle question CLAIM karein.',
            ),
          ),
        );

        return;
      }

      if (!_hasActiveClaim) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Aapka claim expire ho chuka hai. Question dobara CLAIM karein.',
            ),
          ),
        );

        return;
      }
    }

    setState(() {
      _loading = true;
    });

    try {
      final fullAnswer = [
        subject,
        body,
      ].join('\n\n');

      // =====================================================
      // OWNER / ADMIN
      // =====================================================

      if (isOwnerOrAdmin) {
        final questionChanged =
            questionText !=
                widget.question
                    .questionText
                    .trim();

        if (questionChanged) {
          await _service
              .editQuestionByAdminOrOwner(
            questionId:
            widget.question.id,
            newQuestionText:
            questionText,
            editorRole:
            realRole,
          );
        }

        await _service
            .submitFullAnswer(
          questionId:
          widget.question.id,
          answerText:
          fullAnswer,
          category:
          _category!,
          subCategory:
          _subCategory!,
          reference:
          reference,
        );
      }

      // =====================================================
      // MUFTI
      // =====================================================

      else {
        await _service
            .submitMuftiAnswer(
          questionId:
          widget.question.id,
          questionText:
          questionText,
          answerText:
          fullAnswer,
          category:
          _category!,
          subCategory:
          _subCategory!,
          reference:
          reference,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Answer publish ho gaya',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      String message =
          'Answer submit nahi ho saka';

      final error =
      e.toString();

      if (error.contains(
        'edit opportunity already used',
      )) {
        message =
        'Is sawal par Mufti ka edit aur answer mauqa pehle hi istemal ho chuka hai';
      } else if (error.contains(
        'claim',
      )) {
        message =
        'Is question ko pehle CLAIM karein ya claim expire ho chuka hai.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
          Text(message),
        ),
      );

      debugPrint(
        'Submit answer error: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _questionSubscription?.cancel();
    _claimExpiryTimer?.cancel();

    _questionController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _referenceController.dispose();

    super.dispose();
  }

  // =========================================================
  // CLAIM SECTION
  // =========================================================

  Widget _buildClaimSection({
    required bool isOwnerOrAdmin,
  }) {
    if (isOwnerOrAdmin) {
      return const SizedBox.shrink();
    }

    // =======================================================
    // OTHER MUFTI CLAIMED
    // =======================================================

    if (_hasActiveClaim &&
        !_isClaimedByMe) {
      return Container(
        width: double.infinity,
        padding:
        const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey
              .withValues(alpha: 0.12),
          borderRadius:
          BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lock_outline,
              size: 20,
            ),

            const SizedBox(width: 8),

            const Expanded(
              child: Text(
                'CLAIMED',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // =======================================================
    // CURRENT MUFTI CLAIMED
    // =======================================================

    if (_hasActiveClaim &&
        _isClaimedByMe) {
      return Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(12),
            decoration:
            BoxDecoration(
              color: Colors.green
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
              BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),

                const SizedBox(width: 8),

                const Expanded(
                  child: Text(
                    'Question Claimed',
                    style: TextStyle(
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (_claimExpiresAt != null)
            Text(
              _claimExpiryText(),
              style:
              const TextStyle(
                fontSize: 12,
                color:
                Colors.orange,
              ),
            ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed:
            _unclaiming ||
                _loading
                ? null
                : _unclaimQuestion,
            icon:
            _unclaiming
                ? const SizedBox(
              width: 16,
              height: 16,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.undo,
            ),
            label:
            const Text(
              'Unclaim Question',
            ),
          ),
        ],
      );
    }

    // =======================================================
    // EXPIRED / UNCLAIMED
    // =======================================================

    return SizedBox(
      width: double.infinity,
      child:
      ElevatedButton.icon(
        onPressed:
        _claiming ||
            _loading
            ? null
            : _claimQuestion,
        icon:
        _claiming
            ? const SizedBox(
          width: 18,
          height: 18,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color:
            Colors.white,
          ),
        )
            : const Icon(
          Icons.lock_open,
        ),
        label:
        const Text(
          'CLAIM',
        ),
      ),
    );
  }

  // =========================================================
  // CLAIM EXPIRY TEXT
  // =========================================================

  String _claimExpiryText() {
    if (_claimExpiresAt == null) {
      return '';
    }

    final remaining =
    _claimExpiresAt!
        .toDate()
        .difference(
      DateTime.now(),
    );

    if (remaining.isNegative ||
        remaining == Duration.zero) {
      return 'Claim expired';
    }

    final days =
        remaining.inDays;

    final hours =
        remaining.inHours % 24;

    if (days > 0) {
      return 'Claim expires in $days day${days == 1 ? '' : 's'}';
    }

    return 'Claim expires in $hours hour${hours == 1 ? '' : 's'}';
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final roleController =
    context.watch<
        RoleViewController>();

    final realRole =
        roleController.realRole;

    final isOwnerOrAdmin =
        realRole == 'owner' ||
            realRole == 'admin';

    final canMuftiUseOpportunity =
    !widget.question
        .questionEditedByMufti;

    final canEditQuestion =
        isOwnerOrAdmin ||
            canMuftiUseOpportunity;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Write Answer',
        ),
      ),

      body:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            // =================================================
            // NEW → PENDING LOADING
            // =================================================

            if (_markingPending) ...[
              const LinearProgressIndicator(),

              const SizedBox(
                height: 16,
              ),
            ],

            // =================================================
            // CLAIM SECTION
            // =================================================

            _buildClaimSection(
              isOwnerOrAdmin:
              isOwnerOrAdmin,
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // QUESTION
            // =================================================

            const Text(
              'Question',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            TextField(
              controller:
              _questionController,

              readOnly:
              !canEditQuestion,

              maxLines: null,

              decoration:
              InputDecoration(
                border:
                const OutlineInputBorder(),

                helperText:
                isOwnerOrAdmin
                    ? 'Owner/Admin sawal edit kar sakte hain'
                    : canMuftiUseOpportunity
                    ? 'Sirf answer publish karte waqt sawal edit kar sakte hain'
                    : 'Mufti ka edit mauqa khatam ho chuka hai',

                suffixIcon:
                canEditQuestion
                    ? const Icon(
                  Icons.edit,
                )
                    : const Icon(
                  Icons.lock,
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // SUBJECT
            // =================================================

            const Text(
              'Subject',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            TextField(
              controller:
              _subjectController,

              decoration:
              const InputDecoration(
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // ANSWER
            // =================================================

            const Text(
              'Answer',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            TextField(
              controller:
              _bodyController,

              maxLines: 6,

              decoration:
              const InputDecoration(
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // REFERENCE
            // =================================================

            const Text(
              'Reference',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            TextField(
              controller:
              _referenceController,

              maxLines: null,

              decoration:
              const InputDecoration(
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // CATEGORY
            // =================================================

            const Text(
              'Category',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            DropdownButtonFormField<String>(
              initialValue:
              _category,

              items:
              kCategories.keys
                  .map(
                    (category) {
                  return DropdownMenuItem<
                      String>(
                    value:
                    category,
                    child:
                    Text(
                      category,
                    ),
                  );
                },
              ).toList(),

              onChanged:
              _loading
                  ? null
                  : (value) {
                setState(() {
                  _category =
                      value;

                  _subCategory =
                  null;
                });
              },

              decoration:
              const InputDecoration(
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // SUB CATEGORY
            // =================================================

            const Text(
              'SubCategory',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            DropdownButtonFormField<String>(
              key:
              ValueKey(
                _category,
              ),

              initialValue:
              _subCategory,

              items:
              _category == null
                  ? const <
                  DropdownMenuItem<
                      String>>[]
                  : kCategories[
              _category]!
                  .map(
                    (
                    subCategory,
                    ) =>
                    DropdownMenuItem<
                        String>(
                      value:
                      subCategory,
                      child:
                      Text(
                        subCategory,
                      ),
                    ),
              )
                  .toList(),

              onChanged:
              _loading ||
                  _category ==
                      null
                  ? null
                  : (value) {
                setState(() {
                  _subCategory =
                      value;
                });
              },

              decoration:
              const InputDecoration(
                border:
                OutlineInputBorder(),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // =================================================
            // IMAGE
            // =================================================

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed:
                  _loading
                      ? null
                      : _pickImage,

                  icon:
                  const Icon(
                    Icons.image,
                  ),

                  label:
                  const Text(
                    'Upload Image',
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                if (_image != null)
                  const Expanded(
                    child: Text(
                      'Image selected',
                      overflow:
                      TextOverflow
                          .ellipsis,
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),

            // =================================================
            // PUBLISH
            // =================================================

            if (_loading)
              const Center(
                child:
                CircularProgressIndicator(),
              )
            else if (!isOwnerOrAdmin &&
                (!_hasActiveClaim ||
                    !_isClaimedByMe))
              Container(
                width:
                double.infinity,
                padding:
                const EdgeInsets.all(
                  12,
                ),
                decoration:
                BoxDecoration(
                  color: Colors.orange
                      .withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    10,
                  ),
                ),
                child:
                const Text(
                  'Answer publish karne ke liye pehle is question ko CLAIM karein.',
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              )
            else
              SizedBox(
                width:
                double.infinity,

                child:
                ElevatedButton(
                  onPressed:
                  _submit,

                  child:
                  const Text(
                    'Publish',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}