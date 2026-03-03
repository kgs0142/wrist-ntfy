using Toybox.Application;
using Toybox.Communications;
using Toybox.WatchUi;
using Toybox.Lang;

class NtfyApp extends Application.AppBase {
    var messageStore;
    var listView;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        messageStore = new MessageStore();
    }

    function onStop(state as Lang.Dictionary?) as Void {
        messageStore.save();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        listView = new MessageListView(messageStore);
        var delegate = new MessageListDelegate(messageStore, listView);
        return [listView, delegate];
    }

    // System calls this when Communications.startSync() is invoked
    // Returns our SyncDelegate which handles WiFi HTTP requests
    function getSyncDelegate() as Communications.SyncDelegate? {
        return new NtfySyncDelegate(messageStore);
    }
}
