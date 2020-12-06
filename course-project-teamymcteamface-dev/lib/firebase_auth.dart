import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'profileUpdate.dart';

// these variables will store FirebaseUser info
String name;
String email;
String imageUrl;
String currUID;
String signInMethod;
String password;
String bio;

final firebaseDB = FirebaseDatabase.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

Future<String> signInWithGoogle() async {
  final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
  final GoogleSignInAuthentication googleSignInAuthentication =
      await googleSignInAccount.authentication;

  final AuthCredential credential = GoogleAuthProvider.getCredential(
    accessToken: googleSignInAuthentication.accessToken,
    idToken: googleSignInAuthentication.idToken,
  );

  final AuthResult authResult = await _auth.signInWithCredential(credential);
  final FirebaseUser user = authResult.user;

  assert(!user.isAnonymous);
  assert(await user.getIdToken() != null);

  final FirebaseUser currentUser = await _auth.currentUser();
  assert(user.uid == currentUser.uid);

  // Checking if email and name is null
  assert(user.email != null);
  assert(user.displayName != null);
  assert(user.photoUrl != null);

  // set local vars to user info
  name = user.displayName;
  email = user.email;
  imageUrl = user.photoUrl;
  currUID = currentUser.uid;
  bio = bioChange.text;

  // create firebase db reference to access entries
  final ref = firebaseDB.reference().child("users");

  // check if user exists; if not create new entry in db
  ref.orderByChild("uid").equalTo(currentUser.uid);
  DataSnapshot snapshot =
      await ref.orderByChild("uid").equalTo(currentUser.uid).once();
  if (snapshot.value == null) {
    print("adding new user");
    ref.push().set({
      // add to database
      "name": name,
      "uid": currUID,
      "email": email,
      "photo": imageUrl,
      "bio": "Update profile to make bio"
    });
  }

  signInMethod = "google";
  return 'signInWithGoogle succeeded: $user';
}

void signOutGoogle() async {
  await googleSignIn.signOut();
  print("User Sign Out");
}

Future<void> signUpWithEmail(String formName, String formEmail,
    String formPassword, BuildContext context) async {
  try {
    _auth.createUserWithEmailAndPassword(
        email: formEmail, password: formPassword);
  } catch (e) {
    // Display alert if signup fails for some reason.
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Error"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(e.code),
                  Text(e.message),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
  final FirebaseUser currentUser = await _auth.currentUser();
  UserUpdateInfo userUpdateInfo = UserUpdateInfo();
  userUpdateInfo.displayName = formName;

  currentUser.reload();
  print(currentUser.displayName);

  //name = formName;
  name = currentUser.displayName;
  email = currentUser.email;
  currUID = currentUser.uid;
  imageUrl = "";

  // create firebase db reference to access entries
  final ref = firebaseDB.reference().child("users");

  // check if user exists; if not create new entry in db
  ref.orderByChild("uid").equalTo(currentUser.uid);
  DataSnapshot snapshot =
      await ref.orderByChild("uid").equalTo(currentUser.uid).once();
  if (snapshot.value == null) {
    print("adding new user");
    ref.push().set({
      // add to database
      "name": name,
      "uid": currUID,
      "email": email,
      "photo": imageUrl,
    });
  }
}

Future<void> signUpWithEmail2(String formName, String formEmail,
    String formPassword, BuildContext context) async {
  print(formName);
  print(formEmail);
  print(formPassword);
  print('123');

  int succeed = 0;
  FirebaseUser currentUser;

  _auth
      .createUserWithEmailAndPassword(email: formEmail, password: formPassword)
      .then((credential) {
    currentUser = credential.user;
    UserUpdateInfo userUpdateInfo = UserUpdateInfo();
    userUpdateInfo.displayName = formName;

    currentUser.reload();
    //print(currentUser.displayName);

    name = formName;
    //name = currentUser.displayName;
    email = currentUser.email;
    currUID = currentUser.uid;
    imageUrl = "";

    succeed = 1;
  }).catchError((error) {
    print(error);
  });

  // Didn't put this in then() because await keyword doesn't work in then().
  if (succeed == 1) {
    // create firebase db reference to access entries
    final ref = firebaseDB.reference().child("users");

    // check if user exists; if not create new entry in db
    ref.orderByChild("email").equalTo(currentUser.uid);
    DataSnapshot snapshot =
        await ref.orderByChild("email").equalTo(currentUser.uid).once();
    if (snapshot.value == null) {
      print("adding new user");
      ref.push().set({
        // add to database
        "name": name,
        "uid": currUID,
        "email": email,
        "photo": imageUrl
      });
    }
  }
}

Future<void> signInWithEmail(String formEmail, String formPassword) async {
  _auth
      .signInWithEmailAndPassword(email: formEmail, password: formPassword)
      .then((credential) {
    final FirebaseUser currentUser = credential.user;
    email = currentUser.email;
    currUID = currentUser.uid;
    return;
  }).catchError((error) {
    print(error);
    return;
  });
  return;
}

void signOutEmail() async {
  await _auth.signOut();
  print('Email User Sign Out');
}

void userSignOut() async {
  name = null;
  currUID = null;
  email = null;
  imageUrl = null;

  if (signInMethod == "google") {
    signOutGoogle();
    return;
  }
  signOutEmail();
  return;
}

String getEmail() {
  return email;
}

FirebaseAuth getAuth() {
  return _auth;
}

Future<int> requestChangePassword(String currPW, String newPW) async {
  final user = await _auth.currentUser();
  AuthCredential cred =
      EmailAuthProvider.getCredential(email: email, password: currPW);
  user.reauthenticateWithCredential(cred).then((value) {
    user.updatePassword(newPW).whenComplete(() {
      return 0;
    }).catchError((error) {
      print(error);
      return 2;
    });
  }).catchError((error) {
    print(error);
    return 1;
  });

  return -1;
}