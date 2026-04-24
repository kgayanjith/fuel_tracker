import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:fuel_tracker/screens/reports.dart';
import '../screens/home.dart';
import '../screens/generators.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final BottomBarController _controller = BottomBarController();
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<String> _labels = ["Home", "Generators", "Reports"];

  final List<IconData> _icons = [
    Icons.home,
    Icons.grid_view_sharp,
    Icons.file_copy,
  ];

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        Widget screen;
        switch (index) {
          case 0:
            screen = const HomeScreen();
            break;
          case 1:
            screen = const GeneratorsScreen();
            break;
          case 2:
            screen = const ReportsList();
            break;
          default:
            screen = const SizedBox();
        }
        return MaterialPageRoute(builder: (_) => screen);
      },
    );
  }

  Future<bool> _onWillPop() async {
    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BottomBar(
        controller: _controller,
        borderRadius: BorderRadius.circular(80),
        child: Container(
          height: 60,
          width: 300,
          margin: const EdgeInsets.symmetric(horizontal: 35),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(80),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_icons.length, (index) => _navItem(index)),
          ),
        ),
        body: (context, controller) {
          return IndexedStack(
            index: _currentIndex,
            children: List.generate(3, (index) => _buildTabNavigator(index)),
          );
        },
      ),
    );
  }

  Widget _navItem(int index) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        if (_currentIndex == index) {
          _navigatorKeys[index].currentState?.popUntil(
            (route) => route.isFirst,
          );
        } else {
          setState(() => _currentIndex = index);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icons[index],
                color: isActive ? Colors.black : Colors.white,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: isActive
                  ? Column(
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          _labels[index],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
