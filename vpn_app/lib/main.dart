import 'dart:async';
import 'package:flutter/material.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: const VPNHomePage(),
    );
  }
}

class VPNHomePage extends StatefulWidget {
  const VPNHomePage({super.key});

  @override
  _VPNHomePageState createState() => _VPNHomePageState();
}

class _VPNHomePageState extends State<VPNHomePage> {
  bool _socialMediaOnly = true;
  Duration _remainingTime = const Duration(hours: 0, minutes: 0, seconds: 0);
  late Timer _timer;
  bool _isVPNConnected = false;
  late OpenVPN openVPN;
  String? _vpnStatus; // Для хранения текущего статуса VPN

  @override
  void initState() {
    super.initState();
    _remainingTime = const Duration(hours: 1);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime -= const Duration(seconds: 1);
        } else {
          _timer.cancel();
        }
      });
    });

    // Инициализация OpenVPN
    openVPN = OpenVPN(
      onVpnStatusChanged: (status) {
        print('VPN Status: $status');
        setState(() {
          _vpnStatus = status; // Сохраняем статус как строку
          _isVPNConnected = status == "CONNECTED"; // Проверяем статус
        });
      },
      onVpnStageChanged: (stage, raw) {
        print('VPN Stage: $stage, Raw: $raw');
      },
    );
    openVPN.initialize(
      groupIdentifier: 'group.com.kremanitus.vpnapp',
      providerBundleIdentifier: 'com.kremanitus.vpnapp.VPNExtension',
      localizedDescription: 'Kremanitus VPN',
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    openVPN.disconnect();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> _toggleVPN(bool enable) async {
    if (enable) {
      String config = await DefaultAssetBundle.of(context).loadString('assets/amnezia.conf');
      print('Loaded config: $config');
      try {
        openVPN.connect(
          config,
          'Kremanitus VPN',
          username: 'your-username',
          password: 'your-password',
          certIsRequired: false,
        );
      } catch (e) {
        print('Error connecting to VPN: $e');
        setState(() {
          _socialMediaOnly = false;
        });
      }
    } else {
      openVPN.disconnect();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Subscription ended',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              _formatDuration(_remainingTime),
              style: const TextStyle(color: Colors.white, fontSize: 48),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                'For Social Media Only',
                style: TextStyle(color: Colors.white),
              ),
              value: _socialMediaOnly,
              onChanged: (bool value) {
                setState(() {
                  _socialMediaOnly = value;
                });
                _toggleVPN(value);
              },
              activeColor: Colors.green,
            ),
            const SizedBox(height: 10),
            Text(
              _isVPNConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: _isVPNConnected ? Colors.green : Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: ${_vpnStatus ?? "Unknown"}',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _remainingTime = const Duration(hours: 1);
                });
              },
              child: const Text('Add subscription'),
            ),
            const SizedBox(height: 10),
            const Text(
              'To use the service, activate your subscription',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}