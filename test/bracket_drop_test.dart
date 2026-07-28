import 'package:flutter_test/flutter_test.dart';
import 'package:bracket_drop/game/bracket_board.dart';
import 'package:bracket_drop/game/bracket_renderer.dart';
import 'package:bracket_drop/game/bracket_piece.dart';
import 'package:bracket_drop/main.dart';

void main() {
  group('BracketBoard tests', () {
    test('default dimensions are 10 columns by 20 rows', () {
      final board = BracketBoard();
      expect(board.width, equals(10));
      expect(board.height, equals(20));
    });

    test('static square occupies exactly 4 cells', () {
      final board = BracketBoard();
      int count = 0;
      for (int y = 0; y < board.height; y++) {
        for (int x = 0; x < board.width; x++) {
          if (board.isOccupied(x, y)) {
            count++;
          }
        }
      }
      expect(count, equals(4));
    });

    test('square piece moves left, right, and drops', () {
      final board = BracketBoard(
        activePiece: BracketPiece.fromType(PieceType.O),
        activePiecePosition: const BoardPoint(4, 1),
      );

      final initialX = board.activePiecePosition.x;
      expect(board.moveLeft(), isTrue);
      expect(board.activePiecePosition.x, equals(initialX - 1));

      expect(board.moveRight(), isTrue);
      expect(board.activePiecePosition.x, equals(initialX));

      final initialY = board.activePiecePosition.y;
      expect(board.tick(), isEmpty);
      expect(board.activePiecePosition.y, equals(initialY + 1));
    });

    test('hold piece system swaps active piece into hold slot and allows swapping back', () {
      final board = BracketBoard(
        activePiece: BracketPiece.fromType(PieceType.I),
      );

      expect(board.holdPiece, isNull);
      expect(board.holdCurrentPiece(), isTrue);
      expect(board.holdPiece?.type, equals(PieceType.I));

      final newActiveType = board.activePiece.type;
      expect(board.holdCurrentPiece(), isTrue);
      expect(board.holdPiece?.type, equals(newActiveType));
      expect(board.activePiece.type, equals(PieceType.I));
    });

    test('speed accelerates gradually as level increases', () {
      final board = BracketBoard();
      expect(board.currentSpeedMs, equals(750));

      board.level = 5;
      expect(board.currentSpeedMs, lessThan(750));
    });

    test('clears multiple full lines correctly without index shifting bugs', () {
      final board = BracketBoard();
      for (int x = 0; x < 10; x++) {
        board.grid[18][x] = true;
        board.grid[19][x] = true;
      }
      board.pendingClearedRows = [18, 19];
      board.isClearingLines = true;

      final count = board.finalizeLineClear();
      expect(count, equals(2));
      expect(board.linesCleared, equals(2));
      expect(board.grid[19].every((cell) => !cell), isTrue);
      expect(board.grid[18].every((cell) => !cell), isTrue);
    });
  });

  group('BracketRenderer tests', () {
    test('renders correct top and bottom borders and 20 rows', () {
      final board = BracketBoard();
      final renderer = BracketRenderer(board);
      final rendered = renderer.renderBoard();

      final lines = rendered.split('\n');
      expect(lines.length, equals(22));

      const expectedBorder = '+--------------------+';
      expect(lines.first, equals(expectedBorder));
      expect(lines.last, equals(expectedBorder));
    });

    test('renders next and hold piece boxes correctly', () {
      final board = BracketBoard();
      final renderer = BracketRenderer(board);
      expect(renderer.renderNextPiece(), contains('+--------+'));
      expect(renderer.renderHoldPiece(), contains('+--------+'));
    });
  });

  group('Widget tests', () {
    testWidgets('renders BracketDropScreen landing page and starts game on tap', (tester) async {
      await tester.pumpWidget(const BracketDropApp());
      await tester.pump();

      expect(find.text('[{ BRACKET DROP }]'), findsOneWidget);
      expect(find.text('PLAY NOW'), findsOneWidget);

      await tester.tap(find.text('PLAY NOW'));
      await tester.pump();

      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text('LINES'), findsOneWidget);
      expect(find.text('HOLD'), findsNWidgets(2));
      expect(find.text('ROTATE'), findsOneWidget);
    });
  });
}
