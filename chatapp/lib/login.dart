// import 'dart:html';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatapp/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool pageInitialised = false;

  final googleSignin = GoogleSignIn();
  final firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    checkIfUserLoggedIn();
    super.initState();
  }

  checkIfUserLoggedIn() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool userLoggedIn = {sharedPreferences.getString('id') ?? ''}.isNotEmpty;

    if (userLoggedIn) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => Home()));
    } else {
      setState(() {
        pageInitialised = true;
      });
    }
  }

  handleSignIn() async {
    // User user = FirebaseAuth.instance.currentUser;
    final res = await googleSignin.signIn();
    final auth = await res.authentication;
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    final credentials = GoogleAuthProvider.credential(
        idToken: auth.idToken, accessToken: auth.accessToken);
    final firebaseUser =
        {await firebaseAuth.signInWithCredential(credentials)}.user;

    if (firebaseUser != null) {
      final result = (await FirebaseFirestore.instance
              .collection('users')
              .where('id', isEqualTo: firebaseUser.uid)
              .get())
          .docs;

      if (result.length == 0) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          "id": firebaseUser.uid,
          "name": firebaseUser.displayName,
          "profile_pic": firebaseUser.photoUrl,
          // "created_at": DataTime.now().millisecondsSinceEpoch,
        });

        sharedPreferences.setString("id", firebaseUser.uid);
        sharedPreferences.setString("name", firebaseUser.displayName);
        sharedPreferences.setString("profile_pic", firebaseUser.photoUrl);

         Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => Home()));

      }
      else{
        ///old user
          sharedPreferences.setString("id", result[0]["id"]);
        sharedPreferences.setString("name", result[0]["name"]);
        sharedPreferences.setString("profile_pic", result[0]["profile_pic"]);

         Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => Home()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: (pageInitialised)
            ? Center(
                child: RaisedButton(
                  child: Text('Sign in'),
                  onPressed:  handleSignIn,
                ),
              )
            : Center(
                child: SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ))));
  }
}
