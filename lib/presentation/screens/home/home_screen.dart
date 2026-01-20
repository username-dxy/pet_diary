import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_diary/presentation/screens/home/home_viewmodel.dart';
import 'package:pet_diary/presentation/screens/home/widgets/calendar_wall_widget.dart';
import 'package:pet_diary/presentation/screens/home/widgets/drawer_widget.dart';
import 'package:pet_diary/presentation/screens/home/widgets/photo_frame_widget.dart';
import 'package:pet_diary/presentation/screens/calendar/calendar_screen.dart';
import 'package:pet_diary/presentation/screens/diary/diary_screen.dart';
import 'package:pet_diary/presentation/screens/profile/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel()..loadData(),
      child: const _HomeScreenContent(),
    );
  }
}

class _HomeScreenContent extends StatelessWidget {
  const _HomeScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // 墙上日历区域
                  Center(
                    child: GestureDetector(
                      onTap: () => _navigateToCalendar(context, viewModel),
                      child: CalendarWallWidget(
                        todaySticker: viewModel.todaySticker,
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // 桌子区域
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 抽屉
                        GestureDetector(
                          onTap: () => _navigateToDiary(context),
                          child: DrawerWidget(
                            hasNewDiary: viewModel.hasNewDiary,
                          ),
                        ),

                        // 相框
                        GestureDetector(
                          onTap: () => _navigateToProfile(context),
                          child: PhotoFrameWidget(
                            pet: viewModel.currentPet,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Future<void> _navigateToCalendar(BuildContext context, HomeViewModel viewModel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
    // 从日历页返回后刷新数据
    viewModel.refresh();
  }

  void _navigateToDiary(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DiaryScreen()),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }
}