import { json, optionsResponse } from "../_shared/cors.ts";
import { adminClient, requireAdmin } from "../_shared/supabase.ts";

async function sendExpo(messages: Array<Record<string, unknown>>) {
  const response = await fetch("https://exp.host/--/api/v2/push/send", {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify(messages),
  });
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data?.errors?.[0]?.message || "Expo push service failed.");
  return data;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    await requireAdmin(req);
    const body = await req.json();
    const title = String(body.title || "").trim().slice(0, 80);
    const message = String(body.body || "").trim().slice(0, 500);
    const target = String(body.target || "Home").slice(0, 40);
    const kind = String(body.kind || "General").slice(0, 40);
    const assignmentIds = Array.isArray(body.assignmentIds)
      ? body.assignmentIds.filter((id: unknown): id is string => typeof id === "string").slice(0, 100)
      : [];
    if (!title || !message) return json({ error: "Title and message are required." }, 400);

    const db = adminClient();
    let deviceQuery = db.from("device_tokens").select("expo_push_token").eq("active", true);
    if (assignmentIds.length > 0) {
      const { data: assignments, error: assignmentError } = await db
        .from("service_assignments")
        .select("user_id")
        .in("id", assignmentIds);
      if (assignmentError) throw assignmentError;
      const userIds = [...new Set((assignments || []).map((row) => row.user_id).filter(Boolean))];
      if (userIds.length === 0) return json({ ok: true, sent: 0 });
      deviceQuery = deviceQuery.in("user_id", userIds);
    }
    const { data: devices, error } = await deviceQuery;
    if (error) throw error;
    const tokens = (devices || []).map((d) => d.expo_push_token).filter(Boolean);
    let sent = 0;
    for (let i = 0; i < tokens.length; i += 100) {
      const chunk = tokens.slice(i, i + 100).map((to) => ({ to, title, body: message, sound: "default", data: { screen: target, kind } }));
      if (chunk.length) { await sendExpo(chunk); sent += chunk.length; }
    }
    await db.from("notification_history").insert({ title, body: message, target, sent_count: sent });
    return json({ ok: true, sent });
  } catch (error) {
    console.error(error);
    return json({ error: error instanceof Error ? error.message : "Could not send notification." }, 500);
  }
});
