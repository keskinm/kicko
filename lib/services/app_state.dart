import 'package:dio/dio.dart';
import 'package:kicko/syntax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kicko/services/auth.dart';
import 'package:kicko/models/user.dart';

import '../dio.dart';
import 'database.dart';

AppState appState = AppState();

enum AppStatus {
  init,
  login,
  connected,
  disconnected,
  unknownPlatform,
}

class AppState {
  AppState();

  DatabaseMethods dataBaseMethods = DatabaseMethods();

  String language = "french";

  late Map<dynamic, dynamic> platformState;

  late String serverUrl;

  late User currentUser = User();
  late String userGroup;

  late SharedPreferences sharedPreferences;
  AppStatus appStatus = AppStatus.init;

  AuthMethods authMethods = AuthMethods();

  Future<AppStatus> init() async {
    if (await getCredentials()) {
      appStatus = AppStatus.login;

      await authMethods.firebaseSignInWithEmailAndPassword(
          currentUser.email, currentUser.password);

      if (checkToken(await authMethods.authenticationToken(
          username: currentUser.username,
          password: currentUser.password,
          userGroup: userGroup))) {
        final res = await authMethods
            .getCurrentUser(token: currentUser.token, userGroup: userGroup)
            .catchError((Object e, StackTrace stackTrace) {
          throw Exception(e.toString());
        });
        currentUser.setParameters(res);
        appStatus = AppStatus.connected;
        return AppStatus.connected;
      } else {
        appStatus = AppStatus.disconnected;
        print('Can\'t reach token');
        return AppStatus.disconnected;
      }
    } else {
      appStatus = AppStatus.disconnected;
      return AppStatus.disconnected;
    }
  }

  Future<bool> getCredentials() async {
    sharedPreferences = await SharedPreferences.getInstance();
    return checkCredentials(keys: sharedPreferences);
  }

  void addCredentials({required Map<String, String> keys}) async {
    sharedPreferences = await SharedPreferences.getInstance();
    keys.forEach((key, value) {
      appState.sharedPreferences.setString(key, value);
    });
  }

  bool checkCredentials({required SharedPreferences keys}) {
    print(keys.getKeys());
    if (keys.containsKey('username') &&
        keys.get('username') != null &&
        keys.containsKey('password') &&
        keys.get('password') != null) {
      currentUser.username = keys.get('username').toString();
      currentUser.password = keys.get('password').toString();
      print('Credentials OK');
      return true;
    } else {
      print('Credentials NOT OK');
      return false;
    }
  }

  bool checkToken(token) {
    if (token.containsKey('token')) {
      currentUser.token = token['token'];
      return true;
    } else {
      return false;
    }
  }

  Future deleteAccount() async {
    if (appState.checkToken(await appState.authMethods
        .authenticationToken(
            username: currentUser.username,
            password: currentUser.password,
            userGroup: userGroup)
        .catchError((Object e, StackTrace stackTrace) {
      throw Exception(e.toString());
    }))) {
      Response response =
          await dioHttpGet(route: "delete_${userGroup}_account", token: true);

      if (response.statusCode == 200) {
        if (userGroup == userGroupSyntax.professional) {
          await dataBaseMethods.deleteFireBaseStorageBucket(
              '$userGroup/${appState.currentUser.username}/business_images');

          await dataBaseMethods.deleteFireBaseStorageBucket(
              '$userGroup/${appState.currentUser.username}/job_offer_qr_codes');
        } else if (userGroup == userGroupSyntax.candidate) {
          await dataBaseMethods.deleteFireBaseStorageBucket(
              '$userGroup/${appState.currentUser.username}/resumes');
        }

        await dataBaseMethods.deleteUserFromFireBase(
            currentUser.email, currentUser.password);
        appState.zero();
      } else {
        throw Exception("Server failed deleteAccount");
      }
    } else {
      throw Exception("Check token returned false");
    }
  }

  zero() {
    currentUser = User();
    userGroup = "";
  }
}
