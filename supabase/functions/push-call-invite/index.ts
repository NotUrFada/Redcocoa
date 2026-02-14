/**
 * Push notification when an incoming call is created (call_invites INSERT with status ringing).
 * Notifies the callee on and off the app (lock screen, background, or closed).
 *
 * Setup:
 * 1. Create a Database Webhook in Supabase Dashboard → Database → Webhooks
 * 2. Table: call_invites, Event: Insert
 * 3. Edge Function: push-call-invite
 * 4. Same APNs secrets as push-message: APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY, APNS_BUNDLE_ID
 *
 * Payload includes inviteId, channelName, callerId, callType so the app can show Accept/Decline and join the call.
 */
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface CallInviteRecord {
  id: string;
  match_id: string;
  caller_id: string;
  callee_id: string;
  channel_name: string;
  call_type: string;
  status: string;
  created_at: string;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: CallInviteRecord;
  schema: string;
  old_record: CallInviteRecord | null;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const payload: WebhookPayload = await req.json();
    if (payload.table !== "call_invites" || payload.type !== "INSERT") {
      return new Response(JSON.stringify({ received: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const record = payload.record;
    if (record.status !== "ringing") {
      return new Response(JSON.stringify({ skipped: true, reason: "not ringing" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const { id, callee_id, caller_id, channel_name, call_type } = record;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: callerProfile } = await supabase
      .from("profiles")
      .select("name")
      .eq("id", caller_id)
      .single();

    const callerName = callerProfile?.name ?? "Someone";

    const { data: tokenRow, error: tokenError } = await supabase
      .from("user_device_tokens")
      .select("token")
      .eq("user_id", callee_id)
      .single();

    if (tokenError || !tokenRow?.token) {
      return new Response(
        JSON.stringify({ skipped: true, reason: "No device token for callee" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const apnsKeyId = Deno.env.get("APNS_KEY_ID");
    const apnsTeamId = Deno.env.get("APNS_TEAM_ID");
    const apnsKey = Deno.env.get("APNS_KEY");
    const apnsBundleId = Deno.env.get("APNS_BUNDLE_ID") ?? "com.redcocoa.app";

    if (!apnsKeyId || !apnsTeamId || !apnsKey) {
      console.log("Push call invite:", callerName, "→ callee", callee_id, "(APNs not configured)");
      return new Response(
        JSON.stringify({
          queued: true,
          message: "APNs not configured - add APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY secrets",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    const apnsPayload = {
      aps: {
        alert: {
          title: "Incoming Call",
          body: `${callerName} is calling you`,
        },
        sound: "default",
        category: "INCOMING_CALL",
        "mutable-content": 1,
      },
      inviteId: id,
      channelName: channel_name,
      callerId: caller_id,
      callType: call_type,
    };

    const production = Deno.env.get("APNS_PRODUCTION") === "true";
    const sent = await sendApns({
      deviceToken: tokenRow.token,
      payload: apnsPayload,
      bundleId: apnsBundleId,
      keyId: apnsKeyId,
      teamId: apnsTeamId,
      keyP8: apnsKey,
      production,
    });

    return new Response(
      JSON.stringify({
        success: sent,
        recipient: callee_id,
        callerName,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    console.error("Push call invite error:", error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  }
});

async function sendApns(options: {
  deviceToken: string;
  payload: Record<string, unknown>;
  bundleId: string;
  keyId: string;
  teamId: string;
  keyP8: string;
  production?: boolean;
}): Promise<boolean> {
  const { deviceToken, payload, bundleId, keyId, teamId, keyP8, production = false } = options;
  const host = production ? "api.push.apple.com" : "api.sandbox.push.apple.com";

  try {
    const jwt = await createApnsJwt({ keyId, teamId, keyP8 });
    const url = `https://${host}/3/device/${deviceToken}`;
    const res = await fetch(url, {
      method: "POST",
      headers: {
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-expiration": "0",
        authorization: `bearer ${jwt}`,
        "content-type": "application/json",
      },
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const text = await res.text();
      console.error("APNs error", res.status, text);
      return false;
    }
    return true;
  } catch (e) {
    console.error("APNs send failed:", e);
    return false;
  }
}

function base64UrlEncode(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (let i = 0; i < bytes.length; i++) binary += String.fromCharCode(bytes[i]);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function createApnsJwt(options: {
  keyId: string;
  teamId: string;
  keyP8: string;
}): Promise<string> {
  const { keyId, teamId, keyP8 } = options;
  const pemDecoded = keyP8.includes("-----BEGIN")
    ? keyP8
    : atob(keyP8.replace(/\s/g, ""));
  const keyMatch = pemDecoded.match(/-----BEGIN PRIVATE KEY-----([\s\S]*?)-----END PRIVATE KEY-----/);
  const keyBase64 = keyMatch ? keyMatch[1].replace(/\s/g, "") : pemDecoded.replace(/\s/g, "");
  const keyBinary = Uint8Array.from(atob(keyBase64), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBinary,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const encoder = new TextEncoder();
  const b64 = (data: string) =>
    btoa(String.fromCharCode(...encoder.encode(data))).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

  const header = { alg: "ES256", kid: keyId };
  const now = Math.floor(Date.now() / 1000);
  const claims = { iss: teamId, iat: now };
  const headerB64 = b64(JSON.stringify(header));
  const claimsB64 = b64(JSON.stringify(claims));
  const signingInput = `${headerB64}.${claimsB64}`;

  const sig = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    encoder.encode(signingInput)
  );
  const sigB64 = base64UrlEncode(sig);
  return `${signingInput}.${sigB64}`;
}
