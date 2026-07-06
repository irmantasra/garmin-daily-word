import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Full-screen readings view: date header, First reading / Psalm / Gospel
// references with labels, and the day's short scripture line.
class DailyWordView extends WatchUi.View {

    private var _data as DailyWordData;

    function initialize() {
        View.initialize();
        _data = new DailyWordData(method(:onDataUpdate));
    }

    function onShow() as Void {
        _data.load();
    }

    function onDataUpdate() as Void {
        WatchUi.requestUpdate();
    }

    // Called by the settings menu after the language changes.
    function refresh() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var cx = w / 2;
        var block = _data.localized();

        if (block == null) {
            var msg = _data.errorMsg != null
                ? "Error: " + _data.errorMsg
                : "Loading…";
            dc.drawText(cx, dc.getHeight() / 2, Graphics.FONT_SMALL, msg,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        var y = dc.getHeight() * 0.13;

        // Date header, gold.
        dc.setColor(0xE2B74A, Graphics.COLOR_TRANSPARENT);
        var date = _data.readings != null ? (_data.readings as Dictionary)["date"] : null;
        dc.drawText(cx, y, Graphics.FONT_TINY,
            date instanceof String ? date as String : "",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        y += dc.getFontHeight(Graphics.FONT_TINY) + 6;

        y = drawRow(dc, cx, y, "Reading", block["reading1"]);
        y = drawRow(dc, cx, y, "Reading 2", block["reading2"]);
        y = drawRow(dc, cx, y, "Psalm", block["psalm"]);
        y = drawRow(dc, cx, y, "Gospel", block["gospel"]);

        // Daily scripture line, italic-ish (small font), wrapped.
        var line = block["line"];
        if (line instanceof String && (line as String).length() > 0) {
            y += 4;
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            drawWrapped(dc, cx, y, w - 20, line as String, Graphics.FONT_XTINY);
        }
    }

    // Draws "Label  Reference" and returns the next y. Skips missing refs.
    private function drawRow(dc as Graphics.Dc, cx as Number, y as Numeric,
                             label as String, ref as Object?) as Numeric {
        if (!(ref instanceof String) || (ref as String).length() == 0) {
            return y;
        }
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        y += dc.getFontHeight(Graphics.FONT_XTINY) - 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, ref as String,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        y += dc.getFontHeight(Graphics.FONT_SMALL) + 2;
        return y;
    }

    // Word-wraps text into lines that fit maxW, drawing centered from y.
    private function drawWrapped(dc as Graphics.Dc, cx as Number, y as Numeric,
                                 maxW as Number, text as String, font as Graphics.FontType) as Void {
        var words = splitWords(text);
        var lineH = dc.getFontHeight(font);
        var cur = "";
        for (var i = 0; i < words.size(); i++) {
            var trial = cur.equals("") ? words[i] : cur + " " + words[i];
            if (dc.getTextWidthInPixels(trial, font) > maxW && !cur.equals("")) {
                dc.drawText(cx, y, font, cur,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                y += lineH;
                cur = words[i];
            } else {
                cur = trial;
            }
        }
        if (!cur.equals("")) {
            dc.drawText(cx, y, font, cur,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function splitWords(text as String) as Array<String> {
        var out = [] as Array<String>;
        var cur = "";
        var chars = text.toCharArray();
        for (var i = 0; i < chars.size(); i++) {
            if (chars[i] == ' ') {
                if (!cur.equals("")) {
                    out.add(cur);
                    cur = "";
                }
            } else {
                cur += chars[i].toString();
            }
        }
        if (!cur.equals("")) {
            out.add(cur);
        }
        return out;
    }
}
