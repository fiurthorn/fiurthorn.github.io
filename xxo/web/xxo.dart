import 'dart:async';
import 'dart:collection';
import 'dart:html';

import 'package:xxo/src/xxo.dart';

class WebGame extends Game {
  Player _currentPlayer;
  final queue = SyncQueue();

  WebGame(Board board, Player playerX, Player playerO)
      : _currentPlayer = Game.rand.nextBool() ? playerX : playerO,
        super(board, playerX, playerO) {
    for (var i = 0; i < 9; i++) {
      querySelector('#-cell-$i')?.onClick.forEach((_) => turn(i, false));
    }

    //? reminder setProperty(window, 'turn', allowInterop((int cell) => game.turn(cell)));
    //? reminder setProperty(window, 'clear', allowInterop(() => game.initNewGame()));

    querySelector('#clear')?.onClick.forEach((_) => printit('-- new game ---', initNewGame()));

    for (var i in ['X', 'O']) {
      querySelector('#player$i')?.onChange.forEach((_) => queue.queue(checkAI));
    }
  }

  void turn(int index, bool ai) {
    try {
      if (stopped || ai != checkAiFlag(_currentPlayer)) return;

      board[board.pos(index)] = _currentPlayer;
      querySelector('#-cell-$index')?.text = _currentPlayer.symbol;
      _currentPlayer = getNextPlayer(_currentPlayer);

      if (stopped) {
        highlight();
      } else if (checkAiFlag(_currentPlayer)) {
        queue.queue(checkAI);
      }
    } on Exception catch (e, t) {
      print('$e: $t');
    }
  }

  @override
  Player initNewGame() {
    _currentPlayer = super.initNewGame();

    board.clear();
    for (var i = 0, len = Board.size * Board.size; i < len; i++) {
      querySelector('#-cell-$i')
        ?..text = ''
        ..classes.removeAll(['won', 'draw']);
    }
    _currentPlayer = getNextPlayer(_currentPlayer);

    querySelector('#nextPlayer')?.text = 'Next Player: ${_currentPlayer.symbol}';
    queue.queue(checkAI);
    return _currentPlayer;
  }

  @override
  Player getNextPlayer(Player player) {
    final nextPlayer = super.getNextPlayer(player);
    querySelector('#nextPlayer')?.text = 'Next Player: ${nextPlayer.symbol}';
    return nextPlayer;
  }

  final lines = [
    [Pos.xy(0, 0), Pos.xy(0, 1), Pos.xy(0, 2)],
    [Pos.xy(1, 0), Pos.xy(1, 1), Pos.xy(1, 2)],
    [Pos.xy(2, 0), Pos.xy(2, 1), Pos.xy(2, 2)],
    [Pos.xy(0, 0), Pos.xy(1, 0), Pos.xy(2, 0)],
    [Pos.xy(0, 1), Pos.xy(1, 1), Pos.xy(2, 1)],
    [Pos.xy(0, 2), Pos.xy(1, 2), Pos.xy(2, 2)],
    [Pos.xy(0, 0), Pos.xy(1, 1), Pos.xy(2, 2)],
    [Pos.xy(0, 2), Pos.xy(1, 1), Pos.xy(2, 0)],
  ];

  void highlight() {
    for (var line in lines) {
      if (aLine(line)) {
        for (var i = 0; i < 3; i++) {
          querySelector('#-cell-${line[i].x + line[i].y * 3}')?.classes.add('won');
        }
        return;
      }
    }
    for (var i = 0; i < 9; i++) {
      querySelector('#-cell-$i')?.classes.add('draw');
    }
  }

  bool aLine(List<Pos> line) {
    final a = board[line[0]];
    final b = board[line[1]];
    final c = board[line[2]];
    return a == b && b == c && !board.isEmpty(line[2]);
  }

  void checkAI() {
    if (stopped) return;

    if (checkAiFlag(_currentPlayer)) {
      turn(board.index(bestMove(_currentPlayer)), true);
    }
  }

  bool checkAiFlag(Player player) =>
      (querySelector('#player${player.symbol}')!.querySelector('input') as InputElement).checked ?? false;
}

class SyncQueue {
  static final _delay = Duration(milliseconds: 100);
  final _queue = Queue<Function>();
  late final Stream<int> _timer = Stream.periodic(_delay, _period);
  late final _listener = _timer.listen(_OnData);

  void queue(FutureOr<dynamic> Function() f) {
    querySelector('#-game-spinner')!.style.display = 'inline-block';
    _queue.add(f);
    _listener.resume();
  }

  int _period(int x) {
    if (_queue.isNotEmpty) {
      (_queue.removeFirst())();
    } else {
      querySelector('#-game-spinner')!.style.display = 'none';
      _listener.pause();
    }
    return x;
  }

  void _OnData(int event) => null;
}

void main() => WebGame(Board(), Player.X(), Player.O())..initNewGame();
