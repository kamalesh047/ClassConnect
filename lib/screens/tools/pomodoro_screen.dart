import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  static const int workTime = 25 * 60;
  static const int shortBreak = 5 * 60;
  static const int longBreak = 15 * 60;

  int _timeLeft = workTime;
  Timer? _timer;
  bool _isRunning = false;
  String _mode = 'Work'; // 'Work', 'Short Break', 'Long Break'

  void _startTimer() {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _isRunning = false;
        _handleTimeUp();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (_mode == 'Work') _timeLeft = workTime;
      if (_mode == 'Short Break') _timeLeft = shortBreak;
      if (_mode == 'Long Break') _timeLeft = longBreak;
    });
  }

  void _handleTimeUp() {
    // Play sound or show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_mode Session Finished!'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }

  void _setMode(String mode) {
    _timer?.cancel();
    setState(() {
      _mode = mode;
      _isRunning = false;
      if (mode == 'Work') _timeLeft = workTime;
      if (mode == 'Short Break') _timeLeft = shortBreak;
      if (mode == 'Long Break') _timeLeft = longBreak;
    });
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = _mode == 'Work' ? Colors.redAccent : Colors.teal;

    return Scaffold(
      backgroundColor: themeColor,
      appBar: AppBar(
        title: Text(
          'Study Timer',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mode Selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton('Work', themeColor),
                const SizedBox(width: 8),
                _buildModeButton('Short Break', themeColor),
                const SizedBox(width: 8),
                _buildModeButton('Long Break', themeColor),
              ],
            ),
            const SizedBox(height: 60),
            // Timer Display
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value:
                        _timeLeft /
                        (_mode == 'Work'
                            ? workTime
                            : (_mode == 'Short Break'
                                  ? shortBreak
                                  : longBreak)),
                    strokeWidth: 10,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Text(
                  _formatTime(_timeLeft),
                  style: GoogleFonts.outfit(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  _isRunning ? _pauseTimer : _startTimer,
                ),
                const SizedBox(width: 30),
                _buildControlButton(Icons.refresh_rounded, _resetTimer),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              _mode == 'Work' ? 'Stay Focused!' : 'Take a rest.',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, Color activeColor) {
    bool isSelected = _mode == mode;
    return GestureDetector(
      onTap: () => _setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: _mode == 'Work' ? Colors.redAccent : Colors.teal,
          size: 32,
        ),
      ),
    );
  }
}
