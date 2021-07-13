import 'package:dart_console/dart_console.dart';
import 'package:xxo/src/xxo.dart';

void main() => ConsoleGame(Console(), Board(), Player.X(), Player.O()).mixed();

typedef Move = Pos Function(Player p);

class ConsoleGame extends Game {
  final Console console;

  ConsoleGame(this.console, Board board, Player playerX, Player playerO) : super(board, playerX, playerO);

  static final RegExp _extract = RegExp(r'^(?:(?<x>[abc])(?<y>[123])|(?<xy>[1-9]))$');
  static final int _a = _firstCharToInt('a');
  static final int _1 = _firstCharToInt('1');

  Pos _getCoordinates(String line) {
    final result = _extract.firstMatch(line);

    if (result == null) throw WrongInputException();

    final xy = result.namedGroup('xy');
    if (xy != null) {
      return board.pos(int.parse(xy) - 1);
    }

    return Pos(
      x: _firstCharToInt(result.namedGroup('x')!) - _a,
      y: _firstCharToInt(result.namedGroup('y')!) - _1,
    );
  }

  static int _firstCharToInt(String value) => value.isEmpty ? throw WrongInputException() : value.codeUnitAt(0).toInt();

  String _readCoordinatesFromConsole() {
    final numberPattern = RegExp(r'[1-9]');

    final result = List<String>.empty(growable: true);
    while (result.length < 2) {
      final key = console.readKey();
      if (key.isControl && key.controlChar == ControlCharacter.ctrlC) {
        throw CtrlCInputException();
      } else if (key.isControl && key.controlChar == ControlCharacter.backspace && result.isNotEmpty) {
        result.removeLast();
        _removeConsoleChar();
      } else if (!key.isControl) {
        result.add(key.char);
        if (result.length == 1 && key.char.startsWith(numberPattern)) {
          break;
        }
        console.write(key.char);
      }
    }
    return result.join();
  }

  void _removeConsoleChar() {
    console.cursorLeft();
    console.eraseCursorToEnd();
  }

  Move _human() => (_) => _getCoordinates(_readCoordinatesFromConsole());

  Move _ai() => (Player player) => bestMove(player);

  void human() => _play(_human(), _human());

  void mixed() => _play(_ai(), _human());

  void ai() => _play(_ai(), _ai());

  void _play(Move x, Move o) {
    var moves = {playerX: x, playerO: o};

    var draw = 0;

    final alertPostion = Coordinate(0, 0);
    final boardPostion = Coordinate(4, 0);
    final dialogPostion = Coordinate(2, 0);
    // ignore: unused_local_variable
    final printPostion = Coordinate(11, 0);

    game:
    while (true) {
      var player = initNewGame();

      console.setBackgroundColor(ConsoleColor.black);
      console.clearScreen();

      console.setForegroundColor(ConsoleColor.brightGreen);
      console.cursorPosition = boardPostion;
      console.write('$board');

      console.setForegroundColor(ConsoleColor.white);
      while (!stopped) {
        try {
          console.cursorPosition = dialogPostion;
          console.write('Player "${player.symbol}" next turn: ');
          console.eraseCursorToEnd();

          console.showCursor();
          var xy = (moves[player]!)(player);
          console.hideCursor();
          board.set(player, xy);

          console.cursorPosition = Coordinate(boardPostion.row + 4 - xy.y * 2, boardPostion.col + 5 + (xy.x * 4));
          console.setForegroundColor(player == playerX ? ConsoleColor.magenta : ConsoleColor.cyan);
          console.write(player.symbol);
          console.setForegroundColor(ConsoleColor.white);

          console.cursorPosition = alertPostion;
          console.eraseCursorToEnd();

          player = getNextPlayer(player);
        } on CtrlCInputException {
          break game;
        } on XXOException catch (e) {
          console.cursorPosition = alertPostion;
          console.setBackgroundColor(ConsoleColor.red);
          console.writeErrorLine('!!! Fehler ${e.runtimeType}: ${e.toString()} !!!');
          console.setBackgroundColor(ConsoleColor.black);
        }
      }

      console.cursorPosition = alertPostion;
      console.showCursor();
      console.setBackgroundColor(ConsoleColor.blue);
      if (board.won) {
        player.won++;
        console.write('the winner is "${board.winner}"');
      } else {
        draw++;
        console.write('draw!');
      }
      console.setBackgroundColor(ConsoleColor.black);
      console.eraseCursorToEnd();

      console.cursorPosition = dialogPostion;
      console.write('restart game (y/n)? ');
      console.eraseCursorToEnd();
      while (true) {
        final key = console.readKey();
        if (key.controlChar == ControlCharacter.escape) return;
        if (key.controlChar == ControlCharacter.enter) break;
        if (key.char == 'n') break game;
        if (key.char == 'y') break;
      }
    }

    console.clearScreen();
    console.writeLine('${playerX.symbol}: ${playerX.won}');
    console.writeLine('${playerO.symbol}: ${playerO.won}');
    console.writeLine('Draw: $draw');
    console.resetColorAttributes();
  }
}
