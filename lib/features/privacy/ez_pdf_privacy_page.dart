import 'package:flutter/material.dart';

import '../../core/constants/app_links.dart';

class EzPdfPrivacyPage extends StatelessWidget {
  const EzPdfPrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EZ PDF 개인정보 처리방침')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'EZ PDF는 사용자의 개인정보를 수집하거나 저장하지 않습니다.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          const _PolicyItem('업로드된 이미지는 서버에 저장되지 않습니다.'),
          const _PolicyItem('모든 변환은 브라우저 또는 앱 내부에서 처리됩니다.'),
          const SizedBox(height: 24),
          Text('문의: ${AppLinks.contactEmail}'),
          const SizedBox(height: 8),
          const Text('시행일: 2026년 5월 15일'),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final String text;

  const _PolicyItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
