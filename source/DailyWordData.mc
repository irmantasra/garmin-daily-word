import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Fetches and caches the daily readings JSON published by the scraper.
// Endpoint (GitHub Pages): <baseUrl>/YYYY-MM-DD.json
(:glance)
class DailyWordData {

    // Cached payload for the current day, or null until first successful load.
    var readings as Dictionary?;
    var errorMsg as String?;
    var loading as Boolean = false;

    private var _onUpdate as Method() as Void;

    function initialize(onUpdate as Method() as Void) {
        _onUpdate = onUpdate;
    }

    // Returns today's date as "YYYY-MM-DD" in local time.
    private function todayKey() as String {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return Lang.format("$1$-$2$-$3$", [
            now.year.format("%04d"),
            now.month.format("%02d"),
            now.day.format("%02d")
        ]);
    }

    private function baseUrl() as String {
        var url = Application.Properties.getValue("dataBaseUrl");
        if (url == null || (url as String).length() == 0) {
            return "https://irmantasra.github.io/garmin-daily-word/data";
        }
        return url as String;
    }

    // Shows the cached day immediately (works offline), then refreshes just
    // today's file from the network. We fetch a single day rather than a
    // multi-day bundle: parsing the larger bundle synchronously in onReceive
    // trips the watchdog ("Code Executed Too Long") on slower devices such as
    // the Forerunner 255 and fenix 6X Pro.
    function load() as Void {
        var cached = Application.Storage.getValue("readings");
        if (cached instanceof Dictionary) {
            readings = cached as Dictionary;
            _onUpdate.invoke();
        }
        fetch(todayKey() + ".json");
    }

    // Fetches as plain text (not JSON): GitHub Pages sends
    // "application/json; charset=utf-8", which Communications' native JSON
    // parser rejects with -400. We parse the text ourselves via Json.parse.
    private function fetch(file as String) as Void {
        loading = true;
        var url = baseUrl() + "/" + file;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };
        Communications.makeWebRequest(url, null, options, method(:onReceive));
    }

    function onReceive(code as Number, data as Dictionary or String or Null) as Void {
        loading = false;
        if (code == 200 && data instanceof String) {
            var parsed = Json.parse(data as String);
            if (parsed instanceof Dictionary) {
                errorMsg = null;
                readings = parsed as Dictionary;
                Application.Storage.setValue("readings", parsed);
                _onUpdate.invoke();
                return;
            }
            errorMsg = "Bad data";
        } else if (readings == null) {
            // Only surface an error if we have nothing cached to show.
            errorMsg = "HTTP " + code.toString();
        }
        _onUpdate.invoke();
    }

    // Returns the readings for the active language, or null if that language
    // has no usable data (missing, or only an error placeholder).
    function localized() as Dictionary? {
        if (readings == null) {
            return null;
        }
        var useLt = Application.Properties.getValue("useLithuanian");
        var lang = (useLt == null || useLt as Boolean) ? "lt" : "en";
        var block = readings[lang];
        if (!(block instanceof Dictionary)) {
            return null;
        }
        var b = block as Dictionary;
        // A block that only carries an "error" (or has no references) is not
        // usable — treat as no data so the view shows a message.
        if (b["gospel"] == null && b["reading1"] == null) {
            return null;
        }
        return b;
    }

    // True when data loaded but the *active* language is unavailable (so the
    // view can suggest switching language rather than just "no data").
    function activeLangUnavailable() as Boolean {
        return readings != null && localized() == null;
    }
}
