import 'package:flutter/material.dart';
import 'package:flutter_banner/banner/indicator_plugin.dart';

/// 矩形 or 圆角矩形 or 圆形指示器（默认展示圆形指示器）
class RectOrCircularIndicator extends IndicatorPlugin {
  /// 宽
  final double width;

  /// 高
  final double height;

  /// 圆角
  final double indicatorRadius;

  /// 指示器之间的间距
  final double indicatorSpace;

  /// 指示器与底部之间的间距
  final double indicatorMarginBottom;

  /// 选中的颜色
  final Color selectedColor;

  /// 未选中的颜色
  final Color unselectedColor;

  const RectOrCircularIndicator({
    this.width = 8.0,
    this.height = 8.0,
    this.indicatorRadius = 8.0,
    this.indicatorSpace = 5.0,
    this.indicatorMarginBottom = 8.0,
    this.selectedColor = Colors.red,
    this.unselectedColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context, IndicatorPluginConfig config) {
    final List<Widget> list = [];
    for (int i = 0; i < config.itemCount; i++) {
      bool active = config.activeIndex == i;
      list.add(Container(
        width: width,
        height: height,
        margin: EdgeInsets.only(
            left: indicatorSpace, bottom: indicatorMarginBottom),
        decoration: BoxDecoration(
            color: active ? selectedColor : unselectedColor,
            borderRadius: BorderRadius.circular(indicatorRadius)),
      ));
    }
    return Align(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: list,
      ),
    );
  }
}
