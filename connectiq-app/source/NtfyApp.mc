using Toybox.Application;
using Toybox.WatchUi;
using Toybox.Communications;

class NtfyApp extends Application.AppBase {
    var messageStore;

    function initialize() {
        AppBase.initialize();
        messageStore = new MessageStore();
    }

    function onStart(state) {
    }

    function onStop(state) {
        messageStore.save();
    }

    function getInitialView() {
        var view = new MessageListView(messageStore);
        var delegate = new MessageListDelegate(messageStore);
        return [view, delegate];
    }

    function getSyncDelegate() {
        return new NtfySyncDelegate(messageStore);
    }
}
