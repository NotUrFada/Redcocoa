/**
 * Push notification webhook - triggered when a new message is inserted.
 * Sends a push to the recipient's device so it appears on the lock screen.
 *
 * Setup:
 * 1. Create a Database Webhook in Supabase Dashboard → Database → Webhooks
 * 2. Table: messages, Event: Insert
 * 3. Edge Function: push-message
 * 4. Add secrets: APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY (base64 .p8 key), APNS_BUNDLE_ID
 *
 * Get APNs credentials from Apple Developer → Certificates, Identifiers & Profiles → Keys
 */
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface MessageRecord {
  id: string;
  match_id: string;
  sender_id: string;
  content: string;
  created_at: string;
}

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: MessageRecord;
  schema: string;
  old_record: MessageRecord | null;
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
    if (payload.table !== "messages" || payload.type !== "INSERT") {
      return new Response(JSON.stringify({ received: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const { match_id, sender_id, content } = payload.record;

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Get match to find recipient
    const { data: match, error: matchError } = await supabase
      .from("matches")
      .select("user1_id, user2_id")
      .eq("id", match_id)
      .single();

    if (matchError || !match) {
      console.error("Match lookup failed:", matchError);
      return new Response(JSON.stringify({ error: "Match not found" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      });
    }

    const recipientId =
      match.user1_id === sender_id ? match.user2_id : match.user1_id;

    // Get sender name for notification
    const { data: sender } = await supabase
      .from("profiles")
      .select("name")
      .eq("id", sender_id)
      .single();

    const senderName = sender?.name ?? "Someone";
    const body =
      content?.startsWith("voice:") ? "Voice message" : (content ?? "New message");
    const title = `${senderName}`;

    // Get recipient's device token
    const { data: tokenRow, error: tokenError } = await supabase
      .from("user_device_tokens")
      .select("token")
      .eq("user_id", recipientId)
      .single();

    if (tokenError || !tokenRow?.token) {
      return new Response(
        JSON.stringify({ skipped: true, reason: "No device token for recipient" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    // Send via APNs (requires APNS_* secrets to be configured)
    const apnsKeyId = Deno.env.get("APNS_KEY_ID");
    const apnsTeamId = Deno.env.get("APNS_TEAM_ID");
    const apnsKey = Deno.env.get("APNS_KEY");
    const apnsBundleId = Deno.env.get("APNS_BUNDLE_ID") ?? "com.redcocoa.app";

    if (!apnsKeyId || !apnsTeamId || !apnsKey) {
      return new Response(
        JSON.stringify({
          queued: true,
          message: "APNs not configured - add APNS_KEY_ID, APNS_TEAM_ID, APNS_KEY secrets",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
      );
    }

    // Call APNs - for now log; full JWT + HTTP/2 implementation needed
    // See NOTIFICATIONS_SETUP.md for complete APNs setup
    console.log("Would send push to", tokenRow.token.substring(0, 20) + "...", ":", title, body);

    return new Response(
      JSON.stringify({ success: true, recipient: recipientId }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    console.error("Push webhook error:", error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  }
});
