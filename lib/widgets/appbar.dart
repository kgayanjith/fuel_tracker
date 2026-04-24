import 'package:flutter/material.dart';
import 'package:fuel_tracker/screens/info.dart';

enum LeadingIconType { back, notification, none }

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final LeadingIconType leadingIconType;
  final bool showInfoIcon;
  final String? avatarPath;
  final VoidCallback? onLeadingIconTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leadingIconType = LeadingIconType.none,
    this.showInfoIcon = true,
    this.avatarPath = 'assets/profile.png',
    this.onLeadingIconTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget? leading;

    switch (leadingIconType) {
      case LeadingIconType.back:
        leading = IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onLeadingIconTap ?? () => Navigator.pop(context),
        );
        break;
      case LeadingIconType.notification:
        leading = IconButton(
          onPressed: () {},
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_outlined,
                size: 28,
                color: Colors.black,
              ),
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        );
        break;
      case LeadingIconType.none:
        leading = null;
        break;
    }

    return AppBar(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      centerTitle: true,

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: leading,
      actions: [
        if (showInfoIcon)
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Info()),
            ),
            icon: const Icon(Icons.info_outline, color: Colors.black),
          ),
        const SizedBox(width: 2),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),

          child: CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(avatarPath!),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}
