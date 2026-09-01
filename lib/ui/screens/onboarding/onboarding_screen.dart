import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../domain/hen_state.dart';
import '../../widgets/hen.dart';
import '../root_shell.dart';

class _Slide {
  const _Slide({
    required this.asset,
    required this.kicker,
    required this.title,
    required this.body,
    required this.tint,
  });

  final String asset;
  final String kicker;
  final String title;
  final String body;
  final Color tint;
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HenState>().promptChimesOnFirstLaunch();
    });
  }

  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      asset: Artwork.henCurious,
      kicker: 'Welcome',
      title: 'Every habit is a\nstretch of road',
      body:
          'Crazy Hen Run turns your daily routine into a track. Add habits, close them, and watch the distance add up.',
      tint: Meadow.lime,
    ),
    _Slide(
      asset: Artwork.henRunner,
      kicker: 'Run',
      title: 'Close habits,\ncover distance',
      body:
          'Every completed habit puts real metres behind you. Harder habits pay more, so the effort actually shows.',
      tint: Meadow.moss,
    ),
    _Slide(
      asset: Artwork.henSprinter,
      kicker: 'Grow',
      title: 'Your hen levels\nup with you',
      body:
          'Chick, Hen, Runner, Sprinter, Legend. Keep the streak alive and the bird in your pocket gets faster.',
      tint: Meadow.corn,
    ),
    _Slide(
      asset: Artwork.henLegend,
      kicker: 'Own it',
      title: 'Everything stays\non your phone',
      body:
          'No account, no sync, no internet needed. Your streaks, notes and photos never leave the device.',
      tint: Meadow.comb,
    ),
  ];

  Future<void> _finish() async {
    final app = context.read<HenState>();
    await app.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
    );
  }

  void _next() {
    if (_index == _slides.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final slide = _slides[_index];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              slide.tint.withValues(alpha: 0.24),
              c.canvas,
              c.canvas,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  Insets.sm,
                  Insets.md,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Image.asset(Artwork.logo, height: 42),
                    const Spacer(),
                    TextButton(
                      onPressed: _finish,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.lg,
                  0,
                  Insets.lg,
                  Insets.lg,
                ),
                child: Column(
                  children: <Widget>[
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _slides.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3.6,
                        spacing: 6,
                        dotColor: c.outlineStrong,
                        activeDotColor: c.accent,
                      ),
                    ),
                    const SizedBox(height: Insets.lg),
                    FilledButton(
                      onPressed: _next,
                      child: Text(
                        _index == _slides.length - 1
                            ? 'Start running'
                            : 'Continue',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: HenFigure(asset: slide.asset, size: 240)
                .animate()
                .fadeIn(duration: 420.ms)
                .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
          ),
          const SizedBox(height: Insets.xl),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.tint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(Corners.pill),
            ),
            child: Text(
              slide.kicker.toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: slide.tint.computeLuminance() > 0.6
                    ? context.palette.textPrimary
                    : slide.tint,
                letterSpacing: 1.4,
              ),
            ),
          ),
          const SizedBox(height: Insets.md),
          Text(slide.title, style: context.text.displaySmall)
              .animate()
              .fadeIn(delay: 120.ms)
              .moveY(begin: 12, end: 0),
          const SizedBox(height: Insets.sm),
          Text(slide.body, style: context.text.bodyLarge?.copyWith(
                color: context.palette.textSecondary,
              ))
              .animate()
              .fadeIn(delay: 200.ms)
              .moveY(begin: 12, end: 0),
        ],
      ),
    );
  }
}
