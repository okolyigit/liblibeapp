import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const REGION = "europe-west3";

// ========================================
// lookupIsbnFallback — 3rd fallback after Google Books / Open Library
// ========================================
// Server-side ISBN lookup for books missing from Google Books and Open Library
// (especially Turkish books). Scrapes D&R (dr.com.tr) which exposes JSON-LD
// structured data — robust to HTML changes.
//
// Accepts both schema.org/Book (rich metadata) and schema.org/Product
// (cover-only). D&R's product pages currently emit Product blocks more
// reliably than Book blocks, so accepting both maximizes catch rate.
//
// Results cached in /books_cache/{isbn} for 30 days to minimize upstream hits.
//
// Input:  { isbn: string }
// Output: { title, author, publisher, publishedDate, language, coverUrl,
//           description, pageCount } | null

const ISBN_CACHE_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 days
const ISBN_CACHE_SCHEMA_VERSION = 3;
const ISBN_USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
  "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36";

interface FallbackResult {
  title: string;
  author: string | null;
  publisher: string | null;
  publishedDate: string | null;
  language: string | null;
  coverUrl: string | null;
  description: string | null;
  pageCount: number | null;
}

// Extract a usable image URL from a schema.org image field, which may be:
//   - "https://..."                           (plain string)
//   - ["https://...", ...]                    (string array)
//   - { "@type": "ImageObject", "url": "..." } (ImageObject)
//   - [{ "@type": "ImageObject", ... }, ...]  (ImageObject array)
//   - { contentUrl: "..." } / { thumbnailUrl: "..." } (legacy variants)
function extractImageUrl(image: unknown): string | null {
  if (!image) return null;
  if (typeof image === "string") {
    return image.trim() || null;
  }
  if (Array.isArray(image)) {
    for (const entry of image) {
      const url = extractImageUrl(entry);
      if (url) return url;
    }
    return null;
  }
  if (typeof image === "object") {
    const obj = image as Record<string, unknown>;
    const candidate = obj["url"] ?? obj["contentUrl"] ?? obj["thumbnailUrl"];
    if (typeof candidate === "string") {
      return candidate.trim() || null;
    }
  }
  return null;
}

// Extract value from possibly-nested schema.org field.
// Handles: "name", { name: "x" }, { "@type": "Person", name: "x" }
function flattenName(v: unknown): string | null {
  if (!v) return null;
  if (typeof v === "string") return v.trim() || null;
  if (Array.isArray(v)) {
    return v.map(flattenName).filter(Boolean).join(", ") || null;
  }
  if (typeof v === "object" && v !== null && "name" in v) {
    return flattenName((v as Record<string, unknown>).name);
  }
  return null;
}

// Build a FallbackResult from a single JSON-LD object if it matches the
// expected ISBN. Works for both Book and Product schemas — Product blocks
// won't have author/publisher/etc, but title and cover are usually present.
function buildResult(
  obj: Record<string, unknown>,
  expectedIsbn: string,
): FallbackResult | null {
  // Sanity: gtin13/isbn (if present) must match input. Prevents wrong book
  // when D&R falls back to fuzzy search results.
  const gtin = obj["gtin13"] || obj["isbn"];
  if (
    gtin &&
    typeof gtin === "string" &&
    gtin.replace(/\D/g, "") !== expectedIsbn
  ) {
    return null;
  }

  const name = flattenName(obj["name"]);
  if (!name) return null;

  const coverUrl = extractImageUrl(obj["image"]);

  const pages = obj["numberOfPages"];
  let pageCount: number | null = null;
  if (typeof pages === "number") pageCount = pages;
  else if (typeof pages === "string" && pages.trim()) {
    const n = parseInt(pages, 10);
    if (!isNaN(n) && n > 0) pageCount = n;
  }

  return {
    title: name,
    author: flattenName(obj["author"]),
    publisher: flattenName(obj["publisher"]) ?? flattenName(obj["brand"]),
    publishedDate:
      typeof obj["datePublished"] === "string"
        ? (obj["datePublished"] as string)
        : null,
    language:
      typeof obj["inLanguage"] === "string"
        ? (obj["inLanguage"] as string)
        : null,
    coverUrl,
    description:
      typeof obj["description"] === "string"
        ? (obj["description"] as string).trim() || null
        : null,
    pageCount,
  };
}

function hasType(obj: Record<string, unknown>, type: string): boolean {
  const t = obj["@type"];
  return t === type || (Array.isArray(t) && (t as unknown[]).includes(type));
}

function parseDrJsonLd(html: string, expectedIsbn: string): FallbackResult | null {
  // Collect every parseable JSON-LD block first, then apply schema preference.
  const scriptRe =
    /<script[^>]*type=["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;
  const blocks: Record<string, unknown>[] = [];
  let m: RegExpExecArray | null;
  while ((m = scriptRe.exec(html)) !== null) {
    // D&R sometimes emits raw \r\n inside JSON string literals (illegal per
    // RFC 8259). Replace ALL control chars with space before parsing — safe
    // because JSON treats space as whitespace outside strings, and space is
    // a valid character inside strings.
    const cleaned = m[1].replace(/[\x00-\x1F]/g, " ");
    let parsed: unknown;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      continue;
    }
    if (typeof parsed === "object" && parsed !== null) {
      blocks.push(parsed as Record<string, unknown>);
    }
  }

  // Pass 1: prefer Book schema (richer metadata: author, publisher, pages...).
  for (const obj of blocks) {
    if (!hasType(obj, "Book")) continue;
    const result = buildResult(obj, expectedIsbn);
    if (result) return result;
  }

  // Pass 2: fall back to Product schema (D&R uses this for many titles —
  // cover + title only, but better than null).
  for (const obj of blocks) {
    if (!hasType(obj, "Product")) continue;
    const result = buildResult(obj, expectedIsbn);
    if (result) return result;
  }

  return null;
}

export const lookupIsbnFallback = onCall(
  { region: REGION, timeoutSeconds: 15 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Giriş yapmalısınız.");
    }
    const isbnRaw = String(request.data?.isbn ?? "").replace(/\D/g, "");
    if (isbnRaw.length !== 10 && isbnRaw.length !== 13) {
      throw new HttpsError(
        "invalid-argument",
        "ISBN 10 veya 13 hane olmalı."
      );
    }

    // 1) Cache check
    const cacheRef = db.collection("books_cache").doc(isbnRaw);
    const cacheSnap = await cacheRef.get();
    if (cacheSnap.exists) {
      const cached = cacheSnap.data()!;
      const fetchedAt: admin.firestore.Timestamp | undefined = cached.fetchedAt;
      const cachedVersion = cached.schemaVersion as number | undefined;
      const age = fetchedAt
        ? Date.now() - fetchedAt.toMillis()
        : Number.POSITIVE_INFINITY;
      if (
        age < ISBN_CACHE_TTL_MS &&
        cachedVersion === ISBN_CACHE_SCHEMA_VERSION &&
        cached.data
      ) {
        return cached.data;
      }
    }

    // 2) Fetch + parse from D&R
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 8000);
    let html: string;
    try {
      const resp = await fetch(
        `https://www.dr.com.tr/search?q=${isbnRaw}`,
        {
          headers: {
            "User-Agent": ISBN_USER_AGENT,
            "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "tr-TR,tr;q=0.9,en;q=0.8",
          },
          signal: controller.signal,
          redirect: "follow",
        }
      );
      if (!resp.ok) {
        console.warn(`[isbn-fallback] non-200 status=${resp.status} isbn=${isbnRaw}`);
        return null;
      }
      html = await resp.text();
    } catch (e) {
      console.warn(`[isbn-fallback] fetch failed isbn=${isbnRaw}: ${e}`);
      return null;
    } finally {
      clearTimeout(timeoutId);
    }

    const parsed = parseDrJsonLd(html, isbnRaw);
    if (!parsed) {
      // Not necessarily an error — book may simply not be in D&R catalog.
      console.info(`[isbn-fallback] no Book/Product schema for isbn=${isbnRaw}`);
      return null;
    }

    // 3) Cache write (best-effort, only on success)
    try {
      await cacheRef.set({
        source: "dr",
        schemaVersion: ISBN_CACHE_SCHEMA_VERSION,
        data: parsed,
        fetchedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (e) {
      console.warn(`[isbn-fallback] cache write failed: ${e}`);
    }

    return parsed;
  }
);

// ========================================
// setUserRole — admin-only role management
// ========================================
// Sets a user's role as a Firebase Auth custom claim (the source of truth for
// authorization, enforced by Firestore/Storage rules), mirrors it to the
// Firestore users doc for display/search, and records an audit_logs entry.
// Only callers whose own token already carries role:'admin' may invoke this —
// so clients can never escalate their own privileges.
//
// Input:  { role: 'user'|'premium'|'admin', email?: string, uid?: string }
// Output: { ok: true, uid, role }

const ALLOWED_ROLES = ["user", "premium", "admin"] as const;
type Role = (typeof ALLOWED_ROLES)[number];

export const setUserRole = onCall({ region: REGION }, async (request) => {
  // Authorization: only existing admins (by custom claim) may change roles.
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Bu işlem için admin yetkisi gerekli.");
  }

  const role = String(request.data?.role ?? "");
  if (!ALLOWED_ROLES.includes(role as Role)) {
    throw new HttpsError("invalid-argument", "Geçersiz rol.");
  }
  // Admin is a single, console-managed account — never grantable from the app.
  if (role === "admin") {
    throw new HttpsError(
      "failed-precondition",
      "Admin yetkisi uygulamadan verilemez (yalnızca Firebase konsolu).",
    );
  }

  // Resolve the target uid from an explicit uid or an email.
  let uid = request.data?.uid as string | undefined;
  const email = request.data?.email as string | undefined;
  if (!uid && email) {
    try {
      uid = (await admin.auth().getUserByEmail(email)).uid;
    } catch {
      throw new HttpsError("not-found", "Bu e-posta ile kullanıcı bulunamadı.");
    }
  }
  if (!uid) {
    throw new HttpsError("invalid-argument", "uid veya email gerekli.");
  }

  const targetUser = await admin.auth().getUser(uid);
  const oldRole = (targetUser.customClaims?.role as string) ?? "user";

  // The admin account is immutable from the app (console-managed). This also
  // covers the acting admin's own account (no self-lockout).
  if (oldRole === "admin") {
    throw new HttpsError(
      "failed-precondition",
      "Admin hesabı uygulamadan değiştirilemez.",
    );
  }

  // 1) Custom claim — authoritative for rules. Client can never set this.
  await admin.auth().setCustomUserClaims(uid, { role });

  // 2) Mirror to Firestore (+ premium membership dates) for the admin panel.
  const mirror: Record<string, unknown> = {
    role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  if (role === "premium") {
    // Set start only when transitioning into premium (preserve existing start).
    if (oldRole !== "premium") {
      mirror.premiumStart = admin.firestore.FieldValue.serverTimestamp();
    }
    const endMillis = request.data?.premiumEndMillis;
    mirror.premiumEnd =
      typeof endMillis === "number"
        ? admin.firestore.Timestamp.fromMillis(endMillis)
        : null; // null = indefinite
  } else {
    mirror.premiumStart = null;
    mirror.premiumEnd = null;
  }
  await db.collection("users").doc(uid).set(mirror, { merge: true });

  // 3) Audit trail (only the Admin SDK can write to audit_logs).
  await db.collection("audit_logs").add({
    action: "setUserRole",
    actorUid: request.auth.uid,
    actorEmail: request.auth.token.email ?? null,
    targetUid: uid,
    targetEmail: targetUser.email ?? null,
    oldRole,
    newRole: role,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true, uid, role };
});

// ========================================
// getAdminStats — admin dashboard totals
// ========================================
// Returns total document counts for the admin panel. Uses Firestore
// aggregation .count() (server-side, doesn't read every doc — cheap). Counting
// libraries/books from the client is intentionally blocked by security rules,
// so this admin-only function does it via the Admin SDK.
//
// Output: { users, libraries, books }

export const getAdminStats = onCall({ region: REGION }, async (request) => {
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Bu işlem için admin yetkisi gerekli.");
  }

  const [users, libraries, books, premium] = await Promise.all([
    db.collection("users").count().get(),
    db.collection("libraries").count().get(),
    db.collection("books").count().get(),
    db.collection("users").where("role", "==", "premium").count().get(),
  ]);

  return {
    users: users.data().count,
    libraries: libraries.data().count,
    books: books.data().count,
    premiumUsers: premium.data().count,
  };
});

// ========================================
// createUser — admin-only account creation
// ========================================
// Lets an admin create a new account from the panel (e-mail + password + role)
// without affecting their own session. Uses the Admin SDK (createUser), sets
// the role custom claim, mirrors to Firestore and writes an audit log.
//
// Input:  { email: string, password: string, role: 'user'|'premium'|'admin' }
// Output: { ok: true, uid }

export const createUser = onCall({ region: REGION }, async (request) => {
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Bu işlem için admin yetkisi gerekli.");
  }

  const email = String(request.data?.email ?? "").trim().toLowerCase();
  const password = String(request.data?.password ?? "");
  const role = String(request.data?.role ?? "user");

  if (!email.includes("@")) {
    throw new HttpsError("invalid-argument", "Geçerli bir e-posta girin.");
  }
  if (password.length < 6) {
    throw new HttpsError("invalid-argument", "Şifre en az 6 karakter olmalı.");
  }
  if (!ALLOWED_ROLES.includes(role as Role) || role === "admin") {
    // Admin accounts are console-managed only.
    throw new HttpsError("invalid-argument", "Geçersiz rol.");
  }

  let user;
  try {
    user = await admin.auth().createUser({
      email,
      password,
      emailVerified: true,
    });
  } catch (e) {
    const code = (e as { code?: string }).code;
    if (code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "Bu e-posta zaten kayıtlı.");
    }
    throw new HttpsError("internal", "Kullanıcı oluşturulamadı.");
  }

  await admin.auth().setCustomUserClaims(user.uid, { role });

  await db
    .collection("users")
    .doc(user.uid)
    .set({
      email,
      displayName: email.split("@")[0],
      role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

  await db.collection("audit_logs").add({
    action: "createUser",
    actorUid: request.auth.uid,
    actorEmail: request.auth.token.email ?? null,
    targetUid: user.uid,
    targetEmail: email,
    newRole: role,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true, uid: user.uid };
});

// ========================================
// getUserDetails — admin-only user metadata + stats (NO content)
// ========================================
// KVKK / data-minimization: returns only counts and metadata, never the
// content of a user's books/libraries/lists.
//
// Input:  { uid: string }
// Output: { email, displayName, role, photoURL, createdAt, disabled,
//           premiumStart, premiumEnd, libraryCount, bookCount, lastBookAddedAt }

export const getUserDetails = onCall({ region: REGION }, async (request) => {
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Bu işlem için admin yetkisi gerekli.");
  }
  const uid = String(request.data?.uid ?? "");
  if (!uid) throw new HttpsError("invalid-argument", "uid gerekli.");

  const [authUser, userDoc, libCount, bookCount] = await Promise.all([
    admin.auth().getUser(uid),
    db.collection("users").doc(uid).get(),
    db.collection("libraries").where("ownerId", "==", uid).count().get(),
    db.collection("books").where("ownerId", "==", uid).count().get(),
  ]);

  const data = userDoc.data() ?? {};
  const tsToMillis = (v: unknown) =>
    v instanceof admin.firestore.Timestamp ? v.toMillis() : null;

  // Last added book needs a composite index (ownerId + addedDate). Done
  // separately and tolerantly so a missing index degrades to null instead of
  // failing the whole call.
  let lastBookAddedAt: number | null = null;
  try {
    const snap = await db
      .collection("books")
      .where("ownerId", "==", uid)
      .orderBy("addedDate", "desc")
      .limit(1)
      .get();
    if (!snap.empty) {
      lastBookAddedAt = tsToMillis(snap.docs[0].data().addedDate);
    }
  } catch (e) {
    console.warn(`getUserDetails: lastBook query failed (index?): ${e}`);
  }

  return {
    email: authUser.email ?? null,
    displayName: data.displayName ?? authUser.displayName ?? null,
    role: (data.role as string) ?? "user",
    photoURL: data.photoURL ?? authUser.photoURL ?? null,
    createdAt: tsToMillis(data.createdAt),
    disabled: authUser.disabled,
    premiumStart: tsToMillis(data.premiumStart),
    premiumEnd: tsToMillis(data.premiumEnd),
    libraryCount: libCount.data().count,
    bookCount: bookCount.data().count,
    lastBookAddedAt,
  };
});

// ========================================
// updateUserProfile — admin-only profile edit (display name)
// ========================================
// Input: { uid: string, displayName: string }

export const updateUserProfile = onCall({ region: REGION }, async (request) => {
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Bu işlem için admin yetkisi gerekli.");
  }
  const uid = String(request.data?.uid ?? "");
  const displayName = String(request.data?.displayName ?? "").trim();
  if (!uid) throw new HttpsError("invalid-argument", "uid gerekli.");
  if (displayName.length === 0) {
    throw new HttpsError("invalid-argument", "Ad boş olamaz.");
  }

  await admin.auth().updateUser(uid, { displayName });
  await db.collection("users").doc(uid).set(
    {
      displayName,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await db.collection("audit_logs").add({
    action: "updateUserProfile",
    actorUid: request.auth.uid,
    actorEmail: request.auth.token.email ?? null,
    targetUid: uid,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});

// ========================================
// deleteUser — admin-only full account + data erasure (KVKK)
// ========================================
// Input: { uid: string }

async function deleteByQuery(
  query: admin.firestore.Query,
): Promise<void> {
  const snap = await query.get();
  let batch = db.batch();
  let n = 0;
  for (const doc of snap.docs) {
    batch.delete(doc.ref);
    if (++n >= 400) {
      await batch.commit();
      batch = db.batch();
      n = 0;
    }
  }
  if (n > 0) await batch.commit();
}

async function removeFromMembers(
  collection: string,
  uid: string,
): Promise<void> {
  const snap = await db
    .collection(collection)
    .where("members", "array-contains", uid)
    .get();
  let batch = db.batch();
  let n = 0;
  for (const doc of snap.docs) {
    batch.update(doc.ref, {
      members: admin.firestore.FieldValue.arrayRemove(uid),
    });
    if (++n >= 400) {
      await batch.commit();
      batch = db.batch();
      n = 0;
    }
  }
  if (n > 0) await batch.commit();
}

export const deleteUser = onCall({ region: REGION }, async (request) => {
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Bu işlem için admin yetkisi gerekli.");
  }
  const uid = String(request.data?.uid ?? "");
  if (!uid) throw new HttpsError("invalid-argument", "uid gerekli.");

  let targetEmail: string | null = null;
  try {
    const u = await admin.auth().getUser(uid);
    targetEmail = u.email ?? null;
    // The single admin account is console-managed and can never be deleted
    // from the app (this also covers the acting admin's own account).
    if ((u.customClaims?.role as string) === "admin") {
      throw new HttpsError("failed-precondition", "Admin hesabı silinemez.");
    }
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    // already gone from Auth; continue with Firestore cleanup
  }

  // Owned content
  await deleteByQuery(db.collection("books").where("ownerId", "==", uid));
  await deleteByQuery(db.collection("lists").where("ownerId", "==", uid));
  await deleteByQuery(db.collection("libraries").where("ownerId", "==", uid));
  await deleteByQuery(db.collection("shopping_items").where("ownerId", "==", uid));
  await deleteByQuery(db.collection("likes").where("userId", "==", uid));
  await deleteByQuery(
    db.collection("reading_activities").where("userId", "==", uid),
  );

  // Shared memberships
  await removeFromMembers("libraries", uid);
  await removeFromMembers("lists", uid);

  // User doc + subcollections (book_progress, notifications)
  await db.recursiveDelete(db.collection("users").doc(uid));

  // Auth account
  try {
    await admin.auth().deleteUser(uid);
  } catch {
    // ignore if already deleted
  }

  await db.collection("audit_logs").add({
    action: "deleteUser",
    actorUid: request.auth.uid,
    actorEmail: request.auth.token.email ?? null,
    targetUid: uid,
    targetEmail,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { ok: true };
});
