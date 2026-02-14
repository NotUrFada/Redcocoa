/**
 * Returns a Twilio Video access token for the given room and identity.
 * Used for voice and video calls via Twilio Programmable Video.
 *
 * Setup:
 * 1. Twilio Console: get Account SID, create API Key (US1 region) → API Key SID + API Key Secret.
 * 2. Set secrets:
 *    supabase secrets set TWILIO_ACCOUNT_SID=AC...
 *    supabase secrets set TWILIO_API_KEY_SID=SK...
 *    supabase secrets set TWILIO_API_KEY_SECRET=...
 *
 * Request: POST with JSON { "roomName": "channel1", "identity": "user1" }
 * Response: { "token": "eyJ..." }
 */
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { SignJWT } from "npm:jose@5.9.6";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const accountSid = Deno.env.get("TWILIO_ACCOUNT_SID");
    const apiKeySid = Deno.env.get("TWILIO_API_KEY_SID");
    const apiKeySecret = Deno.env.get("TWILIO_API_KEY_SECRET");
    if (!accountSid || !apiKeySid || !apiKeySecret) {
      return new Response(
        JSON.stringify({ error: "TWILIO_ACCOUNT_SID, TWILIO_API_KEY_SID, and TWILIO_API_KEY_SECRET must be set" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = (await req.json().catch(() => ({}))) as { roomName?: string; identity?: string };
    const roomName = typeof body.roomName === "string" ? body.roomName.trim() : "";
    const identity = typeof body.identity === "string" && body.identity.trim() ? body.identity.trim() : "user";

    if (!roomName) {
      return new Response(
        JSON.stringify({ error: "roomName is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const now = Math.floor(Date.now() / 1000);
    const exp = now + 3600;
    const jti = `${apiKeySid}-${now}-${Math.random().toString(36).slice(2)}`;

    const payload = {
      jti,
      iss: apiKeySid,
      sub: accountSid,
      iat: now,
      nbf: now,
      exp,
      grants: {
        identity,
        video: { room: roomName },
      },
    };

    const secret = new TextEncoder().encode(apiKeySecret);
    const token = await new SignJWT(payload as Record<string, unknown>)
      .setProtectedHeader({ alg: "HS256", cty: "twilio-fpa;v=1", typ: "JWT" })
      .setIssuedAt(now)
      .setExpirationTime(exp)
      .sign(secret);

    return new Response(
      JSON.stringify({ token }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("twilio-token error:", e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
