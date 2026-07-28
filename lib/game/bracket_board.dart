import 'dart:math';
import 'bracket_piece.dart';

class BoardPoint {
  final int x;
  final int y;

  const BoardPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

class BracketBoard {
  static const int defaultWidth = 10;
  static const int defaultHeight = 20;

  final int width;
  final int height;
  final List<List<bool>> grid;

  BoardPoint activePiecePosition;
  BracketPiece activePiece;
  BracketPiece nextPiece;
  BracketPiece? holdPiece;
  bool canHold = true;

  List<int> pendingClearedRows = [];
  bool isClearingLines = false;

  int score = 0;
  int level = 1;
  int linesCleared = 0;
  bool isGameOver = false;

  final Random _random = Random();
  final List<PieceType> _bag = [];

  BracketBoard({
    this.width = defaultWidth,
    this.height = defaultHeight,
    List<List<bool>>? grid,
    BoardPoint? activePiecePosition,
    BracketPiece? activePiece,
    BracketPiece? nextPiece,
  })  : grid = grid ??
            List.generate(
              defaultHeight,
              (_) => List.filled(defaultWidth, false),
            ),
        activePiece = activePiece ?? BracketPiece.fromType(PieceType.O),
        nextPiece = nextPiece ?? BracketPiece.fromType(PieceType.T),
        activePiecePosition = activePiecePosition ?? const BoardPoint(4, 1) {
    if (activePiece == null || nextPiece == null) {
      _fillBag();
    }
  }

  int get currentSpeedMs {
    const baseSpeed = 750;
    final levelDecrease = (level - 1) * 75;
    final lineDecrease = (linesCleared % 10) * 5;
    final calculatedSpeed = baseSpeed - levelDecrease - lineDecrease;
    return calculatedSpeed.clamp(25, 750);
  }

  void _fillBag() {
    _bag.clear();
    _bag.addAll(PieceType.values);
    _bag.shuffle(_random);
  }

  BracketPiece _getNextPieceFromBag() {
    if (_bag.isEmpty) {
      _fillBag();
    }
    return BracketPiece.fromType(_bag.removeLast());
  }

  void reset() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        grid[y][x] = false;
      }
    }
    score = 0;
    level = 1;
    linesCleared = 0;
    isGameOver = false;
    holdPiece = null;
    canHold = true;
    pendingClearedRows = [];
    isClearingLines = false;
    _fillBag();
    activePiece = _getNextPieceFromBag();
    nextPiece = _getNextPieceFromBag();
    activePiecePosition = const BoardPoint(4, 0);
  }

  bool holdCurrentPiece() {
    if (isGameOver || isClearingLines) return false;

    if (holdPiece == null) {
      holdPiece = BracketPiece.fromType(activePiece.type);
      _spawnNextPiece();
    } else {
      final temp = holdPiece!;
      holdPiece = BracketPiece.fromType(activePiece.type);
      activePiece = BracketPiece.fromType(temp.type);
      activePiecePosition = const BoardPoint(4, 0);
    }
    return true;
  }

  bool isBoardCellOccupied(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return false;
    }
    return grid[y][x];
  }

  bool isPieceCellOccupied(int x, int y) {
    if (isClearingLines) return false;
    for (final offset in activePiece.shape) {
      if (activePiecePosition.x + offset.x == x &&
          activePiecePosition.y + offset.y == y) {
        return true;
      }
    }
    return false;
  }

  bool isOccupied(int x, int y) {
    return isBoardCellOccupied(x, y) || isPieceCellOccupied(x, y);
  }

  bool isValidPosition(BracketPiece piece, BoardPoint pos) {
    for (final offset in piece.shape) {
      final targetX = pos.x + offset.x;
      final targetY = pos.y + offset.y;

      if (targetX < 0 || targetX >= width || targetY < 0 || targetY >= height) {
        return false;
      }
      if (grid[targetY][targetX]) {
        return false;
      }
    }
    return true;
  }

  bool moveLeft() {
    if (isGameOver || isClearingLines) return false;
    final newPos = BoardPoint(activePiecePosition.x - 1, activePiecePosition.y);
    if (isValidPosition(activePiece, newPos)) {
      activePiecePosition = newPos;
      return true;
    }
    return false;
  }

  bool moveRight() {
    if (isGameOver || isClearingLines) return false;
    final newPos = BoardPoint(activePiecePosition.x + 1, activePiecePosition.y);
    if (isValidPosition(activePiece, newPos)) {
      activePiecePosition = newPos;
      return true;
    }
    return false;
  }

  bool rotate() {
    if (isGameOver || isClearingLines) return false;
    final rotated = activePiece.rotateClockwise();
    if (isValidPosition(rotated, activePiecePosition)) {
      activePiece = rotated;
      return true;
    }
    return false;
  }

  List<int> tick() {
    if (isGameOver || isClearingLines) return [];

    final nextPos = BoardPoint(activePiecePosition.x, activePiecePosition.y + 1);
    if (isValidPosition(activePiece, nextPos)) {
      activePiecePosition = nextPos;
      return [];
    } else {
      _lockPiece();
      return _checkFullRows();
    }
  }

  List<int> hardDrop() {
    if (isGameOver || isClearingLines) return [];
    while (true) {
      final nextPos = BoardPoint(activePiecePosition.x, activePiecePosition.y + 1);
      if (isValidPosition(activePiece, nextPos)) {
        activePiecePosition = nextPos;
        score += 2;
      } else {
        break;
      }
    }
    _lockPiece();
    return _checkFullRows();
  }

  void _lockPiece() {
    for (final offset in activePiece.shape) {
      final x = activePiecePosition.x + offset.x;
      final y = activePiecePosition.y + offset.y;
      if (y >= 0 && y < height && x >= 0 && x < width) {
        grid[y][x] = true;
      }
    }
    canHold = true;
  }

  List<int> _checkFullRows() {
    pendingClearedRows = _findFullRows();
    if (pendingClearedRows.isNotEmpty) {
      isClearingLines = true;
      return List.unmodifiable(pendingClearedRows);
    } else {
      _spawnNextPiece();
      return [];
    }
  }

  List<int> _findFullRows() {
    final fullRows = <int>[];
    for (int y = height - 1; y >= 0; y--) {
      bool full = true;
      for (int x = 0; x < width; x++) {
        if (!grid[y][x]) {
          full = false;
          break;
        }
      }
      if (full) {
        fullRows.add(y);
      }
    }
    return fullRows;
  }

  int finalizeLineClear() {
    if (!isClearingLines || pendingClearedRows.isEmpty) return 0;

    int count = 0;
    for (int y = height - 1; y >= 0; y--) {
      bool full = true;
      for (int x = 0; x < width; x++) {
        if (!grid[y][x]) {
          full = false;
          break;
        }
      }

      if (full) {
        count++;
        grid.removeAt(y);
        grid.insert(0, List.filled(width, false));
        y++;
      }
    }

    if (count > 0) {
      linesCleared += count;
      score += [0, 100, 300, 500, 800][min(count, 4)] * level;
      level = 1 + (linesCleared ~/ 10);
    }

    pendingClearedRows = [];
    isClearingLines = false;

    _spawnNextPiece();
    return count;
  }

  void _spawnNextPiece() {
    activePiece = nextPiece;
    nextPiece = _getNextPieceFromBag();
    activePiecePosition = const BoardPoint(4, 0);

    if (!isValidPosition(activePiece, activePiecePosition)) {
      isGameOver = true;
    }
  }
}
