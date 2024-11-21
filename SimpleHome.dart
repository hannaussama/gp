
import 'package:flutter/material.dart';
import 'package:gp/src/constants/colors.dart';

enum ShapeType { square, rectangle }

class Shape {
  final ShapeType type;
  final Color color;

  Shape(this.type, this.color);
}

class DragDropGrid extends StatefulWidget {
  @override
  _DragDropGridState createState() => _DragDropGridState();
}

class _DragDropGridState extends State<DragDropGrid> {
  int gridSize = 5; // Grid size is fixed at 5x5
  List<List<List<Shape?>>> layers = []; // A stack of grid layers with Shape objects

  @override
  void initState() {
    super.initState();
    addNewLayer();
  }

  void addNewLayer() {
    setState(() {
      layers.add(List.generate(gridSize, (_) => List.generate(gridSize, (_) => null)));
    });
  }

  void resetGrid() {
    setState(() {
      layers.clear();
      addNewLayer(); // Reset to a single layer
    });
  }

  void calculateResult() {
    showDialog(
      context: context,
      builder: (context) {
        String result = layers.asMap().entries.map((entry) {
          int layerIndex = entry.key;
          List<List<Shape?>> layer = entry.value;

          String matrixOutput = layer.map((row) {
            return row.map((shape) {
              if (shape == null) return "null";
              return shape.type == ShapeType.square ? "Square" : "Rectangle";
            }).join("  ");
          }).join("\n");

          return "Layer ${layerIndex + 1}:\n$matrixOutput";
        }).join("\n\n");

        return AlertDialog(
          title: Text("Total Grid State"),
          content: SingleChildScrollView(
            child: Text(result),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void placeShapeInGrid(int layerIndex, int index, Shape shape) {
    setState(() {
      int x = index ~/ gridSize;
      int y = index % gridSize;

      // Clear the existing shape in the cell
      clearShapeAt(layerIndex, index);

      // Now place the new shape in the cell
      if (shape.type == ShapeType.square) {
        layers[layerIndex][x][y] = shape;
      }
      else if (shape.type == ShapeType.rectangle) {
        // Ensure both current and next cells are empty and enabled for placing a rectangle
        if (y < gridSize - 1) {
          if (layers[layerIndex][x][y] == null && layers[layerIndex][x][y + 1] == null) {
            if (isCellEnabled(layerIndex, x, y) && isCellEnabled(layerIndex, x, y + 1)) {
              layers[layerIndex][x][y] = shape;
              layers[layerIndex][x][y + 1] = shape;
            }
          }
        }
      }
    });
  }




  void clearShapeAt(int layerIndex, int index) {
    int x = index ~/ gridSize;
    int y = index % gridSize;

    Shape? shape = layers[layerIndex][x][y];
    if (shape != null) {
      if (shape.type == ShapeType.rectangle) {
        layers[layerIndex][x][y] = null;
        if (y + 1 < gridSize && layers[layerIndex][x][y + 1] == shape) {
          layers[layerIndex][x][y + 1] = null;
        }
        if (y - 1 >= 0 && layers[layerIndex][x][y - 1] == shape) {
          layers[layerIndex][x][y - 1] = null;
        }
      } else {
        layers[layerIndex][x][y] = null;
      }
    }
  }

  bool isCellEnabled(int layerIndex, int x, int y) {
    if (layerIndex == 0) return true; // Always enabled for the first layer
    return layers[layerIndex - 1][x][y] != null; // Enabled only if the cell is occupied in the previous layer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFC2E3F4),
        title: Text('Home Page',style: TextStyle(color: tButtonColor,fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            icon: Icon(Icons.menu,
            color: tIconColor),
            onPressed: resetGrid,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [Color(0xffc4e0e5),
                Color(0xffa1c6cf)],
              stops: [0, 1],
              center: Alignment(-0.0, -0.0),
            )
        ),
        child: Column(
          children: [
            SizedBox(height: 20,),
            Text(
              'Craft Your Designs, Watch Them Come Alive!',
              style: TextStyle(fontFamily: 'Dancing Script',fontSize: 27,color: tButtonColor, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: layers.length,
                itemBuilder: (context, layerIndex) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          'Layer ${layerIndex + 1}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: tButtonColor),
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Container(
                            width: 450, // Set width for the grid
                            height: 450, // Set height for the grid
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridSize, // Keep 5x5 grid
                                childAspectRatio: 1, // Make cells square-shaped
                                crossAxisSpacing: 4, // Smaller spacing between cells
                                mainAxisSpacing: 4, // Smaller spacing between rows
                              ),
                              itemCount: gridSize * gridSize, // 5x5 grid, so 25 cells
                              itemBuilder: (context, index) {
                                int x = index ~/ gridSize;
                                int y = index % gridSize;
                                bool isEnabled = isCellEnabled(layerIndex, x, y);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      clearShapeAt(layerIndex, index); // Allow clearing the shape on tap
                                    });
                                  },

                                  child: DragTarget<Shape>(
                                    builder: (context, candidateData, rejectedData) {
                                      return GestureDetector(
                                        child: Container(
                                          margin: EdgeInsets.all(4),
                                          color: isCellEnabled(layerIndex, x, y)
                                              ? (layers[layerIndex][x][y]?.color ?? Colors.white)
                                              : Colors.grey[300],
                                          child: Center(
                                            child: Text(
                                              layers[layerIndex][x][y] == null
                                                  ? "Empty"
                                                  : (layers[layerIndex][x][y]?.type == ShapeType.square
                                                  ? "Square"
                                                  : "Rectangle"),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isCellEnabled(layerIndex, x, y) ? Colors.black : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    onWillAccept: (shape) {
                                      // Ensure that the cell is either empty or already occupied by a shape that can be replaced
                                      return true;
                                    },
                                    onAccept: (shape) {
                                      placeShapeInGrid(layerIndex, index, shape); // Place the new shape
                                    },
                                  ),
                                );

                              },
                            ),

                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: tButtonColor),
                    onPressed: calculateResult,
                    child: Text("Submit",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white,side: BorderSide(color: tButtonColor)),
                    onPressed: addNewLayer,
                    child: Text("Add Layer",style: TextStyle(color: tButtonColor,fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Draggable<Shape>(
                    data: Shape(ShapeType.square, Colors.red),
                    feedback: buildShapeWidget(Shape(ShapeType.square, Colors.red)),
                    childWhenDragging: buildShapeWidget(Shape(ShapeType.square, Colors.red.withOpacity(0.5))),
                    child: buildShapeWidget(Shape(ShapeType.square, Colors.red)),
                  ),
                  SizedBox(width: 20),
                  Draggable<Shape>(
                    data: Shape(ShapeType.rectangle, Colors.green),
                    feedback: buildShapeWidget(Shape(ShapeType.rectangle, Colors.green)),
                    childWhenDragging: buildShapeWidget(Shape(ShapeType.rectangle, Colors.green.withOpacity(0.5))),
                    child: buildShapeWidget(Shape(ShapeType.rectangle, Colors.green)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildShapeWidget(Shape shape) {
    return Container(
      width: shape.type == ShapeType.square ? 30 : 60,
      height: 30,
      color: shape.color,
      margin: EdgeInsets.all(4),
    );
  }
}
