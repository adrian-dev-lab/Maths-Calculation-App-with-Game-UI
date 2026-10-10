import 'package:flutter/material.dart';
import 'abacus_bead.dart';

class AbacusColumnState {
  bool upperActive = false;
  int lowerActiveCount = 0;

  int get value => (upperActive ? 5 : 0) + lowerActiveCount;
}

class AbacusWidget extends StatefulWidget {
  final int columnCount;
  final ValueChanged<int>? onValueChanged;
  final int? displayValue;
  final bool isInteractive;

  const AbacusWidget({
    super.key,
    this.columnCount = 5,
    this.onValueChanged,
    this.displayValue,
    this.isInteractive = true,
  });

  @override
  State<AbacusWidget> createState() => _AbacusWidgetState();
}

class _AbacusWidgetState extends State<AbacusWidget> {
  late List<AbacusColumnState> columns;

  @override
  void initState() {
    super.initState();
    _initColumns();
  }

  @override
  void didUpdateWidget(covariant AbacusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.columnCount != widget.columnCount ||
        oldWidget.displayValue != widget.displayValue) {
      _initColumns();
    }
  }

  void _initColumns() {
    columns = List.generate(widget.columnCount, (_) => AbacusColumnState());
    if (widget.displayValue != null) {
      int temp = widget.displayValue!;
      for (int i = widget.columnCount - 1; i >= 0; i--) {
        int digit = temp % 10;
        columns[i].upperActive = digit >= 5;
        columns[i].lowerActiveCount = digit % 5;
        temp ~/= 10;
      }
    }
  }

  void _calculateTotal() {
    int total = 0;
    int multiplier = 1;
    for (int i = columns.length - 1; i >= 0; i--) {
      total += columns[i].value * multiplier;
      multiplier *= 10;
    }
    if (widget.onValueChanged != null) {
      widget.onValueChanged!(total);
    }
  }

  void _toggleUpper(int colIndex) {
    if (!widget.isInteractive) return;
    setState(() {
      columns[colIndex].upperActive = !columns[colIndex].upperActive;
    });
    _calculateTotal();
  }

  void _toggleLower(int colIndex, int beadIndex) {
    if (!widget.isInteractive) return;
    setState(() {
      var col = columns[colIndex];
      int targetCount = beadIndex + 1;
      if (col.lowerActiveCount == targetCount) {
        col.lowerActiveCount = beadIndex;
      } else {
        col.lowerActiveCount = targetCount;
      }
    });
    _calculateTotal();
  }

  Widget _buildColumn(int colIndex) {
    var colState = columns[colIndex];
    return Container(
      width: 60,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Flat Grey Rod
          Positioned(
            top: 0,
            bottom: 0,
            child: Container(width: 8, color: Colors.grey[400]),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Upper section
              Container(
                height: 35, // Just enough for 1 bead and margin
                alignment: Alignment.bottomCenter,
                child: AbacusBead(
                  isActive: colState.upperActive,
                  isUpper: true,
                  onTap: () => _toggleUpper(colIndex),
                ),
              ),
              // Flat Grey Reckoning bar
              Container(height: 10, width: 64, color: Colors.grey[400]),
              // Lower section
              Container(
                height: 120, // Just enough for 4 beads
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(4, (index) {
                    bool isActive = index < colState.lowerActiveCount;
                    return AbacusBead(
                      isActive: isActive,
                      isUpper: false,
                      onTap: () => _toggleLower(colIndex, index),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          widget.columnCount,
          (index) => _buildColumn(index),
        ),
      ),
    );
  }
}
