import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads book cover images to Cloud Storage for privileged users.
///
/// Covers are picked from the gallery and resized/compressed at pick time
/// (`maxWidth/maxHeight` + `imageQuality`) so each file stays small (typically
/// well under 100 KB) — keeping the free Storage quota usable. Stored at the
/// deterministic path `covers/{ownerId}/{bookId}.jpg`, which makes cleanup on
/// book deletion trivial and lets re-uploads overwrite the previous cover.
///
/// Write access is enforced server-side by storage.rules (only the owner with
/// a premium/admin role). Callers should still gate the UI on
/// [AuthService.canUploadCover].
class CoverStorageService {
  final FirebaseStorage _storage;
  final ImagePicker _picker;

  CoverStorageService({FirebaseStorage? storage, ImagePicker? picker})
    : _storage = storage ?? FirebaseStorage.instance,
      _picker = picker ?? ImagePicker();

  Reference _coverRef(String ownerId, String bookId) =>
      _storage.ref('covers/$ownerId/$bookId.jpg');

  /// Opens the gallery and returns the picked image's bytes (resized/compressed
  /// at pick time), or null if the user cancelled. Used by the "add book" flow,
  /// where the book id isn't known until after save — the bytes are held and
  /// uploaded via [uploadCoverBytes] once the id exists.
  Future<Uint8List?> pickCoverBytes() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  /// Uploads already-picked image [bytes] and returns the download URL.
  /// Uses putData (not putFile) so it also works on web.
  Future<String> uploadCoverBytes({
    required String ownerId,
    required String bookId,
    required Uint8List bytes,
  }) async {
    final ref = _coverRef(ownerId, bookId);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Convenience for the "edit book" flow (book id already exists): picks an
  /// image and uploads it in one step. Returns the download URL, or null if
  /// the user cancelled.
  Future<String?> pickAndUploadCover({
    required String ownerId,
    required String bookId,
  }) async {
    final bytes = await pickCoverBytes();
    if (bytes == null) return null;
    return uploadCoverBytes(ownerId: ownerId, bookId: bookId, bytes: bytes);
  }

  /// Best-effort removal of a book's uploaded cover. Ignores "not found"
  /// (the book may have used an external URL with no Storage object).
  Future<void> deleteCover(String ownerId, String bookId) async {
    try {
      await _coverRef(ownerId, bookId).delete();
    } on FirebaseException catch (_) {
      // object-not-found / unauthorized — nothing to clean up.
    }
  }
}
