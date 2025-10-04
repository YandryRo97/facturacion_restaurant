import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});


@override
State<LoginScreen> createState() => _LoginScreenState();
}


class _LoginScreenState extends State<LoginScreen> {
final emailCtrl = TextEditingController();
final passCtrl = TextEditingController();
bool loading = false;


Future<void> _login() async {
setState(() => loading = true);
try {
final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
email: emailCtrl.text.trim(),
password: passCtrl.text.trim(),
);
await _ensureUserDoc(cred.user!);
} on FirebaseAuthException catch (e) {
if (e.code == 'user-not-found') {
final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
email: emailCtrl.text.trim(),
password: passCtrl.text.trim(),
);
await _ensureUserDoc(cred.user!, defaultRole: 'admin'); // primer usuario -> admin
} else {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Error')));
}
} finally {
if (mounted) setState(() => loading = false);
}
}


Future<void> _ensureUserDoc(User user, {String defaultRole = 'waiter'}) async {
final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
await doc.set({
'displayName': user.displayName ?? '',
'email': user.email,
'role': (await doc.get()).exists ? (await doc.get()).data()!['role'] : defaultRole,
'active': true,
'createdAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));
}


@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Login')),
body: Padding(
padding: const EdgeInsets.all(16),
child: Column(children: [
TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
const SizedBox(height: 12),
ElevatedButton(onPressed: loading ? null : _login, child: Text(loading ? '...' : 'Entrar / Registrar')),
]),
),
);
}
}