import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../core/ads/ad_support.dart';
import '../../core/ads/banner_ad_widget.dart';
import '../../core/constants/app_links.dart';

class SuperAppHomePage extends StatelessWidget {
  const SuperAppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HeroSection()),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '앱 리스트',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 20),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 640;
                            return GridView.count(
                              crossAxisCount: isWide ? 2 : 1,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.15,
                              children: const [
                                _ToolCard(
                                  icon: '📄',
                                  title: 'EZ PDF',
                                  description: '이미지를 간편하게 PDF로 변환할 수 있는 무료 도구입니다.',
                                  buttonText: '시작하기',
                                  routeName: App.routeEzPdf,
                                ),
                                _ToolCard(
                                  icon: '🛠️',
                                  title: '준비 중',
                                  description: '다음으로 만들 작은 도구를 준비하고 있습니다.',
                                  buttonText: 'Coming Soon',
                                ),
                              ],
                            );
                          },
                        ),
                        if (isMobileAdSupported) ...[
                          const SizedBox(height: 28),
                          const Center(child: BannerAdWidget()),
                        ],
                        const SizedBox(height: 40),
                        const _ContactCard(),
                        const SizedBox(height: 28),
                        const _Footer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F8CFF), Color(0xFF7C5CFF)],
        ),
      ),
      child: Column(
        children: [
          Text(
            '일상을 편안하게 해주는 앱을 만들어요',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '작지만 유용한 도구들을 하나의 앱에서 사용할 수 있습니다.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String buttonText;
  final String? routeName;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = routeName != null;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
              ),
            ),
            FilledButton(
              onPressed: enabled ? () => Navigator.of(context).pushNamed(routeName!) : null,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '문의',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            const Text('서비스 이용 중 문의사항이나 제안이 있다면 아래 메일로 연락해주세요.'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _launchMail(context),
              child: Text(
                AppLinks.contactEmail,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchMail(BuildContext context) async {
    final uri = Uri(scheme: 'mailto', path: AppLinks.contactEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('메일 앱을 열 수 없습니다.')),
      );
    }
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(
                'https://skek933.cafe24.com/privacy',
              );
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
            },
            child: const Text('개인정보 처리방침'),
          ),
          Text(
            '© 2026 Hackyeon Kim. All rights reserved.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
