using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Lang;

class NtfyApp extends Application.AppBase {
    var messageStore;
    var syncHelper;
    var listView;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Lang.Dictionary?) as Void {
        messageStore = new MessageStore();
        syncHelper = new NtfySyncHelper(messageStore);
    }

    function onStop(state as Lang.Dictionary?) as Void {
        messageStore.save();
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        listView = new MessageListView(messageStore);
        var delegate = new MessageListDelegate(messageStore, listView);
        return [listView, delegate];
    }
}
