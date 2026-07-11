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

    // On button devices without a dedicated MENU, SELECT opens settings.
    function onSelect() as Boolean {
        openSettings();
        return true;
    }

    // UP / DOWN buttons scroll by ~half a screen (animated).
    function onNextPage() as Boolean {
        _view.scrollByPage(0.5);
        return true;
    }

    function onPreviousPage() as Boolean {
        _view.scrollByPage(-0.5);
        return true;
    }

    // Touchscreen swipe: up = scroll down, down = scroll up. A swipe moves
    // most of a screen, animated for smoothness.
    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var dir = evt.getDirection();
        if (dir == WatchUi.SWIPE_UP) {
            _view.scrollByPage(0.8);
            return true;
        } else if (dir == WatchUi.SWIPE_DOWN) {
            _view.scrollByPage(-0.8);
            return true;
        }
        return false;
    }

    private function openSettings() as Void {
        WatchUi.pushView(
            new LanguageMenu(),
            new LanguageMenuDelegate(_view),
            WatchUi.SLIDE_UP
        );
    }
}
