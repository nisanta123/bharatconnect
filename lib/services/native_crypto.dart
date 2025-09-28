import 'dart:typed_data';
import 'package:flutter/services.dart';

class NativeCrypto {
  static const MethodChannel _channel = MethodChannel('bharatconnect.crypto');

  /// Generates a hardware-backed identity keypair (Curve25519 or platform equivalent).
  static Future<void> generateIdentityKeyPair() async {
    await _channel.invokeMethod('generateIdentityKeyPair');
  }

  /// Gets the public part of the identity keypair as bytes.
  static Future<Uint8List> getIdentityPublicKey() async {
    final bytes = await _channel.invokeMethod('getIdentityPublicKey');
    return Uint8List.fromList(List<int>.from(bytes));
  }

  /// Encrypts a message using the established session (native-side).
  static Future<Uint8List> encryptMessage(String sessionId, Uint8List plaintext) async {
    final ciphertext = await _channel.invokeMethod('encryptMessage', {
      'sessionId': sessionId,
      'plaintext': plaintext,
    });
    return Uint8List.fromList(List<int>.from(ciphertext));
  }

  /// Decrypts a message using the established session (native-side).
  static Future<Uint8List> decryptMessage(String sessionId, Uint8List ciphertext) async {
    final plaintext = await _channel.invokeMethod('decryptMessage', {
      'sessionId': sessionId,
      'ciphertext': ciphertext,
    });
    return Uint8List.fromList(List<int>.from(plaintext));
  }

  /// Wraps a symmetric master key for DB/file encryption using hardware key.
  static Future<Uint8List> wrapMasterKey(Uint8List plainKey) async {
    final wrapped = await _channel.invokeMethod('wrapMasterKey', {
      'plainKey': plainKey,
    });
    return Uint8List.fromList(List<int>.from(wrapped));
  }

  /// Unwraps a symmetric master key using hardware key.
  static Future<Uint8List> unwrapMasterKey(Uint8List wrappedKey) async {
    final plain = await _channel.invokeMethod('unwrapMasterKey', {
      'wrappedKey': wrappedKey,
    });
    return Uint8List.fromList(List<int>.from(plain));
  }
}
