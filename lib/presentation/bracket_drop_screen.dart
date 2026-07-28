import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game/bracket_board.dart';
import '../game/bracket_renderer.dart';

class BracketDropScreen extends StatefulWidget {
  final BracketBoard? initialBoard;

  const BracketDropScreen({super.key, this.initialBoard});

  @override
  State<BracketDropScreen> createState() => _BracketDropScreenState();
}

class _BracketDropScreenState extends State<BracketDropScreen>
    with SingleTickerProviderStateMixin {
  late BracketBoard _board;
  late BracketRenderer _renderer;
  Timer? _gameTimer;
  bool _hasStartedGame = false;
  bool _isPaused = false;
  final FocusNode _focusNode = FocusNode();
  int _lastSpeedMs = 800;

  // Binary Splash Animation Controller
  late AnimationController _splashController;
  final List<_BinaryParticle> _particles = [];
  final Random _random = Random();

  // Terminal color theme: Cyberpunk Green Phosphor
  static const Color terminalGreen = Color(0xFF00FF66);
  static const Color terminalDarkBg = Color(0xFF060907);
  static const Color terminalScreenBg = Color(0xFF030704);
  static const Color terminalDim = Color(0xFF003816);

  @override
  void initState() {
    super.initState();
    _board = widget.initialBoard ?? BracketBoard();
    _renderer = BracketRenderer(_board);

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _splashController.addListener(() {
      setState(() {
        for (final p in _particles) {
          p.update();
        }
      });
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _focusNode.dispose();
    _splashController.dispose();
    super.dispose();
  }

  void _onPressStartGame() {
    setState(() {
      _hasStartedGame = true;
      _isPaused = false;
      _board.reset();
    });
    _focusNode.requestFocus();
    _startGameTimer();
  }

  void _triggerBinarySplashForRows(List<int> clearedRows) {
    if (clearedRows.isEmpty) return;

    _particles.clear();
    const double boardHeight = 380.0;
    const double boardWidth = 220.0;

    for (final rowY in clearedRows) {
      final rowCenterY = (rowY + 0.5) * (boardHeight / 20.0) - (boardHeight / 2.0);

      for (int i = 0; i < 20; i++) {
        final rowX = (_random.nextDouble() - 0.5) * (boardWidth - 16);
        _particles.add(
          _BinaryParticle(
            x: rowX,
            y: rowCenterY + (_random.nextDouble() - 0.5) * 6,
            vx: (_random.nextDouble() - 0.5) * 7,
            vy: (_random.nextDouble() - 0.5) * 4,
            char: _random.nextBool() ? '0' : '1',
            size: 13 + _random.nextDouble() * 8,
            opacity: 1.0,
          ),
        );
      }
    }

    const int durationMs = 150;
    _splashController.duration = const Duration(milliseconds: durationMs);
    _splashController.forward(from: 0.0);

    Timer(const Duration(milliseconds: durationMs), () {
      if (mounted) {
        setState(() {
          _board.finalizeLineClear();
        });
      }
    });
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _lastSpeedMs = _board.currentSpeedMs;
    _gameTimer = Timer.periodic(Duration(milliseconds: _lastSpeedMs), (_) {
      if (_hasStartedGame && !_isPaused && !_board.isGameOver && !_board.isClearingLines) {
        setState(() {
          final clearedRows = _board.tick();
          if (clearedRows.isNotEmpty) {
            _triggerBinarySplashForRows(clearedRows);
          }
          if (_board.currentSpeedMs != _lastSpeedMs) {
            _startGameTimer();
          }
        });
      }
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    if (!_hasStartedGame) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _onPressStartGame();
      }
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyP ||
        event.logicalKey == LogicalKeyboardKey.escape) {
      _togglePause();
      return;
    }

    if (_board.isGameOver || _board.isClearingLines || _isPaused) {
      return;
    }

    setState(() {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _board.moveLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _board.moveRight();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _board.rotate();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final clearedRows = _board.tick();
        if (clearedRows.isNotEmpty) _triggerBinarySplashForRows(clearedRows);
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        final clearedRows = _board.hardDrop();
        if (clearedRows.isNotEmpty) _triggerBinarySplashForRows(clearedRows);
      } else if (event.logicalKey == LogicalKeyboardKey.keyC ||
          event.logicalKey == LogicalKeyboardKey.shiftLeft ||
          event.logicalKey == LogicalKeyboardKey.shiftRight) {
        _board.holdCurrentPiece();
      }
    });
  }

  void _restartGame() {
    setState(() {
      _board.reset();
      _isPaused = false;
    });
    _focusNode.requestFocus();
    _startGameTimer();
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
    if (!_isPaused) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<int>? fadingRows = _board.isClearingLines ? _board.pendingClearedRows.toSet() : null;
    final double fadeProgress = _splashController.isAnimating ? _splashController.value : 0.0;

    final boardText = _renderer.renderBoard(fadingRows, fadeProgress);
    final nextPieceText = _renderer.renderNextPiece();
    final holdPieceText = _renderer.renderHoldPiece();

    final scoreStr = _board.score.toString().padLeft(6, '0');
    final levelStr = _board.level.toString().padLeft(2, '0');
    final linesStr = _board.linesCleared.toString().padLeft(3, '0');

    final boardTextStyle = GoogleFonts.shareTechMono(
      color: terminalGreen,
      fontSize: 20,
      height: 1.0,
      letterSpacing: 1.6,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: terminalDarkBg,
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: RawKeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKey: _handleKeyEvent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: !_hasStartedGame
                  ? _buildLandingPage()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth > constraints.maxHeight && constraints.maxWidth >= 650;

                        return isDesktop
                            ? _buildDesktopLayout(
                                boardText: boardText,
                                nextPieceText: nextPieceText,
                                holdPieceText: holdPieceText,
                                scoreStr: scoreStr,
                                levelStr: levelStr,
                                linesStr: linesStr,
                                boardTextStyle: boardTextStyle,
                              )
                            : _buildMobileLayout(
                                boardText: boardText,
                                nextPieceText: nextPieceText,
                                holdPieceText: holdPieceText,
                                scoreStr: scoreStr,
                                levelStr: levelStr,
                                linesStr: linesStr,
                                boardTextStyle: boardTextStyle,
                              );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // LANDING PAGE (Fills full screen naturally)
  Widget _buildLandingPage() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: terminalScreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: terminalGreen, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: terminalGreen.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Title Header
              Column(
                children: [
                  Text(
                    '[{ BRACKET DROP }]',
                    style: GoogleFonts.shareTechMono(
                      color: terminalGreen,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      shadows: const [
                        Shadow(color: terminalGreen, blurRadius: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'CYBERPUNK TETRIS CONSOLE',
                    style: GoogleFonts.shareTechMono(
                      color: terminalGreen.withOpacity(0.7),
                      fontSize: 11,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),

              // Controls Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: terminalDarkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: terminalGreen.withOpacity(0.4), width: 1.2),
                ),
                child: Column(
                  children: [
                    Text(
                      'SYSTEM CONTROLS',
                      style: GoogleFonts.shareTechMono(
                        color: terminalGreen.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildControlRow('MOVE LEFT / RIGHT', 'LEFT / RIGHT ARROWS'),
                    const SizedBox(height: 6),
                    _buildControlRow('ROTATE PIECE', 'UP ARROW / TAP'),
                    const SizedBox(height: 6),
                    _buildControlRow('SOFT DROP', 'DOWN ARROW'),
                    const SizedBox(height: 6),
                    _buildControlRow('HARD DROP', 'SPACEBAR'),
                    const SizedBox(height: 6),
                    _buildControlRow('HOLD PIECE', 'C / SHIFT KEY'),
                    const SizedBox(height: 6),
                    _buildControlRow('PAUSE / RESUME', 'P / ESC KEY'),
                  ],
                ),
              ),

              // Play Now Action Button
              Column(
                children: [
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _onPressStartGame,
                      style: ElevatedButton.styleFrom(
                        primary: terminalGreen,
                        onPrimary: Colors.black,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        shadowColor: terminalGreen,
                      ),
                      child: Text(
                        'PLAY NOW',
                        style: GoogleFonts.shareTechMono(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PRESS ENTER OR SPACE TO START',
                    style: GoogleFonts.shareTechMono(
                      color: terminalGreen.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlRow(String action, String keyBinding) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            action,
            style: GoogleFonts.shareTechMono(
              color: terminalGreen.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            keyBinding,
            style: GoogleFonts.shareTechMono(
              color: terminalGreen,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // DESKTOP LAYOUT (Container fills full screen, Game Board stays un-stretched in center)
  Widget _buildDesktopLayout({
    required String boardText,
    required String nextPieceText,
    required String holdPieceText,
    required String scoreStr,
    required String levelStr,
    required String linesStr,
    required TextStyle boardTextStyle,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: terminalScreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: terminalGreen.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: terminalGreen.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Game Board Section - Centered and preserved in ratio
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: _buildInteractiveBoard(boardText, boardTextStyle),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Sidebar Controls & HUD Section
          SizedBox(
            width: 320,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIntegratedHUDHeader(scoreStr, levelStr, linesStr, holdPieceText, nextPieceText),
                const SizedBox(height: 12),
                _buildCommandsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MOBILE PORTRAIT LAYOUT (Container fills full screen, Game Board stays un-stretched in center)
  Widget _buildMobileLayout({
    required String boardText,
    required String nextPieceText,
    required String holdPieceText,
    required String scoreStr,
    required String levelStr,
    required String linesStr,
    required TextStyle boardTextStyle,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: terminalScreenBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: terminalGreen.withOpacity(0.8), width: 2),
        boxShadow: [
          BoxShadow(
            color: terminalGreen.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top HUD Header Bar
          _buildIntegratedHUDHeader(scoreStr, levelStr, linesStr, holdPieceText, nextPieceText),
          const SizedBox(height: 8),

          // Center Game Board (Expanded flexible area holding exact CRT grid ratio)
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: _buildInteractiveBoard(boardText, boardTextStyle),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Bottom Integrated Control Console
          _buildIntegratedControlConsole(),
        ],
      ),
    );
  }

  // Integrated Top HUD Bar (Stretches full width)
  Widget _buildIntegratedHUDHeader(
    String scoreStr,
    String levelStr,
    String linesStr,
    String holdPieceText,
    String nextPieceText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: terminalDarkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: terminalGreen.withOpacity(0.4), width: 1.2),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('SCORE', style: _hudLabelStyle),
                    const SizedBox(width: 4),
                    Text(scoreStr, style: _hudValueStyle),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('LEVEL', style: _hudLabelStyle),
                    const SizedBox(width: 4),
                    Text(levelStr, style: _hudValueStyle),
                    const SizedBox(width: 8),
                    Text('LINES', style: _hudLabelStyle),
                    const SizedBox(width: 4),
                    Text(linesStr, style: _hudValueStyle),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 12),

            Row(
              children: [
                _buildMiniBox('HOLD', holdPieceText),
                const SizedBox(width: 6),
                _buildMiniBox('NEXT', nextPieceText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _hudLabelStyle => GoogleFonts.shareTechMono(
        color: terminalGreen.withOpacity(0.7),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      );

  TextStyle get _hudValueStyle => GoogleFonts.shareTechMono(
        color: terminalGreen,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );

  Widget _buildMiniBox(String label, String pieceText) {
    return Column(
      children: [
        Text(label, style: _hudLabelStyle.copyWith(fontSize: 9)),
        Text(
          pieceText,
          style: GoogleFonts.shareTechMono(
            color: terminalGreen,
            fontSize: 10,
            height: 1.0,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  // Interactive CRT Board (Preserves exact 10x20 text grid bounds)
  Widget _buildInteractiveBoard(String boardText, TextStyle textStyle) {
    final bool inputsDisabled = _board.isGameOver || _board.isClearingLines || _isPaused;

    return GestureDetector(
      onTap: inputsDisabled ? null : () => setState(() => _board.rotate()),
      onDoubleTap: inputsDisabled
          ? null
          : () {
              final cleared = _board.hardDrop();
              if (cleared.isNotEmpty) _triggerBinarySplashForRows(cleared);
            },
      onHorizontalDragEnd: inputsDisabled
          ? null
          : (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < 0) {
                  setState(() => _board.moveLeft());
                } else if (details.primaryVelocity! > 0) {
                  setState(() => _board.moveRight());
                }
              }
            },
      onVerticalDragEnd: inputsDisabled
          ? null
          : (details) {
              if (details.primaryVelocity != null) {
                if (details.primaryVelocity! < 0) {
                  setState(() => _board.rotate());
                } else if (details.primaryVelocity! > 0) {
                  final cleared = _board.tick();
                  if (cleared.isNotEmpty) _triggerBinarySplashForRows(cleared);
                }
              }
            },
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            FittedBox(
              fit: BoxFit.contain,
              child: Text(
                boardText,
                style: textStyle,
                softWrap: false,
                overflow: TextOverflow.clip,
              ),
            ),

            // Binary 0s and 1s Row-Aligned Particle Splash Overlay
            if (_splashController.isAnimating)
              CustomPaint(
                painter: _BinaryParticlePainter(_particles),
                child: const SizedBox(width: 220, height: 380),
              ),

            // Game Paused Overlay
            if (_isPaused && !_board.isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SYSTEM PAUSED',
                        style: GoogleFonts.shareTechMono(
                          color: terminalGreen,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: terminalGreen, blurRadius: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: _togglePause,
                        style: ElevatedButton.styleFrom(
                          primary: terminalGreen,
                          onPrimary: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          textStyle: GoogleFonts.shareTechMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('RESUME'),
                      ),
                    ],
                  ),
                ),
              ),

            // Game Over Overlay
            if (_board.isGameOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.88),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'SYSTEM FAILURE',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.redAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: Colors.red, blurRadius: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'GAME OVER',
                        style: GoogleFonts.shareTechMono(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          primary: terminalGreen,
                          onPrimary: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: GoogleFonts.shareTechMono(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('RESTART'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Integrated Control Console (Stretches full width)
  Widget _buildIntegratedControlConsole() {
    final bool inputsDisabled = _board.isGameOver || _board.isClearingLines || _isPaused;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: terminalDarkBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: terminalGreen.withOpacity(0.4), width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildVectorControlButton(
                  label: 'HOLD',
                  icon: Icons.swap_horiz_rounded,
                  onPressed: inputsDisabled ? null : () => setState(() => _board.holdCurrentPiece()),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildVectorControlButton(
                  label: 'ROTATE',
                  icon: Icons.rotate_right_rounded,
                  onPressed: inputsDisabled ? null : () => setState(() => _board.rotate()),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildVectorControlButton(
                  label: 'HARD DROP',
                  icon: Icons.keyboard_double_arrow_down_rounded,
                  onPressed: inputsDisabled
                      ? null
                      : () {
                          final cleared = _board.hardDrop();
                          if (cleared.isNotEmpty) _triggerBinarySplashForRows(cleared);
                        },
                  isAccent: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: _buildVectorControlButton(
                  label: 'LEFT',
                  icon: Icons.arrow_left_rounded,
                  onPressed: inputsDisabled ? null : () => setState(() => _board.moveLeft()),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildVectorControlButton(
                  label: 'SOFT',
                  icon: Icons.arrow_drop_down_rounded,
                  onPressed: inputsDisabled
                      ? null
                      : () {
                          final cleared = _board.tick();
                          if (cleared.isNotEmpty) _triggerBinarySplashForRows(cleared);
                        },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildVectorControlButton(
                  label: 'RIGHT',
                  icon: Icons.arrow_right_rounded,
                  onPressed: inputsDisabled ? null : () => setState(() => _board.moveRight()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          _buildSystemButtonsRow(),
        ],
      ),
    );
  }

  Widget _buildCommandsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: terminalScreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: terminalGreen.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'COMMANDS',
            style: GoogleFonts.shareTechMono(
              color: terminalGreen.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          _buildIntegratedControlConsole(),
        ],
      ),
    );
  }

  Widget _buildSystemButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSystemButton(
            label: _isPaused ? 'RESUME' : 'PAUSE',
            icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onTap: _togglePause,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSystemButton(
            label: 'RESET',
            icon: Icons.restart_alt_rounded,
            onTap: _restartGame,
          ),
        ),
      ],
    );
  }

  Widget _buildVectorControlButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    double? width,
    bool isAccent = false,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 38,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          primary: isAccent ? terminalGreen : terminalDim.withOpacity(0.5),
          onPrimary: isAccent ? Colors.black : terminalGreen,
          side: BorderSide(color: terminalGreen.withOpacity(0.8), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isAccent ? Colors.black : terminalGreen,
            ),
            const SizedBox(width: 2),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: terminalGreen.withOpacity(0.8), width: 1.2),
          borderRadius: BorderRadius.circular(6),
          color: terminalDim.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: terminalGreen),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.shareTechMono(
                color: terminalGreen,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Binary 0s and 1s Particle Model & Custom Painter
class _BinaryParticle {
  double x;
  double y;
  double vx;
  double vy;
  String char;
  double size;
  double opacity;

  _BinaryParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.char,
    required this.size,
    required this.opacity,
  });

  void update() {
    x += vx;
    y += vy;
    opacity = (opacity - 0.12).clamp(0.0, 1.0);
  }
}

class _BinaryParticlePainter extends CustomPainter {
  final List<_BinaryParticle> particles;

  _BinaryParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final p in particles) {
      if (p.opacity <= 0) continue;

      final textPainter = TextPainter(
        text: TextSpan(
          text: p.char,
          style: GoogleFonts.shareTechMono(
            color: const Color(0xFF00FF66).withOpacity(p.opacity),
            fontSize: p.size,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: const Color(0xFF00FF66).withOpacity(p.opacity * 0.9),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        center + Offset(p.x - textPainter.width / 2, p.y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BinaryParticlePainter oldDelegate) => true;
}
