# Stripe Webhook Setup Guide

This guide explains how to set up Stripe webhooks so that payment status is automatically updated to "completed" when a payment succeeds.

## Overview

When a user pays with their card, Stripe sends a webhook event (`payment_intent.succeeded`) to your backend. The webhook endpoint updates the payment status from "pending" to "completed" in the database.

## Prerequisites

1. Stripe account (Test or Live mode)
2. Stripe Secret Key
3. Stripe Webhook Secret (obtained after configuring webhook endpoint)

## Setup Steps

### Step 1: Configure Stripe Secrets

**For Local Development (User Secrets):**

```bash
# Set Stripe Secret Key
dotnet user-secrets set "Stripe:SecretKey" "sk_test_..."

# Set Stripe Webhook Secret (you'll get this after setting up the webhook endpoint)
dotnet user-secrets set "Stripe:WebhookSecret" "whsec_..."
```

**For Production (Environment Variables):**

```bash
# Set environment variables
export STRIPE_SECRET_KEY="sk_live_..."
export STRIPE_WEBHOOK_SECRET="whsec_..."
```

**Important:** Do NOT store these secrets in `appsettings.json` or `appsettings.Development.json`. The application will fail to start if secrets are missing.

### Step 2: Set Up Webhook Endpoint

#### Option A: Local Development (Using Stripe CLI)

1. **Install Stripe CLI:**
   - Download from: https://stripe.com/docs/stripe-cli
   - Or use: `brew install stripe/stripe-cli/stripe` (macOS)

2. **Login to Stripe CLI:**
   ```bash
   stripe login
   ```

3. **Forward webhooks to your local server:**
   ```bash
   stripe listen --forward-to https://localhost:5001/api/stripe/webhook
   ```
   (Replace `5001` with your actual port if different)

4. **Copy the webhook signing secret:**
   The CLI will output something like:
   ```
   > Ready! Your webhook signing secret is whsec_xxxxxxxxxxxxx
   ```

5. **Set the webhook secret:**
   ```bash
   dotnet user-secrets set "Stripe:WebhookSecret" "whsec_xxxxxxxxxxxxx"
   ```

6. **Test the webhook:**
   ```bash
   stripe trigger payment_intent.succeeded
   ```

#### Option B: Production (Stripe Dashboard)

1. **Go to Stripe Dashboard:**
   - Navigate to: https://dashboard.stripe.com/webhooks
   - Click "Add endpoint"

2. **Configure the endpoint:**
   - **Endpoint URL:** `https://your-domain.com/api/stripe/webhook`
   - **Description:** "TaxiMo Payment Webhook"
   - **Events to send:** Select `payment_intent.succeeded`

3. **Get the webhook signing secret:**
   - After creating the endpoint, click on it
   - Find "Signing secret" section
   - Click "Reveal" and copy the secret (starts with `whsec_`)

4. **Set the webhook secret:**
   - Add to your production environment variables:
     ```bash
     export STRIPE_WEBHOOK_SECRET="whsec_..."
     ```

### Step 3: Verify Webhook is Working

1. **Make a test payment** in your mobile app
2. **Check the application logs** for:
   ```
   Stripe webhook received - Event type: payment_intent.succeeded
   Payment status updated successfully - PaymentId: X, OldStatus: pending, NewStatus: completed
   ```
3. **Check the database:**
   - Query the `Payments` table
   - Verify `Status` is "completed"
   - Verify `PaidAt` is set to current timestamp
   - Verify `TransactionRef` contains the PaymentIntent ID

## Troubleshooting

### Payment Status Not Updating

1. **Check webhook secret is configured:**
   - Verify User Secrets or environment variables are set
   - Check application logs for "Stripe webhook secret configuration error"

2. **Check webhook endpoint is reachable:**
   - For local: Ensure Stripe CLI is running and forwarding
   - For production: Verify the endpoint URL is publicly accessible

3. **Check webhook events in Stripe Dashboard:**
   - Go to: https://dashboard.stripe.com/webhooks
   - Click on your webhook endpoint
   - Check "Events" tab for recent events
   - Look for failed events and error messages

4. **Check application logs:**
   - Look for webhook-related log entries
   - Check for errors in `HandlePaymentIntentSucceeded`
   - Verify payment lookup is successful

### Common Issues

**Issue: "Stripe webhook secret configuration error"**
- **Solution:** Set the webhook secret in User Secrets or environment variables

**Issue: "Webhook signature verification failed"**
- **Solution:** Ensure you're using the correct webhook secret for your endpoint
- For local: Use the secret from `stripe listen` command
- For production: Use the secret from Stripe Dashboard

**Issue: "PaymentId metadata is required but missing"**
- **Solution:** This shouldn't happen if PaymentIntent is created correctly
- Verify the `create-payment-intent` endpoint includes metadata with `paymentId`

**Issue: "Payment not found"**
- **Solution:** Verify the `paymentId` in metadata matches an existing Payment record
- Check that the payment was created before the PaymentIntent

## Testing

### Test with Stripe CLI (Local)

```bash
# Trigger a test payment_intent.succeeded event
stripe trigger payment_intent.succeeded

# Check your application logs for the webhook processing
```

### Test with Stripe Dashboard (Production)

1. Go to: https://dashboard.stripe.com/test/webhooks
2. Click on your webhook endpoint
3. Click "Send test webhook"
4. Select `payment_intent.succeeded`
5. Check your application logs

## Security Notes

- Webhook endpoint is public (no authentication required)
- Security is provided by Stripe signature verification
- Never trust payment confirmation from the mobile app
- Webhook is the single source of truth for payment status

## Monitoring

Monitor these logs for webhook health:
- `Stripe webhook received` - Webhook received
- `Payment status updated successfully` - Payment updated
- `Payment already completed` - Idempotent handling (normal)
- Any error logs indicate issues that need attention

