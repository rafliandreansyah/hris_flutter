import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/constants/app_contacts.dart';

void main() {
  test('whatsappUrl memakai nomor dan pesan yang sudah di-encode', () {
    final url = AppContacts.whatsappUrl;
    expect(url, contains('phone=${AppContacts.whatsappNumber}'));
    expect(url, contains('text=Halo%20Tim%20Oasish'));
    expect(url, isNot(contains(' ')));
  });

  test('nomor WhatsApp tidak mengandung karakter non-digit', () {
    expect(RegExp(r'^\d+$').hasMatch(AppContacts.whatsappNumber), isTrue);
  });
}
