import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/flame.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setPortrait();
  final game = TicTacToe();
  runApp(GameWidget(game: game));
}

class TicTacToe extends FlameGame with HasHoverables, HasTappables {
  late Board board;
  late NewGameButton newGameButton;
  TextComponent title = TextComponent(
      text: "Tic-Tac-Toe",
      textRenderer:
          TextPaint(style: const TextStyle(color: Colors.black, fontSize: .1)));
  TicTacToe() {
    init();
  }
  void init() {
    camera.viewport = FixedResolutionViewport(Vector2.all(1));
    board = Board(this);
    title.center = Vector2(
        camera.gameSize.x / 2 + title.width / 4, camera.gameSize.y / 10);
    newGameButton = NewGameButton(this, Vector2(camera.gameSize.x / 2 - camera.gameSize.x / 8, camera.gameSize.y / 8), Vector2(camera.gameSize.x / 4, camera.gameSize.y / 14));
  }

  @override
  Color backgroundColor() => Colors.white;
  @override
  Future<void> onLoad() async {
    add(board);
    add(title);
    add(newGameButton);
    return super.onLoad();
  }
}

class NewGameButton extends RectangleComponent with Hoverable, Tappable {
  TextComponent text = TextComponent(text: "New Game", textRenderer: TextPaint(style: const TextStyle(color: Colors.white, fontSize: .04)));
  TicTacToe game;
  NewGameButton(this.game, position, size):super(position: position, size: size){
    paint = Paint();
    paint.color = Colors.lightBlue;
    text.center = Vector2(.5+text.width/40, .05);
  }
  @override
  Future<void> onLoad() async {
    add(text);
  }
  @override
  bool onTapDown(TapDownInfo info) {
    game.remove(game.board);
    game.board = Board(game);
    game.add(game.board);
    return true;
  }
}

class Board extends RectangleComponent {
  late List tiles;
  late Status status;
  String turn = "x";
  TicTacToe game;
  String winner = "";
  Board(this.game)
      : super.square(
            position:
                Vector2(game.camera.gameSize.x / 3, game.camera.gameSize.y / 3),
            size: game.camera.gameSize.x / 3) {
    paint = Paint();
    paint.color = Colors.black;
    paint.isAntiAlias = false;
    tiles = List.generate(
        3,
        (index) => List.generate(
            3,
            (index2) => Tile(this, [index, index2],
                Vector2(width / 3 * index, height / 3 * index2), width / 3)));
    status = Status(this);
    status.center = Vector2(2 / 3 - status.width / 10, 0);
  }
  @override
  Future<void>? onLoad() {
    for (var i in tiles) {
      addAll(i);
    }
    add(status);
    return super.onLoad();
  }

  void takeTurn(Tile tile) {
    if (tile.owner != "" || winner != "") {
      return;
    }
    tile.owner = turn;
    if (checkThree() != "") {
      winner = checkThree();
      status.text = winner.toUpperCase() + " wins!";
    } else {
      turn = turn == "x" ? "o" : "x";
      status.text = turn.toUpperCase() + "'s Turn";
    }
  }

  String checkThree() {
    for (var i = 0; i < 3; i++) {
      if (tiles[i][i].owner == "") {
        continue;
      }
      if (tiles[i].every((element) => element.owner == tiles[i][i].owner) ||
          tiles.every((element) => element[i].owner == tiles[i][i].owner)) {
        return tiles[i][i].owner;
      }
    }
    if (tiles[1][1].owner != "") {
      if ((tiles[0][0].owner == tiles[1][1].owner &&
              tiles[1][1].owner == tiles[2][2].owner) ||
          (tiles[0][2].owner == tiles[1][1].owner &&
              tiles[1][1].owner == tiles[2][0].owner)) {
        return tiles[1][1].owner;
      }
    }
    if (!tiles
        .any((element) => element.any((belement) => belement.owner == ""))) {
      return "tie";
    }
    return "";
  }
}

class Status extends TextComponent {
  Board board;
  TextPaint paint =
      TextPaint(style: const TextStyle(color: Colors.red, fontSize: .05));
  Status(this.board)
      : super(
            text: board.turn.toUpperCase() + "'s Turn",
            textRenderer: TextPaint()) {
    textRenderer = paint;
  }
  @override
  void render(Canvas canvas) {
    paint = TextPaint(
        style: TextStyle(
            color: board.turn == "x" ? Colors.red : Colors.blue,
            fontSize: .05));
    textRenderer = paint;
    super.render(canvas);
  }
}

class Tile extends RectangleComponent with Hoverable, Tappable {
  late TextComponent text;
  late TextPaint textPaint;
  late ColorEffect hoverEffect;
  bool hoverIn = false;
  String owner;
  List coords;
  Board board;
  Tile(this.board, this.coords, position, size, {this.owner = ""})
      : super.square(position: position, size: size) {
    paint = Paint();
    paint.color = Colors.white;
    paint.isAntiAlias = false;
    text = TextComponent(text: owner);
    textPaint = TextPaint(
        style: TextStyle(
            color: owner == "x" ? Colors.red : Colors.blue, fontSize: .07));
    text.textRenderer = textPaint;
    text.center = Vector2(.0375, .075);
    hoverEffect = ColorEffect(
      Colors.grey,
      const Offset(0, 1),
      EffectController(duration: .2, alternate: true, infinite: true)
    );
    hoverEffect.pause();
    add(hoverEffect);
  }
  @override
  Future<void>? onLoad() {
    add(text);
    super.onLoad();
    return null;
  }

  @override
  bool onTapDown(TapDownInfo info) {
    hoverEffect.reset();
    remove(hoverEffect);
    paint.color = Colors.white;
    board.takeTurn(this);
    return true;
  }
  @override
  bool onHoverEnter(PointerHoverInfo info){
    hoverIn = true;
    if(owner==""&&board.winner=="") {
      hoverEffect.resume();
    }
    return true;
  }
  @override
  bool onHoverLeave(PointerHoverInfo info){
    hoverIn = false;
    if(owner==""&&board.winner=="") {
      hoverEffect.resume();
    }
    return true;
  }

  @override
  void render(Canvas canvas) async{
    text.text = owner;
    textPaint = TextPaint(
        style: TextStyle(
            color: owner == "x" ? Colors.red : Colors.blue, fontSize: .07));
    text.textRenderer = textPaint;
    if(!hoverEffect.isPaused && (hoverIn?(hoverEffect.controller.progress+.1>=1):(hoverEffect.controller.progress-.1<=0))){
      hoverEffect.pause();
      hoverEffect.apply(hoverIn?1:0);
    }
    if(!(owner==""&&board.winner=="")){
      if(hoverEffect.isMounted) {
        hoverEffect.reset();
        hoverEffect.pause();
      }
      paint.color = Colors.white;
    }
    canvas.drawRect(Rect.fromCenter(center: Offset(width/2, height/2), width: width, height: height), Paint()..color = Colors.black ..style = PaintingStyle.stroke ..strokeWidth = .002);
    super.render(canvas);
  }
}
