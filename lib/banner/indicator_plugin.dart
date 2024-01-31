import 'package:flutter/material.dart';

abstract class IndicatorPlugin {
  const IndicatorPlugin();

  Widget build(BuildContext context, IndicatorPluginConfig config);
}

class IndicatorPluginConfig {
  final int activeIndex;
  final int itemCount;

  const IndicatorPluginConfig({this.activeIndex = 0, this.itemCount = 0});
}
