library;

import 'dart:math' as math;

typedef TelemetryLookup = num? Function(String key);

num evaluateFormula(String expression, TelemetryLookup lookup) {
  final tokens = _tokenize(expression);
  if (tokens.isEmpty) return 0;
  final result = _expr(tokens, 0, lookup);
  return result.value;
}

class _Result {
  final num value;
  final int nextPos;
  const _Result(this.value, this.nextPos);
}

enum _TokenKind { number, ident, plus, minus, star, slash, caret, lparen, rparen }

class _Token {
  final _TokenKind kind;
  final String text;
  const _Token(this.kind, this.text);
}

List<_Token> _tokenize(String s) {
  final tokens = <_Token>[];
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == ' ' || c == '\t') {
      i++;
      continue;
    }
    if (c == '+' || c == '-' || c == '*' || c == '/' || c == '^' || c == '(' || c == ')') {
      final kind = switch (c) {
        '+' => _TokenKind.plus,
        '-' => _TokenKind.minus,
        '*' => _TokenKind.star,
        '/' => _TokenKind.slash,
        '^' => _TokenKind.caret,
        '(' => _TokenKind.lparen,
        ')' => _TokenKind.rparen,
        _ => throw const FormatException('bad token'),
      };
      tokens.add(_Token(kind, c));
      i++;
      continue;
    }
    if (_isDigit(c) || c == '.') {
      final start = i;
      while (i < s.length && (_isDigit(s[i]) || s[i] == '.')) {
        i++;
      }
      tokens.add(_Token(_TokenKind.number, s.substring(start, i)));
      continue;
    }
    if (_isIdentStart(c)) {
      final start = i;
      while (i < s.length && (_isIdentPart(s[i]))) {
        i++;
      }
      tokens.add(_Token(_TokenKind.ident, s.substring(start, i)));
      continue;
    }
    throw FormatException('unexpected character: $c');
  }
  return tokens;
}

bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
bool _isIdentStart(String c) => (c.codeUnitAt(0) >= 65 && c.codeUnitAt(0) <= 90) ||
    (c.codeUnitAt(0) >= 97 && c.codeUnitAt(0) <= 122) ||
    c == '_';
bool _isIdentPart(String c) => _isIdentStart(c) || _isDigit(c) || c == '.';

_Result _expr(List<_Token> tokens, int pos, TelemetryLookup lookup) {
  var result = _term(tokens, pos, lookup);
  pos = result.nextPos;
  while (pos < tokens.length) {
    final t = tokens[pos];
    if (t.kind != _TokenKind.plus && t.kind != _TokenKind.minus) break;
    pos++;
    final right = _term(tokens, pos, lookup);
    result = _Result(
      t.kind == _TokenKind.plus ? result.value + right.value : result.value - right.value,
      right.nextPos,
    );
    pos = right.nextPos;
  }
  return _Result(result.value, pos);
}

_Result _term(List<_Token> tokens, int pos, TelemetryLookup lookup) {
  var result = _factor(tokens, pos, lookup);
  pos = result.nextPos;
  while (pos < tokens.length) {
    final t = tokens[pos];
    if (t.kind != _TokenKind.star && t.kind != _TokenKind.slash) break;
    pos++;
    final right = _factor(tokens, pos, lookup);
    result = _Result(
      t.kind == _TokenKind.star ? result.value * right.value : result.value / right.value,
      right.nextPos,
    );
    pos = right.nextPos;
  }
  return _Result(result.value, pos);
}

_Result _factor(List<_Token> tokens, int pos, TelemetryLookup lookup) {
  final base = _primary(tokens, pos, lookup);
  pos = base.nextPos;
  if (pos < tokens.length && tokens[pos].kind == _TokenKind.caret) {
    pos++;
    final exp = _factor(tokens, pos, lookup);
    return _Result(math.pow(base.value, exp.value).toDouble(), exp.nextPos);
  }
  return _Result(base.value, pos);
}

_Result _primary(List<_Token> tokens, int pos, TelemetryLookup lookup) {
  if (pos >= tokens.length) throw const FormatException('unexpected end of expression');
  final t = tokens[pos];
  switch (t.kind) {
    case _TokenKind.number:
      return _Result(num.parse(t.text), pos + 1);
    case _TokenKind.ident:
      final v = lookup(t.text);
      if (v == null) throw FormatException('unknown key: ${t.text}');
      return _Result(v, pos + 1);
    case _TokenKind.minus:
      final operand = _primary(tokens, pos + 1, lookup);
      return _Result(-operand.value, operand.nextPos);
    case _TokenKind.lparen:
      final inner = _expr(tokens, pos + 1, lookup);
      if (inner.nextPos >= tokens.length || tokens[inner.nextPos].kind != _TokenKind.rparen) {
        throw const FormatException('expected )');
      }
      return _Result(inner.value, inner.nextPos + 1);
    default:
      throw FormatException('unexpected token: ${t.text}');
  }
}
