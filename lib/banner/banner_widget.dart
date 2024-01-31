import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_banner/banner/custom_page_view.dart';
import 'package:flutter_banner/banner/indicator_plugin.dart';

/// 参考：
/// https://juejin.cn/post/6844903864932663310#heading-2
/// https://juejin.cn/post/6967134993348821023
/// https://www.bilibili.com/video/BV1cV4y1T72E?vd_source=94d85202d2f96b1bd53d83e8103535df
///
/// TODO 自定义动画样式
class BannerWidget extends StatefulWidget {
  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ValueChanged<int>? onPageChanged;

  /// 初始化第几页面，索引从0开始
  final int initialPage;

  /// 轮播间隔时间
  final int delayTime;

  /// 轮播滑动执行时间
  final int scrollTime;

  /// 是否自动轮播
  final bool autoPlay;

  /// 轮播图宽高
  final double itemWidth;
  final double itemHeight;

  /// 轮播图圆角
  final double bannerRadius;

  /// 指示器
  final IndicatorPlugin? indicatorPlugin;

  const BannerWidget({
    Key? key,
    required this.itemBuilder,
    required this.itemCount,
    this.onPageChanged,
    this.initialPage = 0,
    this.delayTime = 3000,
    this.scrollTime = 500,
    this.autoPlay = true,
    this.itemWidth = double.infinity,
    this.itemHeight = double.infinity,
    this.bannerRadius = 0.0,
    this.indicatorPlugin,
  }) : super(key: key);

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  // 页面数量
  int _itemCount = 0;
  CustomPageController? _pageController;

  Timer? _timer;

  // 当前的真实索引
  final ValueNotifier<int> _realIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    if (widget.initialPage > widget.itemCount - 1) {
      throw StateError('InitialPage is out of range.');
    }

    _lastPage = widget.initialPage;

    // >1的情况
    if (widget.itemCount > 1) {
      // 头尾各添加一页，头部添加最后一页，尾部添加第一页
      _itemCount = 1 + widget.itemCount + 1;
      _pageController = CustomPageController(initialPage: widget.initialPage + 1);
    } else {
      // <=1的情况
      _itemCount = widget.itemCount;
    }

    // 页面渲染完成后再开启定时器
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _startLoop();
    });
  }

  @override
  void dispose() {
    super.dispose();
    // 回收
    _stopLoop();
    _realIndex.dispose();
  }

  /// 开始轮播
  _startLoop() {
    if (widget.autoPlay && widget.itemCount > 1) {
      _timer = Timer.periodic(
        Duration(milliseconds: widget.delayTime),
        (timer) {
          _pageController?.nextPage(
            duration: Duration(milliseconds: widget.scrollTime),
            curve: Curves.linear,
          );
        },
      );
    }
  }

  /// 停止轮播
  _stopLoop() {
    _timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.itemWidth,
      height: widget.itemHeight,
      // 一个监听 [Notification] 冒泡树的Widget
      child: NotificationListener<ScrollNotification>(
        onNotification: _onNotification,
        child: Stack(
          children: [
            _buildPager(),
            _buildIndicator(),
          ],
        ),
      ),
    );
  }

  /// 构建页面
  Widget _buildPager() {
    return CustomPageView.builder(
      itemBuilder: (context, index) => _buildPagerChildren(context, index),
      itemCount: _itemCount,
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: widget.itemCount > 1
          ? const CustomPageScrollPhysics()
          : const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildPagerChildren(context, index) {
    int position = 0;
    if (widget.itemCount > 1) {
      position = _getRealIndex(index);
    }
    if (widget.bannerRadius == 0) {
      return widget.itemBuilder(context, position);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.bannerRadius),
      child: widget.itemBuilder(context, position),
    );
  }

  /// 原数据索引 2 012 0 => 真实数据索引 012
  int _getRealIndex(int index) {
    int realIndex = 0;
    if (index == _itemCount - 1) {
      // 当轮播到最后一个位置时，自动修正为第一个位置
      realIndex = 0;
    } else if (index == 0) {
      // 当轮播到第一个位置时，自动修正为倒数第二个位置
      realIndex = _itemCount - 2 - 1;
    } else {
      realIndex = index - 1;
      if (realIndex < 0) realIndex = 0;
    }
    return realIndex;
  }

  /// 监听PageView滚动状态
  bool _onNotification(ScrollNotification notification) {
    // 如果当前处于通知源头并且是滚动开始时的状态
    if (notification.depth == 0 && notification is ScrollStartNotification) {
      // 如果由于拖动而开始滚动，则dragDetails有值，否则为空
      if (notification.dragDetails != null) {
        _stopLoop();
      }
    }
    // 如果是滚动结束时的状态
    if (notification is ScrollEndNotification) {
      _stopLoop();
      _startLoop();
    }
    return true;
  }

  int _lastPage = 0;

  /// 数据2 012 0 => 数据012
  _onPageChanged(page) {
    if (page == _itemCount - 1) {
      // 当轮播到最后一个位置时，自动修正为第一个位置
        _pageController?.jumpToPage(1);
    } else if (page == 0) {
      // 当轮播到第一个位置时，自动修正为倒数第二个位置
        _pageController?.jumpToPage(_itemCount - 2);
    }

    if (page != _lastPage) {
      _lastPage = page;
      // 设置真实索引
      int realIndex = _getRealIndex(page);
      _realIndex.value = realIndex;
      widget.onPageChanged?.call(realIndex);
    }
  }

  /// 构建指示器
  Widget _buildIndicator() {
    if (widget.itemCount > 1 && widget.indicatorPlugin != null) {
      return ValueListenableBuilder(
        valueListenable: _realIndex,
        builder: (context, value, child) {
          return widget.indicatorPlugin!.build(
            context,
            IndicatorPluginConfig(activeIndex: value, itemCount: widget.itemCount),
          );
        },
      );
    }
    return Container();
  }
}
