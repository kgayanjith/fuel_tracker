import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/mainlayout.dart';

class OnboardingData {
  final String imagePath;
  final String title;
  final String desc;

  OnboardingData({
    required this.imagePath,
    required this.title,
    required this.desc,
  });
}

final List<OnboardingData> onboardingList = [
  OnboardingData(
    imagePath: "assets/onboardimage.jpg",
    title: "Monitor Fuel Usage",
    desc: "Track your generators and fuel consumption easily and efficiently.",
  ),
  OnboardingData(
    imagePath: "assets/onboardmanage.jpg",
    title: "Manage Fuel Efficiency",
    desc:
        "Request fuel for your generators quickly and manage deliveries seamlessly.",
  ),
  OnboardingData(
    imagePath: "assets/onboardlast.jpg",
    title: "Track Every Usage",
    desc: "Keep detailed logs of fuel usage for better control.",
  ),
];

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  int currentIndex = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentData = onboardingList[currentIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 50),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
                child: Image.asset(
                  currentData.imagePath,
                  key: ValueKey(currentData.imagePath),
                  height: 400,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 40),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  currentData.title,
                  key: ValueKey(currentData.title),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  currentData.desc,
                  key: ValueKey(currentData.desc),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  currentIndex == 0
                      ? const SizedBox(width: 60)
                      : ElevatedButton(
                          onPressed: () => setState(() => currentIndex--),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            fixedSize: const Size(64, 64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_rounded,
                            color: Colors.white,
                            size: 24,
                            fontWeight: FontWeight(700),
                          ),
                        ),
                  const SizedBox(width: 17),

                  currentIndex < onboardingList.length - 1
                      ? ElevatedButton(
                          onPressed: () => setState(() => currentIndex++),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            fixedSize: const Size(64, 64),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white,
                            size: 24,
                            fontWeight: FontWeight(700),
                          ),
                        )
                      : Expanded(
                          child: ElevatedButton(
                            onPressed: _completeOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              fixedSize: const Size(double.infinity, 64),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Get Started",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
