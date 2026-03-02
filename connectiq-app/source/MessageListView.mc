using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Math;
using Toybox.Application.Properties;

class MessageListView extends WatchUi.View {
    var messageStore;
    var scrollOffset;
    var lastVisibleCount;
    const LINE_H = 24;
    const BUBBLE_VPAD = 4;
    const BUBBLE_HPAD = 6;
    const BUBBLE_GAP = 4;
    const SCREEN_MARGIN = 28;

    function initialize(store) {
        View.initialize();
        messageStore = store;
        scrollOffset = 0;
        lastVisibleCount = 4;
    }

    function onLayout(dc) {
    }

    // Word-wrap text into lines that fit within maxW
    function wrapText(dc, text, maxW) {
        var lines = [];
        var remaining = text;
        while (remaining.length() > 0) {
            if (dc.getTextWidthInPixels(remaining, Graphics.FONT_XTINY) <= maxW) {
                lines.add(remaining);
                break;
            }
            // Find longest substring that fits
            var breakIdx = remaining.length() - 1;
            while (breakIdx > 1) {
                if (dc.getTextWidthInPixels(remaining.substring(0, breakIdx), Graphics.FONT_XTINY) <= maxW) {
                    break;
                }
                breakIdx--;
            }
            if (breakIdx <= 1) {
                lines.add(remaining.substring(0, 1));
                remaining = remaining.substring(1, remaining.length());
                continue;
            }
            // Try to break at a word boundary (look back for a space)
            var wordBreak = -1;
            for (var j = breakIdx; j >= 1 && j >= breakIdx - 15; j--) {
                if (remaining.substring(j - 1, j).equals(" ")) {
                    wordBreak = j - 1;
                    break;
                }
            }
            if (wordBreak > 0) {
                lines.add(remaining.substring(0, wordBreak));
                remaining = remaining.substring(wordBreak + 1, remaining.length());
            } else {
                lines.add(remaining.substring(0, breakIdx));
                remaining = remaining.substring(breakIdx, remaining.length());
            }
        }
        if (lines.size() == 0) { lines.add(""); }
        return lines;
    }

    // Calculate usable width at a given Y position on a round screen
    function getRowBounds(screenW, screenH, y, rowH) {
        var r = screenW / 2;
        var cy = screenH / 2;
        var edgeY = y;
        if ((y + rowH) > cy) {
            edgeY = y + rowH;
        }
        var dy = (edgeY - cy).abs();
        if (dy >= r) {
            return [r, 0];
        }
        var halfW = Math.sqrt(r * r - dy * dy).toNumber();
        var margin = r - halfW + 8;
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

        if (scrollOffset >= count) { scrollOffset = count - 1; }
        if (scrollOffset < 0) { scrollOffset = 0; }

        // Max text width for wrapping (~75% of screen)
        var maxTextW = screenW * 3 / 4 - BUBBLE_HPAD * 2;
        var maxH = screenH - SCREEN_MARGIN * 2;

        // First pass: compute layout for visible messages
        // Each entry: [msgIndex, lines, bubbleH, maxLineW]
        var layouts = [];
        var totalH = 0;

        for (var i = scrollOffset; i < count; i++) {
            var text = msgs[i]["message"] as Lang.String;
            var lines = wrapText(dc, text, maxTextW);
            var bubbleH = lines.size() * LINE_H + BUBBLE_VPAD * 2;

            if (totalH > 0 && totalH + bubbleH + BUBBLE_GAP > maxH) {
                break;
            }

            // Find max line width for bubble sizing
            var maxLW = 0;
            for (var li = 0; li < lines.size(); li++) {
                var lw = dc.getTextWidthInPixels(lines[li], Graphics.FONT_XTINY);
                if (lw > maxLW) { maxLW = lw; }
            }

            layouts.add([i, lines, bubbleH, maxLW]);
            totalH += bubbleH + BUBBLE_GAP;
        }

        if (totalH > BUBBLE_GAP) { totalH -= BUBBLE_GAP; }
        lastVisibleCount = layouts.size();

        // Center vertically
        var startY = (screenH - totalH) / 2;
        var y = startY;

        // Second pass: render
        for (var vi = 0; vi < layouts.size(); vi++) {
            var layout = layouts[vi];
            var msgIdx = layout[0] as Lang.Number;
            var lines = layout[1];
            var bubbleH = layout[2] as Lang.Number;
            var maxLW = layout[3] as Lang.Number;
            var msg = msgs[msgIdx];
            var isSent = msg["sent"];

            var bubbleW = maxLW + BUBBLE_HPAD * 2;

            var bounds = getRowBounds(screenW, screenH, y, bubbleH);
            var leftMargin = bounds[0] as Lang.Number;
            var usableW = bounds[1] as Lang.Number;
            if (usableW < 40) {
                y += bubbleH + BUBBLE_GAP;
                continue;
            }
            if (bubbleW > usableW) { bubbleW = usableW; }

            var bubbleX;
            if (isSent) {
                bubbleX = leftMargin + usableW - bubbleW;
                var msgId = msg["id"] as Lang.String;
                var isPending = (msgId.find("local_") != null);
                dc.setColor(isPending ? 0x405880 : 0x2060C0, Graphics.COLOR_TRANSPARENT);
            } else {
                bubbleX = leftMargin;
                dc.setColor(0x404040, Graphics.COLOR_TRANSPARENT);
            }

            dc.fillRoundedRectangle(bubbleX, y, bubbleW, bubbleH, 10);

            // Draw text lines
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            var lineCount = (lines as Lang.Array).size();
            for (var ti = 0; ti < lineCount; ti++) {
                var textY = y + BUBBLE_VPAD + ti * LINE_H + LINE_H / 2;
                dc.drawText(
                    bubbleX + BUBBLE_HPAD,
                    textY,
                    Graphics.FONT_XTINY,
                    lines[ti],
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }

            y += bubbleH + BUBBLE_GAP;
        }

        // Scroll indicators
        if (scrollOffset > 0) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([[screenW/2-6, 16], [screenW/2+6, 16], [screenW/2, 8]]);
        }
        var lastShown = -1;
        if (layouts.size() > 0) {
            lastShown = (layouts[layouts.size() - 1])[0] as Lang.Number;
        }
        if (lastShown < count - 1) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            var by = screenH - 16;
            dc.fillPolygon([[screenW/2-6, by], [screenW/2+6, by], [screenW/2, by+8]]);
        }
    }

    function scrollToBottom() {
        var vc = lastVisibleCount;
        if (vc == null || vc < 2) { vc = 4; }
        scrollOffset = messageStore.getMessageCount() - vc;
        if (scrollOffset < 0) { scrollOffset = 0; }
        WatchUi.requestUpdate();
    }

    function pageUp() {
        var vc = lastVisibleCount;
        if (vc == null || vc < 2) { vc = 4; }
        scrollOffset -= vc;
        if (scrollOffset < 0) { scrollOffset = 0; }
        WatchUi.requestUpdate();
    }

    function pageDown() {
        var vc = lastVisibleCount;
        if (vc == null || vc < 2) { vc = 4; }
        scrollOffset += vc;
        var maxOff = messageStore.getMessageCount() - 1;
        if (maxOff < 0) { maxOff = 0; }
        if (scrollOffset > maxOff) { scrollOffset = maxOff; }
        WatchUi.requestUpdate();
    }
}
