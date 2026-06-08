import 'package:bestme/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GrowthOS app smoke test', (tester) async {
    await tester.pumpWidget(const GrowthOSApp());
    await tester.pump();
  });
}
