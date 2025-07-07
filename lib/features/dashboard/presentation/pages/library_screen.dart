import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_bottom_nav_bar.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_fonts.dart';

class LibraryScreen extends HookWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(0);
    
    return Scaffold(
      backgroundColor: const Color(0xFF081122),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'LIBRARY',
          style: AppFonts.dashHorizonStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 18.0),
                    child: Text(
                      'Categories',
                      style: AppFonts.audiowideStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _buildTab('Animations', 1, selectedTab),
                  const SizedBox(width: 12),
                  _buildTab('Images', 2, selectedTab),
                  const SizedBox(width: 12),
                  _buildTab('GIF', 3, selectedTab),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: 8, // Example count
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1A33),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Image.asset(
                            'assets/images/hookaba_logo.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Item ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: PrimaryBottomNavBar(
        currentIndex: 1, // Set to the correct index for Library
        onTap: (index) {
          // TODO: Implement navigation logic
        },
      ),
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 32,
        child: PrimaryButton(
          text: 'Proceed',
          onPressed: () {},
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTab(String text, int index, ValueNotifier<int> selectedTab) {
    final isSelected = selectedTab.value == index;
    return GestureDetector(
      onTap: () => selectedTab.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : const Color(0xFF0D1A33),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppFonts.audiowideStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
} 