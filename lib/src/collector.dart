import 'dart:io';

import 'package:lcov_dart/lcov_dart.dart';
import 'package:path/path.dart' as path;

Future runTestsWithCoverage(String packageRoot) async {
  final flutterArgs = ['test', '--coverage', ''];

  final process = await Process.start('flutter', flutterArgs,
      workingDirectory: packageRoot);
  print('exit code: ${await process.exitCode}');
}

double calculateLineCoverage(File lcovReport) {
  final report = Report.fromCoverage(lcovReport.readAsStringSync());
  var totalLines = 0;
  var hitLines = 0;
  for (final rec in report.records) {
    for (final line in rec!.lines!.data) {
      totalLines++;
      hitLines += (line.executionCount > 0) ? 1 : 0;
    }
  }
  return hitLines / totalLines;
}

void generateBadge(Directory packageRoot, double lineCoverage) {
  const leftWidth = 59;
  final value = '${(lineCoverage * 100).floor()}%';
  final color = _color(lineCoverage);
  final metrics = _BadgeMetrics.forPercentage(lineCoverage);
  final rightWidth = metrics.width! - leftWidth;
  final content = _kBadgeTemplate
      .replaceAll('{width}', metrics.width.toString())
      .replaceAll('{rightWidth}', rightWidth.toString())
      .replaceAll('{rightX}', metrics.rightX.toString())
      .replaceAll('{rightLength}', metrics.rightLength.toString())
      .replaceAll('{color}', color.toString())
      .replaceAll('{value}', value.toString());
  File(path.join(packageRoot.path, 'coverage_badge.svg'))
      .writeAsStringSync(content);
}

class _BadgeMetrics {
  final int? width;
  final int? rightX;
  final int? rightLength;

  _BadgeMetrics({this.width, this.rightX, this.rightLength});

  factory _BadgeMetrics.forPercentage(double value) {
    final pct = (value * 100).floor();
    if (pct.toString().length == 1) {
      return _BadgeMetrics(
        width: 88,
        rightX: 725,
        rightLength: 190,
      );
    } else if (pct.toString().length == 2) {
      return _BadgeMetrics(
        width: 94,
        rightX: 755,
        rightLength: 250,
      );
    } else {
      return _BadgeMetrics(
        width: 102,
        rightX: 795,
        rightLength: 330,
      );
    }
  }
}

String _color(double percentage) {
  final map = {
    0.0: _Color(0xE0, 0x5D, 0x44),
    0.5: _Color(0xE0, 0x5D, 0x44),
    0.6: _Color(0xDF, 0xB3, 0x17),
    0.9: _Color(0x97, 0xCA, 0x00),
    1.0: _Color(0x44, 0xCC, 0x11),
  };
  double? lower;
  double? upper;
  for (final key in map.keys) {
    if (percentage < key) {
      upper = key;
      break;
    }
    if (key < 1.0) lower = key;
  }
  upper ??= 1.0;
  final lowerColor = map[lower!]!;
  final upperColor = map[upper]!;
  final range = upper - lower;
  final rangePct = (percentage - lower) / range;
  final pctLower = 1 - rangePct;
  final pctUpper = rangePct;
  final r = (lowerColor.r * pctLower + upperColor.r * pctUpper).floor();
  final g = (lowerColor.g * pctLower + upperColor.g * pctUpper).floor();
  final b = (lowerColor.b * pctLower + upperColor.b * pctUpper).floor();
  final color = _Color(r, g, b);
  return color.toString();
}

class _Color {
  final int r, g, b;

  _Color(this.r, this.g, this.b);

  @override
  String toString() =>
      '#${((1 << 24) + (r << 16) + (g << 8) + b).toRadixString(16).substring(1)}';
}

const _kBadgeTemplate = '''
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{width}" height="20">
  <linearGradient id="b" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="a">
    <rect width="{width}" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#a)">
    <path fill="#555" d="M0 0h59v20H0z"/>
    <path fill="{color}" d="M59 0h{rightWidth}v20H59z"/>
    <path fill="url(#b)" d="M0 0h{width}v20H0z"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="DejaVu Sans,Verdana,Geneva,sans-serif" font-size="110">
    <text x="305" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="490">coverage</text>
    <text x="305" y="140" transform="scale(.1)" textLength="490">coverage</text>
    <text x="{rightX}" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="{rightLength}">{value}</text>
    <text x="{rightX}" y="140" transform="scale(.1)" textLength="{rightLength}">{value}</text>
  </g>
</svg>
''';
