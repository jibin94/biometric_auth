import 'package:biometric_auth/utils/app_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';
import 'package:local_auth/local_auth.dart';

///Manager class for biometric
class BiometricManager {
  final LocalAuthentication localAuthentication = LocalAuthentication();

  ///to check if biometric authentication is in progress
  ///to avoid iteration of [checkBiometric]
  bool isAuthenticationInProgress = false;

  BiometricManager._();

  // Singleton instance
  static final BiometricManager _instance = BiometricManager._();

  // Static getter for the singleton instance
  static BiometricManager get shared => _instance;

  ///Function for Biometric authentication
  Future<void> checkBiometric() async {
    List<BiometricType> availableBiometrics =
        await localAuthentication.getAvailableBiometrics();

    if ((availableBiometrics.isNotEmpty) ||
        await localAuthentication.isDeviceSupported()) {
      try {
        isAuthenticationInProgress = true;
        bool isAuthenticated = await localAuthentication.authenticate(
          localizedReason: AppStrings.biometric,
          options: const AuthenticationOptions(
              biometricOnly: false, useErrorDialogs: true, stickyAuth: true),
        );
        if (isAuthenticated) {
          isAuthenticationInProgress = true;
          const snackBar = SnackBar(content: Text('Authentication successful'));
          ScaffoldMessenger.of(Get.context!).showSnackBar(snackBar);
          return;
        } else {
          isAuthenticationInProgress = true;
          await showAlertForBiometric();
        }
      } on PlatformException catch (e) {
        debugPrint(e.toString());
        isAuthenticationInProgress = true;
        await showAlertForBiometric();
      } finally {
        Future.delayed(const Duration(seconds: 2), () {
          isAuthenticationInProgress = false;
        });
      }
    } else {
      ///if biometrics are not enrolled, check if the user is logged in
      ///if true, navigate to homepage. Else to do nothing
    }
  }

  ///Function for showing alert when authentication fails
  Future<void> showAlertForBiometric() async {
    return showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          onPopInvoked: (value) {
            value;
          },
          child: CupertinoAlertDialog(
            title: Text(
              AppStrings.authFailed,
            ),
            content: Text(
              AppStrings.authFailedDesc,
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  AppStrings.unlock,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  isAuthenticationInProgress = false;
                  checkBiometric();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  ///Function for checking if biometric authentication is available in device
  Future<bool> checkBiometricAvailable() async {
    ///lists available biometrics

    List<BiometricType> availableBiometrics =
        await localAuthentication.getAvailableBiometrics();

    if ((availableBiometrics.isNotEmpty) ||
        await localAuthentication.isDeviceSupported()) {
      return true;
    } else {
      return false;
    }
  }
}
