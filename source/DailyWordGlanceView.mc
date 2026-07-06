import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
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
                ? "Error: " + _data.errorMsg
                : "Loading readings…";
            dc.drawText(4, h / 2, Graphics.FONT_GLANCE,
                msg, Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Line 1: the Gospel reference, large and gold.
        // Line 2: a smaller invite to open the app for the full readings.
        var gospel = block["gospel"];
        var gospelStr = gospel instanceof String ? gospel as String : "—";

        // Center the two-line block on h/2 so it aligns with the icon.
        var h1 = dc.getFontHeight(Graphics.FONT_GLANCE_NUMBER);
        var h2 = dc.getFontHeight(Graphics.FONT_XTINY);
        var gap = -2; // lines overlap slightly; font heights include leading
        var blockTop = (h - (h1 + gap + h2)) / 2 + 1;
        var top = blockTop + h1 / 2;
        var bottom = blockTop + h1 + gap + h2 / 2;

        dc.setColor(0xE2B74A, Graphics.COLOR_TRANSPARENT); // gold
        dc.drawText(2, top, Graphics.FONT_GLANCE_NUMBER,
            fit(dc, gospelStr, w - 4, Graphics.FONT_GLANCE_NUMBER),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(2, bottom, Graphics.FONT_XTINY,
            "Open for readings",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
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
