import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the currently logged-in user
  User? currentUser() {
    return _auth.currentUser;
  }

  // Listen for auth state changes
  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }

  // Login method with error handling and a return value
  Future<bool> login(String email, String pwd) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: pwd);
      print("Login successful!");
      return true; // Login successful
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth exceptions
      if (e.code == 'user-not-found') {
        print("No user found for this email.");
      } else if (e.code == 'wrong-password') {
        print("Incorrect password.");
      } else {
        print("Login failed: ${e.message}");
      }
      return false; // Login failed
    } catch (e) {
      print("An unexpected error occurred: $e");
      return false; // Login failed
    }
  }

  // Sign-up method
  Future<bool> signUp(String email, String pwd, String username) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pwd,
      );

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("Sign-up successful!");
      return true; // Sign-up successful
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth exceptions
      if (e.code == 'weak-password') {
        print("The password is too weak.");
      } else if (e.code == 'email-already-in-use') {
        print("An account already exists for this email.");
      } else {
        print("Sign-up failed: ${e.message}");
      }
      return false; // Sign-up failed
    } catch (e) {
      print("An unexpected error occurred: $e");
      return false; // Sign-up failed
    }
  }

  // Logout method
  Future<void> logout() async {
    await _auth.signOut();
    print("Logged out successfully.");
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Password reset email sent.");
      return true;
    } catch (e) {
      print("Failed to send password reset email: $e");
      return false;
    }
  }
}

