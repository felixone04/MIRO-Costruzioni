import 'package:flutter/material.dart';

import '../widgets/sections.dart';
import '../widgets/site_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteScaffold(
      current: '/',
      children: [
        HomeHero(),
        IntroSection(),
        Ticker(),
        FeaturedProjects(),
        ServicesSection(),
        ProcessSection(),
        QuoteBand(),
        TestimonialsSection(),
        CtaSection(),
      ],
    );
  }
}
