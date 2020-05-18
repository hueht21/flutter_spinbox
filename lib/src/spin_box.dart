// MIT License
//
// Copyright (c) 2020 J-P Nurmi <jpnurmi@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'spin_button.dart';
import 'spin_formatter.dart';

/// {@template flutter_spinbox.SpinBox}
/// A numeric input widget with an input field for entering a specific value,
/// and stepper buttons for quick, convenient, and accurate value adjustments.
///
/// SpinBox is best suited for such applications, where users typically know
/// upfront the exact value they are entering, but may later have the need to
/// accurately adjust a previously entered value.
/// {@endtemplate}
class SpinBox extends StatefulWidget {
  SpinBox({
    Key key,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.value = 0,
    this.interval = const Duration(milliseconds: 100),
    this.acceleration,
    this.decimals = 0,
    bool enabled,
    this.autofocus = false,
    TextInputType keyboardType,
    this.textInputAction,
    InputDecoration decoration,
    this.validator,
    List<TextInputFormatter> inputFormatters,
    this.keyboardAppearance,
    Icon incrementIcon,
    Icon decrementIcon,
    this.direction = Axis.horizontal,
    this.textAlign = TextAlign.center,
    this.textDirection,
    this.textStyle,
    this.toolbarOptions,
    this.showCursor,
    this.enableInteractiveSelection = true,
    this.spacing = 8,
    this.onChanged,
  })  : assert(min != null),
        assert(max != null),
        assert(min <= max),
        assert(value != null),
        assert(interval != null),
        assert(direction != null),
        keyboardType = keyboardType ??
            TextInputType.numberWithOptions(
              signed: min < 0,
              decimal: decimals > 0,
            ),
        enabled = (enabled ?? true) && min < max,
        decoration = decoration ?? const InputDecoration(),
        incrementIcon = incrementIcon ?? Icon(Icons.add),
        decrementIcon = decrementIcon ?? Icon(Icons.remove),
        super(key: key);

  /// The minimum value the user can enter.
  ///
  /// Defaults to `0.0`. Must be less than or equal to [max].
  ///
  /// If min is equal to [max], the spinbox is disabled.
  final double min;

  /// The maximum value the user can enter.
  ///
  /// Defaults to `100.0`. Must be greater than or equal to [min].
  ///
  /// If max is equal to [min], the spinbox is disabled.
  final double max;

  /// The step size for incrementing and decrementing the value.
  ///
  /// Defaults to `1.0`.
  final double step;

  /// The current value.
  ///
  /// Defaults to `0.0`.
  final double value;

  /// The number of decimal places used for formatting the value.
  ///
  /// Defaults to `0`.
  final int decimals;

  /// The interval used for auto-incrementing and -decrementing.
  ///
  /// When holding down the increment and decrement buttons, respectively.
  ///
  /// Defaults to `100` milliseconds.
  final Duration interval;

  /// The amount of acceleration that is added to the value on each step.
  ///
  /// When holding down the increment and decrement buttons, respectively.
  ///
  /// Defaults to `null` (no acceleration).
  final double acceleration;

  /// The visual direction of the spinbox layout.
  ///
  /// In horizontal mode the increment and decrement buttons are on the sides,
  /// and in vertical mode the buttons are above and below the input field.
  ///
  /// Defaults to [Axis.horizontal].
  final Axis direction;

  /// The visual spacing of the spinbox layout.
  ///
  /// In horizontal mode the increment and decrement buttons are on the sides,
  /// and in vertical mode the buttons are above and below the input field.
  ///
  /// Defaults to `8.0`.
  final double spacing;

  /// The visual icon for the increment button.
  ///
  /// Defaults to [Icons.add].
  final Icon incrementIcon;

  /// The visual icon for the decrement button.
  ///
  /// Defaults to [Icons.remove].
  final Icon decrementIcon;

  /// Called when the user has changed the value.
  final ValueChanged<double> onChanged;

  /// See [TextField.enabled].
  final bool enabled;

  /// See [TextField.autofocus].
  final bool autofocus;

  /// See [TextField.keyboardType].
  final TextInputType keyboardType;

  /// See [TextField.textInputAction].
  final TextInputAction textInputAction;

  /// See [TextField.decoration].
  final InputDecoration decoration;

  /// See [FormField.validator].
  final FormFieldValidator<String> validator;

  /// See [TextField.keyboardAppearance].
  final Brightness keyboardAppearance;

  /// See [TextField.showCursor].
  final bool showCursor;

  /// See [TextField.enableInteractiveSelection].
  final bool enableInteractiveSelection;

  /// See [TextField.textAlign].
  final TextAlign textAlign;

  /// See [TextField.textDirection].
  final TextDirection textDirection;

  /// See [TextField.style].
  final TextStyle textStyle;

  /// See [TextField.toolbarOptions].
  final ToolbarOptions toolbarOptions;

  @override
  _SpinBoxState createState() => _SpinBoxState();
}

class _SpinBoxState extends State<SpinBox> {
  double _value;
  FocusNode _focusNode;
  TextEditingController _controller;

  double get value => _value;

  static double _parseValue(String text) => double.tryParse(text) ?? 0;
  String _formatText(double value) => value.toStringAsFixed(widget.decimals);

  @override
  void initState() {
    super.initState();
    _value = widget.value;
    _controller = TextEditingController(text: _formatText(_value));
    _controller.addListener(_updateValue);
    _focusNode = FocusNode(onKey: (node, event) => _handleKey(event));
    _focusNode.addListener(_selectAll);
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    _focusNode = null;
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incrementButton = SpinButton(
      step: widget.step,
      icon: widget.incrementIcon,
      enabled: widget.enabled && value < widget.max,
      interval: widget.interval,
      acceleration: widget.acceleration,
      onStep: (step) => _setValue(value + step),
    );

    final decrementButton = SpinButton(
      step: widget.step,
      icon: widget.decrementIcon,
      enabled: widget.enabled && value > widget.min,
      interval: widget.interval,
      acceleration: widget.acceleration,
      onStep: (step) => _setValue(value - step),
    );

    final isHorizontal = widget.direction == Axis.horizontal;
    final errorText = widget.validator?.call(_controller.text);

    final inputDecoration = InputDecoration(
      // all this because
      // - InputDecoration.prefix/suffix and prefix/suffixText cannot be set at the same time
      // - SpinBox wants to wrap prefix/suffix to be able to inject buttons
      // - InputDecoration.copyWith() cannot set prefix/suffix to null
      // -> so, let's make a manual copy of the whole thing :(
      icon: widget.decoration.icon,
      labelText: widget.decoration.labelText,
      labelStyle: widget.decoration.labelStyle,
      helperText: widget.decoration.helperText,
      helperStyle: widget.decoration.helperStyle,
      helperMaxLines: widget.decoration.helperMaxLines,
      hintText: widget.decoration.hintText,
      hintStyle: widget.decoration.hintStyle,
      hintMaxLines: widget.decoration.hintMaxLines,
      errorText: errorText ?? widget.decoration.errorText,
      errorStyle: widget.decoration.errorStyle,
      errorMaxLines: widget.decoration.errorMaxLines,
      floatingLabelBehavior: widget.decoration.floatingLabelBehavior,
      isCollapsed: widget.decoration.isCollapsed,
      isDense: widget.decoration.isDense,
      contentPadding: widget.decoration.contentPadding,
      prefixStyle: widget.decoration.prefixStyle,
      prefixIconConstraints: widget.decoration.prefixIconConstraints,
      suffixStyle: widget.decoration.suffixStyle,
      suffixIconConstraints: widget.decoration.suffixIconConstraints,
      counter: widget.decoration.counter,
      counterText: widget.decoration.counterText,
      counterStyle: widget.decoration.counterStyle,
      filled: widget.decoration.filled,
      fillColor: widget.decoration.fillColor,
      focusColor: widget.decoration.focusColor,
      hoverColor: widget.decoration.hoverColor,
      errorBorder: widget.decoration.errorBorder,
      focusedBorder: widget.decoration.focusedBorder,
      focusedErrorBorder: widget.decoration.focusedErrorBorder,
      disabledBorder: widget.decoration.disabledBorder,
      enabledBorder: widget.decoration.enabledBorder,
      border: widget.decoration.border,
      enabled: widget.decoration.enabled,
      semanticCounterText: widget.decoration.semanticCounterText,
      alignLabelWithHint: widget.decoration.alignLabelWithHint,
      prefix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isHorizontal) decrementButton,
          if (isHorizontal) SizedBox(width: widget.spacing),
          if (widget.decoration.prefixIcon != null)
            widget.decoration.prefixIcon,
          if (widget.decoration.prefix != null) widget.decoration.prefix,
          if (widget.decoration.prefixText != null)
            Text(
              widget.decoration.prefixText,
              style: widget.decoration.prefixStyle,
            ),
        ],
      ),
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.decoration.suffixText != null)
            Text(
              widget.decoration.suffixText,
              style: widget.decoration.suffixStyle,
            ),
          if (widget.decoration.suffix != null) widget.decoration.suffix,
          if (widget.decoration.suffixIcon != null)
            widget.decoration.suffixIcon,
          if (isHorizontal) SizedBox(width: widget.spacing),
          if (isHorizontal) incrementButton,
        ],
      ),
    );

    final textField = TextField(
      controller: _controller,
      style: widget.textStyle,
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      toolbarOptions: widget.toolbarOptions,
      keyboardAppearance: widget.keyboardAppearance,
      inputFormatters: [
        SpinFormatter(
          min: widget.min,
          max: widget.max,
          decimals: widget.decimals,
        ),
      ],
      decoration: inputDecoration,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      showCursor: widget.showCursor,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      focusNode: _focusNode,
    );

    if (isHorizontal) return textField;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        incrementButton,
        SizedBox(height: widget.spacing),
        textField,
        SizedBox(height: widget.spacing),
        decrementButton,
      ],
    );
  }

  bool _handleKey(RawKeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      return event is RawKeyUpEvent || _setValue(value + widget.step);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      return event is RawKeyUpEvent || _setValue(value - widget.step);
    }
    return false;
  }

  void _updateValue() {
    double v = _parseValue(_controller.text);
    if (v == _value) return;
    setState(() => _value = v);
    widget.onChanged?.call(v);
  }

  bool _setValue(double newValue) {
    newValue = newValue?.clamp(widget.min, widget.max);
    if (newValue == null || newValue == value) return false;
    final text = _formatText(newValue);
    final selection = _controller.selection;
    final oldOffset = value.isNegative ? 1 : 0;
    final newOffset = _parseValue(text).isNegative ? 1 : 0;
    setState(() {
      _controller.value = _controller.value.copyWith(
        text: text,
        selection: selection.copyWith(
          baseOffset: selection.baseOffset - oldOffset + newOffset,
          extentOffset: selection.extentOffset - oldOffset + newOffset,
        ),
      );
    });
    return true;
  }

  void _selectAll() {
    if (!_focusNode.hasFocus) return;
    _controller.selection = _controller.selection
        .copyWith(baseOffset: 0, extentOffset: _controller.text.length);
  }
}