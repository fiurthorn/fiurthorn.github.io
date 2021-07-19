import 'dart:math';

import 'package:xxo/os.dart';

T printit<T>(String prefix, T t) {
  // print('$prefix: $t');
  return t;
}

class Pos {
  final int x;
  final int y;

  const Pos({required this.x, required this.y});

  const Pos.xy(this.x, this.y);

  const Pos.index(int index)
      : x = index % 3,
        y = index ~/ 3;

  @override
  String toString() => '{$x, $y}';

  @override
  int get hashCode => y << 4 + x;

  @override
  bool operator ==(Object other) => other is Pos && other.x == x && other.y == y;
}

class Player {
  static final _empty = Player._(' ');
  static final _x = Player._('X');
  static final _o = Player._('O');

  Player._(this.symbol);

  final String symbol;
  int won = 0;

  factory Player.X() => _x;
  factory Player.O() => _o;
  factory Player.empty() => _empty;

  @override
  String toString() => '<$symbol>';

  @override
  int get hashCode => symbol.hashCode;

  @override
  bool operator ==(Object other) => other is Player && other.symbol == symbol;
}

class Board {
  static const size = 3;
  static int get length => size * size;

  static final empty = Player.empty();

  final List<Player> _fields;

  Board() : this._(List.filled(size * size, empty));

  Board._(this._fields);

  bool get won => winner != empty;

  Player get winner {
    var a = this[Pos(x: 1, y: 1)];
    if (_inALine(this[Pos(x: 0, y: 0)], a, this[Pos(x: 2, y: 2)])) return a;
    if (_inALine(this[Pos(x: 2, y: 0)], a, this[Pos(x: 0, y: 2)])) return a;
    for (var i = 0; i < size; i++) {
      var b = this[Pos(x: i, y: i)];
      if (_inALine(this[Pos(x: 0, y: i)], this[Pos(x: 1, y: i)], this[Pos(x: 2, y: i)])) return b;
      if (_inALine(this[Pos(x: i, y: 0)], this[Pos(x: i, y: 1)], this[Pos(x: i, y: 2)])) return b;
    }
    return empty;
  }

  int get remaining => _fields.where((e) => e == empty).length;

  void operator []=(Pos xy, Player p) {
    if (xy.x >= size || xy.x < 0 || xy.y >= size || xy.y < 0) {
      throw OutOfBoundException();
    }
    if (!isEmpty(xy)) {
      throw NonEmptyFieldException();
    }
    _fields[index(xy)] = p;
  }

  Player operator [](Pos xy) {
    return _fields[index(xy)];
  }

  bool isEmpty(Pos xy) {
    return this[xy] == empty;
  }

  int index(Pos xy) => xy.y * size + xy.x;

  Pos pos(int index) => Pos(x: index % size, y: index ~/ size);

  bool _inALine(Player a, Player b, Player c) => a == b && b == c && c != empty;

  @override
  String toString() {
    final split = '---\xb7---\xb7---\xb7---';

    final result = StringBuffer();
    for (var i = 0, line = size; i < size; i++, line--) {
      result.writeln(' $line | ${_fields.sublist(line * size - size, line * size).map((e) => e.symbol).join(' | ')}');
      result.writeln(split);
    }
    result.writeln('   | a | b | c');

    return result.toString();
  }

  Pos emptyField() {
    final index = _fields.indexOf(empty);
    return index < 0 ? throw OutOfBoundException() : pos(index);
  }

  void clear() => _fields.fillRange(0, _fields.length, empty);

  Board clone() {
    return Board._(List.from(_fields));
  }

  void unset(Pos xy) => _fields[index(xy)] = empty;
}

class Game {
  static final Random rand = Random.secure();

  final Board board;
  final Player playerX;
  final Player playerO;

  Game(this.board, this.playerX, this.playerO);

  bool get stopped => board.remaining == 0 || board.won;

  Player initNewGame() {
    print('${OperationSystem.name} (${OperationSystem.version})');
    // print(Platform.operatingSystemVersion);
    // print(Platform.environment);

    board.clear();
    return rand.nextBool() ? playerX : playerO;
  }

  void set(Player player, Pos pos) => board[pos] = player;

  Player getNextPlayer(Player player) => _oppoite(player);

  Player _oppoite(Player p) => p == playerO ? playerX : playerO;

  static const edges = [
    Pos.xy(2, 2),
    Pos.xy(1, 1),
    Pos.xy(0, 0),
    Pos.xy(2, 0),
    Pos.xy(0, 2),
  ];

  static final lines = ({
    0: [
      [3, 6],
      [4, 8],
      [1, 2],
    ],
    1: [
      [0, 2],
      [4, 7],
    ],
    2: [
      [0, 1],
      [4, 6],
      [5, 8],
    ],
    3: [
      [0, 6],
      [4, 5],
    ],
    4: [
      [3, 5],
      [0, 8],
      [1, 7],
      [2, 6],
    ],
    5: [
      [3, 4],
      [2, 8],
    ],
    6: [
      [3, 0],
      [4, 2],
      [7, 8],
    ],
    7: [
      [6, 8],
      [4, 1],
    ],
    8: [
      [6, 7],
      [0, 4],
      [2, 5],
    ],
  }.map(convert));

  static MapEntry<Pos, Iterable<List<Pos>>> convert(int key, List<List<int>> value) => MapEntry(Pos.index(key), value.map(listToPos));

  static List<Pos> listToPos(List<int> e) => [Pos.index(e[0]), Pos.index(e[1])];

  List<Pos> adjust(List<Pos> selected, Player player) {
    if (selected.length == 1) return selected;

    final adjusted = List.of(selected)..retainWhere((pos) => retainLinesWithEmptyAndOwnField(pos, player));
    return adjusted.isEmpty ? selected : adjusted;
  }

  bool retainLinesWithEmptyAndOwnField(Pos element, Player player) {
    return lines[element]!.fold<bool>(false, (select, line) => foldLinesToEmptyAndOwn(select, line, player));
  }

  bool foldLinesToEmptyAndOwn(bool select, List<Pos> line, Player player) {
    if (select) return true;
    final positions = line.map((pos) => board[pos]);
    final empties = positions.where((sym) => sym == Board.empty).length;
    final owns = positions.where((sym) => sym == player).length;
    return empties == 1 && owns == 1;
  }

  Pos bestMove(Player player) {
    final moves = <Pos>[];
    final score = minimax(player, moves);
    if (score == 0 && moves.length > 1) {
      final selected = printit('$player selected (1)', (printit('$player moves', List<Pos>.from(moves))..retainWhere((e) => edges.contains(e))));
      if (selected.length > 1) {
        if (board.remaining > 6) {
          return printit('$player turn (2) [${board.remaining}]', printit('$player selected (2)', selected)[rand.nextInt(selected.length)]);
        }

        final adjusted = adjust(selected, player);
        return printit('$player turn (3)', printit('$player adjusted $selected vs', adjusted)[rand.nextInt(adjusted.length)]);
      }
    }
    return printit('$player turn (1)', moves[rand.nextInt(moves.length)]);
  }

  int rating(Player player) {
    if (board.won) {
      return (player == board.winner ? 10 : -10) * (board.remaining + 1);
    }
    return 0;
  }

  int minimax(Player player, List<Pos>? move) {
    if (board.won || board.remaining == 0) {
      return rating(player);
    }

    var bestScore = -1000;
    for (var i = 0, len = Board.length; i < len; i++) {
      var xy = board.pos(i);
      if (board.isEmpty(xy)) {
        board[xy] = player;
        final score = -minimax(_oppoite(player), null);
        board.unset(xy);
        if (score > bestScore) {
          if (move != null) move.clear();
          bestScore = score;
        }
        if (bestScore == score && move != null) {
          move.add(xy);
        }
      }
    }
    return bestScore;
  }
}

class XXOException implements Exception {}

class NonEmptyFieldException implements XXOException {}

class OutOfBoundException implements XXOException {}

class WrongInputException implements XXOException {}

class CtrlCInputException implements XXOException {}
