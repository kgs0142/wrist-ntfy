using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;

class MessageListView extends WatchUi.View {
    var messageStore;
    var scrollOffset;
    const LINES_PER_PAGE = 5;
    const LINE_HEIGHT = 36;
    const PADDING = 6;

    function initialize(store) {
        View.initialize();
        messageStore = store;
        scrollOffset = 0;
    }

    function onLayout(dc) {
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var msgs = messageStore.getMessages();
        var count = msgs.size();

        if (count == 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                dc.getWidth() / 2,
                dc.getHeight() / 2,
                Graphics.FONT_SMALL,
                WatchUi.loadResource(Rez.Strings.NoMessages),
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
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

        var screenW = dc.getWidth();
        var y = 24; // top padding for round screen

        for (var i = scrollOffset; i < count && i < scrollOffset + LINES_PER_PAGE; i++) {
            var msg = msgs[i];
            var text = msg["message"];
            var isSent = msg["sent"];

            // Truncate long messages
            if (text.length() > 25) {
                text = text.substring(0, 22) + "...";
            }

            if (isSent) {
                // Sent messages: right-aligned, blue background
                dc.setColor(Graphics.COLOR_DK_BLUE, Graphics.COLOR_TRANSPARENT);
                var textW = dc.getTextWidthInPixels(text, Graphics.FONT_XTINY);
                var bubbleX = screenW - textW - PADDING * 3;
                dc.fillRoundedRectangle(bubbleX, y, textW + PADDING * 2, LINE_HEIGHT - 4, 8);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    screenW - PADDING * 2,
                    y + (LINE_HEIGHT - 4) / 2,
                    Graphics.FONT_XTINY,
                    text,
                    Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            } else {
                // Received messages: left-aligned, gray background
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                var textW = dc.getTextWidthInPixels(text, Graphics.FONT_XTINY);
                dc.fillRoundedRectangle(PADDING, y, textW + PADDING * 2, LINE_HEIGHT - 4, 8);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(
                    PADDING * 2,
                    y + (LINE_HEIGHT - 4) / 2,
                    Graphics.FONT_XTINY,
                    text,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }

            y += LINE_HEIGHT;
        }

        // Scroll indicator
        if (count > LINES_PER_PAGE) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            if (scrollOffset > 0) {
                dc.drawText(screenW / 2, 8, Graphics.FONT_XTINY, "^", Graphics.TEXT_JUSTIFY_CENTER);
            }
            if (scrollOffset + LINES_PER_PAGE < count) {
                dc.drawText(screenW / 2, dc.getHeight() - 18, Graphics.FONT_XTINY, "v", Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    function scrollUp() {
        if (scrollOffset > 0) {
            scrollOffset--;
            WatchUi.requestUpdate();
        }
    }

    function scrollDown() {
        var maxOffset = messageStore.getMessageCount() - LINES_PER_PAGE;
        if (maxOffset < 0) { maxOffset = 0; }
        if (scrollOffset < maxOffset) {
            scrollOffset++;
            WatchUi.requestUpdate();
        }
    }
}
