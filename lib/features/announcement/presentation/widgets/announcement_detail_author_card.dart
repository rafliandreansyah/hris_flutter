import 'package:flutter/material.dart';
import 'package:hris_flutter/core/widgets/request_detail_person_card.dart';
import 'package:hris_flutter/features/announcement/data/models/announcement_detail_model.dart';

/// Kartu "Diterbitkan oleh" pada detail pengumuman. Memakai
/// [RequestDetailPersonCard] agar nama, jabatan, dan perusahaan tidak terpotong.
class AnnouncementDetailAuthorCard extends StatelessWidget {
  final AnnouncementAuthor author;

  const AnnouncementDetailAuthorCard({super.key, required this.author});

  @override
  Widget build(BuildContext context) {
    return RequestDetailPersonCard(
      title: 'Diterbitkan oleh',
      name: author.fullName,
      position: author.position?.name,
      department: author.department?.name,
      company: author.company?.name,
      avatarUrl: author.photoUrl,
      initials: author.initials,
    );
  }
}
