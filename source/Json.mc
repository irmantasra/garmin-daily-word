import Toybox.Lang;

// Minimal JSON parser for the readings payload. Needed because
// Communications' native JSON responseType rejects GitHub Pages'
// "application/json; charset=utf-8" content-type with error -400, so we
// fetch the body as plain text and parse it here.
//
// Supports objects, arrays, strings, numbers, booleans and null — enough for
// the scraper's output. Strings may contain raw UTF-8 (the scraper writes
// ensure_ascii=False) plus the standard \" \\ \/ \n \t \r escapes.
(:glance)
class Json {
    private var _s as String;
    private var _chars as Array<Char>;
    private var _i as Number = 0;
    private var _n as Number;

    function initialize(text as String) {
        _s = text;
        _chars = text.toCharArray();
        _n = _chars.size();
    }

    // Parses the string and returns a Dictionary/Array/primitive, or null on
    // malformed input.
    static function parse(text as String) as Object? {
        return new Json(text).run();
    }

    function run() as Object? {
        try {
            skipWs();
            return parseValue();
        } catch (e instanceof Lang.Exception) {
            return null;
        }
    }

    private function peek() as Char {
        return _chars[_i];
    }

    private function next() as Char {
        var c = _chars[_i];
        _i += 1;
        return c;
    }

    private function skipWs() as Void {
        while (_i < _n) {
            var c = _chars[_i];
            if (c == ' ' || c == '\n' || c == '\t' || c == '\r') {
                _i += 1;
            } else {
                return;
            }
        }
    }

    private function parseValue() as Object? {
        var c = peek();
        if (c == '{') {
            return parseObject();
        } else if (c == '[') {
            return parseArray();
        } else if (c == '"') {
            return parseString();
        } else if (c == 't' || c == 'f') {
            return parseBool();
        } else if (c == 'n') {
            _i += 4; // null
            return null;
        }
        return parseNumber();
    }

    private function parseObject() as Dictionary {
        var out = {} as Dictionary;
        _i += 1; // {
        skipWs();
        if (peek() == '}') {
            _i += 1;
            return out;
        }
        var done = false;
        while (!done && _i < _n) {
            skipWs();
            var key = parseString();
            skipWs();
            _i += 1; // :
            skipWs();
            out.put(key, parseValue());
            skipWs();
            if (next() == '}') { // else ',' -> continue
                done = true;
            }
        }
        return out;
    }

    private function parseArray() as Array {
        var out = [] as Array;
        _i += 1; // [
        skipWs();
        if (peek() == ']') {
            _i += 1;
            return out;
        }
        var done = false;
        while (!done && _i < _n) {
            skipWs();
            out.add(parseValue());
            skipWs();
            if (next() == ']') { // else ',' -> continue
                done = true;
            }
        }
        return out;
    }

    private function parseString() as String {
        _i += 1; // opening quote
        var sb = "";
        while (_i < _n) {
            var c = next();
            if (c == '"') {
                return sb;
            }
            if (c == '\\') {
                var e = next();
                if (e == 'n') {
                    sb += "\n";
                } else if (e == 't') {
                    sb += "\t";
                } else if (e == 'r') {
                    sb += "\r";
                } else if (e == 'u') {
                    // \uXXXX — skip the 4 hex digits. The scraper avoids these
                    // (ensure_ascii=False), so this path is defensive only.
                    _i += 4;
                } else {
                    sb += e.toString(); // " \ / and any other escaped char
                }
            } else {
                sb += c.toString();
            }
        }
        return sb;
    }

    private function parseBool() as Boolean {
        if (peek() == 't') {
            _i += 4; // true
            return true;
        }
        _i += 5; // false
        return false;
    }

    private function parseNumber() as Number or Float {
        var start = _i;
        var isFloat = false;
        while (_i < _n) {
            var c = _chars[_i];
            if (c == '-' || c == '+' || (c >= '0' && c <= '9')) {
                _i += 1;
            } else if (c == '.' || c == 'e' || c == 'E') {
                isFloat = true;
                _i += 1;
            } else {
                break;
            }
        }
        var tok = _s.substring(start, _i);
        if (isFloat) {
            return tok.toFloat();
        }
        return tok.toNumber();
    }
}
