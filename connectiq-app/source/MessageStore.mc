using Toybox.Application;
using Toybox.Application.Storage;

class MessageStore {
    // Each message: {"id" => String, "time" => Number, "message" => String, "sent" => Boolean}
    var messages;
    var outgoingQueue;
    var lastSyncTime;

    function initialize() {
        load();
    }

    function load() {
        var stored = Storage.getValue("messages");
        if (stored != null) {
            messages = stored;
        } else {
            messages = [];
        }

        var queue = Storage.getValue("outgoingQueue");
        if (queue != null) {
            outgoingQueue = queue;
        } else {
            outgoingQueue = [];
        }

        var syncTime = Storage.getValue("lastSyncTime");
        if (syncTime != null) {
            lastSyncTime = syncTime;
        } else {
            lastSyncTime = 0;
        }
    }

    function save() {
        Storage.setValue("messages", messages);
        Storage.setValue("outgoingQueue", outgoingQueue);
        Storage.setValue("lastSyncTime", lastSyncTime);
    }

    function addReceivedMessage(id, time, message) {
        // Check for duplicate
        for (var i = 0; i < messages.size(); i++) {
            if (messages[i]["id"].equals(id)) {
                return;
            }
        }
        messages.add({
            "id" => id,
            "time" => time,
            "message" => message,
            "sent" => false
        });
        // Keep only the last 50 messages
        if (messages.size() > 50) {
            messages = messages.slice(messages.size() - 50, null);
        }
        save();
    }

    function addOutgoingMessage(message) {
        outgoingQueue.add(message);
        // Also add to message list immediately as a sent message
        var now = Toybox.Time.now().value();
        messages.add({
            "id" => "local_" + now,
            "time" => now,
            "message" => message,
            "sent" => true
        });
        if (messages.size() > 50) {
            messages = messages.slice(messages.size() - 50, null);
        }
        save();
    }

    function getNextOutgoing() {
        if (outgoingQueue.size() > 0) {
            return outgoingQueue[0];
        }
        return null;
    }

    function removeFirstOutgoing() {
        if (outgoingQueue.size() > 0) {
            outgoingQueue = outgoingQueue.slice(1, null);
            save();
        }
    }

    function getMessages() {
        return messages;
    }

    function getMessageCount() {
        return messages.size();
    }

    function updateLastSyncTime(time) {
        lastSyncTime = time;
        save();
    }
}
