import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/library.dart';

class LibraryInviteService {
  static final LibraryInviteService _instance =
      LibraryInviteService._internal();

  factory LibraryInviteService() => _instance;

  LibraryInviteService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sends a library invite to a user by their email address.
  /// Always returns success to prevent user enumeration attacks.
  /// If the user doesn't exist, the invite is silently not sent.
  Future<InviteResult> sendInvite({
    required String email,
    required Library library,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return InviteResult(
          success: false,
          message: 'Oturum açmanız gerekiyor.',
        );
      }

      // Don't allow inviting yourself
      if (email.toLowerCase() == currentUser.email?.toLowerCase()) {
        return InviteResult(
          success: false,
          message: 'Kendinizi davet edemezsiniz.',
        );
      }

      // Find user by email - silently handle if not found
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      // If user not found, still return success (security: prevent enumeration)
      if (userQuery.docs.isEmpty) {
        return InviteResult(success: true, message: 'Davet gönderildi!');
      }

      final inviteeDoc = userQuery.docs.first;
      final inviteeUid = inviteeDoc.id;

      // Get sender's display name
      final senderName =
          currentUser.displayName ?? currentUser.email ?? 'Bir kullanıcı';
      final senderPhotoUrl = currentUser.photoURL;

      // Create notification for the invitee
      debugPrint('[Invite] Creating invite notification for user: $inviteeUid');
      await _firestore
          .collection('users')
          .doc(inviteeUid)
          .collection('notifications')
          .add({
            'type': 'library_invite',
            'title': 'Kütüphane Daveti',
            'body':
                '$senderName sizinle "${library.name}" kütüphanesini paylaşmak istiyor.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': {
              'libraryId': library.id,
              'libraryName': library.name,
              'senderUid': currentUser.uid,
              'senderName': senderName,
              'senderPhotoUrl': senderPhotoUrl,
              'status': 'pending', // pending, accepted, rejected
            },
          });

      debugPrint('[Invite] Invite notification created successfully!');
      return InviteResult(success: true, message: 'Davet gönderildi!');
    } catch (e) {
      debugPrint('[Invite] Error sending invite: $e');
      // Even on error, return success to prevent information leakage
      return InviteResult(success: true, message: 'Davet gönderildi!');
    }
  }

  /// Accepts a library invite
  Future<bool> acceptInvite({
    required String notificationId,
    required String libraryId,
    required String libraryName,
    required String senderUid,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Add the current user to the library's members list
      await _firestore.collection('libraries').doc(libraryId).update({
        'members': FieldValue.arrayUnion([currentUser.uid]),
      });

      // Update the notification status
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'data.status': 'accepted', 'isRead': true});

      // Notify the sender that the invite was accepted
      final userName =
          currentUser.displayName ?? currentUser.email ?? 'Bir kullanıcı';
      await _firestore
          .collection('users')
          .doc(senderUid)
          .collection('notifications')
          .add({
            'type': 'invite_accepted',
            'title': 'Davet Kabul Edildi',
            'body': '$userName "$libraryName" kütüphanesi davetini kabul etti.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': {
              'libraryId': libraryId,
              'libraryName': libraryName,
              'userId': currentUser.uid,
              'userName': userName,
            },
          });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Rejects a library invite
  Future<bool> rejectInvite({
    required String notificationId,
    required String libraryName,
    required String senderUid,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Update the notification status
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'data.status': 'rejected', 'isRead': true});

      // Notify the sender that the invite was rejected
      final userName =
          currentUser.displayName ?? currentUser.email ?? 'Bir kullanıcı';
      await _firestore
          .collection('users')
          .doc(senderUid)
          .collection('notifications')
          .add({
            'type': 'invite_rejected',
            'title': 'Davet Reddedildi',
            'body': '$userName "$libraryName" kütüphanesi davetini reddetti.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'data': {
              'libraryName': libraryName,
              'userId': currentUser.uid,
              'userName': userName,
            },
          });

      return true;
    } catch (e) {
      return false;
    }
  }
}

class InviteResult {
  final bool success;
  final String message;

  InviteResult({required this.success, required this.message});
}
