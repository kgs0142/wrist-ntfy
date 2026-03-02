using Toybox.WatchUi;
using Toybox.Communications;

class MessageListDelegate extends WatchUi.BehaviorDelegate {
    var messageStore;

    function initialize(store) {
        BehaviorDelegate.initialize();
        messageStore = store;
    }

    function onMenu() {
        // Menu button triggers sync
        Communications.startSync();
        return true;
    }

    function onSelect() {
        // Select button opens send menu
        var menu = new WatchUi.Menu2({:title => WatchUi.loadResource(Rez.Strings.SendMessage)});
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplyOk), null, :replyOk, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplyOnMyWay), null, :replyOnMyWay, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplyWait), null, :replyWait, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplyCallMe), null, :replyCallMe, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplyYes), null, :replyYes, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplyNo), null, :replyNo, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplyThanks), null, :replyThanks, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.ReplySeeYouSoon), null, :replySeeYouSoon, {}));
        menu.addItem(new WatchUi.MenuItem(WatchUi.loadResource(Rez.Strings.CustomInput), null, :customInput, {}));

        WatchUi.pushView(menu, new SendMenuDelegate(messageStore), WatchUi.SLIDE_UP);
        return true;
    }

    function onNextPage() {
        // Scroll down
        var view = WatchUi.getCurrentView();
        if (view[0] instanceof MessageListView) {
            (view[0] as MessageListView).scrollDown();
        }
        return true;
    }

    function onPreviousPage() {
        // Scroll up
        var view = WatchUi.getCurrentView();
        if (view[0] instanceof MessageListView) {
            (view[0] as MessageListView).scrollUp();
        }
        return true;
    }
}
