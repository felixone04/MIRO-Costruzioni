import 'package:flutter/material.dart';

import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteScaffold(
      current: '/',
      overHero: true,
      children: [
        HomeHero(),
        IntroSection(),
        Ticker(),
        RecentProjects(),
        ContactStrip(),
      ],
    );
  }
}
