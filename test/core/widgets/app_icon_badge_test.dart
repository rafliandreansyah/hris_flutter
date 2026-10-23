import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/app/config/app_colors.dart';
import 'package:hris_flutter/core/widgets/app_icon_badge.dart';
import 'package:hris_flutter/core/widgets/whatsapp_icon.dart';

void main() {
  testWidgets('logo brand tidak melar memenuhi badge (tetap berukuran ikon, di tengah)', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppIconBadge(
              color: AppColors.whatsappGreen,
              child: WhatsAppIcon(size: 20),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();

    expect(t.getSize(find.byType(AppIconBadge)), const Size(40, 40));
    expect(t.getSize(find.byType(WhatsAppIcon)), const Size(20, 20));
    expect(t.getCenter(find.byType(WhatsAppIcon)), t.getCenter(find.byType(AppIconBadge)));
  });

  testWidgets('ikon bawaan dan logo memakai wrapper yang sama ukurannya', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(children: [
            AppIconBadge(icon: Icons.mail, color: AppColors.brandTeal),
            AppIconBadge(color: AppColors.whatsappGreen, child: WhatsAppIcon(size: 20)),
          ]),
        ),
      ),
    );
    await t.pumpAndSettle();
    final sizes = t.widgetList(find.byType(AppIconBadge)).map((w) => t.getSize(find.byWidget(w)));
    expect(sizes.toSet().length, 1);
  });
}
