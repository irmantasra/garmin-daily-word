import Toybox.Application;
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
        // Clear to transparent so the system's glance background (a gradient
        // on AMOLED devices) shows through instead of a flat black box.
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.clear();

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

        // Largest font whose text fits the width (and has letters, unlike the
        // digits-only FONT_GLANCE_NUMBER). Keeps the reference big without
        // truncating the book abbreviation.
        var refFont = largestFontThatFits(dc, gospelStr, w - 4);
        var h1 = dc.getFontHeight(refFont);
        var h2 = dc.getFontHeight(Graphics.FONT_XTINY);
        var gap = -2; // lines overlap slightly; font heights include leading
        var blockTop = (h - (h1 + gap + h2)) / 2;
        var top = blockTop + h1 / 2;
        var bottom = blockTop + h1 + gap + h2 / 2;

        dc.setColor(0xE2B74A, Graphics.COLOR_TRANSPARENT); // gold
        dc.drawText(2, top, refFont, gospelStr,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var useLt = Application.Properties.getValue("useLithuanian");
        var invite = (useLt == null || useLt as Boolean)
            ? "Žiūrėti skaitinius" : "Open for readings";
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(2, bottom, Graphics.FONT_XTINY, invite,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Returns the largest font (from big to small) whose text fits maxW.
    // Falls back to the smallest if none fit.
    private function largestFontThatFits(dc as Graphics.Dc, text as String, maxW as Number) as Graphics.FontType {
        var fonts = [
            Graphics.FONT_MEDIUM,
            Graphics.FONT_GLANCE,
            Graphics.FONT_XTINY
        ] as Array<Graphics.FontType>;
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(text, fonts[i]) <= maxW) {
                return fonts[i];
            }
        }
        return Graphics.FONT_XTINY;
    }
}
