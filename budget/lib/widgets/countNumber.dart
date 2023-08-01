import 'dart:math';

import 'package:budget/database/tables.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:provider/provider.dart';

class CountUp extends StatefulWidget {
  const CountUp({
    Key? key,
    required this.count,
    this.fontSize = 16,
    this.prefix = "",
    this.suffix = "",
    this.fontWeight = FontWeight.normal,
    this.textAlign = TextAlign.left,
    this.textColor,
    this.maxLines = null,
    this.duration = const Duration(milliseconds: 3000),
    this.decimals = 2,
    this.curve = Curves.easeOutExpo,
    this.walletPkForCurrency,
  }) : super(key: key);

  final double count;
  final double fontSize;
  final String prefix;
  final String suffix;
  final FontWeight fontWeight;
  final Color? textColor;
  final TextAlign textAlign;
  final int? maxLines;
  final Duration duration;
  final int decimals;
  final Curve curve;
  final int? walletPkForCurrency;

  @override
  State<CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<CountUp> {
  @override
  Widget build(BuildContext context) {
    if (appStateSettings["batterySaver"]) {
      return TextFont(
        text: widget.prefix +
            (widget.count).toStringAsFixed(widget.decimals) +
            widget.suffix,
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        textAlign: widget.textAlign,
        textColor: widget.textColor,
        maxLines: widget.maxLines,
        walletPkForCurrency: widget.walletPkForCurrency,
      );
    }
    return TweenAnimationBuilder<int>(
      tween: IntTween(
          begin: 0, end: (widget.count * pow(10, widget.decimals)).toInt()),
      duration: widget.duration,
      curve: widget.curve,
      builder: (BuildContext context, int animatedCount, Widget? child) {
        String countString = animatedCount.toString();
        return TextFont(
          text: widget.prefix +
              (countString.length >= widget.decimals + 1
                  ? countString.substring(
                      0, countString.length - widget.decimals)
                  : "0") +
              (widget.decimals > 0 ? "." : "") +
              (countString.length >= widget.decimals
                  ? countString.substring(countString.length - widget.decimals)
                  : countString.substring(countString.length - 1)) +
              widget.suffix,
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
          textAlign: widget.textAlign,
          textColor: widget.textColor,
          maxLines: widget.maxLines,
          walletPkForCurrency: widget.walletPkForCurrency,
        );
      },
    );
  }
}

class CountNumber extends StatefulWidget {
  const CountNumber({
    Key? key,
    required this.count,
    required this.textBuilder,
    this.fontSize = 16,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeOutQuint,
    this.initialCount = 0,
    this.decimals,
    this.dynamicDecimals = false,
    this.lazyFirstRender = true,
  }) : super(key: key);

  final double count;
  final Function(double) textBuilder;
  final double fontSize;
  final Duration duration;
  final Curve curve;
  final double initialCount;
  final int? decimals;
  final bool dynamicDecimals;
  final bool lazyFirstRender;

  @override
  State<CountNumber> createState() => _CountNumberState();
}

class _CountNumberState extends State<CountNumber> {
  int finalDecimalPlaces = 2;
  double previousAmount = 0;
  int decimals = 2;
  bool lazyFirstRender = true;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted)
        setState(() {
          int currentSelectedDecimals =
              Provider.of<AllWallets>(context, listen: false)
                      .indexedByPk[appStateSettings["selectedWallet"]]
                      ?.decimals ??
                  2;
          finalDecimalPlaces = ((widget.decimals ?? currentSelectedDecimals) > 2
              ? widget.count.toString().split('.')[1].length <
                      (widget.decimals ?? currentSelectedDecimals)
                  ? widget.count.toString().split('.')[1].length
                  : (widget.decimals ?? currentSelectedDecimals)
              : (widget.decimals ?? currentSelectedDecimals));
          previousAmount = widget.initialCount;
          decimals = finalDecimalPlaces;
          lazyFirstRender = widget.lazyFirstRender;
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dynamicDecimals) {
      if (widget.count % 1 == 0) {
        decimals = 0;
      } else {
        int currentSelectedDecimals = Provider.of<AllWallets>(context)
                .indexedByPk[appStateSettings["selectedWallet"]]
                ?.decimals ??
            2;
        decimals = ((widget.decimals ?? currentSelectedDecimals) > 2
            ? widget.count.toString().split('.')[1].length <
                    (widget.decimals ?? currentSelectedDecimals)
                ? widget.count.toString().split('.')[1].length
                : (widget.decimals ?? currentSelectedDecimals)
            : (widget.decimals ?? currentSelectedDecimals));
      }
    }

    if (appStateSettings["batterySaver"]) {
      return widget.textBuilder(
        double.parse((widget.count).toStringAsFixed(finalDecimalPlaces)),
      );
    }

    if (lazyFirstRender && widget.initialCount == widget.count) {
      lazyFirstRender = false;
      return widget.textBuilder(
        double.parse((widget.count).toStringAsFixed(finalDecimalPlaces)),
      );
    }

    Widget builtWidget = TweenAnimationBuilder<int>(
      tween: IntTween(
        begin: (double.parse(
                    (previousAmount).toStringAsFixed(finalDecimalPlaces)) *
                pow(10, decimals))
            .toInt(),
        end: (double.parse((widget.count).toStringAsFixed(finalDecimalPlaces)) *
                pow(10, decimals))
            .toInt(),
      ),
      duration: widget.duration,
      curve: widget.curve,
      builder: (BuildContext context, int animatedCount, Widget? child) {
        return widget.textBuilder(
          animatedCount / pow(10, decimals).toDouble(),
        );
      },
    );

    previousAmount = widget.count;
    return builtWidget;
  }
}
