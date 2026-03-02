export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const topic = url.searchParams.get("topic");
    if (!topic) {
      return Response.json({ error: "missing topic parameter" }, { status: 400, headers: corsHeaders });
    }

    try {
      if (url.pathname === "/messages" && request.method === "GET") {
        return await handleGetMessages(topic, url, corsHeaders);
      } else if (url.pathname === "/send" && request.method === "POST") {
        return await handleSendMessage(topic, request, corsHeaders);
      } else {
        return Response.json({ error: "not found" }, { status: 404, headers: corsHeaders });
      }
    } catch (err) {
      return Response.json({ error: err.message }, { status: 500, headers: corsHeaders });
    }
  },
};

async function handleGetMessages(topic, url, corsHeaders) {
  const since = url.searchParams.get("since") || "24h";
  const ntfyUrl = `https://ntfy.sh/${encodeURIComponent(topic)}/json?poll=1&since=${since}`;

  const resp = await fetch(ntfyUrl);
  if (!resp.ok) {
    return Response.json({ error: `ntfy returned ${resp.status}` }, { status: 502, headers: corsHeaders });
  }

  const text = await resp.text();
  const lines = text.trim().split("\n").filter(Boolean);

  const messages = [];
  for (const line of lines) {
    const obj = JSON.parse(line);
    if (obj.event !== "message") continue;
    messages.push({
      id: obj.id,
      time: obj.time,
      message: obj.message || "",
    });
    if (messages.length >= 20) break;
  }

  return Response.json({ messages }, { headers: corsHeaders });
}

async function handleSendMessage(topic, request, corsHeaders) {
  const body = await request.json();
  const message = body.message;
  if (!message) {
    return Response.json({ error: "missing message" }, { status: 400, headers: corsHeaders });
  }

  const ntfyUrl = `https://ntfy.sh/${encodeURIComponent(topic)}`;
  const resp = await fetch(ntfyUrl, {
    method: "POST",
    body: message,
  });

  if (!resp.ok) {
    return Response.json({ error: `ntfy returned ${resp.status}` }, { status: 502, headers: corsHeaders });
  }

  const result = await resp.json();
  return Response.json({ success: true, id: result.id }, { headers: corsHeaders });
}
