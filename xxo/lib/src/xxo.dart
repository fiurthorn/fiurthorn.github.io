import 'dart:math';

class Pos {
  final int x;
  final int y;

  Pos({required this.x, required this.y});

  Pos.xy(this.x, this.y);

  @override
  String toString() => '[$x, $y]';

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
  String toString() => symbol;

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

  Board() : this._(List.filled(size * size, Player.empty()));

  Board._(this._fields);

  bool get won => winner != empty;

  Player get winner {
    var a = get(Pos(x: 1, y: 1));
    if (_inALine(get(Pos(x: 0, y: 0)), a, get(Pos(x: 2, y: 2)))) return a;
    if (_inALine(get(Pos(x: 2, y: 0)), a, get(Pos(x: 0, y: 2)))) return a;
    for (var i = 0; i < size; i++) {
      var b = get(Pos(x: i, y: i));
      if (_inALine(get(Pos(x: 0, y: i)), get(Pos(x: 1, y: i)), get(Pos(x: 2, y: i)))) return b;
      if (_inALine(get(Pos(x: i, y: 0)), get(Pos(x: i, y: 1)), get(Pos(x: i, y: 2)))) return b;
    }
    return empty;
  }

  int get remaining => _fields.where((e) => e == empty).length;

  void set(Player p, Pos xy) {
    if (xy.x >= size || xy.x < 0 || xy.y >= size || xy.y < 0) {
      throw OutOfBoundException();
    }
    if (!isEmpty(xy)) {
      throw NonEmptyFieldException();
    }
    _fields[index(xy)] = p;
  }

  Player get(Pos xy) {
    return _fields[index(xy)];
  }

  bool isEmpty(Pos xy) {
    return get(xy) == empty;
  }

  int index(Pos xy) => xy.y * size + xy.x;

  Pos pos(int index) => Pos(x: index % size, y: index ~/ size);

  bool _inALine(Player a, Player b, Player c) => a == b && b == c && c != empty;

  @override
  String toString() {
    final split = '---\xb7---\xb7---\xb7---';

    final result = StringBuffer();
    for (var i = 0, line = size; i < size; i++, line--) {
      result.writeln(' $line | ${_fields.sublist(line * size - size, line * size).join(' | ')}');
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

class Move {
  int x;
  int y;

  @override
  String toString() => '[$x:$y]';

  Move(this.x, this.y);
  Move.pos(Pos p)
      : x = p.x,
        y = p.y;
}

class Game {
  static final Random rand = Random.secure();

  final Board board;
  final Player playerX;
  final Player playerO;

  Game(this.board, this.playerX, this.playerO);

  bool get stopped => board.remaining == 0 || board.won;

  Player initNewGame() {
    board.clear();
    return rand.nextBool() ? playerX : playerO;
  }

  void set(Player player, Pos pos) => board.set(player, pos);

  Player getNextPlayer(Player player) => _oppoite(player);

  Player _oppoite(Player p) => p == playerO ? playerX : playerO;

  Pos bestMove(Player player) {
    var moves = <Pos>[];
    minimax(player, moves);
    return moves[rand.nextInt(moves.length)];
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
        board.set(player, xy);
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
