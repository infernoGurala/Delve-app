import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/word_model.dart';
import 'package:uuid/uuid.dart';
import '../shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _rules = [
    {
      'title': 'A deck. 15 words. 13 days.',
      'subtitle': 'A structured cycle to build true retention.',
    },
    {
      'title': '7 cards a day. 5 to review. 2 to prove.',
      'subtitle': 'A little effort, every day.',
    },
    {
      'title': 'Miss one day. Start over.',
      'subtitle': 'Consistency is not optional.',
    },
    {
      'title': 'Your words. Your meanings. AI just checks.',
      'subtitle': 'Make it personal.',
    },
  ];

  void _completeOnboarding() async {
    final inventory = context.read<InventoryProvider>();
    
    final initialWords = [
      {'word': 'Ephemeral', 'meaning': 'Lasting for a very short time'},
      {'word': 'Solitude', 'meaning': 'The state of being alone, often peacefully'},
      {'word': 'Reverie', 'meaning': 'A state of being pleasantly lost in thought'},
      {'word': 'Laconic', 'meaning': 'Using very few words to express a lot'},
      {'word': 'Wanderlust', 'meaning': 'A strong desire to travel and explore the world'},
      {'word': 'Serendipity', 'meaning': 'Finding something good without looking for it'},
      {'word': 'Melancholy', 'meaning': 'A deep, thoughtful sadness'},
      {'word': 'Resilience', 'meaning': 'The ability to recover quickly from difficulties'},
      {'word': 'Luminous', 'meaning': 'Full of light; glowing'},
      {'word': 'Catharsis', 'meaning': 'The release of strong emotions through an experience'},
      {'word': 'Threshold', 'meaning': 'The point just before something begins or changes'},
      {'word': 'Liminal', 'meaning': 'Occupying a transitional or in-between space'},
      {'word': 'Fervent', 'meaning': 'Having or showing intense passion or feeling'},
      {'word': 'Tempest', 'meaning': 'A violent, chaotic storm'},
      {'word': 'Cognition', 'meaning': 'The mental process of acquiring knowledge and understanding'},
    ];

    for (var w in initialWords) {
      inventory.addWord(Word(
        id: const Uuid().v4(),
        word: w['word']!,
        meaning: w['meaning']!,
        addedAt: DateTime.now(),
      ));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('delve_has_launched', true);

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _rules.length + 1,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _SplashPage();
                  } else {
                    final rule = _rules[index - 1];
                    return _RulePage(
                      title: rule['title']!,
                      subtitle: rule['subtitle']!,
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: _currentPage == _rules.length
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      onPressed: _completeOnboarding,
                      child: const Text('Start Journey', style: TextStyle(fontSize: 18)),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: Text('Skip', style: TextStyle(color: theme.textSecondary)),
                        ),
                        Row(
                          children: List.generate(_rules.length + 1, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentPage == index ? theme.accent : theme.divider,
                              ),
                            );
                          }),
                        ),
                        TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text('Next', style: TextStyle(color: theme.accent)),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(32), // Soft round square (Squircle)
            child: Image.asset(
              theme.isDark ? 'logos/white.png' : 'logos/black.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.eco_rounded,
                size: 120,
                color: theme.accent,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Delve',
            style: TextStyle(
              color: theme.text,
              fontSize: 56,
              fontWeight: FontWeight.bold,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'One word deeper, every day.',
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: 20,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RulePage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RulePage({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome, color: theme.accent, size: 32),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              style: TextStyle(
                color: theme.text,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 18,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
