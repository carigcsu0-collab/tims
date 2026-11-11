import 'package:flutter/material.dart';

/// Extension on [Widget] providing reusable modifier methods.
extension WidgetExtensions on Widget {
  /// Wraps the widget in an [Expanded].
  Widget expanded([int flex = 1]) => Expanded(flex: flex, child: this);

  /// Wraps the widget in a [Flexible].
  Widget flexible([FlexFit fit = FlexFit.loose]) =>
      Flexible(fit: fit, child: this);

  /// Wraps the widget in a [Padding] with the given [padding].
  Widget padded(EdgeInsets padding) => Padding(padding: padding, child: this);

  /// Wraps the widget in a [Center].
  Widget centered() => Center(child: this);

  /// Wraps the widget in a [SizedBox] with the given dimensions.
  Widget sized({double? width, double? height}) =>
      SizedBox(width: width, height: height, child: this);

  /// Wraps the widget in a [ClipRRect] with the given border radius.
  Widget clipped(BorderRadius radius) =>
      ClipRRect(borderRadius: radius, child: this);

  /// Wraps the widget in a [Visibility] widget.
  Widget visible(bool visible) => Visibility(visible: visible, child: this);

  /// Adds a tooltip to the widget.
  Widget withTooltip(String message) => Tooltip(
        message: message,
        child: this,
      );
}
