import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await MobileAds.instance.initialize();
  AdManager.instance.loadInterstitial();
  AdManager.instance.loadRewarded();
  runApp(const SunnyDuneDashApp());
}

class SunnyDuneDashApp extends StatelessWidget {
  const SunnyDuneDashApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Sunny Dune Dash',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.orange,
          useMaterial3: true,
        ),
        home: const MenuScreen(),
      );
}

// ───────────────────────── MENU ─────────────────────────

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF29B6F6),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🏝️', style: TextStyle(fontSize: 80)),
                    const Text(
                      'SUNNY DUNE\nDASH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black38)],
                      ),
                    ),
                    const SizedBox(height: 40),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 16),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 32),
                      label: const Text('JOUER',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Glisse le doigt pour piloter.\nÉvite les rochers, ramasse les pièces !',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── JEU ─────────────────────────

enum ItemType { rock, coin, boost }

class Item {
  Item(this.type, this.x, this.y);
  final ItemType type;
  final double x; // 0..1 sur la largeur de la piste
  double y; // 0..1 sur la hauteur de l'écran
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const double playerY = 0.82;
  static int _gamesPlayed = 0;
  static int _best = 0;

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final Random _rnd = Random();
  final List<Item> _items = [];
  Size _size = Size.zero;

  double _playerX = 0.5;
  double _distance = 0; // mètres
  double _scroll = 0;
  double _spawnTimer = 0.6;
  double _boostTime = 0;
  int _coins = 0;
  bool _crashed = false;
  bool _revived = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _items.clear();
      _playerX = 0.5;
      _distance = 0;
      _scroll = 0;
      _spawnTimer = 0.6;
      _boostTime = 0;
      _coins = 0;
      _crashed = false;
      _revived = false;
    });
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (_size == Size.zero) return;

    if (!_crashed) {
      final base = 0.45 + min(_distance / 3000, 0.45);
      final v = base * (_boostTime > 0 ? 1.6 : 1.0);
      _boostTime = max(0, _boostTime - dt);
      _distance += v * dt * 60;
      _scroll += v * dt;

      _spawnTimer -= dt;
      if (_spawnTimer <= 0) {
        _spawnTimer = (0.35 + _rnd.nextDouble() * 0.5) * 0.45 / v;
        final r = _rnd.nextDouble();
        final type = r < 0.55
            ? ItemType.rock
            : (r < 0.88 ? ItemType.coin : ItemType.boost);
        _items.add(Item(type, 0.08 + _rnd.nextDouble() * 0.84, -0.08));
      }

      final roadW = _size.width * 0.7;
      final h = _size.height;
      for (final it in List<Item>.from(_items)) {
        it.y += v * dt;
        if (it.y > 1.1) {
          _items.remove(it);
          continue;
        }
        final dx = (it.x - _playerX).abs() * roadW;
        final dy = (it.y - playerY).abs() * h;
        if (dx < roadW * 0.10 && dy < h * 0.05) {
          switch (it.type) {
            case ItemType.coin:
              _coins++;
              _items.remove(it);
              break;
            case ItemType.boost:
              _boostTime = 3;
              _items.remove(it);
              break;
            case ItemType.rock:
              if (_boostTime > 0) {
                _items.remove(it);
                _coins += 2;
              } else {
                _crash();
              }
              break;
          }
        }
      }
    }
    setState(() {});
  }

  void _crash() {
    _crashed = true;
    _gamesPlayed++;
    _best = max(_best, _distance.toInt());
    HapticFeedback.heavyImpact();
  }

  void _replay() {
    // Interstitielle toutes les 3 parties
    if (_gamesPlayed % 3 == 0) {
      AdManager.instance.showInterstitial(_reset);
    } else {
      _reset();
    }
  }

  void _reviveWithAd() {
    AdManager.instance.showRewarded(onReward: () {
      setState(() {
        _items.removeWhere((i) => i.y > 0.45);
        _boostTime = 2.5; // invincibilité courte
        _crashed = false;
        _revived = true;
        _gamesPlayed--; // la partie continue
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, c) {
        _size = Size(c.maxWidth, c.maxHeight);
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) {
                if (_crashed) return;
                _playerX = (_playerX + d.delta.dx / (_size.width * 0.7))
                    .clamp(0.06, 0.94);
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _GamePainter(
                  items: _items,
                  playerX: _playerX,
                  scroll: _scroll,
                  boost: _boostTime > 0,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hud('📏 ${_distance.toInt()} m'),
                    _hud('🪙 $_coins'),
                    if (_boostTime > 0) _hud('⚡ TURBO'),
                  ],
                ),
              ),
            ),
            if (_crashed) _crashOverlay(),
          ],
        );
      }),
    );
  }

  Widget _hud(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.black54, borderRadius: BorderRadius.circular(20)),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _crashOverlay() {
    final canRevive = !_revived && AdManager.instance.rewardedReady;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('💥 CRASH !',
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('Distance : ${_distance.toInt()} m'),
                Text('Pièces : $_coins'),
                Text('Record : $_best m'),
                const SizedBox(height: 20),
                if (canRevive)
                  FilledButton.icon(
                    onPressed: _reviveWithAd,
                    icon: const Icon(Icons.ondemand_video),
                    label: const Text('Continuer (regarder une pub)'),
                  ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _replay,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rejouer'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Menu'),
                ),
                const SizedBox(height: 8),
                const BannerAdWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── DESSIN ─────────────────────────

class _GamePainter extends CustomPainter {
  _GamePainter({
    required this.items,
    required this.playerX,
    required this.scroll,
    required this.boost,
  });
  final List<Item> items;
  final double playerX;
  final double scroll;
  final bool boost;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final roadL = w * 0.15, roadW = w * 0.7;

    // Sable + mer
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF2D49B));
    final sea = Paint()..color = const Color(0xFF29B6F6);
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.07, h), sea);
    canvas.drawRect(Rect.fromLTWH(w * 0.93, 0, w * 0.07, h), sea);
    final foam = Paint()..color = Colors.white70;
    for (var k = -1; k < 12; k++) {
      final y = ((k * 0.1) + (scroll * 0.6) % 0.1) * h;
      canvas.drawCircle(Offset(w * 0.07, y), 7, foam);
      canvas.drawCircle(Offset(w * 0.93, y + h * 0.05), 7, foam);
    }

    // Piste
    canvas.drawRect(Rect.fromLTWH(roadL, 0, roadW, h),
        Paint()..color = const Color(0xFFD9B26F));
    final line = Paint()..color = const Color(0xFFFFF3D6);
    for (var k = -1; k < 10; k++) {
      final y = ((k * 0.12) + (scroll % 0.12)) * h;
      for (final f in [1 / 3, 2 / 3]) {
        canvas.drawRect(
            Rect.fromLTWH(roadL + roadW * f - 3, y, 6, h * 0.06), line);
      }
    }

    // Objets
    final r = roadW * 0.06;
    for (final it in items) {
      final c = Offset(roadL + it.x * roadW, it.y * h);
      switch (it.type) {
        case ItemType.rock:
          canvas.drawOval(
              Rect.fromCenter(center: c, width: r * 2.6, height: r * 2.1),
              Paint()..color = const Color(0xFF6D6D6D));
          canvas.drawOval(
              Rect.fromCenter(
                  center: c.translate(-r * 0.4, -r * 0.4),
                  width: r * 1.1,
                  height: r * 0.8),
              Paint()..color = const Color(0xFF9E9E9E));
          break;
        case ItemType.coin:
          canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFC107));
          canvas.drawCircle(
              c,
              r * 0.6,
              Paint()
                ..color = const Color(0xFFFFE082)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3);
          break;
        case ItemType.boost:
          canvas.drawCircle(c, r * 1.1, Paint()..color = const Color(0xFF00E5FF));
          final tp = TextPainter(
            text: const TextSpan(text: '⚡', style: TextStyle(fontSize: 22)),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
          break;
      }
    }

    // Buggy du joueur
    final p = Offset(roadL + playerX * roadW, playerY0(h));
    final bw = roadW * 0.14, bh = bw * 1.7;
    if (boost) {
      canvas.drawCircle(
          p, bw * 1.2, Paint()..color = const Color(0x5500E5FF));
    }
    final wheel = Paint()..color = Colors.black87;
    for (final dx in [-1.0, 1.0]) {
      for (final dy in [-0.6, 0.6]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: p + Offset(dx * bw * 0.6, dy * bh * 0.5),
                    width: bw * 0.35,
                    height: bh * 0.3),
                const Radius.circular(4)),
            wheel);
      }
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: p, width: bw, height: bh),
            const Radius.circular(12)),
        Paint()..color = const Color(0xFFFF6F00));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: p.translate(0, -bh * 0.12),
                width: bw * 0.7,
                height: bh * 0.22),
            const Radius.circular(6)),
        Paint()..color = const Color(0xFF81D4FA));
    canvas.drawCircle(p.translate(0, bh * 0.08), bw * 0.22,
        Paint()..color = const Color(0xFFFFCC80));
    canvas.drawRect(
        Rect.fromCenter(
            center: p.translate(0, bh * 0.03),
            width: bw * 0.5,
            height: bh * 0.05),
        Paint()..color = const Color(0xFFD32F2F)); // bandeau
  }

  double playerY0(double h) => h * _GameScreenState.playerY;

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}
