import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 }
      );
    }

    const token = authHeader.replace(/^Bearer\s+/i, "").trim();
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    );

    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser(token);

    if (userError || !user) {
      return new Response(
        JSON.stringify({
          error: "Unauthorized",
          detail: userError?.message ?? "Invalid or expired token",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 401 }
      );
    }

    const userId = user.id;

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    async function deleteStorageFolder(path: string): Promise<void> {
      const { data: items, error: listError } = await supabaseAdmin.storage
        .from("avatars")
        .list(path, { limit: 1000 });

      if (listError) {
        console.error("Storage list error:", listError);
        return;
      }

      const pathsToRemove: string[] = [];
      for (const item of items || []) {
        const fullPath = path ? `${path}/${item.name}` : item.name;
        if (item.id) {
          pathsToRemove.push(fullPath);
        } else {
          await deleteStorageFolder(fullPath);
        }
      }

      if (pathsToRemove.length > 0) {
        await supabaseAdmin.storage.from("avatars").remove(pathsToRemove);
      }
    }

    await deleteStorageFolder(userId);

    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      userId
    );

    if (deleteError) {
      throw deleteError;
    }

    return new Response(
      JSON.stringify({ success: true, message: "Account deleted" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );
  } catch (error) {
    console.error("Delete user error:", error);
    const message = error instanceof Error ? error.message : "Failed to delete account";
    return new Response(
      JSON.stringify({ error: message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
    );
  }
});
