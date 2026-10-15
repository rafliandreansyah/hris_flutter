import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/core/utils/currency_util.dart';
import 'package:hris_flutter/core/utils/terbilang_helper.dart';

void main() {
  group('CurrencyUtil Tests', () {
    test('formats null as Rp 0', () {
      expect(formatRupiah(null), equals('Rp 0'));
    });

    test('formats 0 as Rp 0', () {
      expect(formatRupiah(0), equals('Rp 0'));
    });

    test('formats regular Rupiah numbers correctly', () {
      expect(formatRupiah(250000), equals('Rp 250.000'));
      expect(formatRupiah(1500000), equals('Rp 1.500.000'));
      expect(formatRupiah(10000000), equals('Rp 10.000.000'));
    });

    test('formats compact Rupiah numbers correctly when compact is true', () {
      expect(formatRupiah(1500000, compact: true), equals('Rp 1,5 jt'));
      expect(formatRupiah(2000000, compact: true), equals('Rp 2 jt'));
      expect(formatRupiah(25000000, compact: true), equals('Rp 25 jt'));
      // Below 1 million, compact stays normal format
      expect(formatRupiah(500000, compact: true), equals('Rp 500.000'));
    });
  });

  group('TerbilangHelper Tests', () {
    test('handles zero and negative amounts', () {
      expect(angkaKeTerbilang(0), equals('Nol Rupiah'));
      expect(angkaKeTerbilang(-5000), equals('Minus Lima Ribu Rupiah'));
    });

    test('desimal dipotong ke bawah (bagian sen diabaikan)', () {
      expect(angkaKeTerbilang(1500.99), equals('Seribu Lima Ratus Rupiah'));
    });

    test('angka batas ribuan, puluhan ribu, dan ratusan ribu', () {
      expect(angkaKeTerbilang(11000), equals('Sebelas Ribu Rupiah'));
      expect(angkaKeTerbilang(100000), equals('Seratus Ribu Rupiah'));
      expect(angkaKeTerbilang(1001000), equals('Satu Juta Seribu Rupiah'));
      expect(angkaKeTerbilang(111111), equals('Seratus Sebelas Ribu Seratus Sebelas Rupiah'));
    });

    test('converts trillions (triliun)', () {
      expect(angkaKeTerbilang(1000000000000), equals('Satu Triliun Rupiah'));
      expect(
        angkaKeTerbilang(2000500000000),
        equals('Dua Triliun Lima Ratus Juta Rupiah'),
      );
    });

    test('converts basic single units and teens', () {
      expect(angkaKeTerbilang(1), equals('Satu Rupiah'));
      expect(angkaKeTerbilang(7), equals('Tujuh Rupiah'));
      expect(angkaKeTerbilang(10), equals('Sepuluh Rupiah'));
      expect(angkaKeTerbilang(11), equals('Sebelas Rupiah'));
      expect(angkaKeTerbilang(12), equals('Dua Belas Rupiah'));
      expect(angkaKeTerbilang(19), equals('Sembilan Belas Rupiah'));
    });

    test('converts tens and hundreds', () {
      expect(angkaKeTerbilang(20), equals('Dua Puluh Rupiah'));
      expect(angkaKeTerbilang(45), equals('Empat Puluh Lima Rupiah'));
      expect(angkaKeTerbilang(100), equals('Seratus Rupiah'));
      expect(angkaKeTerbilang(105), equals('Seratus Lima Rupiah'));
      expect(angkaKeTerbilang(250), equals('Dua Ratus Lima Puluh Rupiah'));
    });

    test('converts thousands and millions', () {
      expect(angkaKeTerbilang(1000), equals('Seribu Rupiah'));
      expect(angkaKeTerbilang(1500), equals('Seribu Lima Ratus Rupiah'));
      expect(angkaKeTerbilang(250000), equals('Dua Ratus Lima Puluh Ribu Rupiah'));
      expect(angkaKeTerbilang(1000000), equals('Satu Juta Rupiah'));
      expect(angkaKeTerbilang(1500000), equals('Satu Juta Lima Ratus Ribu Rupiah'));
      expect(angkaKeTerbilang(12500000), equals('Dua Belas Juta Lima Ratus Ribu Rupiah'));
    });

    test('converts billions (milyar)', () {
      expect(angkaKeTerbilang(1000000000), equals('Satu Milyar Rupiah'));
      expect(
        angkaKeTerbilang(2500000000),
        equals('Dua Milyar Lima Ratus Juta Rupiah'),
      );
    });
  });
}
