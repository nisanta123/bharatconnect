package com.bharatconnect.crypto;

import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.PublicKey;
import java.security.spec.ECGenParameterSpec;
import java.util.Date;
import javax.crypto.Cipher;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class NativeCryptoPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private static final String KEY_ALIAS = "bharatconnect_identity";

    @Override
    public void onAttachedToEngine(FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), "bharatconnect.crypto");
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "generateIdentityKeyPair":
                generateIdentityKeyPair(result);
                break;
            case "getIdentityPublicKey":
                getIdentityPublicKey(result);
                break;
            // Stubs for encrypt/decrypt/wrap/unwrap
            case "encryptMessage":
                result.error("UNIMPLEMENTED", "encryptMessage not implemented", null);
                break;
            case "decryptMessage":
                result.error("UNIMPLEMENTED", "decryptMessage not implemented", null);
                break;
            case "wrapMasterKey":
                result.error("UNIMPLEMENTED", "wrapMasterKey not implemented", null);
                break;
            case "unwrapMasterKey":
                result.error("UNIMPLEMENTED", "unwrapMasterKey not implemented", null);
                break;
            default:
                result.notImplemented();
        }
    }

    private void generateIdentityKeyPair(Result result) {
        try {
            KeyPairGenerator kpg = KeyPairGenerator.getInstance(
                    KeyProperties.KEY_ALGORITHM_EC, "AndroidKeyStore");
        KeyGenParameterSpec spec = new KeyGenParameterSpec.Builder(
            KEY_ALIAS,
            KeyProperties.PURPOSE_SIGN)
                    .setAlgorithmParameterSpec(new ECGenParameterSpec("secp256r1"))
                    .setUserAuthenticationRequired(false)
                    .setDigests(KeyProperties.DIGEST_SHA256)
                    .setIsStrongBoxBacked(true)
                    .setKeyValidityStart(new Date())
                    .setKeyValidityEnd(new Date(System.currentTimeMillis() + 10L * 365 * 24 * 60 * 60 * 1000))
                    .build();
            kpg.initialize(spec);
            kpg.generateKeyPair();
            result.success(true);
        } catch (Exception e) {
            result.error("KEYGEN_ERROR", e.getMessage(), null);
        }
    }

    private void getIdentityPublicKey(Result result) {
        try {
            KeyStore ks = KeyStore.getInstance("AndroidKeyStore");
            ks.load(null);
            PublicKey pubKey = ks.getCertificate(KEY_ALIAS).getPublicKey();
            byte[] encoded = pubKey.getEncoded();
            result.success(encoded);
        } catch (Exception e) {
            result.error("PUBKEY_ERROR", e.getMessage(), null);
        }
    }
}
