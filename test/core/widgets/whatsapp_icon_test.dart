import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/widgets/whatsapp_icon.dart';

void main() {
  testWidgets('WhatsAppIcon merender logo SVG asli dengan ukuran yang diminta', (t) async {
    await t.pumpWidget(
      const MaterialApp(home: Scaffold(body: WhatsAppIcon(size: 30))),
    );
    await t.pumpAndSettle();

    final svg = t.widget<SvgPicture>(find.byType(SvgPicture));
    expect(svg.width, 30);
    expect(svg.height, 30);
    expect(t.takeException(), isNull);
  });
}
