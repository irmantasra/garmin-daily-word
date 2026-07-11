import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Scrollable readings view: Bible icon, date + liturgical event, the reading
// references (label above reference, with a gap), and the daily line.
// UP/DOWN scroll the content so nothing is clipped by the round screen.
class DailyWordView extends WatchUi.View {

    private var _data as DailyWordData;
    private var _icon as WatchUi.BitmapResource?;
    // Not private: WatchUi.animate() writes this member by symbol.
    var _scroll as Numeric = 0;             // px scrolled from the top
    private var _contentH as Number = 0;    // total drawn height (last frame)
    private var _viewH as Number = 0;

    function initialize() {
        View.initialize();
        _data = new DailyWordData(method(:onDataUpdate));
    }

    function onLayout(dc as Graphics.Dc) as Void {
        _icon = WatchUi.loadResource(Rez.Drawables.LauncherIcon) as WatchUi.BitmapResource;
    }

    function onShow() as Void {
        _data.load();
    }

    function onDataUpdate() as Void {
        WatchUi.requestUpdate();
    }

    // Called by the settings menu after the language changes.
    function refresh() as Void {
        _scroll = 0;
        WatchUi.requestUpdate();
    }

    private function maxScroll() as Number {
        var m = _contentH - _viewH;
        return m < 0 ? 0 : m;
    }

    // Animates the scroll offset to a clamped target so motion feels smooth
    // (used for both swipes and button presses).
    function scrollTo(target as Number) as Void {
        var m = maxScroll();
        if (target < 0) {
            target = 0;
        } else if (target > m) {
            target = m;
        }
        WatchUi.cancelAllAnimations();
        if (target == _scroll) {
            return;
        }
        WatchUi.animate(self, :_scroll, WatchUi.ANIM_TYPE_EASE_OUT,
            _scroll, target, 0.25, null);
    }

    // Scrolls by a fraction of the visible height (positive = down).
    function scrollByPage(fraction as Float) as Void {
        scrollTo(_scroll + (_viewH * fraction).toNumber());
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var cx = w / 2;
        _viewH = dc.getHeight();
        var block = _data.localized();

        if (block == null) {
            var msg = _data.errorMsg != null
                ? "Error: " + _data.errorMsg
                : "Loading…";
            dc.drawText(cx, _viewH / 2, Graphics.FONT_SMALL, msg,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            return;
        }

        // Top margin scales with screen height so content clears the round
        // screen's top chord on small and large devices alike.
        var topMargin = _viewH / 8;
        // y walks down the virtual (unscrolled) content; subtract _scroll to
        // place it on screen.
        var y = topMargin - _scroll;

        // Bible icon, centered (gap scales with screen).
        if (_icon != null) {
            var iw = (_icon as WatchUi.BitmapResource).getWidth();
            dc.drawBitmap(cx - iw / 2, y, _icon as WatchUi.BitmapResource);
            y += (_icon as WatchUi.BitmapResource).getHeight() + _viewH / 20;
        }

        // Date, gold.
        dc.setColor(0xE2B74A, Graphics.COLOR_TRANSPARENT);
        var date = _data.readings != null ? (_data.readings as Dictionary)["date"] : null;
        if (date instanceof String) {
            dc.drawText(cx, y, Graphics.FONT_TINY, date as String,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            y += dc.getFontHeight(Graphics.FONT_TINY);
        }

        // Liturgical event, white, wrapped. A small season-colored dovetail
        // pennant sits just left of the first line.
        var event = block["event"];
        if (event instanceof String && (event as String).length() > 0) {
            var color = seasonColor();
            if (color >= 0) {
                var fh = dc.getFontHeight(Graphics.FONT_XTINY);
                var firstLine = firstWrappedLine(dc, event as String, w - 24, Graphics.FONT_XTINY);
                var lineW = dc.getTextWidthInPixels(firstLine, Graphics.FONT_XTINY);
                var flagW = (fh * 0.9).toNumber();
                var flagH = (fh * 0.55).toNumber();
                var flagX = cx - lineW / 2 - flagW - 4;
                drawFlag(dc, flagX, y, flagW, flagH, color);
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            y = drawWrapped(dc, cx, y, w - 24, event as String, Graphics.FONT_XTINY);
        }
        y += 10;

        var lt = LanguageMenu.usingLithuanian();
        y = drawRow(dc, cx, y, lt ? "Pirmasis skaitinys" : "1st Reading", block["reading1"]);
        y = drawRow(dc, cx, y, lt ? "Antrasis skaitinys" : "2nd Reading", block["reading2"]);
        y = drawRow(dc, cx, y, lt ? "Psalmė" : "Psalm", block["psalm"]);
        y = drawRow(dc, cx, y, lt ? "Evangelija" : "Gospel", block["gospel"]);

        // Record total content height for scroll clamping.
        _contentH = y + _scroll + 8;

        drawScrollHint(dc, w);
    }

    // Draws label then reference (wrapped if long) below it, returns next y.
    private function drawRow(dc as Graphics.Dc, cx as Number, y as Numeric,
                             label as String, ref as Object?) as Numeric {
        if (!(ref instanceof String) || (ref as String).length() == 0) {
            return y;
        }
        var w = dc.getWidth();
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        y += dc.getFontHeight(Graphics.FONT_XTINY) + 8; // gap label -> ref

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        y = drawWrapped(dc, cx, y, w - 16, ref as String, Graphics.FONT_SMALL);
        y += 8; // gap to next row
        return y;
    }

    // Liturgical season color from the readings data (or -1 for none).
    private function seasonColor() as Number {
        var r = _data.readings;
        if (!(r instanceof Dictionary)) {
            return -1;
        }
        var s = (r as Dictionary)["season"];
        if (!(s instanceof String)) {
            return -1;
        }
        if (s.equals("ordinary")) { return 0x2E9E4F; }  // green
        if (s.equals("lent"))     { return 0x8A5CC8; }  // violet
        if (s.equals("festive"))  { return 0xEACB5A; }  // gold/white
        if (s.equals("red"))      { return 0xD0392B; }  // red
        if (s.equals("rose"))     { return 0xE79ABD; }  // rose
        return -1;
    }

    // Draws a small dovetail (swallowtail) pennant with its pole at (x, top).
    private function drawFlag(dc as Graphics.Dc, x as Number, top as Numeric,
                              fw as Number, fh as Number, color as Number) as Void {
        var poleX = x;
        var poleTop = top;
        var poleBot = top + (fh * 1.7).toNumber();
        // Pole.
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(poleX, poleTop, poleX, poleBot);
        dc.setPenWidth(1);
        // Pennant: rectangle-ish body with a V-notch cut into the fly end.
        var fx = poleX + 1;
        var notch = (fw * 0.35).toNumber();
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [fx, poleTop],
            [fx + fw, poleTop],
            [fx + fw - notch, poleTop + fh / 2],
            [fx + fw, poleTop + fh],
            [fx, poleTop + fh]
        ]);
    }

    // Returns the first line drawWrapped would render (for flag positioning).
    private function firstWrappedLine(dc as Graphics.Dc, text as String,
                                      maxW as Number, font as Graphics.FontType) as String {
        var words = splitWords(text);
        var cur = "";
        for (var i = 0; i < words.size(); i++) {
            var trial = cur.equals("") ? words[i] : cur + " " + words[i];
            if (dc.getTextWidthInPixels(trial, font) > maxW && !cur.equals("")) {
                return cur;
            }
            cur = trial;
        }
        return cur;
    }

    // Word-wraps text, drawing centered lines from y. Returns the y after the
    // last line.
    private function drawWrapped(dc as Graphics.Dc, cx as Number, y as Numeric,
                                 maxW as Number, text as String, font as Graphics.FontType) as Numeric {
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
            y += lineH;
        }
        return y;
    }

    // Small down-arrow when there is more content below the fold.
    private function drawScrollHint(dc as Graphics.Dc, w as Number) as Void {
        if (_contentH - _viewH - _scroll <= 2) {
            return;
        }
        var cx = w / 2;
        var by = _viewH - 12;
        dc.setColor(0xE2B74A, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx - 6, by], [cx + 6, by], [cx, by + 6]]);
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
