/**
 * CIPHER-X REAL FCM BACKEND DISPATCHER (Node.js / Firebase Admin SDK)
 * ===================================================================
 * Real-time server-side listener for Cipher-X operational alerts.
 * 
 * Delivers FCM push notifications to registered target devices based on
 * organization isolation and role-based access control (RBAC).
 * 
 * NEVER ships service account keys or FCM server credentials to Flutter client code.
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK using environment credentials
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} else {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

console.log('🚀 Cipher-X FCM Real Backend Dispatcher Started.');
console.log('Listening for real-time operational alerts in Firestore...');

// Listen across all organization alert subcollections
db.collectionGroup('alerts').onSnapshot((snapshot) => {
  snapshot.docChanges().forEach(async (change) => {
    if (change.type === 'added') {
      const alertData = change.doc.data();
      await processAndDispatchAlert(change.doc.id, alertData);
    }
  });
}, (error) => {
  console.error('Error listening to alerts collection group:', error);
});

/**
 * Resolves target recipient device tokens and sends FCM multicast push notifications.
 */
async function processAndDispatchAlert(alertId, alert) {
  const { organizationId, type, sourceEntityId, metadata } = alert;

  if (!organizationId || !type) {
    return;
  }

  console.log(`[ALERT RECEIVED] ID: ${alertId} | Type: ${type} | Org: ${organizationId}`);

  // 1. Target Role Resolution according to Cipher-X RBAC rules
  let targetRoles = ['admin', 'supervisor'];
  let notificationTitle = 'Cipher-X Alert';
  let notificationBody = 'Operational update required.';
  let deepLinkRoute = '/admin/activity-feed';

  switch (type) {
    case 'CRITICAL_INCIDENT':
      notificationTitle = '🚨 Critical Incident Reported';
      notificationBody = metadata?.description || metadata?.message || 'Immediate action required at site.';
      deepLinkRoute = `/admin/incidents/${sourceEntityId}`;
      break;

    case 'LATE_CHECK_IN':
      notificationTitle = '⚠️ Late Guard Check-In';
      notificationBody = metadata?.message || 'Guard check-in delayed beyond scheduled start time.';
      deepLinkRoute = '/admin/activity-feed';
      break;

    case 'MISSED_SHIFT':
      notificationTitle = '❌ Missed Shift Detected';
      notificationBody = metadata?.message || 'Guard failed to check in for assigned shift.';
      deepLinkRoute = '/admin/activity-feed';
      break;

    case 'UNDERSTAFFED_SITE':
      notificationTitle = '🛡️ Site Understaffed';
      notificationBody = metadata?.message || 'Active guard count below site requirement.';
      deepLinkRoute = '/admin/sites';
      break;
  }

  try {
    // 2. Query active device tokens for users in the target organization
    const usersSnapshot = await db.collection('users')
      .where('organizationId', '==', organizationId)
      .get();

    if (usersSnapshot.empty) {
      console.log(`No users found for organization: ${organizationId}`);
      return;
    }

    const recipientTokens = [];

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const userRole = userData.role || 'guard';

      if (targetRoles.includes(userRole)) {
        const devicesSnapshot = await userDoc.ref.collection('devices')
          .where('enabled', '==', true)
          .get();

        devicesSnapshot.forEach((devDoc) => {
          const devData = devDoc.data();
          if (devData.fcmToken) {
            recipientTokens.push(devData.fcmToken);
          }
        });
      }
    }

    if (recipientTokens.length === 0) {
      console.log(`No active FCM device tokens found for Org: ${organizationId}, Roles: ${targetRoles.join(', ')}`);
      return;
    }

    console.log(`Sending FCM push to ${recipientTokens.length} devices for Alert: ${alertId}...`);

    // 3. Dispatch FCM Multicast Message
    const messagePayload = {
      tokens: recipientTokens,
      notification: {
        title: notificationTitle,
        body: notificationBody,
      },
      data: {
        alertId: String(alertId),
        organizationId: String(organizationId),
        type: String(type),
        entityId: String(sourceEntityId || ''),
        route: String(deepLinkRoute),
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'cipher_x_alerts',
          sound: 'default',
          priority: 'max',
        },
      },
    };

    const response = await messaging.sendEachForMulticast(messagePayload);
    console.log(`FCM Multicast Result: ${response.successCount} succeeded, ${response.failureCount} failed.`);
  } catch (error) {
    console.error('Error dispatching FCM notification:', error);
  }
}
