using Toybox.Communications;
using Toybox.Application;
using Toybox.Application.Properties;
using Toybox.Lang;
using Toybox.WatchUi;
using Toybox.PersistedContent;

class NtfySyncHelper {
    var messageStore;
    var topic;
    var statusView;

    function initialize(store) {
        messageStore = store;
    }

    function startSync() {
        topic = Properties.getValue("ntfyTopic");

        if (topic == null || topic.equals("")) {
            topic = "wntfy-default";
        }


        statusView = new SyncStatusView("Syncing...", topic);
        WatchUi.pushView(statusView, new SyncStatusDelegate(), WatchUi.SLIDE_UP);
        sendNextOutgoing();
    }

    // ── Sending ──

    // Simple URL-encode: replace spaces and common special chars
    function urlEncode(str) {
        var result = "";
        for (var i = 0; i < str.length(); i++) {
            var ch = str.substring(i, i + 1);
            if (ch.equals(" ")) {
                result += "+";
            } else if (ch.equals("&")) {
                result += "%26";
            } else if (ch.equals("=")) {
                result += "%3D";
            } else if (ch.equals("+")) {
                result += "%2B";
            } else if (ch.equals("#")) {
                result += "%23";
            } else if (ch.equals("?")) {
                result += "%3F";
            } else {
                result += ch;
            }
        }
        return result;
    }

    // Prefix for messages sent from the watch, so we can identify them on fetch
    static const SEND_PREFIX = "wrist-ntfy: ";

    function sendNextOutgoing() {
        var msg = messageStore.getNextOutgoing();

        if (msg == null) {
            fetchMessages();
            return;
        }

        var prefixedMsg = SEND_PREFIX + msg;
        var url = "https://ntfy.sh/" + topic + "?message=" + urlEncode(prefixedMsg);
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_PUT,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url, null, options, method(:onSendComplete));
    }

    function onSendComplete(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null or PersistedContent.Iterator) as Void {

        if (responseCode == 200 && data != null) {
            messageStore.removeFirstOutgoing();
        }
        sendNextOutgoing();
    }

    // ── Fetching ──

    function fetchMessages() {
        if (statusView != null) {
            statusView.setStatus("Fetching...");
        }

        var since = messageStore.lastSyncTime;
        var sinceParam;
        if (since == 0) {
            sinceParam = "24h";
        } else {
            sinceParam = since.toString();
        }

        // Request as plain text so we can manually parse NDJSON (multiple JSON lines)
        var url = "https://ntfy.sh/" + topic + "/json?poll=1&since=" + sinceParam;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_TEXT_PLAIN
        };
        Communications.makeWebRequest(url, null, options, method(:onFetchComplete));
    }

    // Extract a JSON string value: finds "key":"value" and returns value
    function jsonExtractString(line, key) {
        var search = "\"" + key + "\":\"";
        var idx = line.find(search);
        if (idx == null) { return null; }
        var start = idx + search.length();
        var end = null;
        for (var i = start; i < line.length(); i++) {
            if (line.substring(i, i + 1).equals("\"")) {
                end = i;
                break;
            }
        }
        if (end == null) { return null; }
        return line.substring(start, end);
    }

    // Extract a JSON number value: finds "key":123 and returns the number
    function jsonExtractNumber(line, key) {
        var search = "\"" + key + "\":";
        var idx = line.find(search);
        if (idx == null) { return null; }
        var start = idx + search.length();
        var numStr = "";
        for (var i = start; i < line.length(); i++) {
            var ch = line.substring(i, i + 1);
            if (ch.equals("0") || ch.equals("1") || ch.equals("2") || ch.equals("3")
                || ch.equals("4") || ch.equals("5") || ch.equals("6") || ch.equals("7")
                || ch.equals("8") || ch.equals("9")) {
                numStr += ch;
            } else {
                break;
            }
        }
        if (numStr.length() == 0) { return null; }
        return numStr.toNumber();
    }

    function onFetchComplete(responseCode as Lang.Number, data as Lang.Dictionary or Lang.String or Null or PersistedContent.Iterator) as Void {


        // Empty response (no new messages) — treat as success
        if (data == null || (data instanceof Lang.String && (data as Lang.String).length() == 0)) {
            onSyncDone(200);
            return;
        }

        if (responseCode == 200 && data != null && data instanceof Lang.String) {
            var body = data as Lang.String;
            var maxTime = messageStore.lastSyncTime;

            // Parse NDJSON: split by newline, process each line
            var pos = 0;
            while (pos < body.length()) {
                // Find end of line
                var eol = body.length();
                for (var i = pos; i < body.length(); i++) {
                    if (body.substring(i, i + 1).equals("\n")) {
                        eol = i;
                        break;
                    }
                }

                var line = body.substring(pos, eol);
                pos = eol + 1;

                if (line.length() == 0) { continue; }

                var event = jsonExtractString(line, "event");
                if (event == null || !event.equals("message")) { continue; }

                var id = jsonExtractString(line, "id");
                var time = jsonExtractNumber(line, "time");
                var message = jsonExtractString(line, "message");



                if (id != null && time != null && message != null) {
                    if (message.length() >= SEND_PREFIX.length()
                        && message.substring(0, SEND_PREFIX.length()).equals(SEND_PREFIX)) {
                        var stripped = message.substring(SEND_PREFIX.length(), message.length());
                        messageStore.addSentMessage(id, time, stripped);
                    } else {
                        messageStore.addReceivedMessage(id, time, message);
                    }
                    if (time > maxTime) {
                        maxTime = time;
                    }
                }
            }

            if (maxTime > messageStore.lastSyncTime) {
                messageStore.updateLastSyncTime(maxTime);
            }
        }
        onSyncDone(responseCode);
    }

    function onSyncDone(responseCode) {
        var app = Application.getApp();
        if (app.listView != null) {
            app.listView.scrollToBottom();
        }

        if (statusView != null) {
            if (responseCode == 200) {
                statusView.setStatus("Done!");
            } else {
                statusView.setStatus("Error: " + responseCode);
            }
        }
    }
}

// ── Sync status overlay view ──

class SyncStatusView extends WatchUi.View {
    var statusText;
    var topicText;
    var statusColor;
    var isDone;

    function initialize(text, topic) {
        View.initialize();
        statusText = text;
        topicText = topic;
        statusColor = 0xFFAA00; // Yellow-orange for "Syncing..."
        isDone = false;
    }

    function setStatus(text) {
        statusText = text;
        if (text.equals("Done!")) {
            statusColor = 0x00CC66; // Green for done
            isDone = true;
        } else if (text.find("Fetching") != null) {
            statusColor = 0x40AAFF; // Light blue for fetching
        } else if (text.find("Error") != null) {
            statusColor = 0xFF4444; // Red for error
            isDone = true;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var screenW = dc.getWidth();
        var screenH = dc.getHeight();

        // Draw a chat bubble icon
        dc.setColor(0x4090FF, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(screenW/2 - 24, screenH/2 - 60, 48, 36, 12);
        // Bubble tail
        dc.fillPolygon([
            [screenW/2 - 8, screenH/2 - 26],
            [screenW/2 - 14, screenH/2 - 16],
            [screenW/2 + 4, screenH/2 - 26]
        ]);
        // Dots in bubble
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        for (var dx = -10; dx <= 10; dx += 10) {
            dc.fillCircle(screenW/2 + dx, screenH/2 - 44, 3);
        }

        // Status text — color varies by state
        dc.setColor(statusColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenW / 2,
            screenH / 2 + 10,
            Graphics.FONT_SMALL,
            statusText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // Topic name
        dc.setColor(0x808080, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenW / 2,
            screenH / 2 + 40,
            Graphics.FONT_XTINY,
            topicText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Tap to close hint — brighter when done
        dc.setColor(isDone ? 0xAAAAAA : 0x606060, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            screenW / 2,
            screenH / 2 + 80,
            Graphics.FONT_XTINY,
            "Tap to close",
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }
}

class SyncStatusDelegate extends WatchUi.BehaviorDelegate {
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
