using Toybox.Communications;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Lang;
using Toybox.WatchUi;

class NtfySyncDelegate extends Communications.SyncDelegate {
    var messageStore;
    var workerUrl;
    var topic;

    function initialize(store) {
        SyncDelegate.initialize();
        messageStore = store;
        workerUrl = Properties.getValue("workerUrl");
        topic = Properties.getValue("ntfyTopic");
    }

    function onStartSync() {
        // Step 1: Send any queued outgoing messages first
        sendNextOutgoing();
    }

    function sendNextOutgoing() {
        var msg = messageStore.getNextOutgoing();
        if (msg == null) {
            // No more outgoing messages, proceed to fetch
            fetchMessages();
            return;
        }

        var url = workerUrl + "/send?topic=" + topic;
        var params = {
            "message" => msg
        };
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => {
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, params, options, method(:onSendComplete));
    }

    function onSendComplete(responseCode, data) {
        if (responseCode == 200 && data != null && data["success"] == true) {
            messageStore.removeFirstOutgoing();
        }
        // Try sending next message (or move to fetch if queue empty)
        sendNextOutgoing();
    }

    function fetchMessages() {
        var since = messageStore.lastSyncTime;
        var sinceParam;
        if (since == 0) {
            sinceParam = "24h";
        } else {
            sinceParam = since.toString();
        }

        var url = workerUrl + "/messages?topic=" + topic + "&since=" + sinceParam;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };

        Communications.makeWebRequest(url, null, options, method(:onFetchComplete));
    }

    function onFetchComplete(responseCode, data) {
        if (responseCode == 200 && data != null && data["messages"] != null) {
            var msgs = data["messages"];
            var maxTime = messageStore.lastSyncTime;

            for (var i = 0; i < msgs.size(); i++) {
                var m = msgs[i];
                messageStore.addReceivedMessage(m["id"], m["time"], m["message"]);
                if (m["time"] > maxTime) {
                    maxTime = m["time"];
                }
            }

            if (maxTime > messageStore.lastSyncTime) {
                messageStore.updateLastSyncTime(maxTime);
            }
        }

        Communications.notifySyncComplete(null);
        WatchUi.requestUpdate();
    }

    function onStopSync() {
    }

    function isSyncNeeded() {
        return true;
    }
}
