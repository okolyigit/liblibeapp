import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/env_config.dart';

/// Exception thrown when account already exists with different provider
class AccountExistsException implements Exception {
  final String email;
  final String message;

  AccountExistsException({required this.email, required this.message});

  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Legacy notifier for compatibility
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);

  // Tracks if auth is initializing (e.g., during silent sign-in)
  final ValueNotifier<bool> isInitializing = ValueNotifier<bool>(true);

  // The current user's role: 'user' (default), 'premium', or 'admin'.
  // Loaded once per session from the users/{uid} document and exposed
  // reactively so UI (cover upload button, admin menu) can show/hide.
  final ValueNotifier<String> roleNotifier = ValueNotifier<String>('user');

  // True once the signed-in user's role has been resolved at least once.
  // The home router waits for this before drawing the dashboard, so admins
  // never briefly see the normal (user) UI before the role loads.
  final ValueNotifier<bool> roleLoaded = ValueNotifier<bool>(false);

  String get currentUserRole => roleNotifier.value;

  /// Premium users and admins may upload cover photos from the gallery.
  bool get canUploadCover =>
      currentUserRole == 'premium' || currentUserRole == 'admin';

  /// Admins may manage other users' roles.
  bool get isAdmin => currentUserRole == 'admin';

  /// Loads the signed-in user's role from their ID token's custom claims
  /// (set server-side by the setUserRole Cloud Function) into [roleNotifier].
  /// Forces a token refresh so a freshly-granted role is picked up. Defaults
  /// to 'user' on any error or missing claim.
  Future<void> _loadUserRole(User user) async {
    try {
      final result = await user.getIdTokenResult(true);
      roleNotifier.value = (result.claims?['role'] as String?) ?? 'user';
    } catch (e) {
      debugPrint('[Auth] Could not load user role: $e');
      roleNotifier.value = 'user';
    } finally {
      roleLoaded.value = true;
    }
  }

  // Initialize auth state listener
  Future<void> init() async {
    // Ensure persistence is enabled (web only, but doesn't hurt)
    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      debugPrint('Warning: Could not set auth persistence: $e');
    }

    // WORKAROUND for Xiaomi/HyperOS: If Firebase auth is null,
    // try silent Google sign-in to restore session (blocking - shows splash)
    // Skip on web - Firebase handles persistence automatically on web
    if (!kIsWeb && _auth.currentUser == null) {
      debugPrint('[Auth] Starting silent sign-in...');
      await _attemptSilentGoogleSignIn();
    } else if (kIsWeb) {
      debugPrint(
        '[Auth] Web platform - skipping silent sign-in (Firebase handles persistence)',
      );
    }

    // Mark initialization as complete AFTER silent sign-in
    isInitializing.value = false;
    debugPrint('[Auth] Auth init done. User: ${_auth.currentUser?.uid ?? "NULL"}');

    _auth.authStateChanges().listen((user) async {
      isLoggedInNotifier.value = user != null;
      if (user != null) {
        await _loadUserRole(user);
        await ensureUserHasLibrary(user);
      } else {
        roleNotifier.value = 'user';
        roleLoaded.value = false;
      }
    });
  }

  /// Attempt silent Google sign-in (for devices that clear Firebase auth state)
  Future<void> _attemptSilentGoogleSignIn() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn
          .signInSilently();

      if (googleUser != null) {
        debugPrint(
          '[Auth] Silent sign-in found Google account: ${googleUser.email}',
        );
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await _auth.signInWithCredential(credential);
        debugPrint('[Auth] Silent sign-in SUCCESS - user restored');
      } else {
        debugPrint('[Auth] No previous Google account found for silent sign-in');
      }
    } catch (e) {
      debugPrint('[Auth] Silent sign-in failed: $e');
    }
  }

  /// Ensure the user has a default library (for existing users without one)
  Future<void> ensureUserHasLibrary(User user) async {
    debugPrint('[Library] ensureUserHasLibrary called for user ${user.uid}');
    try {
      // Check and create default library
      final librariesSnapshot = await _firestore
          .collection('libraries')
          .where('members', arrayContains: user.uid)
          .limit(1)
          .get();

      debugPrint('[Library] Found ${librariesSnapshot.docs.length} libraries');

      if (librariesSnapshot.docs.isEmpty) {
        final libraryRef = _firestore.collection('libraries').doc();
        await libraryRef.set({
          'ownerId': user.uid,
          'name': 'Kişisel Kütüphanem',
          'description': 'Varsayılan kişisel kütüphaneniz',
          'icon': 'books',
          'color': '#10B981',
          'members': [user.uid],
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[OK] Created default library for user ${user.uid}');
      }

      // Check and create default favorites list
      debugPrint('[Library] Checking for favorites list...');
      final userListsSnapshot = await _firestore
          .collection('lists')
          .where('ownerId', isEqualTo: user.uid)
          .get();

      debugPrint('[Library] Found ${userListsSnapshot.docs.length} lists for user');

      final hasDefaultList = userListsSnapshot.docs.any(
        (doc) => doc.data()['isDefault'] == true,
      );

      debugPrint('[Library] Has default list: $hasDefaultList');

      if (!hasDefaultList) {
        debugPrint('[Library] Creating favorites list...');
        await _firestore.collection('lists').add({
          'ownerId': user.uid,
          'name': 'Beğenilenler',
          'description': 'En sevdiğim ve tekrar okumak istediğim kitaplar',
          'icon': 'heart',
          'color': '#EF4444',
          'bookIds': [],
          'members': [],
          'isPublic': false,
          'isDefault': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[OK] Created default favorites list for user ${user.uid}');
      }
    } catch (e, stackTrace) {
      debugPrint('[Error] Error ensuring user has library/favorites: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // ============ Email/Password Authentication ============

  /// Register with email and password
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(credential.user!, displayName);

      // Send verification email
      if (!credential.user!.emailVerified) {
        await credential.user!.sendEmailVerification();
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send verification email manually
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============ Google Sign-In ============

  // Pending Google credential for account linking
  AuthCredential? _pendingGoogleCredential;
  String? _pendingLinkEmail;

  /// Sign in with Google
  /// If the Google email already has an email/password account,
  /// Firebase will throw 'account-exists-with-different-credential'.
  /// In that case, we save the credential for later linking.
  ///
  /// IMPORTANT: After successful Google sign-in, check if email/password
  /// provider was lost and warn the user.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: kIsWeb ? EnvConfig.googleWebClientId : null,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return null; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Try to sign in with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        // Check if this is a new user
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createUserDocument(user, user.displayName ?? 'User');
        }

        // Log the providers for debugging
        final providers = user.providerData.map((p) => p.providerId).toList();
        debugPrint('[Auth] User providers after Google sign-in: $providers');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle account linking: when email already exists with different provider
      if (e.code == 'account-exists-with-different-credential') {
        debugPrint(
          'Account exists with different credential - saving for link',
        );

        // Save the credential for later linking
        _pendingGoogleCredential = e.credential;
        _pendingLinkEmail = e.email;

        // Throw a specific error that the UI can catch
        throw AccountExistsException(
          email: e.email ?? 'unknown',
          message:
              'Bu e-posta zaten kayıtlı. Şifrenizi girerek hesapları birleştirebilirsiniz.',
        );
      }
      debugPrint('Google Sign-In Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  /// Check if current user has email/password provider
  bool get hasPasswordProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Check if current user has Google provider
  bool get hasGoogleProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  /// Get list of provider IDs for current user
  List<String> get currentProviders {
    final user = _auth.currentUser;
    if (user == null) return [];
    return user.providerData.map((p) => p.providerId).toList();
  }

  /// Add email/password provider to current user
  /// This allows a Google-only user to also log in with email/password
  Future<void> addPasswordProvider(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Kullanıcı oturumu yok';
    if (user.email == null) throw 'Kullanıcının e-posta adresi yok';

    if (hasPasswordProvider) {
      throw 'Bu hesap zaten e-posta/şifre ile giriş yapabiliyor';
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.linkWithCredential(credential);
      debugPrint('[OK] Password provider added successfully');
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Complete account linking after password verification
  Future<UserCredential?> completeGoogleLinking(String password) async {
    if (_pendingGoogleCredential == null || _pendingLinkEmail == null) {
      throw 'Bekleyen Google bağlantısı bulunamadı';
    }

    try {
      // Sign in with email/password first
      final emailCredential = await _auth.signInWithEmailAndPassword(
        email: _pendingLinkEmail!,
        password: password,
      );

      // Link the Google credential
      await emailCredential.user?.linkWithCredential(_pendingGoogleCredential!);

      debugPrint('[OK] Successfully linked Google account');

      // Clear pending credentials
      _pendingGoogleCredential = null;
      _pendingLinkEmail = null;

      return emailCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'Şifre hatalı';
      }
      throw _handleAuthException(e);
    }
  }

  /// Check if there's a pending Google link
  bool get hasPendingGoogleLink => _pendingGoogleCredential != null;
  String? get pendingLinkEmail => _pendingLinkEmail;

  /// Cancel pending link
  void cancelPendingLink() {
    _pendingGoogleCredential = null;
    _pendingLinkEmail = null;
  }

  /// Link Google account to current user
  Future<void> linkGoogleAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'Lütfen önce giriş yapın';
    }

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.linkWithCredential(credential);
      debugPrint('[OK] Google account linked successfully');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw 'Bu Google hesabı başka bir kullanıcıya bağlı.';
      } else if (e.code == 'provider-already-linked') {
        throw 'Zaten bir Google hesabı bağlı.';
      }
      throw 'Hesap bağlama hatası: ${e.message}';
    }
  }

  // ============ Anonymous Sign-In ============

  /// Sign in anonymously
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============ Password Reset ============

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Change password (requires recent login)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw 'Kullanıcı oturumu bulunamadı';
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ============ Sign Out ============

  /// Sign out
  Future<void> signOut() async {
    debugPrint('[SignOut] SignOut called - starting logout process');

    // Try to sign out from Google if it was used (optional - may not be configured)
    try {
      await GoogleSignIn().signOut();
      debugPrint('[SignOut] Google signOut completed');
    } catch (e) {
      // Google Sign-In might not be configured or user didn't use it - that's OK
      debugPrint('[SignOut] Google signOut skipped: $e');
    }

    // Firebase sign out is required
    await _auth.signOut();
    debugPrint(
      '[SignOut] Firebase signOut completed - current user: ${_auth.currentUser}',
    );
  }

  // ============ Account Management ============

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete user data from Firestore
      await _deleteUserData(user.uid);

      // Delete auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update FCM Token
  Future<void> updateFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[OK] FCM Token updated for user ${user.uid}');
    } catch (e) {
      debugPrint('[Error] Error updating FCM token: $e');
    }
  }

  // ============ Helper Methods ============

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    await _firestore.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': displayName,
      'photoURL': user.photoURL,
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Note: Default personal library and favorites list are created by
    // ensureUserHasLibrary() which is called after auth state change.
    // We intentionally do not create them here to avoid race conditions and duplicates.
  }

  /// Delete user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    debugPrint('[Delete] Starting user data deletion for: $userId');

    // 1. Delete user's libraries and books in them
    final librariesQuery = await _firestore
        .collection('libraries')
        .where('ownerId', isEqualTo: userId)
        .get();

    debugPrint('[Delete] Found ${librariesQuery.docs.length} libraries to delete');

    for (final libDoc in librariesQuery.docs) {
      // Delete books in this library
      final booksQuery = await _firestore
          .collection('books')
          .where('libraryId', isEqualTo: libDoc.id)
          .get();

      debugPrint(
        '[Delete] Deleting ${booksQuery.docs.length} books from library ${libDoc.id}',
      );

      for (final bookDoc in booksQuery.docs) {
        await bookDoc.reference.delete();
      }

      // Delete the library itself
      await libDoc.reference.delete();
    }

    // 2. Remove user from shared libraries (where they are member but not owner)
    final sharedLibsQuery = await _firestore
        .collection('libraries')
        .where('members', arrayContains: userId)
        .get();

    for (final libDoc in sharedLibsQuery.docs) {
      // Only if they are not owner (already handled above, but double check)
      if (libDoc.data()['ownerId'] != userId) {
        await libDoc.reference.update({
          'members': FieldValue.arrayRemove([userId]),
        });
      }
    }

    // 3. Delete user's lists (owned by user)
    final listsQuery = await _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: userId)
        .get();

    debugPrint('[Delete] Found ${listsQuery.docs.length} lists to delete');

    for (final doc in listsQuery.docs) {
      await doc.reference.delete();
    }

    // 4. Remove user from shared lists (where they are member but not owner)
    final sharedListsQuery = await _firestore
        .collection('lists')
        .where('members', arrayContains: userId)
        .get();

    for (final listDoc in sharedListsQuery.docs) {
      if (listDoc.data()['ownerId'] != userId) {
        await listDoc.reference.update({
          'members': FieldValue.arrayRemove([userId]),
        });
      }
    }

    // 5. Delete user document
    await _firestore.collection('users').doc(userId).delete();

    debugPrint('[Delete] User data deletion completed for: $userId');
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-not-found':
        return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'invalid-credential':
        return 'Kullanıcı adı veya şifre hatalı.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.';
      case 'requires-recent-login':
        return 'Bu işlem için yeniden giriş yapmanız gerekiyor.';
      case 'network-request-failed':
        return 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }
}
