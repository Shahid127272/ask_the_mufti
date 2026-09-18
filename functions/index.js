const {
  onDocumentCreated,
  onDocumentUpdated,
} = require('firebase-functions/v2/firestore');

const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

const USERS_COLLECTION = 'users';
const NOTIFICATIONS_COLLECTION = 'notifications';

const QUESTION_RECIPIENT_ROLES = [
  'admin',
  'owner',
  'mufti',
];

const ADMIN_OWNER_ROLES = [
  'admin',
  'owner',
];

exports.newQuestionNotification = onDocumentCreated(
  'questions/{questionId}',
  async (event) => {
    const question = event.data?.data();

    if (!question) return;

    const questionId = event.params.questionId;
    const username = question.askedBy || 'User';

    const recipients =
      await getUsersByRoles(
        QUESTION_RECIPIENT_ROLES,
      );

    await deliverNotifications({
      eventId: event.id,
      questionId,
      type: 'question',
      recipients,
      title: 'New Question',
      body: `New question submitted by ${username}`,
      route: '/notifications',
    });
  },
);

exports.answerNotification = onDocumentUpdated(
  'questions/{questionId}',
  async (event) => {
    const before =
      event.data?.before?.data();

    const after =
      event.data?.after?.data();

    if (!before || !after) return;

    if (!didPublishAnswer(before, after)) {
      return;
    }

    const questionId =
      event.params.questionId;

    const authorUid =
      after.uid || null;

    const answerInfo =
      typeof after.answer === 'object'
        ? after.answer
        : {};

    const answeredByUid =
      answerInfo.answeredBy ||
      after.muftiId ||
      null;

    const muftiName =
      await resolveUserName(
        answeredByUid,
        'A mufti',
      );

    // ========================================================
    // QUESTION AUTHOR
    // ========================================================

    const authorRecipients =
      authorUid
        ? await getUsersByIds([
            authorUid,
          ])
        : [];

    // ========================================================
    // ANSWERING MUFTI
    // ========================================================
    //
    // Only the Mufti who answered gets:
    // "Your answer submitted"
    //
    // Other Muftis are NOT included.
    //

    const answeredByRecipients =
      answeredByUid
        ? await getUsersByIds([
            answeredByUid,
          ])
        : [];

    // ========================================================
    // ADMIN / OWNER
    // ========================================================

    const adminOwners =
      await getUsersByRoles(
        ADMIN_OWNER_ROLES,
      );

    const adminOwnerRecipients =
      adminOwners.filter((user) => {
        // Don't send Mufti Update to the question author.
        if (user.uid === authorUid) {
          return false;
        }

        // Don't send Mufti Update to the answering Mufti.
        if (user.uid === answeredByUid) {
          return false;
        }

        return true;
      });

    // ========================================================
    // NORMAL USERS
    // ========================================================
    //
    // Only role == "user".
    // Muftis are intentionally NOT included.
    //

    const normalUsers =
      await getNormalUsers();

    const otherRecipients =
      normalUsers.filter((user) => {
        // Question author already gets:
        // "Your question has been answered"
        if (user.uid === authorUid) {
          return false;
        }

        // Answering Mufti should not receive:
        // "New Answer"
        if (user.uid === answeredByUid) {
          return false;
        }

        return true;
      });

    await Promise.all([
      // ======================================================
      // QUESTION AUTHOR
      // ======================================================

      deliverNotifications({
        eventId: `${event.id}_author`,
        questionId,
        type: 'answer',
        recipients: authorRecipients,
        title: 'Question Answered',
        body: 'Your question has been answered',
      }),

      // ======================================================
      // ANSWERING MUFTI
      // ======================================================

      deliverNotifications({
        eventId: `${event.id}_mufti`,
        questionId,
        type: 'answer_submitted',
        recipients: answeredByRecipients,
        title: 'Answer Submitted',
        body: 'Your answer has been submitted',
      }),

      // ======================================================
      // NORMAL USERS
      // ======================================================

      deliverNotifications({
        eventId: `${event.id}_others`,
        questionId,
        type: 'answer',
        recipients: otherRecipients,
        title: 'New Answer',
        body: 'New answer submitted',
      }),

      // ======================================================
      // ADMIN / OWNER
      // ======================================================

      deliverNotifications({
        eventId: `${event.id}_admin_owner`,
        questionId,
        type: 'admin',
        recipients: adminOwnerRecipients,
        title: 'Mufti Update',
        body: `${muftiName} answered a question`,
        route: '/notifications',
      }),
    ]);
  },
);

// ============================================================
// ANSWER DETECTION
// ============================================================

function didPublishAnswer(
  before,
  after,
) {
  const hadPublishedAnswer =
    before.status === 'published' &&
    hasAnswerText(before.answer);

  const hasPublishedAnswer =
    after.status === 'published' &&
    hasAnswerText(after.answer);

  return (
    !hadPublishedAnswer &&
    hasPublishedAnswer
  );
}

function hasAnswerText(answer) {
  if (!answer) return false;

  if (typeof answer === 'string') {
    return answer.trim().length > 0;
  }

  if (typeof answer === 'object') {
    return (
      typeof answer.text === 'string' &&
      answer.text.trim().length > 0
    );
  }

  return false;
}

// ============================================================
// GET USERS BY ROLES
// ============================================================

async function getUsersByRoles(roles) {
  if (!roles.length) return [];

  const snapshot =
    await db
      .collection(USERS_COLLECTION)
      .where('role', 'in', roles)
      .get();

  return snapshot.docs.map(
    mapUserDoc,
  );
}

// ============================================================
// GET USERS BY IDS
// ============================================================

async function getUsersByIds(ids) {
  const uniqueIds = [
    ...new Set(
      ids.filter(Boolean),
    ),
  ];

  if (!uniqueIds.length) {
    return [];
  }

  const docs =
    await Promise.all(
      uniqueIds.map(
        (uid) =>
          db
            .collection(
              USERS_COLLECTION,
            )
            .doc(uid)
            .get(),
      ),
    );

  return docs
    .filter(
      (doc) => doc.exists,
    )
    .map(mapUserDoc);
}

// ============================================================
// GET NORMAL USERS
// ============================================================

async function getNormalUsers() {
  const snapshot =
    await db
      .collection(USERS_COLLECTION)
      .where('role', '==', 'user')
      .get();

  return snapshot.docs.map(
    mapUserDoc,
  );
}

// ============================================================
// MAP USER DOCUMENT
// ============================================================

function mapUserDoc(doc) {
  const data = doc.data() || {};

  return {
    uid: doc.id,
    role: (
      data.role || 'user'
    ).toLowerCase(),
    name:
      data.name ||
      data.displayName ||
      data.email ||
      'User',
    deviceToken:
      data.deviceToken || null,
  };
}

// ============================================================
// RESOLVE USER NAME
// ============================================================

async function resolveUserName(
  uid,
  fallback,
) {
  if (!uid) return fallback;

  const doc =
    await db
      .collection(USERS_COLLECTION)
      .doc(uid)
      .get();

  if (!doc.exists) {
    return fallback;
  }

  const data =
    doc.data() || {};

  return (
    data.name ||
    data.displayName ||
    data.email ||
    fallback
  );
}

// ============================================================
// DELIVER NOTIFICATIONS
// ============================================================

async function deliverNotifications({
  eventId,
  questionId,
  type,
  recipients,
  title,
  body,
  route = '/notifications',
}) {
  const uniqueRecipients =
    dedupeRecipients(
      recipients,
    );

  if (!uniqueRecipients.length) {
    console.log(
      `[${type}] No recipients found.`,
    );
    return;
  }

  const batch = db.batch();
  const fcmMessages = [];

  console.log(
    `[${type}] Recipients found: ${uniqueRecipients.length}`,
  );

  for (const recipient of uniqueRecipients) {
    const notificationId =
      `${eventId}_${recipient.uid}_${type}`;

    const notificationRef =
      db
        .collection(
          NOTIFICATIONS_COLLECTION,
        )
        .doc(notificationId);

    batch.set(
      notificationRef,
      {
        userId: recipient.uid,
        title,
        message: body,
        type,
        questionId:
          questionId || null,
        route,
        isRead: false,
        time:
          admin.firestore.FieldValue.serverTimestamp(),
        notificationId,
      },
      {
        merge: true,
      },
    );

    if (recipient.deviceToken) {
      console.log(
        `[${type}] FCM token found for user: ${recipient.uid}`,
      );

      fcmMessages.push({
        token: recipient.deviceToken,
        notification: {
          title,
          body,
        },
        data: {
          type,
          questionId:
            questionId || '',
          route,
          userId:
            recipient.uid,
          notificationId,
        },
        android: {
          priority: 'high',
        },
      });
    } else {
      console.warn(
        `[${type}] NO FCM TOKEN for user: ${recipient.uid}`,
      );
    }
  }

  await batch.commit();

  console.log(
    `[${type}] Firestore notifications saved: ${uniqueRecipients.length}`,
  );

  if (!fcmMessages.length) {
    console.warn(
      `[${type}] No FCM messages to send.`,
    );
    return;
  }

  const chunks =
    chunkArray(
      fcmMessages,
      500,
    );

  for (
    const chunk of chunks
  ) {
    try {
      const response =
        await admin
          .messaging()
          .sendEach(chunk);

      console.log(
        `[${type}] FCM send complete. Success: ${response.successCount}, Failure: ${response.failureCount}`,
      );

      response.responses.forEach(
        (result, index) => {
          const message =
            chunk[index];

          if (result.success) {
            console.log(
              `[${type}] FCM SUCCESS for token ending ...${message.token.slice(-8)}`,
            );
          } else {
            console.error(
              `[${type}] FCM FAILED for token ending ...${message.token.slice(-8)}`,
            );

            console.error(
              `[${type}] FCM ERROR:`,
              result.error,
            );
          }
        },
      );
    } catch (error) {
      console.error(
        `[${type}] FCM sendEach failed:`,
        error,
      );
    }
  }
}

// ============================================================
// REMOVE DUPLICATE RECIPIENTS
// ============================================================

function dedupeRecipients(
  recipients,
) {
  const seen = new Set();
  const result = [];

  for (
    const recipient of recipients
  ) {
    if (
      !recipient?.uid ||
      seen.has(recipient.uid)
    ) {
      continue;
    }

    seen.add(
      recipient.uid,
    );

    result.push(
      recipient,
    );
  }

  return result;
}

// ============================================================
// CHUNK ARRAY
// ============================================================

function chunkArray(
  items,
  size,
) {
  const chunks = [];

  for (
    let i = 0;
    i < items.length;
    i += size
  ) {
    chunks.push(
      items.slice(
        i,
        i + size,
      ),
    );
  }

  return chunks;
}