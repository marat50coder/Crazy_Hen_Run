import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/app_state.dart';
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<_Slide> _slides = <_Slide>[
    _Slide(
      asset: AppAssets.henCurious,
      kicker: 'Welcome',
      title: 'Every habit is a\nstretch of road',
      body:
          'Crazy Hen Run turns your daily routine into a track. Add habits, close them, and watch the distance add up.',
      tint: Brand.lime,
    ),
    _Slide(
      asset: AppAssets.henRunner,
      kicker: 'Run',
      title: 'Close habits,\ncover distance',
      body:
          'Every completed habit puts real metres behind you. Harder habits pay more, so the effort actually shows.',
      tint: Brand.moss,
    ),
    _Slide(
      asset: AppAssets.henSprinter,
      kicker: 'Grow',
      title: 'Your hen levels\nup with you',
      body:
          'Chick, Hen, Runner, Sprinter, Legend. Keep the streak alive and the bird in your pocket gets faster.',
      tint: Brand.corn,
    ),
    _Slide(
      asset: AppAssets.henLegend,
      kicker: 'Own it',
      title: 'Everything stays\non your phone',
      body:
          'No account, no sync, no internet needed. Your streaks, notes and photos never leave the device.',
      tint: Brand.comb,
    ),
  ];

  Future<void> _finish() async {
    final app = context.read<AppState>();
    await app.completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RootShell()),
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
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    Image.asset(AppAssets.logo, height: 42),
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
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
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
                    const SizedBox(height: AppSpacing.lg),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: slide.tint.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadii.pill),
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
          const SizedBox(height: AppSpacing.md),
          Text(slide.title, style: context.text.displaySmall)
              .animate()
              .fadeIn(delay: 120.ms)
              .moveY(begin: 12, end: 0),
          const SizedBox(height: AppSpacing.sm),
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
