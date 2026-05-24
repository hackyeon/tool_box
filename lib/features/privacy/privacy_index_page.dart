import 'package:flutter/material.dart';

import '../../app.dart';

class PrivacyIndexPage extends StatelessWidget {
  const PrivacyIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('개인정보 처리방침')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '앱별 개인정보 처리방침은 아래에서 확인하실 수 있습니다.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Text('📄', style: TextStyle(fontSize: 24)),
              title: const Text('EZ PDF 개인정보 처리방침'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed(App.routeEzPdfPrivacy),
            ),
          ),
        ],
      ),
    );
  }
}
