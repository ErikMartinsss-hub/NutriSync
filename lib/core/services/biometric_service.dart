import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricResult {
  final bool success;
  final String? message;
  const BiometricResult(this.success, this.message);
}

class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasEnrolledBiometrics() async {
    try {
      final list = await _auth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static const _channel = MethodChannel('com.mamba.nutrisync/biometric');

  static Future<void> openEnrollSettings() async {
    try {
      await _channel.invokeMethod('openBiometricEnroll');
    } catch (_) {}
  }

  static Future<BiometricResult> authenticate() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Use sua digital para entrar na sua conta',
        biometricOnly: true,
      );
      return BiometricResult(ok, null);
    } on LocalAuthException catch (e) {
      log('[BIOMETRIC] Falha code=${e.code.name} desc=${e.description}');
      return BiometricResult(false, _messageFor(e.code));
    } catch (e) {
      log('[BIOMETRIC] Falha generica: $e');
      return const BiometricResult(false, 'Erro ao usar a digital. Tente novamente mais tarde.');
    }
  }

  static String _messageFor(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.userRequestedFallback:
        return 'Digital cancelada ou tempo esgotado. Tente novamente.';
      case LocalAuthExceptionCode.uiUnavailable:
        return 'Não foi possível abrir a tela da digital. Tente novamente.';
      case LocalAuthExceptionCode.noCredentialsSet:
        return 'Configure uma senha/PIN no aparelho para usar a digital.';
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noBiometricHardware:
        return 'Nenhuma digital cadastrada neste aparelho.';
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return 'A digital está indisponível no momento. Tente mais tarde.';
      case LocalAuthExceptionCode.temporaryLockout:
        return 'Muitas tentativas sem sucesso. Aguarde um pouco e tente de novo.';
      case LocalAuthExceptionCode.biometricLockout:
        return 'Muitas tentativas. Desbloqueie o aparelho com a senha/PIN para liberar a digital.';
      case LocalAuthExceptionCode.authInProgress:
        return 'Uma autenticação já está em andamento.';
      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        return 'Erro do aparelho ao usar a digital. Tente novamente mais tarde.';
    }
  }
}