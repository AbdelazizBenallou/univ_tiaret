import 'package:flutter/material.dart';

class SocialLink {
  final IconData icon;
  final String label;
  final String url;

  const SocialLink({
    required this.icon,
    required this.label,
    required this.url,
  });
}

class TeamMember {
  final String nameKey;
  final String roleKey;
  final String bioKey;
  final IconData avatarIcon;
  final List<SocialLink> socialLinks;

  const TeamMember({
    required this.nameKey,
    required this.roleKey,
    required this.bioKey,
    required this.avatarIcon,
    required this.socialLinks,
  });
}

final teamMembers = [
  const TeamMember(
    nameKey: 'dev_name',
    roleKey: 'dev_role',
    bioKey: 'dev_bio',
    avatarIcon: Icons.person_rounded,
    socialLinks: [
      SocialLink(
        icon: Icons.phone,
        label: '0558340669',
        url: 'tel:0558340669',
      ),
      SocialLink(
        icon: Icons.send,
        label: 'Telegram',
        url: 't.me/aziz_benallou',
      ),
      SocialLink(
        icon: Icons.smart_display,
        label: 'YouTube',
        url: 'youtube.com/@abdelazizbenallou',
      ),
      SocialLink(
        icon: Icons.business_center,
        label: 'LinkedIn',
        url: 'www.linkedin.com/in/abdelaziz-benallou-1a0428377',
      ),
      SocialLink(
        icon: Icons.code,
        label: 'GitHub',
        url: 'github.com/AbdelazizBenallou',
      ),
    ],
  ),
];
