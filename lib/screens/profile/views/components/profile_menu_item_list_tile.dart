import 'package:flutter/material.dart';
import 'package:univ_tiaret/components/list_tile/divider_list_tile.dart';

class ProfileMenuListTile extends StatelessWidget {
  const ProfileMenuListTile({
    super.key,
    required this.text,
    required this.icon,
    required this.press,
    this.isShowDivider = true,
  });

  final String text;
  final IconData icon;
  final VoidCallback press;
  final bool isShowDivider;

  @override
  Widget build(BuildContext context) {
    return DividerListTile(
      minLeadingWidth: 24,
      leading: Icon(
        icon,
        size: 24,
        color: Theme.of(context).iconTheme.color,
      ),
      title: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1),
      ),
      press: press,
      isShowDivider: isShowDivider,
    );
  }
}
