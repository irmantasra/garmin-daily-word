import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class DailyWordGlanceView extends WatchUi.GlanceView {

    private var _data as DailyWordData;

    function initialize() {
        GlanceView.initialize();
        _data = new DailyWordData(method(:onDataUpdate));
    }

    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onShow() as Void {
        _data.load();
    }

    function onDataUpdate() as Void {
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var w = dc.getWidth();
        var h = dc.getHeight();
        var block = _data.localized();

        if (block == null) {
            var msg = _data.errorMsg != null
                ? (WatchUi.loadResource(Rez.Strings.ErrPrefix) as String) + " " + _data.errorMsg
                : WatchUi.loadResource(Rez.Strings.Loading) as String;
            dc.drawText(4, h / 2, Graphics.FONT_GLANCE,
                msg, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Line 1: compact reading references "R1 · Ps · Gospel".
        var refs = joinRefs(block);
        // Line 2: the short daily scripture line.
        var line = block["line"];
        var lineStr = line instanceof String ? line as String : "";

        var y = h * 0.20;
        dc.drawText(4, y, Graphics.FONT_GLANCE_NUMBER,
            refs, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        y = h * 0.62;
        dc.drawText(4, y, Graphics.FONT_GLANCE,
            fit(dc, lineStr, w - 8, Graphics.FONT_GLANCE),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function joinRefs(block as Dictionary) as String {
        var parts = [] as Array<String>;
        var keys = ["reading1", "psalm", "gospel"] as Array<String>;
        for (var i = 0; i < keys.size(); i++) {
            var v = block[keys[i]];
            if (v instanceof String && (v as String).length() > 0) {
                parts.add(v as String);
            }
        }
        var out = "";
        for (var i = 0; i < parts.size(); i++) {
            out += (i == 0 ? "" : "  ·  ") + parts[i];
        }
        return out.length() > 0 ? out : "—";
    }

    // Truncates text with an ellipsis to fit the given pixel width.
    private function fit(dc as Graphics.Dc, text as String, maxW as Number, font as Graphics.FontType) as String {
        if (dc.getTextWidthInPixels(text, font) <= maxW) {
            return text;
        }
        var s = text;
        while (s.length() > 1 && dc.getTextWidthInPixels(s + "…", font) > maxW) {
            s = s.substring(0, s.length() - 1);
        }
        return s + "…";
    }
}
