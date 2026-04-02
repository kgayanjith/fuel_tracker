import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
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

  final List<Widget> _screens = const [
    HomeScreen(),
    GeneratorsScreen(),
    Center(child: Text("Reports")),
  ];

  final List<String> _labels = ["Home", "Generators", "Reports"];

  final List<IconData> _icons = [
    Icons.home,
    Icons.grid_view_sharp,
    Icons.file_copy,
  ];

  @override
  Widget build(BuildContext context) {
    return BottomBar(
      controller: _controller,
      borderRadius: BorderRadius.circular(80),

      child: Container(
        height: 60,
        width: 300,
        margin: const EdgeInsets.symmetric(horizontal: 45),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(80),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (index) {
            return _navItem(index);
          }),
        ),
      ),

      // 🔻 Body
      body: (context, controller) {
        return IndexedStack(index: _currentIndex, children: _screens);
      },
    );
  }

  Widget _navItem(int index) {
    final bool isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              color: isActive
                  ? Colors.black
                  : const Color.fromARGB(255, 255, 255, 255),
              size: 24,
            ),
          ),
          if (isActive) ...[
            const SizedBox(height: 4),

            Text(
              _labels[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
