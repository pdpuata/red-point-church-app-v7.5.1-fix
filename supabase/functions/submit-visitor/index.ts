import { corsHeaders, json, optionsResponse } from "../_shared/cors.ts";
import { adminClient } from "../_shared/supabase.ts";

// Server-side abuse control: limit submissions per client IP.
// First layer only — 3 submissions per 10-minute window per IP.
const RATE_LIMIT_MAX = 3;
const RATE_LIMIT_WINDOW_SECONDS = 600; // 10 minutes

// Deno.serve provides the peer address via info.remoteAddr. We deliberately do
// NOT trust client-supplied headers such as x-forwarded-for / x-real-ip, which
// are trivially spoofable. If the address is unavailable we fall back to a
// shared "unknown" key rather than inventing an identity.
// NOTE: whether info.remoteAddr is the true end-user IP (versus the Supabase
// relay) must be verified against a deployed request before relying on it as
// the primary key — see Production Verification in the project docs.
function clientKey(info: unknown): string {
  const addr = (info as { remoteAddr?: { hostname?: unknown } } | undefined)?.remoteAddr?.hostname;
  return typeof addr === "string" && addr.length > 0 ? addr : "unknown";
}

// Returns true if the request is within the limit, false if it exceeds it.
// Fails OPEN: a transient limiter/database problem is logged and the submission
// is allowed, so a real visitor enquiry is never silently lost.
async function withinRateLimit(db: any, key: string): Promise<boolean> {
  try {
    const { data, error } = await db.rpc("check_visitor_rate", {
      p_key: key,
      p_max: RATE_LIMIT_MAX,
      p_window_seconds: RATE_LIMIT_WINDOW_SECONDS,
    });
    if (error) throw error;
    const count = typeof data === "number" ? data : Number(data);
    return Number.isFinite(count) && count <= RATE_LIMIT_MAX;
  } catch (limiterError) {
    console.error("Rate limiter failed; allowing submission (fail-open):", limiterError);
    return true;
  }
}

Deno.serve(async (req, info) => {
  if (req.method === "OPTIONS") return optionsResponse();
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);
  try {
    const db = adminClient();

    // Rate-limit BEFORE any database insert or email so abuse is stopped early.
    if (!(await withinRateLimit(db, clientKey(info)))) {
      return json({ error: "Too many submissions. Please try again later." }, 429);
    }

    const body = await req.json();
    const name = String(body.name || "").trim().slice(0, 120);
    const contact = String(body.contact || "").trim().slice(0, 180);
    const message = String(body.message || "").trim().slice(0, 2000);
    if (!name || !contact) return json({ error: "Name and contact are required." }, 400);

    const { data, error } = await db.from("visitor_submissions").insert({ name, contact, message: message || null }).select("id").single();
    if (error) throw error;

    const to = Deno.env.get("VISITOR_EMAIL_TO");
    const resendKey = Deno.env.get("RESEND_API_KEY");
    const from = Deno.env.get("RESEND_FROM_EMAIL");
    if (to && resendKey && from) {
      const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: { Authorization: `Bearer ${resendKey}`, "Content-Type": "application/json" },
        body: JSON.stringify({ from, to: [to], subject: `New Red Point Church visitor: ${name}`, text: `Name: ${name}\nContact: ${contact}\nMessage: ${message || "(none)"}\nSubmission ID: ${data.id}` }),
      });
      if (!response.ok) console.error("Visitor email failed", await response.text());
    } else {
      console.warn("Visitor email secrets are not configured; submission was stored.");
    }
    return json({ ok: true });
  } catch (error) {
    console.error(error);
    return json({ error: "Could not submit visitor details." }, 500);
  }
});
