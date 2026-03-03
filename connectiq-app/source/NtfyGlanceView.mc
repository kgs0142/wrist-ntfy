using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Application;
using Toybox.Application.Properties;

(:glance)
class NtfyGlanceView extends WatchUi.GlanceView {
    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc) {
        var w = dc.getWidth();
        var h = dc.getHeight();

        // App name
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(0, h / 2 - 16, Graphics.FONT_GLANCE, "wrist-ntfy", Graphics.TEXT_JUSTIFY_LEFT);

        // Message count or setup hint
        var topic = Properties.getValue("ntfyTopic");
        if (topic == null || topic.equals("")) {
            dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, h / 2 + 8, Graphics.FONT_GLANCE_NUMBER, "Setup required", Graphics.TEXT_JUSTIFY_LEFT);
        } else {
            var store = Application.getApp().messageStore;
            var count = 0;
            if (store != null) {
                count = store.getMessageCount();
            }
            dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
            if (count == 0) {
                dc.drawText(0, h / 2 + 8, Graphics.FONT_GLANCE_NUMBER, "No messages", Graphics.TEXT_JUSTIFY_LEFT);
            } else {
                dc.drawText(0, h / 2 + 8, Graphics.FONT_GLANCE_NUMBER, count + " messages", Graphics.TEXT_JUSTIFY_LEFT);
            }
        }
    }
}
