/**
 * Returns an Agora RTC token for the given channel and uid.
 * Required when your Agora project is in "Secure" mode (App Certificate enabled).
 *
 * Setup:
 * 1. In Agora Console → your project → get App ID and App Certificate.
 * 2. Set secrets:
 *    supabase secrets set AGORA_APP_ID=your_app_id
 *    supabase secrets set AGORA_APP_CERTIFICATE=your_app_certificate
 *
 * Request: POST with JSON { "channelName": "channel1", "uid": 0 }
 * Response: { "token": "007eJx..." }
 */
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { RtcTokenBuilder, RtcRole } from "npm:agora-access-token@2.0.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const appId = Deno.env.get("AGORA_APP_ID");
    const appCert = Deno.env.get("AGORA_APP_CERTIFICATE");
    if (!appId || !appCert) {
      return new Response(
        JSON.stringify({ error: "AGORA_APP_ID and AGORA_APP_CERTIFICATE must be set" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body = await req.json().catch(() => ({})) as { channelName?: string; uid?: number };
    const channelName = typeof body.channelName === "string" ? body.channelName.trim() : "";
    const uid = typeof body.uid === "number" ? body.uid : 0;

    if (!channelName) {
      return new Response(
        JSON.stringify({ error: "channelName is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const expirationTimeInSeconds = 3600;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCert,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    return new Response(
      JSON.stringify({ token }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("agora-token error:", e);
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
