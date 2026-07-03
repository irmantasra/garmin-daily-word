import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class DailyWordApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Glance-only app: no full-view. getGlanceView is the entry point shown
    // in the device's glance carousel.
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new DailyWordGlanceView() ];
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        // Fallback view when opened as a full app (older devices / debugging).
        return [ new DailyWordGlanceView() ];
    }
}
