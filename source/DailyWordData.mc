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
    private var _triedFallback as Boolean = false;

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

    // Shows the best cached day immediately (works fully offline), then
    // refreshes the multi-day bundle from the network when reachable.
    function load() as Void {
        showCachedDay();
        _triedFallback = false;
        fetch("week.json");
    }

    // Picks today's entry from the cached multi-day bundle (or the legacy
    // single-day cache) so the app is useful before/without a network fetch.
    private function showCachedDay() as Void {
        var key = todayKey();
        var bundle = Application.Storage.getValue("week");
        if (bundle instanceof Dictionary) {
            var days = (bundle as Dictionary)["days"];
            if (days instanceof Dictionary && (days as Dictionary)[key] instanceof Dictionary) {
                readings = (days as Dictionary)[key] as Dictionary;
                _onUpdate.invoke();
                return;
            }
        }
        var cached = Application.Storage.getValue("readings");
        if (cached instanceof Dictionary) {
            readings = cached as Dictionary;
            _onUpdate.invoke();
        }
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
                storeResponse(parsed as Dictionary);
                _onUpdate.invoke();
                return;
            }
            errorMsg = "Bad data";
        } else if (!_triedFallback) {
            // week.json may be missing; fall back to the single-day file.
            _triedFallback = true;
            fetch(todayKey() + ".json");
            return;
        } else if (readings == null) {
            // Only surface an error if we have nothing cached to show.
            errorMsg = "HTTP " + code.toString();
        }
        _onUpdate.invoke();
    }

    // Handles both the multi-day bundle ({"days": {...}}) and a single day.
    private function storeResponse(parsed as Dictionary) as Void {
        errorMsg = null;
        if (parsed["days"] instanceof Dictionary) {
            Application.Storage.setValue("week", parsed);
            var key = todayKey();
            var days = parsed["days"] as Dictionary;
            if (days[key] instanceof Dictionary) {
                readings = days[key] as Dictionary;
            }
        } else {
            readings = parsed;
            Application.Storage.setValue("readings", parsed);
        }
    }

    // Returns the sub-dictionary for the active language ("lt" or "en").
    function localized() as Dictionary? {
        if (readings == null) {
            return null;
        }
        var useLt = Application.Properties.getValue("useLithuanian");
        var lang = (useLt == null || useLt as Boolean) ? "lt" : "en";
        var block = readings[lang];
        return block instanceof Dictionary ? block as Dictionary : null;
    }
}
