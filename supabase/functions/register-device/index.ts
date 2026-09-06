import { corsHeaders, json, optionsResponse } from "../_shared/cors.ts";
import { adminClient } from "../_shared/supabase.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.112.4";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const body = await req.json();
    const expoPushToken = String(body.expoPushToken || "").trim();
    const platform = ["ios", "android", "web", "unknown"].includes(body.platform) ? body.platform : "unknown";
    if (!expoPushToken.startsWith("ExponentPushToken[") && !expoPushToken.startsWith("ExpoPushToken[")) {
      return json({ error: "Invalid Expo push token." }, 400);
    }
    let userId: string | null = null;
    const authorization = req.headers.get("Authorization") || "";
    if (authorization.startsWith("Bearer ")) {
      const url = Deno.env.get("SUPABASE_URL");
      const anon = Deno.env.get("SUPABASE_ANON_KEY") || Deno.env.get("SUPABASE_PUBLISHABLE_KEY");
      if (!url || !anon) return json({ error: "Supabase server configuration is incomplete." }, 500);
      const userClient = createClient(url, anon, { global: { headers: { Authorization: authorization } }, auth: { persistSession: false, autoRefreshToken: false } });
      const { data: { user } } = await userClient.auth.getUser();
      userId = user?.id || null;
    }
    const db = adminClient();
    const { error } = await db.from("device_tokens").upsert({
      expo_push_token: expoPushToken,
      user_id: userId,
      platform,
      device_name: typeof body.deviceName === "string" ? body.deviceName.slice(0, 120) : null,
      app_version: typeof body.appVersion === "string" ? body.appVersion.slice(0, 40) : null,
      active: true,
      last_seen_at: new Date().toISOString(),
    }, { onConflict: "expo_push_token" });
    if (error) throw error;
    return json({ ok: true });
  } catch (error) {
    console.error(error);
    return json({ error: "Could not register device." }, 500);
  }
});
