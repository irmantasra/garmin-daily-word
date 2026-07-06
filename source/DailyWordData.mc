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

    // Loads from local cache immediately, then refreshes over the network
    // if the cache is stale (different day).
    function load() as Void {
        var key = todayKey();
        var cached = Application.Storage.getValue("readings");
        var cachedDate = Application.Storage.getValue("readingsDate");

        if (cached != null && cachedDate != null && (cachedDate as String).equals(key)) {
            readings = cached as Dictionary;
            _onUpdate.invoke();
            return;
        }

        // Show stale cache (if any) while fetching fresh data.
        if (cached != null) {
            readings = cached as Dictionary;
            _onUpdate.invoke();
        }
        _triedFallback = false;
        fetch(key + ".json");
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
                readings = parsed as Dictionary;
                errorMsg = null;
                Application.Storage.setValue("readings", parsed);
                Application.Storage.setValue("readingsDate", (parsed as Dictionary)["date"]);
                _onUpdate.invoke();
                return;
            }
            errorMsg = "Bad data";
        } else if (!_triedFallback) {
            // Today's dated file may not be published yet (the cron runs later
            // in the day), or the request failed. Fall back to the
            // always-current today.json once before giving up.
            _triedFallback = true;
            fetch("today.json");
            return;
        } else {
            errorMsg = "HTTP " + code.toString();
        }
        _onUpdate.invoke();
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
