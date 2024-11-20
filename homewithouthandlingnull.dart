import 'package:flutter/material.dart';

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
  Shape? selectedShape; // For edit functionality
  int? selectedLayerIndex;
  int? selectedIndex;

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
        // Construct the output for each layer
        String result = layers.asMap().entries.map((entry) {
          int layerIndex = entry.key;
          List<List<Shape?>> layer = entry.value;

          // Format the matrix for this layer
          String matrixOutput = layer.map((row) {
            return row.map((shape) {
              if (shape == null) return "null";
              return shape.type == ShapeType.square ? "Square" : "Rectangle";
            }).join("  ");
          }).join("\n");

          return "Layer ${layerIndex + 1}:\n$matrixOutput";
        }).join("\n\n");

        // Show the dialog with the formatted output
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

      // Clear any overlapping shapes before placing the new one
      clearShapeAt(layerIndex, index);

      // Handle the square shape, placing it in one grid cell
      if (shape.type == ShapeType.square) {
        layers[layerIndex][x][y] = shape;
      }
      // Handle the rectangle shape, which occupies two adjacent cells
      else if (shape.type == ShapeType.rectangle && y < gridSize - 1) {
        // Check if both cells for the rectangle are empty
        if (layers[layerIndex][x][y] == null && layers[layerIndex][x][y + 1] == null) {
          layers[layerIndex][x][y] = shape;
          layers[layerIndex][x][y + 1] = shape; // Place the rectangle across two cells
        }
      }
    });
  }

  void clearShapeAt(int layerIndex, int index) {
    int x = index ~/ gridSize;
    int y = index % gridSize;

    // Check the shape type at the current cell
    Shape? shape = layers[layerIndex][x][y];
    if (shape != null) {
      if (shape.type == ShapeType.rectangle) {
        // Clear both cells occupied by the rectangle
        layers[layerIndex][x][y] = null;
        if (y + 1 < gridSize && layers[layerIndex][x][y + 1] == shape) {
          layers[layerIndex][x][y + 1] = null;
        }
        if (y - 1 >= 0 && layers[layerIndex][x][y - 1] == shape) {
          layers[layerIndex][x][y - 1] = null;
        }
      } else {
        // Clear only the single cell for a square
        layers[layerIndex][x][y] = null;
      }
    }
  }

  void startEditing(int layerIndex, int index) {
    setState(() {
      selectedShape = layers[layerIndex][index ~/ gridSize][index % gridSize];
      selectedLayerIndex = layerIndex;
      selectedIndex = index;

      if (selectedShape != null) {
        // Clear the shape from the grid before starting editing
        clearShapeAt(layerIndex, index);
      }
    });
  }


  void completeEditing(int newLayerIndex, int newIndex) {
    if (selectedShape != null) {
      // Only place the shape if it's a valid placement
      placeShapeInGrid(newLayerIndex, newIndex, selectedShape!);
    }

    setState(() {
      selectedShape = null;
      selectedLayerIndex = null;
      selectedIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multi-Layer Drag & Drop Grid'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetGrid,
          ),
        ],
      ),
      body: Column(
        children: [
          Text(
            'Suggested Design',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: layers.length,
              itemBuilder: (context, layerIndex) {
                return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Layer ${layerIndex + 1}',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                width: 400,
                                height: 400, // Set a fixed width for the grid
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: gridSize,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: gridSize * gridSize,
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () {
                                        startEditing(layerIndex, index);
                                      },
                                      child: DragTarget<Shape>(
                                        builder: (context, candidateData, rejectedData) {
                                          return Container(
                                            margin: EdgeInsets.all(4),
                                            color: layers[layerIndex][index ~/ gridSize][index % gridSize]?.color ?? Colors.white,
                                            child: Center(
                                              child: Text(
                                                layers[layerIndex][index ~/ gridSize][index % gridSize] == null
                                                    ? "Empty"
                                                    : (layers[layerIndex][index ~/ gridSize][index % gridSize]?.type == ShapeType.square
                                                    ? "Square"
                                                    : "Rectangle"),
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        },
                                        onAccept: (shape) {
                                          placeShapeInGrid(layerIndex, index, shape);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: addNewLayer,
                        ),
                      ],
                    )
                );
              },
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: calculateResult,
                    child: Text("Submit"),
                  ),
                ],
              ),
              SizedBox(height: 20),// Space between the submit button and draggable shapes
              Text(
                "Drag & Drop for Bricks", // Text above the draggable shapes
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
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
            ],
          )
        ],
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