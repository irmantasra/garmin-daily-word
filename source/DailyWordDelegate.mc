import Toybox.Lang;
import Toybox.WatchUi;

// Input for the detail view: MENU (or long-press UP) opens the language menu.
class DailyWordDelegate extends WatchUi.BehaviorDelegate {

    private var _view as DailyWordView;

    function initialize(view as DailyWordView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onMenu() as Boolean {
        openSettings();
        return true;
    }

    // On button devices without a dedicated MENU, SELECT also opens settings.
    function onSelect() as Boolean {
        openSettings();
        return true;
    }

    private function openSettings() as Void {
        WatchUi.pushView(
            new LanguageMenu(),
            new LanguageMenuDelegate(_view),
            WatchUi.SLIDE_UP
        );
    }
}
