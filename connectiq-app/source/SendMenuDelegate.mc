using Toybox.WatchUi;
using Toybox.Communications;

class SendMenuDelegate extends WatchUi.Menu2InputDelegate {
    var messageStore;

    function initialize(store) {
        Menu2InputDelegate.initialize();
        messageStore = store;
    }

    function onSelect(item) {
        var id = item.getId();

        if (id == :customInput) {
            WatchUi.pushView(
                new WatchUi.TextPicker(""),
                new TextPickerDelegate(messageStore),
                WatchUi.SLIDE_UP
            );
        } else {
            var message = getMessageForId(id);
            if (message != null) {
                messageStore.addOutgoingMessage(message);
                WatchUi.popView(WatchUi.SLIDE_DOWN);
                // Trigger sync to send immediately
                Communications.startSync();
            }
        }
    }

    function getMessageForId(id) {
        if (id == :replyOk) { return "OK"; }
        if (id == :replyOnMyWay) { return "On my way"; }
        if (id == :replyWait) { return "Wait a moment"; }
        if (id == :replyCallMe) { return "Call me"; }
        if (id == :replyYes) { return "Yes"; }
        if (id == :replyNo) { return "No"; }
        if (id == :replyThanks) { return "Thanks"; }
        if (id == :replySeeYouSoon) { return "See you soon"; }
        return null;
    }

    function onBack() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
    }
}

class TextPickerDelegate extends WatchUi.TextPickerDelegate {
    var messageStore;

    function initialize(store) {
        TextPickerDelegate.initialize();
        messageStore = store;
    }

    function onTextEntered(text, changed) {
        if (text != null && text.length() > 0) {
            messageStore.addOutgoingMessage(text);
            // Pop TextPicker and Send menu
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            Communications.startSync();
        }
        return true;
    }

    function onCancel() {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
