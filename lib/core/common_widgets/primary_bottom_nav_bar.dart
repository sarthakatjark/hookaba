import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PrimaryBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const PrimaryBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const iconPaths = [
      'assets/images/home.svg',
      'assets/images/settings.svg',
      'assets/images/user.svg',
    ];
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0x80081122),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        currentIndex: currentIndex,
        onTap: onTap,
        items: List.generate(3, (index) {
          final isSelected = currentIndex == index;
          return BottomNavigationBarItem(
            icon: SvgPicture.asset(
              iconPaths[index],
              width: 25,
              height: 25,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : Colors.grey,
                BlendMode.srcIn,
              ),
            ),
            label: '',
          );
        }),
      ),
    );
  }
}