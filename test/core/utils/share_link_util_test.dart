import 'package:flutter_test/flutter_test.dart';
import 'package:hris_flutter/app/routes/route_name.dart';
import 'package:hris_flutter/core/constants/api_endpoints.dart';
import 'package:hris_flutter/core/utils/share_link_util.dart';

void main() {
  group('ShareLinkUtil.webUrl', () {
    test('menyusun URL web dari base URL dan path modul', () {
      expect(
        ShareLinkUtil.webUrl(ShareModule.leave, 'abc-123'),
        '${ApiEndpoints.webBaseUrl}/approval/leaves/abc-123',
      );
      expect(
        ShareLinkUtil.webUrl(ShareModule.activity, 'act-1'),
        '${ApiEndpoints.webBaseUrl}/report/activities/act-1',
      );
      expect(
        ShareLinkUtil.webUrl(ShareModule.employee, 'emp-101'),
        '${ApiEndpoints.webBaseUrl}/employee/emp-101',
      );
    });
  });

  group('ShareLinkUtil.toAppLocation', () {
    String? map(String url) => ShareLinkUtil.toAppLocation(Uri.parse(url));

    test('memetakan seluruh modul dan deep link profil ke route aplikasi', () {
      const host = 'https://app.hroasish.com';
      expect(map('$host/approval/leaves/l1'),
          '${Routes.LEAVE_DETAIL}?id=l1&isApprover=true');
      expect(map('$host/approval/overtimes/o1'),
          '${Routes.OVERTIME_DETAIL}?id=o1&isApprover=true');
      expect(map('$host/approval/attendances/a1'),
          '${Routes.ATTENDANCE_REQUEST_DETAIL}?id=a1&isApprover=true');
      expect(map('$host/approval/reimbursements/r1'),
          '${Routes.REIMBURSEMENT_DETAIL}?id=r1');
      expect(map('$host/approval/cash-advances/c1'),
          '${Routes.CASH_ADVANCE_DETAIL}?id=c1');
      expect(map('$host/approval/resignation/s1'), Routes.RESIGNATION);
      expect(map('$host/report/activities/x1'),
          '${Routes.ACTIVITY_DETAIL}?id=x1');
      const empId = '3f2b8c1e-9d4a-4e6b-8a57-1c2d3e4f5a6b';
      expect(map('$host/employees/$empId'),
          '${Routes.EMPLOYEE_DETAIL}?id=$empId');
      expect(map('$host/employee/$empId'),
          '${Routes.EMPLOYEE_DETAIL}?id=$empId');
    });

    test('webUrl dan toAppLocation saling cocok untuk semua modul', () {
      for (final module in ShareModule.values) {
        final url = ShareLinkUtil.webUrl(
            module, '3f2b8c1e-9d4a-4e6b-8a57-1c2d3e4f5a6b');
        expect(ShareLinkUtil.toAppLocation(Uri.parse(url)), isNotNull,
            reason: module.name);
      }
    });

    test('mengembalikan null untuk path yang bukan link pengajuan', () {
      expect(map('/approval/leaves'), isNull);
      expect(map('/approval/unknown/1'), isNull);
      expect(map('/dashboard'), isNull);
      expect(map('/employee/create'), isNull);
      expect(map('/employee/leave-balance'), isNull);
      expect(map('/'), isNull);
    });
  });

  group('ShareLinkUtil.pendingLink', () {
    test('hanya meneruskan link pengajuan yang dikenali', () {
      expect(
        ShareLinkUtil.pendingLink(Uri.parse('/splash?from=/approval/leaves/l1')),
        '/approval/leaves/l1',
      );
      expect(ShareLinkUtil.pendingLink(Uri.parse('/splash?from=/payroll')),
          isNull);
      expect(ShareLinkUtil.pendingLink(Uri.parse('/login')), isNull);
    });
  });

  group('WhatsApp & Email', () {
    test('menormalisasi nomor HP ke format 62', () {
      expect(ShareLinkUtil.normalizeWhatsAppPhone('0812-3456-789'), '628123456789');
      expect(ShareLinkUtil.normalizeWhatsAppPhone('+62 812 3456'), '628123456');
      expect(ShareLinkUtil.normalizeWhatsAppPhone('8123'), '628123');
    });

    test('whatsAppUri berisi nomor dan pesan', () {
      final uri = ShareLinkUtil.whatsAppUri('0812', 'Halo Pak\nlink');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/62812');
      expect(uri.queryParameters['text'], 'Halo Pak\nlink');
    });

    test('emailUri meng-encode spasi sebagai %20, bukan +', () {
      final uri = ShareLinkUtil.emailUri(
        'atasan@kantor.id',
        subject: 'Cuti Budi',
        body: 'Mohon approve',
      );
      expect(uri.scheme, 'mailto');
      expect(uri.path, 'atasan@kantor.id');
      expect(uri.toString(), contains('subject=Cuti%20Budi'));
      expect(uri.toString(), isNot(contains('+')));
    });

    test('whatsAppShareUri membuka send tanpa nomor dengan pesan terisi', () {
      final uri = ShareLinkUtil.whatsAppShareUri('Halo ini link profil');
      expect(uri.host, 'api.whatsapp.com');
      expect(uri.path, '/send');
      expect(uri.queryParameters['text'], 'Halo ini link profil');
    });

    test('emailShareUri tanpa penerima menyiapkan subject dan body', () {
      final uri = ShareLinkUtil.emailShareUri(
        subject: 'Profil Karyawan',
        body: 'Berikut link profil',
      );
      expect(uri.scheme, 'mailto');
      expect(uri.path, isEmpty);
      expect(uri.toString(), contains('subject=Profil%20Karyawan'));
      expect(uri.toString(), contains('body=Berikut%20link%20profil'));
    });
  });

  test('ApproverShareArgs.message menyertakan ringkasan dan link', () {
    const args = ApproverShareArgs(
      module: ShareModule.overtime,
      requestId: 'o1',
      summary: 'Ringkasan',
      subject: 'Lembur',
    );
    expect(args.message, contains('Ringkasan'));
    expect(args.message, contains(args.url));
  });
}
