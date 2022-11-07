import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

final mfaAction = AuthStateChangeAction<MFARequired>(
  (context, state) async {
    final nav = Navigator.of(context);

    await startMFAVerification(
      resolver: state.resolver,
      context: context,
    );

    nav.pushReplacementNamed('/profile');
  },
);
