import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fs;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kicko/services/app_state.dart';
import 'package:dio/dio.dart';
import 'package:kicko/dio.dart';

import 'dart:io';

class DatabaseMethods {
  // ------------------------FIREBASE--------------------------------------

  Future<void> addUserInfo(userData) async {
    FirebaseFirestore.instance
        .collection("users")
        .add(userData)
        .catchError((e) {
      print(e.toString());
    });
  }

  getUserInfo(String email) async {
    return FirebaseFirestore.instance
        .collection("users")
        .where("userEmail", isEqualTo: email)
        .get()
        .catchError((e) {
      print(e.toString());
    });
  }

  searchByName(String searchField) {
    return FirebaseFirestore.instance
        .collection("users")
        .where('userName', isEqualTo: searchField)
        .get();
  }

  Future<void> addChatRoom(chatRoom, chatRoomId) async {
    FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(chatRoomId)
        .set(chatRoom)
        .catchError((e) {
      print(e);
    });
  }

  Future getChats(String chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy('time')
        .snapshots();
  }

  Future<void> addMessage(String chatRoomId, chatMessageData) async {
    FirebaseFirestore.instance
        .collection("chatRoom")
        .doc(chatRoomId)
        .collection("chats")
        .add(chatMessageData)
        .catchError((e) {
      print(e.toString());
    });
  }

  getUserChats(String itIsMyName) async {
    return await FirebaseFirestore.instance
        .collection("chatRoom")
        .where('users', arrayContains: itIsMyName)
        .snapshots();
  }

  Future<String> downloadFile(String bucket, String fileId) async {
    fs.Reference ref =
        fs.FirebaseStorage.instance.ref().child(bucket).child(fileId);

    String downloadURL = await ref.getDownloadURL();
    return downloadURL;
  }

  dynamic downloadFiles(String bucket) async {
    fs.Reference ref = fs.FirebaseStorage.instance.ref().child(bucket);

    final urls = await ref.listAll();
    dynamic refs = urls.items;
    dynamic res = [];
    for (dynamic ref in refs) {
      String link = await ref.getDownloadURL();
      res.add(link);
    }

    return res;
  }

  Future<String> uploadFile(
      String bucket, String fileName, dynamic file) async {
    String downloadURL;
    fs.Reference ref =
        fs.FirebaseStorage.instance.ref().child(bucket).child(fileName);

    if (kIsWeb) {
      await ref.putData(await file);
    } else {
      await ref.putFile(File(file.path));
      // await ref.putFile(html.File(image.path.codeUnits, image.path));
    }

    downloadURL = await ref.getDownloadURL();
    return downloadURL;
  }

  Future<String> uploadBytes(
      String bucket, String fileName, Uint8List bytes) async {
    String downloadURL;
    fs.Reference ref =
        fs.FirebaseStorage.instance.ref().child(bucket).child(fileName);
    await ref.putData(bytes);
    downloadURL = await ref.getDownloadURL();
    return downloadURL;
  }

  Future<bool> deleteFireBaseStorageBucket(String bucket) async {
    fs.Reference toDeleteBucket =
        fs.FirebaseStorage.instance.ref().child(bucket);
    final urls = await toDeleteBucket.listAll();
    dynamic refs = urls.items;
    for (dynamic ref in refs) {
      fs.FirebaseStorage.instance.ref(ref.fullPath).delete();
    }

    return true;
  }

  bool deleteFireBaseStorageItem(String storageReference) {
    fs.Reference storageReferenceBase = fs.FirebaseStorage.instance.ref();

    bool success = false;

    storageReferenceBase.child(storageReference).delete().then((_) {
      success = true;
    });

    return success;
  }

  Future deleteUserFromFireBase(String email, String password) async {
    try {
      UserCredential firebaseUser = await appState.authMethods.fAuth
          .signInWithEmailAndPassword(email: email, password: password);
      firebaseUser.user!.delete();
      await appState.authMethods.fAuth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print(
            'The user must reauthenticate before this operation can be executed.');
      }
    }
  }

  // ------------------------SQL--------------------------------------

  Future<bool> updateTableField(
      String value, String field, String route) async {
    String userId = appState.currentUser.id;

    String jsonData = '{"professional_id": "$userId", "$field": "$value"}';

    Response response =
        await dioHttpPost(route: route, jsonData: jsonData, token: true);

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  getTableField(String userId, String route) async {
    String body = '{"professional_id": "$userId"}';
    Response response = await dioHttpPost(
      route: route,
      jsonData: body,
      token: false,
    );

    if (response.statusCode == 200) {
      return response.data;
    } else {
      return {"error": true};
    }
  }
}

// -------------------------------------------------------------------------
