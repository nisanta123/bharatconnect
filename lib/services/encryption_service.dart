import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:bharatconnect/models/chat_models.dart'; // For Message
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage
import 'dart:convert'; // Import for utf8 and base64
import 'package:bharatconnect/services/native_crypto.dart'; // Import NativeCrypto
import 'package:bharatconnect/services/local_data_store.dart'; // Import LocalDataStore

class EncryptionService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(); // Instantiate FlutterSecureStorage
  final LocalDataStore _localDataStore = LocalDataStore(); // Instantiate LocalDataStore

  // Placeholder for actual key management (e.g., generate, store, retrieve)
  Future<void> generateAndStoreKeys(String userId) async {
    debugPrint('EncryptionService: Generating and storing keys for $userId');
    // In a real implementation, this would generate a public/private key pair.
    // For now, we'll store mock keys.
    await _secureStorage.write(key: 'identity_private_key_$userId', value: 'mock_private_key_for_$userId');
    await _secureStorage.write(key: 'identity_public_key_$userId', value: 'mock_public_key_for_$userId');
    await Future.delayed(const Duration(seconds: 1)); // Simulate async operation
  }

  Future<bool> hasLocalKeys(String userId) async {
    debugPrint('EncryptionService: Checking for local keys for $userId');
    final privateKey = await _secureStorage.read(key: 'identity_private_key_$userId');
    return privateKey != null; // Keys exist if private key is found
  }

  Future<String?> getIdentityPrivateKey(String userId) async {
    return await _secureStorage.read(key: 'identity_private_key_$userId');
  }

  Future<String?> getIdentityPublicKey(String userId) async {
    return await _secureStorage.read(key: 'identity_public_key_$userId');
  }

  // Encrypt a message using the native crypto plugin (Android hardware-backed)
  Future<Map<String, dynamic>> encryptMessage(String text, List<String> recipientIds, String senderId, {String? sessionId}) async {
    debugPrint('EncryptionService: Encrypting message for $senderId to $recipientIds using NativeCrypto');
    try {
      // Use sessionId if available, otherwise fallback to senderId
      final id = sessionId ?? senderId;
      final plaintextBytes = utf8.encode(text);
      // Call NativeCrypto to encrypt
      // Note: Native implementation is a stub; will error if not implemented
      final encryptedBytes = await NativeCrypto.encryptMessage(id, Uint8List.fromList(plaintextBytes));
      final encryptedText = base64Encode(encryptedBytes);
      // In a real system, encryptedKeys would be per recipient
      final Map<String, dynamic> encryptedKeys = {};
      for (var recipientId in recipientIds) {
        encryptedKeys[recipientId] = 'native_encrypted_key_for_$recipientId';
      }
      return {
        'encryptedText': encryptedText,
        'keyId': 'nativeKeyId',
        'iv': 'nativeIv',
        'encryptedKeys': encryptedKeys,
      };
    } catch (e) {
      debugPrint('EncryptionService: Native encryption failed, falling back to mock. Error: $e');
      // Fallback to mock encryption
      final String encodedText = base64Encode(utf8.encode(text));
      final String encryptedText = 'ENC:$encodedText';
      final Map<String, dynamic> encryptedKeys = {};
      for (var recipientId in recipientIds) {
        encryptedKeys[recipientId] = 'mock_encrypted_key_for_$recipientId';
      }
      return {
        'encryptedText': encryptedText,
        'keyId': 'mockKeyId',
        'iv': 'mockIv',
        'encryptedKeys': encryptedKeys,
      };
    }
  }

  // Decrypt a message using the native crypto plugin (Android hardware-backed)
  Future<String> decryptMessage(Map<String, dynamic> messageData, String currentUserId, {String? sessionId}) async {
    debugPrint('EncryptionService: Decrypting message for $currentUserId using NativeCrypto');
    final String? messageId = messageData['id'] as String?;
    if (messageId == null) {
      debugPrint('EncryptionService: Message ID not found, cannot cache.');
      return messageData['text'] as String? ?? '[Undecryptable]';
    }

    // Try to retrieve from local store first
    final cachedDecryptedText = await _localDataStore.getDecryptedMessage(messageId);
    if (cachedDecryptedText != null) {
      return cachedDecryptedText;
    }

    final String? encryptedText = messageData['encryptedText'] as String?;
    if (encryptedText == null) {
      debugPrint('EncryptionService: No encryptedText found.');
      return messageData['text'] as String? ?? '[Undecryptable]';
    }
    try {
      String decryptedText;
      // If message is mock-encrypted, decode as before
      if (encryptedText.startsWith('ENC:')) {
        final String encodedText = encryptedText.substring(4);
        decryptedText = utf8.decode(base64Decode(encodedText));
      } else {
        // Otherwise, treat as native-encrypted (base64)
        final id = sessionId ?? currentUserId;
        final encryptedBytes = base64Decode(encryptedText);
        final decryptedBytes = await NativeCrypto.decryptMessage(id, Uint8List.fromList(encryptedBytes));
        decryptedText = utf8.decode(decryptedBytes);
      }
      // Save to local store after successful decryption
      await _localDataStore.saveDecryptedMessage(messageId, decryptedText);
      return decryptedText;
    } catch (e) {
      debugPrint('EncryptionService: Native decryption failed, falling back to mock. Error: $e');
      return '[Decryption Failed]';
    }
  }

  // Placeholder for encrypting and uploading media chunks
  Future<Map<String, dynamic>> encryptAndUploadMedia(dynamic file, String chatId, String senderId, List<String> recipientIds, Function(double) onProgress) async {
    debugPrint('EncryptionService: Encrypting and uploading media (mock)');
    // In a real implementation, this would handle media encryption and upload.
    return {
      'mediaInfo': MediaInfo(fileName: 'mock_image.jpg', fileType: 'image/jpeg', fileId: 'mockFileId'),
      'encryptedAesKey': {},
      'keyId': 'mockKeyId',
    };
  }
}
