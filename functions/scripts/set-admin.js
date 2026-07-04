/* One-time bootstrap: grant the FIRST admin.
 *
 * Custom claims can't be set from the Firebase Console UI, so the very first
 * admin must be created with the Admin SDK. After this, use the in-app
 * "Rol Yönetimi" screen (which calls the setUserRole Cloud Function).
 *
 * Usage (run from the functions/ directory):
 *   node scripts/set-admin.js <email> [password]
 *
 * Requires functions/service-account.json:
 *   Firebase Console -> Project Settings -> Service accounts
 *   -> Generate new private key -> save as functions/service-account.json
 *
 * SECURITY: delete service-account.json when done. It is gitignored.
 */
const path = require("path");
const admin = require("firebase-admin");

const serviceAccount = require(path.join(__dirname, "..", "service-account.json"));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

async function main() {
  const email = process.argv[2];
  const password = process.argv[3];
  if (!email) {
    console.error("Kullanım: node scripts/set-admin.js <email> [password]");
    process.exit(1);
  }

  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
    console.log(`Mevcut kullanıcı bulundu: ${user.uid}`);
  } catch {
    if (!password) {
      console.error(
        "Kullanıcı bulunamadı. Oluşturmak için şifre verin:\n" +
          "  node scripts/set-admin.js <email> <password>",
      );
      process.exit(1);
    }
    user = await admin.auth().createUser({
      email,
      password,
      emailVerified: true,
    });
    console.log(`Yeni kullanıcı oluşturuldu: ${user.uid}`);
  }

  await admin.auth().setCustomUserClaims(user.uid, { role: "admin" });

  await admin
    .firestore()
    .collection("users")
    .doc(user.uid)
    .set(
      {
        email,
        displayName: user.displayName || "Admin",
        role: "admin",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  console.log(
    `\n✅ ${email} artık admin (uid: ${user.uid}).\n` +
      "Uygulamada çıkış yapıp tekrar giriş yapın ki yeni yetki token'a işlensin.\n" +
      "Bittiğinde functions/service-account.json dosyasını SİLİN.",
  );
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
