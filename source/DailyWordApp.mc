import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class DailyWordApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // Shown in the device's glance carousel.
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [ new DailyWordGlanceView() ];
    }

    // Full app, opened when the user presses the action button on the glance.
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var view = new DailyWordView();
        return [ view, new DailyWordDelegate(view) ];
    }
}
