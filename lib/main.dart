import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const FingerChooserApp());
}

class FingerChooserApp extends StatelessWidget {
  const FingerChooserApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finger Chooser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: const HowToPlayScreen(),
    );
  }
}

// ────────────────────────────────────────────────
// Screen 1: How to play (Image 1 style)
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "How to Play",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              const Text(
                "1. Everyone puts **one finger** on the screen\n"
                    "2. Hold still for 2 seconds\n"
                    "3. Circles appear around each finger\n"
                    "4. The app randomly chooses winner(s)",
                style: TextStyle(fontSize: 20, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChooserScreen()),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text("Start Game", style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────
// Screen 2 & 3: Main Chooser (Image 2 + Image 3 combined)
class ChooserScreen extends StatefulWidget {
  const ChooserScreen({Key? key}) : super(key: key);

  @override
  State<ChooserScreen> createState() => _ChooserScreenState();
}

class _ChooserScreenState extends State<ChooserScreen> with TickerProviderStateMixin {
  int _winnerCount = 2;
  final Map<int, Offset> _touches = {}; // pointerId → position
  final Map<int, AnimationController> _pulseControllers = {};
  Timer? _holdTimer;
  bool _selectionDone = false;
  List<int> _selectedPointerIds = [];

  static const double _holdDurationSec = 2.0;
  static const double _circleSize = 90;

  @override
  void dispose() {
    _holdTimer?.cancel();
    for (var ctrl in _pulseControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _startHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = Timer( Duration(milliseconds: (_holdDurationSec * 1000).toInt()), () {
      if (_touches.length >= _winnerCount) {
        _selectWinners();
      }
    });
  }

  void _selectWinners() {
    setState(() => _selectionDone = true);

    final random = Random();
    final pointerIds = _touches.keys.toList()..shuffle(random);
    _selectedPointerIds = pointerIds.take(_winnerCount).toList();

    // Pulse animation for winners
    for (var id in _selectedPointerIds) {
      final ctrl = _pulseControllers[id];
      if (ctrl != null) {
        ctrl.repeat(reverse: true);
      }
    }
  }

  void _reset() {
    setState(() {
      _touches.clear();
      _selectedPointerIds.clear();
      _selectionDone = false;
    });
    for (var ctrl in _pulseControllers.values) {
      ctrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chooser"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {}, // can open help dialog
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background pattern or color
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color(0xFF1B263B), Color(0xFF0D1B2A)],
                center: Alignment.center,
              ),
            ),
          ),

          // Touch area
          Listener(
            onPointerDown: (event) {
              final id = event.pointer;
              _touches[id] = event.position;

              // Create pulse controller if not exists
              _pulseControllers.putIfAbsent(
                id,
                    () => AnimationController(
                  vsync: this,
                  duration: const Duration(milliseconds: 800),
                ),
              );

              if (_touches.length == 1) _startHoldTimer();
              setState(() {});
            },
            onPointerMove: (event) {
              final id = event.pointer;
              if (_touches.containsKey(id)) {
                _touches[id] = event.position;
                setState(() {});
              }
            },
            onPointerUp: (event) {
              final id = event.pointer;
              _touches.remove(id);
              // Optional: remove controller if you want to clean up
              setState(() {});
            },
            onPointerCancel: (event) {
              _touches.remove(event.pointer);
              setState(() {});
            },
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),

          // Number of winners chooser (top center - Image 2/3)
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.orange),
                      onPressed: _winnerCount > 1 ? () => setState(() => _winnerCount--) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "$_winnerCount Winner${_winnerCount == 1 ? '' : 's'}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.orange),
                      onPressed: () => setState(() => _winnerCount++),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Instruction text
          if (!_selectionDone && _touches.isEmpty)
            const Center(
              child: Text(
                "Everyone put 1 finger\nand hold for 2 seconds",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, height: 1.4),
              ),
            ),

          // Circles around fingers
          ..._touches.entries.map((entry) {
            final id = entry.key;
            final pos = entry.value;
            final isSelected = _selectedPointerIds.contains(id);
            final anim = _pulseControllers[id];

            return Positioned(
              left: pos.dx - _circleSize / 2,
              top: pos.dy - _circleSize / 2,
              child: isSelected && anim != null
                  ? ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.25).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeInOut),
                ),
                child: _buildCircle(isSelected: true),
              )
                  : _buildCircle(isSelected: false),
            );
          }),

          // Reset / Play again button after selection
          if (_selectionDone)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: _reset,
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  ),
                  child: const Text("Play Again", style: TextStyle(fontSize: 20)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircle({required bool isSelected}) {
    return Container(
      width: _circleSize,
      height: _circleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? Colors.yellowAccent : Colors.white70,
          width: isSelected ? 6 : 3,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.yellowAccent.withOpacity(0.6), blurRadius: 20, spreadRadius: 8)]
            : null,
      ),
    );
  }
}