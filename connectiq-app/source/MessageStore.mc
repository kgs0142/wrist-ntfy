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
        sortMessages();
        if (messages.size() > 50) {
            messages = messages.slice(messages.size() - 50, null);
        }
        save();
    }

    // Add a message fetched from server that was originally sent by this watch
    function addSentMessage(id, time, message) {
        // Check for duplicate by ntfy ID
        for (var i = 0; i < messages.size(); i++) {
            if (messages[i]["id"].equals(id)) {
                return;
            }
        }
        // Check if a local version exists (local_xxx ID, same message text, sent=true)
        // If so, replace its ID with the server ID instead of adding a duplicate
        for (var i = 0; i < messages.size(); i++) {
            var m = messages[i];
            if (m["sent"] == true && m["message"].equals(message)
                && m["id"].find("local_") != null) {
                // Update the local entry with server ID and time
                messages[i] = {
                    "id" => id,
                    "time" => time,
                    "message" => message,
                    "sent" => true
                };
                save();
                return;
            }
        }
        messages.add({
            "id" => id,
            "time" => time,
            "message" => message,
            "sent" => true
        });
        sortMessages();
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

    function clearAll() {
        messages = [];
        outgoingQueue = [];
        lastSyncTime = 0;
        save();
    }

    // Simple insertion sort by time (ascending)
    function sortMessages() {
        for (var i = 1; i < messages.size(); i++) {
            var current = messages[i];
            var j = i - 1;
            while (j >= 0 && messages[j]["time"] > current["time"]) {
                messages[j + 1] = messages[j];
                j--;
            }
            messages[j + 1] = current;
        }
    }

    function updateLastSyncTime(time) {
        lastSyncTime = time;
        save();
    }
}
