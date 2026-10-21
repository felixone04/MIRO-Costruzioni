import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'pages/about_page.dart';
import 'pages/client_area_page.dart';
import 'pages/admin/admin_page.dart';
import 'pages/contact_page.dart';
import 'pages/home_page.dart';
import 'pages/projects_page.dart';
import 'pages/services_page.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/site_theme.dart';
import 'theme/theme_fader.dart';

/// Permette il trascinamento con il mouse (confronto prima/dopo, galleria).
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

CustomTransitionPage<void> _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (_, a, _, c) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: c,
      ),
    );

GoRouter buildRouter(AppState state) => GoRouter(
  redirect: (context, s) {
    final q = s.uri.queryParameters;
    if (q.isNotEmpty) {
      // Fuori dalla costruzione della pagina: lo stato avvisa chi ascolta.
      scheduleMicrotask(() => state.applyLinkParams(q));
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', pageBuilder: (c, s) => _fade(s, const HomePage())),
    GoRoute(
      path: '/progetti',
      pageBuilder: (c, s) => _fade(
        s,
        ProjectsPage(
          key: ValueKey(s.uri.toString()),
          category: s.uri.queryParameters['categoria'],
        ),
      ),
      routes: [
        GoRoute(
          path: ':id',
          pageBuilder: (c, s) => _fade(
            s,
            ProjectPage(
              key: ValueKey(s.pathParameters['id']),
              id: s.pathParameters['id']!,
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/servizi',
      pageBuilder: (c, s) => _fade(
        s,
        ServicesPage(
          key: ValueKey(s.uri.toString()),
          initial: s.uri.queryParameters['s'],
        ),
      ),
    ),
    GoRoute(
      path: '/azienda',
      pageBuilder: (c, s) => _fade(s, const AboutPage()),
    ),
    GoRoute(
      path: '/contatti',
      pageBuilder: (c, s) => _fade(s, const ContactPage()),
    ),
    GoRoute(
      path: '/area-clienti',
      pageBuilder: (c, s) => _fade(s, const ClientAreaPage()),
      routes: [
        GoRoute(
          path: ':id',
          pageBuilder: (c, s) => _fade(
            s,
            ClientAreaPage(
              key: ValueKey(s.pathParameters['id']),
              worksiteId: s.pathParameters['id'],
            ),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (c, s) => NoTransitionPage(
        key: s.pageKey,
        child: const AdminPage(section: null),
      ),
      routes: [
        GoRoute(
          path: ':section',
          pageBuilder: (c, s) => NoTransitionPage(
            key: s.pageKey,
            child: AdminPage(
              section: s.pathParameters['section'],
              itemId: s.uri.queryParameters['id'],
            ),
          ),
        ),
      ],
    ),
  ],
  errorPageBuilder: (c, s) => _fade(s, const HomePage()),
);

class MiroApp extends StatefulWidget {
  const MiroApp({super.key});

  @override
  State<MiroApp> createState() => _MiroAppState();
}

class _MiroAppState extends State<MiroApp> {
  late final GoRouter _router = buildRouter(context.read<AppState>());

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return ThemeFader(
      child: MaterialApp.router(
        onGenerateTitle: (_) =>
            '${state.content.companyName} · ${state.content.tagline}',
        debugShowCheckedModeBanner: false,
        theme: siteThemeData(),
        builder: (context, child) => ScreenScale(child: child!),
        scrollBehavior: _AppScrollBehavior(),
        locale: const Locale('it', 'IT'),
        supportedLocales: const [Locale('it', 'IT')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
