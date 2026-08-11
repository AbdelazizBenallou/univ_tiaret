import 'package:flutter/material.dart';
import 'package:univ_tiaret/components/modern_list_tile.dart';
import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/models/team_member.dart';
import 'package:univ_tiaret/screens/settings/views/member_detail_screen.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('about_us')),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: teamMembers.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final member = teamMembers[index];
          return ModernListTile(
            icon: member.avatarIcon,
            title: t.translate(member.nameKey),
            subtitle: t.translate(member.roleKey),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberDetailScreen(member: member),
              ),
            ),
          );
        },
      ),
    );
  }
}
