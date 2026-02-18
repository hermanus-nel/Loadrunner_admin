// supabase/functions/verify-bank-account/index.ts
// ============================================================================
// LoadRunner: Paystack Bank Account Verification Edge Function
// ============================================================================
// Called automatically after a driver_bank_accounts row is inserted.
// Validates the account with Paystack Resolve Account API.
// Updates the bank account record with verification result.
// ============================================================================

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PAYSTACK_SECRET_KEY = Deno.env.get("PAYSTACK_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

interface VerifyRequest {
  bank_account_id: string;
  account_number: string;
  bank_code: string;
  driver_id: string;
}

serve(async (req: Request) => {
  try {
    // Validate request
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
    }

    const { bank_account_id, account_number, bank_code, driver_id }: VerifyRequest = await req.json();

    if (!bank_account_id || !account_number || !bank_code || !driver_id) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400 }
      );
    }

    // Initialize Supabase admin client
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // ── Step 1: Call Paystack Resolve Account API ──
    console.log(`Verifying bank account for driver ${driver_id}: ${bank_code} / ${account_number}`);

    const paystackResponse = await fetch(
      `https://api.paystack.co/bank/resolve?account_number=${account_number}&bank_code=${bank_code}`,
      {
        headers: {
          Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
        },
      }
    );

    const paystackData = await paystackResponse.json();
    console.log(`Paystack response:`, JSON.stringify(paystackData));

    if (paystackData.status === true && paystackData.data) {
      // ── Step 2a: Bank account VALID ──
      const accountName = paystackData.data.account_name;
      const accountNumber = paystackData.data.account_number;

      // Update bank account record
      const { error: updateError } = await supabase
        .from("driver_bank_accounts")
        .update({
          is_verified: true,
          verified_at: new Date().toISOString(),
          verification_method: "api",
          verification_details: paystackData.data,
          account_name: accountName,
          verification_notes: `Paystack verified: ${accountName}`,
        })
        .eq("id", bank_account_id);

      if (updateError) {
        console.error("Failed to update bank account:", updateError);
      }

      // Notify driver
      const { error: notifyError } = await supabase.rpc(
        "send_notification_with_preferences",
        {
          p_user_id: driver_id,
          p_notification_type: "bank_verification_completed",
          p_message: `Your bank account (${accountName}) has been verified successfully.`,
          p_related_id: driver_id,
        }
      );

      if (notifyError) {
        console.error("Failed to notify driver:", notifyError);
      }

      // Notify admins (informational)
      const driverInfo = await supabase
        .from("users")
        .select("first_name, last_name")
        .eq("id", driver_id)
        .single();

      const driverName = driverInfo.data
        ? `${driverInfo.data.first_name ?? ""} ${driverInfo.data.last_name ?? ""}`.trim()
        : "Unknown";

      await supabase.rpc("notify_all_admins", {
        p_notification_type: "bank_verification_completed",
        p_message: `Bank verified for ${driverName}: ${accountName} at ${bank_code}`,
        p_related_id: driver_id,
      });

      return new Response(
        JSON.stringify({
          success: true,
          verified: true,
          account_name: accountName,
        }),
        { status: 200 }
      );
    } else {
      // ── Step 2b: Bank account INVALID or verification failed ──
      const errorMessage = paystackData.message || "Unknown verification error";

      // Update bank account record with failure
      const { error: updateError } = await supabase
        .from("driver_bank_accounts")
        .update({
          is_verified: false,
          verification_notes: `Paystack verification failed: ${errorMessage}`,
          rejection_reason: errorMessage,
          rejected_at: new Date().toISOString(),
          verification_details: paystackData,
        })
        .eq("id", bank_account_id);

      if (updateError) {
        console.error("Failed to update bank account:", updateError);
      }

      // Notify driver
      await supabase.rpc("send_notification_with_preferences", {
        p_user_id: driver_id,
        p_notification_type: "bank_verification_completed",
        p_message:
          "We couldn't verify your bank account details. Please check your account number and bank selection in your driver profile.",
        p_related_id: driver_id,
      });

      // Notify admins (they may need to investigate)
      const driverInfo = await supabase
        .from("users")
        .select("first_name, last_name")
        .eq("id", driver_id)
        .single();

      const driverName = driverInfo.data
        ? `${driverInfo.data.first_name ?? ""} ${driverInfo.data.last_name ?? ""}`.trim()
        : "Unknown";

      await supabase.rpc("notify_all_admins", {
        p_notification_type: "bank_verification_completed",
        p_message: `Bank verification FAILED for ${driverName}: ${errorMessage}`,
        p_related_id: driver_id,
      });

      return new Response(
        JSON.stringify({
          success: true,
          verified: false,
          error: errorMessage,
        }),
        { status: 200 }
      );
    }
  } catch (error) {
    console.error("verify-bank-account error:", error);
    return new Response(
      JSON.stringify({ success: false, error: String(error) }),
      { status: 500 }
    );
  }
});
