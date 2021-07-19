import 'package:dart_console/dart_console.dart';
import 'package:mockito/annotations.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:xxo/src/xxo.dart';

@GenerateMocks([Player, Board, Console])
void main() {
  group('xxo', () {
    group('player', () {
      test('get player X', () {
        final player = Player.X();
        expect(player.symbol, equals('X'));
      });

      test('get player O', () {
        final player = Player.O();
        expect(player.symbol, equals('O'));
      });
    });

    group('board', () {
      late Player playerX;
      late Player playerO;
      late Board board;

      setUp(() {
        playerX = Player.X();
        playerO = Player.O();
        board = Board();
      });

      test('create new board have empty fields', () {
        expect(board, isA<Board>());
        expect(board.isEmpty(Pos(x: 0, y: 0)), isTrue);
      });

      test('cleared board have empty fields', () {
        expect(board, isA<Board>());
        expect(board.isEmpty(Pos(x: 0, y: 0)), isTrue);
        board[Pos(x: 0, y: 0)] = playerX;
        expect(board.isEmpty(Pos(x: 0, y: 0)), isFalse);
        board.clear();
        expect(board.isEmpty(Pos(x: 0, y: 0)), isTrue);
        expect(board.remaining, equals(9));
      });

      test('setted field not empty', () {
        board[Pos(x: 0, y: 0)] = playerX;
        expect(board.isEmpty(Pos(x: 0, y: 0)), isFalse);
      });

      test('return first empty field', () {
        expect(board.emptyField(), Pos(x: 0, y: 0));
      });

      test('return next empty field 1', () {
        board[Pos(x: 0, y: 0)] = playerX;
        expect(board.emptyField(), Pos(x: 1, y: 0));
      });

      test('return next empty field 2', () {
        board[Pos(x: 0, y: 0)] = playerX;
        board[Pos(x: 1, y: 0)] = playerX;
        board[Pos(x: 2, y: 0)] = playerX;
        expect(board.emptyField(), Pos(x: 0, y: 1));
      });

      test('empty field', () {
        expect(board.remaining, 9);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 8);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 7);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 6);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 5);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 4);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 3);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 2);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 1);
        board[board.emptyField()] = playerX;
        expect(board.remaining, 0);

        expect(() => board[board.emptyField()] = playerX, throwsException);
      });

      test('next empty field throws exception on full board', () {
        board[Pos(x: 0, y: 0)] = playerX;
        board[Pos(x: 1, y: 0)] = playerX;
        board[Pos(x: 2, y: 0)] = playerX;
        board[Pos(x: 0, y: 1)] = playerX;
        board[Pos(x: 1, y: 1)] = playerX;
        board[Pos(x: 2, y: 1)] = playerX;
        board[Pos(x: 0, y: 2)] = playerX;
        board[Pos(x: 1, y: 2)] = playerX;
        board[Pos(x: 2, y: 2)] = playerX;
        expect(() => board.emptyField(), throwsException);
      });

      test('player X set field to >=3||<0, y or x, >=3||<0 throws out of bound', () {
        expect(() => board[Pos(x: -1, y: 0)] = playerX, throwsA(isA<OutOfBoundException>()));
        expect(() => board[Pos(x: 0, y: -1)] = playerX, throwsA(isA<OutOfBoundException>()));
        expect(() => board[Pos(x: 0, y: 3)] = playerX, throwsA(isA<OutOfBoundException>()));
        expect(() => board[Pos(x: 3, y: 0)] = playerX, throwsA(isA<OutOfBoundException>()));
      });

      test('throw exception on reset field', () {
        board[Pos(x: 0, y: 0)] = playerX;
        expect(() => board[Pos(x: 0, y: 0)] = playerX, throwsException);
      });

      test('setted x, y field returns player', () {
        board[Pos(x: 0, y: 0)] = playerX;
        expect(board[Pos(x: 0, y: 0)], equals(playerX));

        board[Pos(x: 1, y: 1)] = playerO;
        expect(board[Pos(x: 1, y: 1)], equals(playerO));
      });

      test('empty board nobody wins the game', () {
        expect(board.won, isFalse);
        expect(board.winner, Board.empty);
      });

      test('set 0,0; 1,1; 2,2 by player X wins the game', () {
        expect(board.won, isFalse);
        board[Pos(x: 0, y: 0)] = playerX;
        expect(board.won, isFalse);
        board[Pos(x: 1, y: 1)] = playerX;
        expect(board.won, isFalse);
        board[Pos(x: 2, y: 2)] = playerX;
        expect(board.won, isTrue);

        expect(board.winner, playerX);
      });

      test('set 0,0; 0,1; 0,2 by player X wins the game', () {
        expect(board.won, isFalse);
        board[Pos(x: 0, y: 0)] = playerO;
        expect(board.won, isFalse);
        board[Pos(x: 0, y: 1)] = playerO;
        expect(board.won, isFalse);
        board[Pos(x: 0, y: 2)] = playerO;
        expect(board.won, isTrue);

        expect(board.winner, playerO);
      });

      test('remaining step on empty board = 3*3 and 8 on setted one field', () {
        expect(board.remaining, equals(9));
        board[Pos(x: 0, y: 0)] = playerO;
        expect(board.remaining, equals(8));
      });
    });

    group('game', () {
      late Player playerX;
      late Player playerO;
      late Board board;
      late Game game;

      setUp(() {
        board = Board();
        playerX = Player.X();
        playerO = Player.O();
        game = Game(board, playerX, playerO);
      });

      test('empty game has not stopped', () {
        expect(game.stopped, isFalse);
      });

      test('stoppped game on winner', () {
        game.set(playerX, Pos(x: 0, y: 0));
        game.set(playerX, Pos(x: 1, y: 1));
        game.set(playerX, Pos(x: 2, y: 2));
        expect(game.stopped, isTrue);
      });

      test('clear board not stoppped', () {
        game.set(playerX, Pos(x: 0, y: 0));
        game.set(playerX, Pos(x: 1, y: 1));
        game.set(playerX, Pos(x: 2, y: 2));
        expect(game.stopped, isTrue);
        expect(game.initNewGame(), isA<Player>());
        expect(game.stopped, isFalse);
      });

      test('best move returns a position', () {
        expect(game.bestMove(playerO), isA<Pos>());
        List<Pos>? moves = [];
        expect(game.minimax(playerO, moves), isA<int>());
        expect(moves, isNotEmpty);
      });

      test('best move returns last possible position', () {
        expect(game.rating(playerX), equals(0));
        game.set(playerX, Pos(x: 0, y: 0));
        game.set(playerX, Pos(x: 0, y: 1));
        game.set(playerO, Pos(x: 0, y: 2));
        game.set(playerO, Pos(x: 1, y: 0));
        game.set(playerO, Pos(x: 1, y: 1));
        game.set(playerX, Pos(x: 1, y: 2));
        game.set(playerX, Pos(x: 2, y: 0));
        game.set(playerO, Pos(x: 2, y: 1));
        expect(game.stopped, isFalse);
        expect(game.bestMove(playerO), equals(Pos.xy(2, 2)));
        List<Pos>? moves = [];
        expect(game.minimax(playerO, moves), isA<int>());
        expect(moves, isNotEmpty);
        game.set(playerO, moves[0]);
        expect(game.stopped, isTrue);
      });

      test('ai quits the game', () {
        expect(game.rating(playerX), equals(0));
        game.set(playerX, Pos(x: 0, y: 0));
        game.set(playerX, Pos(x: 0, y: 1));
        expect(game.stopped, isFalse);
        expect(game.bestMove(playerX), equals(Pos.xy(0, 2)));
        expect(game.bestMove(playerO), equals(Pos.xy(0, 2)));
        game.set(playerX, Pos(x: 0, y: 2));

        expect(game.rating(playerO), lessThan(0));
        expect(game.rating(playerX), greaterThan(0));
      });

      test('end on wining line', () {
        game.set(playerX, Pos(x: 0, y: 0));
        game.set(playerX, Pos(x: 0, y: 1));
        game.set(playerX, Pos(x: 0, y: 2));
        expect(game.stopped, isTrue);
        expect(board.won, isTrue);
        expect(board.winner, isNot(Board.empty));
      });
    });
  });
}
