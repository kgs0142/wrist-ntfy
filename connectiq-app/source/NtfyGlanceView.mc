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
        var h = dc.getHeight();

        var topic = Properties.getValue("ntfyTopic");
        if (topic == null || topic.equals("")) {
            dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
            dc.drawText(0, h / 2, Graphics.FONT_TINY, "Setup required", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var store = Application.getApp().messageStore;
            var count = 0;
            if (store != null) {
                count = store.getMessageCount();
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            if (count == 0) {
                dc.drawText(0, h / 2, Graphics.FONT_TINY, "No messages", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.drawText(0, h / 2, Graphics.FONT_TINY, count + " messages", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
    }
}
