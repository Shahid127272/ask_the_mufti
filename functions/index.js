const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const USERS_COLLECTION = 'users';
const NOTIFICATIONS_COLLECTION = 'notifications';
const QUESTION_RECIPIENT_ROLES = ['admin', 'owner', 'mufti'];
const ADMIN_OWNER_ROLES = ['admin', 'owner'];

exports.newQuestionNotification = onDocumentCreated(
  'questions/{questionId}',
  async (event) => {
    const question = event.data?.data();
    if (!question) return;

    const questionId = event.params.questionId;
    const username = question.askedBy || 'User';
    const recipients = await getUsersByRoles(QUESTION_RECIPIENT_ROLES);

    await deliverNotifications({
      eventId: event.id,
      questionId,
      type: 'question',
      recipients,
      title: 'New Question',
      body: `New question submitted by ${username}`,
      route: '/notifications',
    });
  }
);

exports.answerNotification = onDocumentUpdated(
  'questions/{questionId}',
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;
    if (!didPublishAnswer(before, after)) return;

    const questionId = event.params.questionId;
    const authorUid = after.uid || null;
    const answerInfo = typeof after.answer === 'object' ? after.answer : {};
    const answeredByUid = answerInfo.answeredBy || after.muftiId || null;
    const muftiName = await resolveUserName(answeredByUid, 'A mufti');

    const adminOwners = await getUsersByRoles(ADMIN_OWNER_ROLES);
    const adminOwnerIds = new Set(adminOwners.map((user) => user.uid));

    const authorRecipients = authorUid
      ? await getUsersByIds([authorUid])
      : [];

    const adminOwnerRecipients = adminOwners.filter((user) => {
      if (user.uid === authorUid) return false;
      if (user.uid === answeredByUid) return false;
      return true;
    });

    const otherCandidates = await getNonAdminOwnerUsers();
    const otherRecipients = otherCandidates.filter((user) => {
      if (user.uid === authorUid) return false;
      if (user.uid === answeredByUid) return false;
      if (adminOwnerIds.has(user.uid)) return false;
      return true;
    });

    await Promise.all([
      deliverNotifications({
        eventId: `${event.id}_author`,
        questionId,
        type: 'answer',
        recipients: authorRecipients,
        title: 'Question Answered',
        body: 'Your question has been answered',
      }),
      deliverNotifications({
        eventId: `${event.id}_others`,
        questionId,
        type: 'answer',
        recipients: otherRecipients,
        title: 'New Answer',
        body: 'New answer submitted',
      }),
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
  }
);

function didPublishAnswer(before, after) {
  const hadPublishedAnswer =
    before.status === 'published' && hasAnswerText(before.answer);
  const hasPublishedAnswer = after.status === 'published' && hasAnswerText(after.answer);
  return !hadPublishedAnswer && hasPublishedAnswer;
}

function hasAnswerText(answer) {
  if (!answer) return false;
  if (typeof answer === 'string') return answer.trim().length > 0;
  if (typeof answer === 'object') {
    return typeof answer.text === 'string' && answer.text.trim().length > 0;
  }
  return false;
}

async function getUsersByRoles(roles) {
  if (!roles.length) return [];

  const snapshot = await db
    .collection(USERS_COLLECTION)
    .where('role', 'in', roles)
    .get();

  return snapshot.docs.map(mapUserDoc);
}

async function getUsersByIds(ids) {
  const uniqueIds = [...new Set(ids.filter(Boolean))];
  if (!uniqueIds.length) return [];

  const docs = await Promise.all(
    uniqueIds.map((uid) => db.collection(USERS_COLLECTION).doc(uid).get())
  );

  return docs.filter((doc) => doc.exists).map(mapUserDoc);
}

async function getNonAdminOwnerUsers() {
  const userSnapshot = await db
    .collection(USERS_COLLECTION)
    .where('role', '==', 'user')
    .get();
  const muftiSnapshot = await db
    .collection(USERS_COLLECTION)
    .where('role', '==', 'mufti')
    .get();

  return dedupeRecipients([
    ...userSnapshot.docs.map(mapUserDoc),
    ...muftiSnapshot.docs.map(mapUserDoc),
  ]);
}

function mapUserDoc(doc) {
  const data = doc.data() || {};
  return {
    uid: doc.id,
    role: (data.role || 'user').toLowerCase(),
    name: data.name || data.displayName || data.email || 'User',
    deviceToken: data.deviceToken || null,
  };
}

async function resolveUserName(uid, fallback) {
  if (!uid) return fallback;

  const doc = await db.collection(USERS_COLLECTION).doc(uid).get();
  if (!doc.exists) return fallback;

  const data = doc.data() || {};
  return data.name || data.displayName || data.email || fallback;
}

async function deliverNotifications({
  eventId,
  questionId,
  type,
  recipients,
  title,
  body,
  route = '/notifications',
}) {
  const uniqueRecipients = dedupeRecipients(recipients);
  if (!uniqueRecipients.length) return;

  const batch = db.batch();
  const fcmMessages = [];

  for (const recipient of uniqueRecipients) {
    const notificationId = `${eventId}_${recipient.uid}_${type}`;
    const notificationRef = db.collection(NOTIFICATIONS_COLLECTION).doc(notificationId);

    batch.set(
      notificationRef,
      {
        userId: recipient.uid,
        title,
        message: body,
        type,
        questionId: questionId || null,
        route,
        isRead: false,
        time: admin.firestore.FieldValue.serverTimestamp(),
        notificationId,
      },
      { merge: true }
    );

    if (recipient.deviceToken) {
      fcmMessages.push({
        token: recipient.deviceToken,
        notification: {
          title,
          body,
        },
        data: {
          type,
          questionId: questionId || '',
          route,
          userId: recipient.uid,
          notificationId,
        },
        android: {
          priority: 'high',
        },
      });
    }
  }

  await batch.commit();

  if (!fcmMessages.length) return;

  const chunks = chunkArray(fcmMessages, 500);
  for (const chunk of chunks) {
    await admin.messaging().sendEach(chunk);
  }
}

function dedupeRecipients(recipients) {
  const seen = new Set();
  const result = [];

  for (const recipient of recipients) {
    if (!recipient?.uid || seen.has(recipient.uid)) continue;
    seen.add(recipient.uid);
    result.push(recipient);
  }

  return result;
}

function chunkArray(items, size) {
  const chunks = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}
