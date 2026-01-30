import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_diary/presentation/screens/home/home_viewmodel.dart';
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

  // 设计稿尺寸 (Figma)
  static const double _designWidth = 393.0;
  static const double _designHeight = 852.0;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();

    return Scaffold(
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 房间背景
                _buildRoomBackground(viewModel),

                // 点击热区
                _buildHotspots(context, viewModel),

                // 设置按钮
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white70),
                    onPressed: () => _navigateToSettings(context),
                  ),
                ),
              ],
            ),
    );
  }

  /// 房间背景图
  Widget _buildRoomBackground(HomeViewModel viewModel) {
    return Positioned.fill(
      child: Image.asset(
        viewModel.isDrawerOpen
            ? 'assets/images/room/room_drawer_open.jpg'
            : 'assets/images/room/room_drawer_closed.jpg',
        fit: BoxFit.cover,
      ),
    );
  }

  /// 点击热区
  Widget _buildHotspots(BuildContext context, HomeViewModel viewModel) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // 计算缩放比例
        final scaleX = screenWidth / _designWidth;
        final scaleY = screenHeight / _designHeight;

        if (viewModel.isDrawerOpen) {
          return _buildDrawerOpenHotspots(context, viewModel, scaleX, scaleY);
        } else {
          return _buildDrawerClosedHotspots(context, viewModel, scaleX, scaleY);
        }
      },
    );
  }

  /// 抽屉关闭状态的热区
  Widget _buildDrawerClosedHotspots(
    BuildContext context,
    HomeViewModel viewModel,
    double scaleX,
    double scaleY,
  ) {
    return Stack(
      children: [
        // 日历点击区域 (右上角)
        Positioned(
          left: 263.5 * scaleX,
          top: 44 * scaleY,
          width: 128.5 * scaleX,
          height: 144 * scaleY,
          child: GestureDetector(
            onTap: () => _navigateToCalendar(context, viewModel),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 相框点击区域 (左侧墙上)
        Positioned(
          left: 5 * scaleX,
          top: 250.5 * scaleY,
          width: 113.5 * scaleX,
          height: 206 * scaleY,
          child: GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 抽屉点击区域 (底部)
        Positioned(
          left: 66 * scaleX,
          top: 538 * scaleY,
          width: 79 * scaleX,
          height: 92.5 * scaleY,
          child: GestureDetector(
            onTap: () => viewModel.toggleDrawer(),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  /// 抽屉打开状态的热区
  Widget _buildDrawerOpenHotspots(
    BuildContext context,
    HomeViewModel viewModel,
    double scaleX,
    double scaleY,
  ) {
    return Stack(
      children: [
        // 日历点击区域 (右上角)
        Positioned(
          left: 264 * scaleX,
          top: 44 * scaleY,
          width: 128.5 * scaleX,
          height: 144 * scaleY,
          child: GestureDetector(
            onTap: () => _navigateToCalendar(context, viewModel),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 相框点击区域 (左侧墙上)
        Positioned(
          left: 10 * scaleX,
          top: 250 * scaleY,
          width: 113.5 * scaleX,
          height: 206 * scaleY,
          child: GestureDetector(
            onTap: () => _navigateToProfile(context),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 抽屉点击区域 (关闭抽屉)
        Positioned(
          left: 133 * scaleX,
          top: 571 * scaleY,
          width: 79 * scaleX,
          height: 92.5 * scaleY,
          child: GestureDetector(
            onTap: () => viewModel.toggleDrawer(),
            child: Container(color: Colors.transparent),
          ),
        ),

        // 日记点击区域 (抽屉内的日记本)
        Positioned(
          left: 93 * scaleX,
          top: 556.5 * scaleY,
          width: 80.5 * scaleX,
          height: 47.5 * scaleY,
          child: GestureDetector(
            onTap: () => _navigateToDiary(context),
            child: Container(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToCalendar(BuildContext context, HomeViewModel viewModel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
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

  void _navigateToSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }
}
