import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
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

        // Liturgical event, white, wrapped.
        var event = block["event"];
        if (event instanceof String && (event as String).length() > 0) {
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
        drawSeasonRing(dc);
    }

    // Liturgical season color (or -1 for none).
    private function seasonColor() as Number {
        var r = _data.readings;
        if (!(r instanceof Dictionary)) {
            return -1;
        }
        var s = (r as Dictionary)["season"];
        if (!(s instanceof String)) {
            return -1;
        }
        if (s.equals("ordinary")) { return 0x1E7A34; }  // green
        if (s.equals("lent"))     { return 0x6A3FA0; }  // violet
        if (s.equals("festive"))  { return 0xE2B74A; }  // gold
        if (s.equals("red"))      { return 0xC0392B; }  // red
        if (s.equals("rose"))     { return 0xD98CA8; }  // rose
        return -1;
    }

    // Draws a 2px accent ring in the season color, shaped to the screen.
    // AMOLED screens get a subtle top-to-bottom gradient; MIP screens a flat
    // ring.
    private function drawSeasonRing(dc as Graphics.Dc) as Void {
        var color = seasonColor();
        if (color < 0) {
            return;
        }
        var w = dc.getWidth();
        var h = dc.getHeight();
        var pen = 3;
        dc.setPenWidth(pen);

        var shape = System.getDeviceSettings().screenShape;
        var amoled = isAmoled();

        if (shape == System.SCREEN_SHAPE_ROUND) {
            var r = (w < h ? w : h) / 2 - pen;
            if (amoled) {
                drawGradientArc(dc, w / 2, h / 2, r, color);
            } else {
                dc.setColor(color, Graphics.COLOR_TRANSPARENT);
                dc.drawCircle(w / 2, h / 2, r);
            }
        } else {
            // Rectangle / semi-round: rounded-rect border.
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            var inset = pen;
            dc.drawRoundedRectangle(inset, inset, w - 2 * inset, h - 2 * inset, 12);
        }
        dc.setPenWidth(1);
    }

    // Approximates a gradient by drawing arc segments from a darker shade at
    // the bottom to the full color at the top.
    private function drawGradientArc(dc as Graphics.Dc, cx as Number, cy as Number,
                                     r as Number, color as Number) as Void {
        var steps = 12;
        for (var i = 0; i < steps; i++) {
            var startDeg = 90 - (i * 360 / steps);
            var endDeg = 90 - ((i + 1) * 360 / steps);
            // Fade factor: 1.0 at top (i=0/steps), down to ~0.45 at bottom.
            var t = i < steps / 2 ? i : steps - i;
            var f = 100 - (t * 55 / (steps / 2));
            dc.setColor(scaleColor(color, f), Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, r, Graphics.ARC_CLOCKWISE, startDeg, endDeg);
        }
    }

    // Scales an RGB color's brightness to pct (0-100).
    private function scaleColor(color as Number, pct as Number) as Number {
        var r = ((color >> 16) & 0xFF) * pct / 100;
        var g = ((color >> 8) & 0xFF) * pct / 100;
        var b = (color & 0xFF) * pct / 100;
        return (r << 16) | (g << 8) | b;
    }

    private function isAmoled() as Boolean {
        var s = System.getDeviceSettings();
        if (s has :requiresBurnInProtection) {
            return s.requiresBurnInProtection;
        }
        return false;
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
