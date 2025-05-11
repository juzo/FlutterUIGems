import 'package:flutter/material.dart';
import 'package:shockwave_demo/widgets/cell_widget.dart';
import 'package:shockwave_demo/widgets/consts.dart';

class ShockwaveGrid extends StatefulWidget {
  const ShockwaveGrid({super.key});

  @override
  State<ShockwaveGrid> createState() => _ShockwaveGridState();
}

class _ShockwaveGridState extends State<ShockwaveGrid> {
  int _trigger = 0;
  bool _isAnimating = false;

  /// Default origin
  Offset _waveOrigin = Offset.zero;

  void _handleCellTap(Offset cellCoords) {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
      _waveOrigin = cellCoords;
      _trigger++;
    });
  }

  void _onAnimationComplete() {
    setState(() {
      _isAnimating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Define EdgeInsets objects once if kCellSpacing > 0,
    /// or use EdgeInsets.zero
    const rowPadding = (kCellSpacing > 0)
        ? EdgeInsets.only(bottom: kCellSpacing)
        : EdgeInsets.zero;
    const columnPadding = (kCellSpacing > 0)
        ? EdgeInsets.only(right: kCellSpacing)
        : EdgeInsets.zero;
    const noPadding = EdgeInsets.zero;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kRowCount, (rowIndex) {
        final isLastRow = rowIndex == kRowCount - 1;
        return Padding(
          padding: isLastRow ? noPadding : rowPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(kColumnCount, (columnIndex) {
              final isLastColumn = columnIndex == kColumnCount - 1;
              return Padding(
                padding: isLastColumn ? noPadding : columnPadding,
                child: CellWidget(
                  key: ValueKey('$columnIndex-$rowIndex'),
                  columnIndex: columnIndex,
                  rowIndex: rowIndex,
                  waveOrigin: _waveOrigin,
                  trigger: _trigger,
                  onTap: _handleCellTap,
                  onAnimationComplete: _onAnimationComplete,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
