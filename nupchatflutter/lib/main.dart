import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'services/chat_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NupChatApp());
}

/// NupChat - Decentralized P2P Messaging
///
/// A Flutter implementation of the NupChat iOS app with:
/// - Bluetooth mesh networking for offline communication
/// - Nostr protocol for global reach
/// - Location-based channels using geohash
/// - IRC-style commands
class NupChatApp extends StatelessWidget {
  const NupChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ChatService())],
      child: MaterialApp(
        title: 'NupChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
