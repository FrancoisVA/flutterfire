import 'package:firebase_auth/firebase_auth.dart'
    hide PhoneAuthProvider, EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_example/blank.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:firebase_ui_oauth_apple/firebase_ui_oauth_apple.dart';
import 'package:firebase_ui_oauth_facebook/firebase_ui_oauth_facebook.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_twitter/firebase_ui_oauth_twitter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';

import 'config.dart';
import 'decorations.dart';

final actionCodeSettings = ActionCodeSettings(
  url: 'https://flutterfire-e2e-tests.firebaseapp.com',
  handleCodeInApp: true,
  androidMinimumVersion: '1',
  androidPackageName: 'io.flutter.plugins.firebase_ui.firebase_ui_example',
  iOSBundleId: 'io.flutter.plugins.fireabaseUiExample',
);
final emailLinkProviderConfig = EmailLinkAuthProvider(
  actionCodeSettings: actionCodeSettings,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    emailLinkProviderConfig,
    PhoneAuthProvider(),
    GoogleProvider(clientId: GOOGLE_CLIENT_ID),
    AppleProvider(),
    FacebookProvider(clientId: FACEBOOK_CLIENT_ID),
    TwitterProvider(
      apiKey: TWITTER_API_KEY,
      apiSecretKey: TWITTER_API_SECRET_KEY,
      redirectUri: TWITTER_REDIRECT_URI,
    ),
  ]);

  runApp(FirebaseAuthUIExample());
}

// Overrides a label for en locale
// To add localization for a custom language follow the guide here:
// https://flutter.dev/docs/development/accessibility-and-localization/internationalization#an-alternative-class-for-the-apps-localized-resources
class LabelOverrides extends DefaultLocalizations {
  const LabelOverrides();

  @override
  String get emailInputLabel => 'Enter your email';
}

class FirebaseAuthUIExample extends StatelessWidget {
  FirebaseAuthUIExample({Key? key}) : super(key: key);

  String get initialRoute {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      return '/';
    }

    if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
      return '/verify-email';
    }

    return '/profile';
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ButtonStyle(
      padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    return MaterialApp.router(
      theme: ThemeData(
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
        textButtonTheme: TextButtonThemeData(style: buttonStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
      ),
      routerConfig: _router,
      title: 'Firebase UI demo',
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localizationsDelegates: [
        FirebaseUILocalizations.withDefaultOverrides(const LabelOverrides()),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FirebaseUILocalizations.delegate,
      ],
    );
  }

  final GoRouter _router = GoRouter(
    routes: <GoRoute>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return SignInScreen(
            actions: [
              ForgotPasswordAction((context, email) {
                GoRouter.of(context)
                    .go('/forgot-password', extra: {'email': email});
                // Navigator.pushNamed(
                //   context,
                //   '/forgot-password',
                //   arguments: {'email': email},
                // );
              }),
              VerifyPhoneAction((context, _) {
                GoRouter.of(context).go('/phone');
                // Navigator.pushNamed(context, '/phone');
              }),
              AuthStateChangeAction<SignedIn>((context, state) {
                if (!state.user!.emailVerified) {
                  GoRouter.of(context).go('/verify-email');
                  // Navigator.pushNamed(context, '/verify-email');
                } else {
                  GoRouter.of(context).go('/profile');
                  // Navigator.pushReplacementNamed(context, '/profile');
                }
              }),
              AuthStateChangeAction<UserCreated>((context, state) {
                if (!state.credential.user!.emailVerified) {
                  GoRouter.of(context).go('/verify-email');
                  // Navigator.pushNamed(context, '/verify-email');
                } else {
                  GoRouter.of(context).go('/profile');
                  // Navigator.pushReplacementNamed(context, '/profile');
                }
              }),
              AuthStateChangeAction<MFARequired>(
                (context, state) async {
                  // final nav = Navigator.of(context);
                  final nav = GoRouter.of(context);

                  await startMFAVerification(
                    resolver: state.resolver,
                    context: context,
                  );

                  //nav.pushReplacementNamed('/profile');
                  nav.replaceNamed('/profile');
                },
              ),
              EmailLinkSignInAction((context) {
                GoRouter.of(context).replaceNamed('/email-link-sign-in');
                // Navigator.pushReplacementNamed(context, '/email-link-sign-in');
              }),
            ],
            styles: const {
              EmailFormStyle(signInButtonVariant: ButtonVariant.filled),
            },
            headerBuilder: headerImage('assets/images/flutterfire_logo.png'),
            sideBuilder: sideImage('assets/images/flutterfire_logo.png'),
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  action == AuthAction.signIn
                      ? 'Welcome to Firebase UI! Please sign in to continue.'
                      : 'Welcome to Firebase UI! Please create an account to continue',
                ),
              );
            },
            footerBuilder: (context, action) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    action == AuthAction.signIn
                        ? 'By signing in, you agree to our terms and conditions.'
                        : 'By registering, you agree to our terms and conditions.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (BuildContext context, GoRouterState state) {
          return EmailVerificationScreen(
            headerBuilder: headerIcon(Icons.verified),
            sideBuilder: sideIcon(Icons.verified),
            actionCodeSettings: actionCodeSettings,
            actions: [
              EmailVerifiedAction(() {
                GoRouter.of(context).replaceNamed('/profile');
                // Navigator.pushReplacementNamed(context, '/profile');
              }),
              AuthCancelledAction((context) {
                FirebaseUIAuth.signOut(context: context);
                GoRouter.of(context).replaceNamed('/');
                // Navigator.pushReplacementNamed(context, '/');
              }),
            ],
          );
        },
      ),
      GoRoute(
        path: '/phone',
        builder: (BuildContext context, GoRouterState state) {
          return PhoneInputScreen(
            actions: [
              SMSCodeRequestedAction((context, action, flowKey, phone) {
                GoRouter.of(context).replaceNamed('/sms', extra: {
                  'action': action,
                  'flowKey': flowKey,
                  'phone': phone,
                });
                // Navigator.of(context).pushReplacementNamed(
                //   '/sms',
                //   arguments: {
                //     'action': action,
                //     'flowKey': flowKey,
                //     'phone': phone,
                //   },
                // );
              }),
            ],
            headerBuilder: headerIcon(Icons.phone),
            sideBuilder: sideIcon(Icons.phone),
          );
        },
      ),
      GoRoute(
        path: '/sms',
        builder: (BuildContext context, GoRouterState state) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return SMSCodeInputScreen(
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                GoRouter.of(context).replaceNamed('/profile');
                // Navigator.of(context).pushReplacementNamed('/profile');
              })
            ],
            flowKey: arguments?['flowKey'],
            action: arguments?['action'],
            headerBuilder: headerIcon(Icons.sms_outlined),
            sideBuilder: sideIcon(Icons.sms_outlined),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (BuildContext context, GoRouterState state) {
          final arguments = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;

          return ForgotPasswordScreen(
            email: arguments?['email'],
            headerMaxExtent: 200,
            headerBuilder: headerIcon(Icons.lock),
            sideBuilder: sideIcon(Icons.lock),
          );
        },
      ),
      GoRoute(
        path: '/email-link-sign-in',
        builder: (BuildContext context, GoRouterState state) {
          return EmailLinkSignInScreen(
            actions: [
              AuthStateChangeAction<SignedIn>((context, state) {
                GoRouter.of(context).replaceNamed('/');
                // Navigator.pushReplacementNamed(context, '/');
              }),
            ],
            provider: emailLinkProviderConfig,
            headerMaxExtent: 200,
            headerBuilder: headerIcon(Icons.link),
            sideBuilder: sideIcon(Icons.link),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          return ProfileScreen(
            actions: [
              SignedOutAction((context) {
                GoRouter.of(context).replaceNamed('/');
                // Navigator.pushReplacementNamed(context, '/');
              }),
              AuthStateChangeAction<MFARequired>(
                (context, state) async {
                  // final nav = Navigator.of(context);
                  final nav = GoRouter.of(context);

                  await startMFAVerification(
                    resolver: state.resolver,
                    context: context,
                  );

                  //nav.pushReplacementNamed('/profile');
                  nav.replaceNamed('/profile');
                },
              ),
            ],
            actionCodeSettings: actionCodeSettings,
            showMFATile: true,
          );
        },
      ),
      GoRoute(
        path: '/blank',
        builder: (BuildContext context, GoRouterState state) {
          return const BlankScreen();
        },
      ),
    ],
  );
}
