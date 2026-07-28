import 'bracket_board.dart';

enum PieceType { I, J, L, O, S, T, Z }

class BracketPiece {
  final PieceType type;
  final List<BoardPoint> shape;

  const BracketPiece({
    required this.type,
    required this.shape,
  });

  factory BracketPiece.fromType(PieceType type) {
    switch (type) {
      case PieceType.O:
        return const BracketPiece(
          type: PieceType.O,
          shape: [
            BoardPoint(0, 0),
            BoardPoint(1, 0),
            BoardPoint(0, 1),
            BoardPoint(1, 1),
          ],
        );
      case PieceType.I:
        return const BracketPiece(
          type: PieceType.I,
          shape: [
            BoardPoint(0, 1),
            BoardPoint(1, 1),
            BoardPoint(2, 1),
            BoardPoint(3, 1),
          ],
        );
      case PieceType.T:
        return const BracketPiece(
          type: PieceType.T,
          shape: [
            BoardPoint(1, 0),
            BoardPoint(0, 1),
            BoardPoint(1, 1),
            BoardPoint(2, 1),
          ],
        );
      case PieceType.L:
        return const BracketPiece(
          type: PieceType.L,
          shape: [
            BoardPoint(2, 0),
            BoardPoint(0, 1),
            BoardPoint(1, 1),
            BoardPoint(2, 1),
          ],
        );
      case PieceType.J:
        return const BracketPiece(
          type: PieceType.J,
          shape: [
            BoardPoint(0, 0),
            BoardPoint(0, 1),
            BoardPoint(1, 1),
            BoardPoint(2, 1),
          ],
        );
      case PieceType.S:
        return const BracketPiece(
          type: PieceType.S,
          shape: [
            BoardPoint(1, 0),
            BoardPoint(2, 0),
            BoardPoint(0, 1),
            BoardPoint(1, 1),
          ],
        );
      case PieceType.Z:
        return const BracketPiece(
          type: PieceType.Z,
          shape: [
            BoardPoint(0, 0),
            BoardPoint(1, 0),
            BoardPoint(1, 1),
            BoardPoint(2, 1),
          ],
        );
    }
  }

  BracketPiece rotateClockwise() {
    if (type == PieceType.O) return this;

    // Find bounding box center or anchor rotation around (1, 1)
    final rotatedShape = shape.map((p) {
      // 90 deg clockwise rotation around (1, 1): (x', y') = (1 - (y - 1), 1 + (x - 1))
      final newX = 1 - (p.y - 1);
      final newY = 1 + (p.x - 1);
      return BoardPoint(newX, newY);
    }).toList();

    return BracketPiece(type: type, shape: rotatedShape);
  }
}
