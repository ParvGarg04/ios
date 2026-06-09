/**
 * Promote an existing Firebase Auth user to admin role.
 *
 * Usage:
 *   1. Create a user account via Firebase Console or the iOS app
 *   2. Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON
 *   3. Run: node scripts/create-admin.js user@email.com
 */

const admin = require('firebase-admin');

const email = process.argv[2];
if (!email) {
  console.error('Usage: node scripts/create-admin.js <email>');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();
const auth = admin.auth();

async function main() {
  const user = await auth.getUserByEmail(email);
  await db.collection('users').doc(user.uid).set(
    {
      uid: user.uid,
      name: user.displayName || 'Admin',
      email: user.email,
      role: 'admin',
      streak: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  console.log(`User ${email} (${user.uid}) promoted to admin.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
