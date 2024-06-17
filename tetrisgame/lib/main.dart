import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/services.dart'; // Import for LogicalKeyboardKey

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tetris Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TetrisGame(),
    );
  }
}

class TetrisGame extends HookWidget {
  static const int rows = 20;
  static const int cols = 10;
  static const int squareSize = 20;
  static const Color vacantColor = Colors.black;
  static const Duration frameRate = Duration(milliseconds: 500);

  final List<List<Color>> board =
      List.generate(rows, (_) => List.generate(cols, (_) => vacantColor));

  @override
  Widget build(BuildContext context) {
    final piece = useState<Piece>(randomPiece());
    final timer = useState<Timer?>(null);

    useEffect(() {
      timer.value = Timer.periodic(frameRate, (timer) {
        if (!piece.value.moveDown(board)) {
          piece.value.lock(board);
          piece.value = randomPiece();
        }
      });
      return timer.value?.cancel;
    }, []);

    void handleKey(KeyEvent event) {
      if (event is KeyDownEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowLeft: // Arrow Left
            piece.value.moveLeft(board);
            break;
          case LogicalKeyboardKey.arrowUp: // Arrow Up
            piece.value.rotate(board);
            break;
          case LogicalKeyboardKey.arrowRight: // Arrow Right
            piece.value.moveRight(board);
            break;
          case LogicalKeyboardKey.arrowDown: // Arrow Down
            if (!piece.value.moveDown(board)) {
              piece.value.lock(board);
              piece.value = randomPiece();
            }
            break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tetris Game'),
      ),
      body: Focus(
        autofocus: true,
        child: KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: handleKey,
          child: Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.grey[900],
                  child: GridView.builder(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols),
                    itemBuilder: (context, index) {
                      final x = index % cols;
                      final y = index ~/ cols;
                      return Container(
                        margin: EdgeInsets.all(1),
                        color: board[y][x],
                      );
                    },
                    itemCount: rows * cols,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(onPressed: () => piece.value.moveLeft(board), child: Text('Left')),
                  ElevatedButton(onPressed: () => piece.value.rotate(board), child: Text('Rotate')),
                  ElevatedButton(onPressed: () => piece.value.moveRight(board), child: Text('Right')),
                  ElevatedButton(onPressed: () {
                    if (!piece.value.moveDown(board)) {
                      piece.value.lock(board);
                      piece.value = randomPiece();
                    }
                  }, child: Text('Down')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum Tetromino { I, O, T, S, Z, J, L }

class Piece {
  Tetromino type;
  List<List<int>> shape;
  Color color;
  int x;
  int y;

  Piece(this.type, this.shape, this.color)
      : x = 3,
        y = -2;

  static const Map<Tetromino, Color> colors = {
    Tetromino.I: Colors.cyan,
    Tetromino.O: Colors.yellow,
    Tetromino.T: Colors.purple,
    Tetromino.S: Colors.green,
    Tetromino.Z: Colors.red,
    Tetromino.J: Colors.blue,
    Tetromino.L: Colors.orange,
  };

  static const Map<Tetromino, List<List<int>>> shapes = {
    Tetromino.I: [
      [1, 1, 1, 1],
    ],
    Tetromino.O: [
      [1, 1],
      [1, 1],
    ],
    Tetromino.T: [
      [0, 1, 0],
      [1, 1, 1],
    ],
    Tetromino.S: [
      [0, 1, 1],
      [1, 1, 0],
    ],
    Tetromino.Z: [
      [1, 1, 0],
      [0, 1, 1],
    ],
    Tetromino.J: [
      [1, 0, 0],
      [1, 1, 1],
    ],
    Tetromino.L: [
      [0, 0, 1],
      [1, 1, 1],
    ],
  };

  bool moveDown(List<List<Color>> board) {
    if (!checkCollision(board, 0, 1, shape)) {
      y++;
      return true;
    }
    return false;
  }

  void moveLeft(List<List<Color>> board) {
    if (!checkCollision(board, -1, 0, shape)) {
      x--;
    }
  }

  void moveRight(List<List<Color>> board) {
    if (!checkCollision(board, 1, 0, shape)) {
      x++;
    }
  }

  void rotate(List<List<Color>> board) {
    final newShape = rotateShape(shape);
    if (!checkCollision(board, 0, 0, newShape)) {
      shape = newShape;
    }
  }

  void lock(List<List<Color>> board) {
    for (int i = 0; i < shape.length; i++) {
      for (int j = 0; j < shape[i].length; j++) {
        if (shape[i][j] == 1) {
          board[y + i][x + j] = color;
        }
      }
    }
    clearLines(board);
  }

  bool checkCollision(List<List<Color>> board, int offsetX, int offsetY, List<List<int>> newShape) {
    for (int i = 0; i < newShape.length; i++) {
      for (int j = 0; j < newShape[i].length; j++) {
        if (newShape[i][j] == 1) {
          final newX = x + j + offsetX;
          final newY = y + i + offsetY;
          if (newX < 0 || newX >= TetrisGame.cols || newY >= TetrisGame.rows) {
            return true;
          }
          if (newY >= 0 && board[newY][newX] != TetrisGame.vacantColor) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<List<int>> rotateShape(List<List<int>> shape) {
    final newShape = List.generate(shape[0].length, (_) => List.filled(shape.length, 0));
    for (int i = 0; i < shape.length; i++) {
      for (int j = 0; j < shape[i].length; j++) {
        newShape[j][shape.length - i - 1] = shape[i][j];
      }
    }
    return newShape;
  }

  void clearLines(List<List<Color>> board) {
    for (int y = TetrisGame.rows - 1; y >= 0; y--) {
      bool isFullLine = true;
      for (int x = 0; x < TetrisGame.cols; x++) {
        if (board[y][x] == TetrisGame.vacantColor) {
          isFullLine = false;
          break;
        }
      }
      if (isFullLine) {
        for (int newY = y; newY > 0; newY--) {
          for (int newX = 0; newX < TetrisGame.cols; newX++) {
            board[newY][newX] = board[newY - 1][newX];
          }
        }
        for (int newX = 0; newX < TetrisGame.cols; newX++) {
          board[0][newX] = TetrisGame.vacantColor;
        }
        y++;
      }
    }
  }
}

Piece randomPiece() {
  final random = Random();
  final tetrominoType = Tetromino.values[random.nextInt(Tetromino.values.length)];
  return Piece(tetrominoType, Piece.shapes[tetrominoType]!, Piece.colors[tetrominoType]!);
}
