import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pet_diary/config/api_config.dart';
import 'package:pet_diary/data/repositories/pet_repository.dart';
import 'package:pet_diary/domain/services/profile_service.dart';
import 'package:pet_diary/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:pet_diary/presentation/screens/home/home_screen.dart';
import 'package:pet_diary/presentation/screens/profile_setup/profile_setup_screen.dart';
import 'package:pet_diary/presentation/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 检查是否已有宠物 profile
  final petRepo = PetRepository();
  final pet = await petRepo.getCurrentPet();
  var hasProfile = pet != null && pet.name.isNotEmpty;

  // 恢复 token
  if (hasProfile) {
    await ApiConfig.setToken(pet.id);

    // 开发环境启动校验：服务端明确无档案时，清除本地缓存，避免“服务端空但仍显示旧档案”
    if (ApiConfig.environment == Environment.development) {
      try {
        final serverPet = await ProfileService.api().fetchProfile(pet.id);
        if (serverPet == null) {
          await petRepo.clearPet();
          await ApiConfig.clearToken();
          hasProfile = false;
        } else {
          // 服务端有更新时，回写本地，保持一致
          await petRepo.savePet(serverPet);
        }
      } catch (_) {
        // 网络异常/服务不可用时保留本地档案，避免离线不可用
      }
    }
  }

  runApp(MyApp(initialRoute: hasProfile ? '/home' : '/onboarding'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pet Diary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // 本地化配置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'), // 中文简体
        Locale('en', 'US'), // 英语
      ],
      locale: const Locale('zh', 'CN'),
      initialRoute: initialRoute,
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/profile-setup': (context) => const ProfileSetupScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
