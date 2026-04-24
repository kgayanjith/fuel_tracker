import 'package:flutter/material.dart';
import 'package:fuel_tracker/widgets/appbar.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  String _version = '';
  final String _flutterVersion = 'v3.1.4';

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  Future<void> _getVersion() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "App Info",
        leadingIconType: LeadingIconType.back,
        showInfoIcon: true,
        avatarPath: 'assets/profile.png',
        onLeadingIconTap: () => Navigator.pop(context),
      ),
      // backgroundColor: Colors.white,
      extendBodyBehindAppBar: false,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Image(
                    image: AssetImage('assets/info.png'),
                    width: 275,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              Text(
                'Version : $_version',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 4),

              Text(
                'Flutter  $_flutterVersion',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 12),

              Text(
                'Developed by: Kalindu Gayanjith',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
