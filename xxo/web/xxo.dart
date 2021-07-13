import 'dart:async';
import 'dart:html';

import 'package:xxo/src/xxo.dart';

class WebGame extends Game {
  Player _currentPlayer;

  WebGame(Board board, Player playerX, Player playerO)
      : _currentPlayer = Game.rand.nextBool() ? playerX : playerO,
        super(board, playerX, playerO);

  void turn(int index, bool ai) {
    try {
      if (stopped) return;
      if (ai != (querySelector('#player${_currentPlayer.symbol}')! as InputElement).checked) return;

      board.set(_currentPlayer, board.pos(index));
      querySelector('#-cell-$index')?.text = _currentPlayer.symbol;
      _currentPlayer = getNextPlayer(_currentPlayer);

      if (stopped) {
        highlight();
      } else {
        delayed(checkAI);
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
    delayed(checkAI);
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
    final a = board.get(line[0]);
    final b = board.get(line[1]);
    final c = board.get(line[2]);
    return a == b && b == c && !board.isEmpty(line[2]);
  }

  void checkAI() {
    if (stopped) return;

    if ((querySelector('#player${_currentPlayer.symbol}')! as InputElement).checked ?? false) {
      turn(board.index(bestMove(_currentPlayer)), true);
    }
  }
}

final delay = Duration(milliseconds: 333);
void delayed(FutureOr<dynamic> Function() f) {
  querySelector('#-game-spinner')!.style.display = 'inline-block';
  Future.delayed(delay, f).then((_) => querySelector('#-game-spinner')!.style.display = 'none');
}

void main() {
  var game = WebGame(Board(), Player.X(), Player.O())..initNewGame();

  for (var i = 0; i < 9; i++) {
    querySelector('#-cell-$i')?.onClick.forEach((_) => game.turn(i, false));
  }

  //? reminder setProperty(window, 'turn', allowInterop((int cell) => game.turn(cell)));
  //? reminder setProperty(window, 'clear', allowInterop(() => game.initNewGame()));

  querySelector('#clear')?.onClick.forEach((_) => game.initNewGame());

  for (var i in ['X', 'O']) {
    querySelector('#player$i')?.onChange.forEach((_) => delayed(game.checkAI));
  }
}
