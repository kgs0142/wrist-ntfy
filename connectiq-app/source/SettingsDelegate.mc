using Toybox.WatchUi;
using Toybox.Application.Properties;

class SettingsView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var topic = Properties.getValue("ntfyTopic");
        var w = dc.getWidth();
        var h = dc.getHeight();

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2 - 30, Graphics.FONT_SMALL, "Settings", Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h / 2 + 10, Graphics.FONT_XTINY, "Topic:", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w / 2, h / 2 + 35, Graphics.FONT_XTINY, topic, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(w / 2, h / 2 + 70, Graphics.FONT_XTINY, "Edit in Garmin Connect", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class SettingsDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
