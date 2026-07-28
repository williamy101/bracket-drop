import 'bracket_board.dart';

class BracketRenderer {
  static const String occupiedCell = '[]';
  static const String emptyCell = '  ';

  final BracketBoard board;

  const BracketRenderer(this.board);

  String renderBoard([Set<int>? fadingRows, double fadeProgress = 0.0]) {
    final buffer = StringBuffer();
    final horizontalBorder = '+${'-' * (board.width * 2)}+';

    buffer.writeln(horizontalBorder);
    for (int y = 0; y < board.height; y++) {
      buffer.write('|');
      final isFading = fadingRows != null && fadingRows.contains(y);
      for (int x = 0; x < board.width; x++) {
        if (isFading) {
          if (fadeProgress > 0.75) {
            buffer.write(emptyCell);
          } else if (fadeProgress > 0.5) {
            buffer.write('..');
          } else if (fadeProgress > 0.25) {
            buffer.write('::');
          } else {
            buffer.write(occupiedCell);
          }
        } else {
          buffer.write(board.isOccupied(x, y) ? occupiedCell : emptyCell);
        }
      }
      buffer.writeln('|');
    }
    buffer.write(horizontalBorder);

    return buffer.toString();
  }

  String renderNextPiece() {
    return _renderSmallBox(board.nextPiece.shape);
  }

  String renderHoldPiece() {
    if (board.holdPiece == null) {
      return '+--------+\n|        |\n|        |\n+--------+';
    }
    return _renderSmallBox(board.holdPiece!.shape);
  }

  String _renderSmallBox(List<BoardPoint> shape) {
    final buffer = StringBuffer();
    buffer.writeln('+--------+');
    for (int y = 0; y < 2; y++) {
      buffer.write('|');
      for (int x = 0; x < 4; x++) {
        bool occupied = false;
        for (final offset in shape) {
          if (offset.x == x && offset.y == y) {
            occupied = true;
            break;
          }
        }
        buffer.write(occupied ? occupiedCell : emptyCell);
      }
      buffer.writeln('|');
    }
    buffer.write('+--------+');
    return buffer.toString();
  }
}
