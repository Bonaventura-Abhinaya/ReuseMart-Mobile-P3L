import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'views/home/home_guest_page.dart';
import 'views/home/barang_lainnya_page.dart';
import 'views/auth/login_page.dart';
import 'views/dashboard/hunter_dashboard.dart';
import 'views/dashboard/kurir_dashboard.dart';
import 'views/dashboard/penitip_dashboard.dart';
import 'views/dashboard/pembeli_dashboard.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    print("⚠️ Error saat init Firebase di background: $e");
  }

  print("🔕 [TERMINATED] Notifikasi diterima: ${message.messageId}");
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    print("⚠️ Firebase sudah di-initialize sebelumnya: $e");
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final fcmToken = await FirebaseMessaging.instance.getToken();
  print("🔑 FCM Token: $fcmToken");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print("📬 [FOREGROUND] Judul: ${message.notification!.title}");
      print("📬 [FOREGROUND] Isi: ${message.notification!.body}");
    }
  });

  runApp(const ReuseMartApp());
}



class ReuseMartApp extends StatelessWidget {
  const ReuseMartApp({super.key});

  Future<Widget> _getInitialPage() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');

    switch (role) {
      case 'pembeli':
        return const PembeliDashboard();
      case 'penitip':
        return const PenitipDashboard();
      case 'hunter':
        return const HunterDashboard();
      case 'kurir':
        return const KurirDashboard();
      default:
        return const HomeGuestPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReuseMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: FutureBuilder<Widget>(
        future: _getInitialPage(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Terjadi kesalahan saat membuka aplikasi")),
            );
          } else {
            return snapshot.data!;
          }
        },
      ),
      routes: {
        '/barang-lainnya': (context) => const BarangLainnyaPage(),
        '/login': (context) => const LoginPage(),
        '/dashboardPembeli': (context) => const PembeliDashboard(),
        '/dashboardPenitip': (context) => const PenitipDashboard(),
        '/dashboardHunter': (context) => const HunterDashboard(),
        '/dashboardKurir': (context) => const KurirDashboard(),
      },
    );
  }
}
