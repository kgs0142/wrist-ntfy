using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Application.Properties;

class MessageListView extends WatchUi.View {
    var messageStore;
    var scrollOffset;
    const LINES_PER_PAGE = 7;
    const LINE_HEIGHT = 38;
    const BUBBLE_PAD = 6;

    function initialize(store) {
        View.initialize();
        messageStore = store;
        scrollOffset = 0;
    }

    function onLayout(dc) {
    }

    // Calculate usable width at a given Y position on a round screen
    // Returns [leftMargin, usableWidth]
    function getRowBounds(screenW, screenH, y, rowH) {
        var r = screenW / 2;
        var cy = screenH / 2;
        // Find the tightest point in this row (closest to top or bottom edge)
        var edgeY = y;
        if ((y + rowH) > cy) {
            // Bottom half — use bottom edge of row
            edgeY = y + rowH;
        }
        var dy = (edgeY - cy).abs();
        if (dy >= r) {
            return [r, 0]; // off screen
        }
        // chord half-width at this y
        var halfW = Math.sqrt(r * r - dy * dy).toNumber();
        var margin = r - halfW + 8; // extra 8px safety margin
        return [margin, screenW - margin * 2];
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var msgs = messageStore.getMessages();
        var count = msgs.size();
        var screenW = dc.getWidth();
        var screenH = dc.getHeight();

        if (count == 0) {
            var topic = Properties.getValue("ntfyTopic");
            if (topic == null || topic.equals("")) {
                dc.setColor(0xFFAA00, Graphics.COLOR_TRANSPARENT);
                dc.drawText(screenW / 2, screenH / 2 - 15, Graphics.FONT_SMALL,
                    "Setup Required", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
                dc.setColor(0x808080, Graphics.COLOR_TRANSPARENT);
                dc.drawText(screenW / 2, screenH / 2 + 15, Graphics.FONT_XTINY,
                    "Tap to configure", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            } else {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(screenW / 2, screenH / 2, Graphics.FONT_SMALL,
                    "No messages yet", Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            }
            return;
        }

        // Auto-scroll to bottom (latest messages)
        var maxOffset = count - LINES_PER_PAGE;
        if (maxOffset < 0) {
            maxOffset = 0;
        }
        if (scrollOffset > maxOffset) {
            scrollOffset = maxOffset;
        }
        if (scrollOffset < 0) {
            scrollOffset = 0;
        }

        // Center messages vertically in the round screen
        var visibleCount = count - scrollOffset;
        if (visibleCount > LINES_PER_PAGE) {
            visibleCount = LINES_PER_PAGE;
        }
        var totalH = visibleCount * LINE_HEIGHT;
        var startY = (screenH - totalH) / 2;

        for (var i = scrollOffset; i < count && i < scrollOffset + LINES_PER_PAGE; i++) {
            var msg = msgs[i];
            var text = msg["message"] as Lang.String;
            var isSent = msg["sent"];
            var y = startY + (i - scrollOffset) * LINE_HEIGHT;

            // Get usable width for this row on round screen
            var bounds = getRowBounds(screenW, screenH, y, LINE_HEIGHT - 4);
            var leftMargin = bounds[0] as Lang.Number;
            var usableW = bounds[1] as Lang.Number;
            if (usableW < 40) {
                continue; // too narrow, skip
            }

            // Truncate text to fit usable width
            var maxTextW = usableW - BUBBLE_PAD * 3;
            var displayText = truncateToFit(dc, text, maxTextW);

            var textW = dc.getTextWidthInPixels(displayText, Graphics.FONT_XTINY);
            var bubbleW = textW + BUBBLE_PAD * 2;
            var bubbleH = LINE_HEIGHT - 6;
            var textY = y + bubbleH / 2;

            if (isSent) {
                // Sent: right-aligned bubble
                // Pending (local_) = muted blue, Synced = bright blue
                var bubbleX = leftMargin + usableW - bubbleW;
                var msgId = msg["id"] as Lang.String;
                var isPending = (msgId.find("local_") != null);
                dc.setColor(isPending ? 0x405880 : 0x2060C0, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(bubbleX, y, bubbleW, bubbleH, 10);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    bubbleX + BUBBLE_PAD,
                    textY,
                    Graphics.FONT_XTINY,
                    displayText,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            } else {
                // Received: left-aligned, gray bubble
                var bubbleX = leftMargin;
                dc.setColor(0x404040, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(bubbleX, y, bubbleW, bubbleH, 10);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    bubbleX + BUBBLE_PAD,
                    textY,
                    Graphics.FONT_XTINY,
                    displayText,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }

        // Scroll indicators
        if (count > LINES_PER_PAGE) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            if (scrollOffset > 0) {
                dc.fillPolygon([[screenW/2-6, 16], [screenW/2+6, 16], [screenW/2, 8]]);
            }
            if (scrollOffset + LINES_PER_PAGE < count) {
                var by = screenH - 16;
                dc.fillPolygon([[screenW/2-6, by], [screenW/2+6, by], [screenW/2, by+8]]);
            }
        }
    }

    function truncateToFit(dc, text, maxW) {
        if (dc.getTextWidthInPixels(text, Graphics.FONT_XTINY) <= maxW) {
            return text;
        }
        // Binary-ish search for max length
        var len = text.length();
        while (len > 1) {
            len = len - 1;
            var truncated = text.substring(0, len) + "..";
            if (dc.getTextWidthInPixels(truncated, Graphics.FONT_XTINY) <= maxW) {
                return truncated;
            }
        }
        return "..";
    }

    function scrollToBottom() {
        var maxOffset = messageStore.getMessageCount() - LINES_PER_PAGE;
        if (maxOffset < 0) { maxOffset = 0; }
        scrollOffset = maxOffset;
        WatchUi.requestUpdate();
    }

    function pageUp() {
        scrollOffset -= LINES_PER_PAGE;
        if (scrollOffset < 0) {
            scrollOffset = 0;
        }
        WatchUi.requestUpdate();
    }

    function pageDown() {
        var maxOffset = messageStore.getMessageCount() - LINES_PER_PAGE;
        if (maxOffset < 0) { maxOffset = 0; }
        scrollOffset += LINES_PER_PAGE;
        if (scrollOffset > maxOffset) {
            scrollOffset = maxOffset;
        }
        WatchUi.requestUpdate();
    }
}
