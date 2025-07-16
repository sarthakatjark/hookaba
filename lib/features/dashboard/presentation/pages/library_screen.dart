import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hookaba/core/common_widgets/primary_bottom_nav_bar.dart';
import 'package:hookaba/core/common_widgets/primary_button.dart';
import 'package:hookaba/core/utils/app_fonts.dart';
import 'package:hookaba/core/utils/enum.dart';
import 'package:hookaba/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:hookaba/features/dashboard/presentation/widgets/show_library_upload_modal.dart';

class LibraryScreen extends HookWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardCubit = context.read<DashboardCubit>();
    final scrollController = useScrollController();
    final selectedTab = useState(0); // 0: All, 1: Animations, 2: Images, 3: GIF
    final selectedIndex = useState<int?>(null); // Track selected image index

    useEffect(() {
      dashboardCubit.fetchLibraryItems();
      void onScroll() {
        final state = context.read<DashboardCubit>().state;
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200 &&
            !state.isLoadingMore &&
            state.currentPage < state.totalPages) {
          dashboardCubit.fetchLibraryItems(page: state.currentPage + 1, loadMore: true);
        }
      }
      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, []);

    Widget _buildTab(String text, int index, ValueNotifier<int> selectedTab) {
      final isSelected = selectedTab.value == index;
      return GestureDetector(
        onTap: () => selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  _buildTab('All', 0, selectedTab),
                  const SizedBox(width: 12),
                  _buildTab('Animations', 1, selectedTab),
                  const SizedBox(width: 12),
                  _buildTab('Images', 2, selectedTab),
                  
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state.status == DashboardStatus.loading && state.libraryItems.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == DashboardStatus.error) {
                  return Center(child: Text(state.errorMessage ?? 'Error'));
                }
                final items = state.libraryItems;
                // TODO: Filter items based on selectedTab.value if you have type info
                return Stack(
                  children: [
                    GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isSelected = selectedIndex.value == index;
                        return GestureDetector(
                          onTap: () {
                            selectedIndex.value = index;
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1A33),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: Colors.blue, width: 3)
                                  : null,
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: item.imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: item.imageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) => const Center(child: Icon(Icons.broken_image, size: 70, color: Colors.white24)),
                                        )
                                      : const Center(child: Icon(Icons.image, size: 70, color: Colors.white24)),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.userId,
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (state.isLoadingMore)
                      const Positioned(
                        left: 0, right: 0, bottom: 16,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
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
          onPressed: selectedIndex.value != null
              ? () {
                  final selected = selectedIndex.value;
                  if (selected != null) {
                    final item = context.read<DashboardCubit>().state.libraryItems[selected];
                    showLibraryUploadModal(context, item, dashboardCubit);
                  }
                }
              : null,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
} 