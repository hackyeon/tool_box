import 'package:flutter_test/flutter_test.dart';

import 'package:tool_box/app.dart';

void main() {
  testWidgets('home shows available tools', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('EZ PDF'), findsOneWidget);
    expect(find.text('QR 생성기'), findsOneWidget);
    expect(find.text('이미지 도구'), findsOneWidget);
  });
}
