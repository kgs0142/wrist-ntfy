using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Application.Properties;

class MessageListDelegate extends WatchUi.BehaviorDelegate {
    var messageStore;
    var view;

    function initialize(store, listView) {
        BehaviorDelegate.initialize();
        messageStore = store;
        view = listView;
    }

    function onSelect() {
        // Check if topic is configured
        var topic = Properties.getValue("ntfyTopic");
        if (topic == null || topic.equals("")) {
            // Show setup instructions
            WatchUi.pushView(
                new SetupNeededView(),
                new SetupNeededDelegate(),
                WatchUi.SLIDE_UP
            );
            return true;
        }

        // Tap screen → main action menu
        var menu = new WatchUi.Menu2({:title => "wrist-ntfy"});
        menu.addItem(new WatchUi.MenuItem("Sync", "Send & receive", :sync, {}));
        menu.addItem(new WatchUi.MenuItem("Send Message", "Quick reply or type", :send, {}));
        menu.addItem(new WatchUi.MenuItem("Clear Messages", "Delete all messages", :clear, {}));

        WatchUi.pushView(menu, new MainMenuDelegate(messageStore), WatchUi.SLIDE_UP);
        return true;
    }

    function onNextPage() {
        view.pageDown();
        return true;
    }

    function onPreviousPage() {
        view.pageUp();
        return true;
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {
    var messageStore;

    function initialize(store) {
        Menu2InputDelegate.initialize();
        messageStore = store;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :sync) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            var app = Application.getApp();
            app.syncHelper.startSync();
        } else if (id == :send) {
            var menu = new WatchUi.Menu2({:title => "Send Message"});
            menu.addItem(new WatchUi.MenuItem("OK", null, :replyOk, {}));
            menu.addItem(new WatchUi.MenuItem("On my way", null, :replyOnMyWay, {}));
            menu.addItem(new WatchUi.MenuItem("Wait a moment", null, :replyWait, {}));
            menu.addItem(new WatchUi.MenuItem("Call me", null, :replyCallMe, {}));
            menu.addItem(new WatchUi.MenuItem("Yes", null, :replyYes, {}));
            menu.addItem(new WatchUi.MenuItem("No", null, :replyNo, {}));
            menu.addItem(new WatchUi.MenuItem("Thanks", null, :replyThanks, {}));
            menu.addItem(new WatchUi.MenuItem("See you soon", null, :replySeeYouSoon, {}));
            menu.addItem(new WatchUi.MenuItem("Custom Input", null, :customInput, {}));

            WatchUi.switchToView(menu, new SendMenuDelegate(messageStore), WatchUi.SLIDE_LEFT);
        } else if (id == :clear) {
            messageStore.clearAll();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.requestUpdate();
        }
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

// ── Setup needed screen ──

class SetupNeededView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        // Warning icon (triangle)
        dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([
            [w/2, h/2 - 100],
            [w/2 - 20, h/2 - 64],
            [w/2 + 20, h/2 - 64]
        ]);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h/2 - 86, Graphics.FONT_XTINY, "!", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Title
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h/2 - 44, Graphics.FONT_SMALL, "Setup Required", Graphics.TEXT_JUSTIFY_CENTER);

        // Instructions
        dc.setColor(0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h/2 - 2, Graphics.FONT_XTINY, "Open Garmin Connect", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w/2, h/2 + 24, Graphics.FONT_XTINY, "app and set your", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(w/2, h/2 + 50, Graphics.FONT_XTINY, "ntfy topic ID", Graphics.TEXT_JUSTIFY_CENTER);

        // Tap to close
        dc.setColor(0x606060, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w/2, h/2 + 80, Graphics.FONT_XTINY, "Tap to close", Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class SetupNeededDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
