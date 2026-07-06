import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Language chooser. A checkmark marks the currently active language.
class LanguageMenu extends WatchUi.CheckboxMenu {

    function initialize() {
        CheckboxMenu.initialize({ :title => "Language" });
        var useLt = usingLithuanian();
        addItem(new WatchUi.CheckboxMenuItem(
            "Lietuvių", "LT", "lt", useLt, null));
        addItem(new WatchUi.CheckboxMenuItem(
            "English", "EN", "en", !useLt, null));
    }

    static function usingLithuanian() as Boolean {
        var v = Application.Properties.getValue("useLithuanian");
        return v == null || v as Boolean;
    }
}

class LanguageMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _view as DailyWordView;

    function initialize(view as DailyWordView) {
        Menu2InputDelegate.initialize();
        _view = view;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var useLt = item.getId().equals("lt");
        Application.Properties.setValue("useLithuanian", useLt);
        _view.refresh();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }

    function onBack() as Void {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}
