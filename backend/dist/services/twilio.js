import twilio from 'twilio';
import { logger } from './logger.js';
let cachedClient = null;
function getTwilioClient() {
    if (cachedClient)
        return cachedClient;
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    if (!accountSid || !authToken) {
        throw new Error('Twilio not configured: missing TWILIO_ACCOUNT_SID or TWILIO_AUTH_TOKEN');
    }
    cachedClient = twilio(accountSid, authToken);
    return cachedClient;
}
export async function sendOtpSms(toPhoneE164, message) {
    const messagingServiceSid = process.env.TWILIO_MESSAGING_SERVICE_SID;
    const fromNumber = process.env.TWILIO_FROM_NUMBER; // alternative to messaging service
    const sendParams = { to: toPhoneE164, body: message };
    if (messagingServiceSid) {
        sendParams.messagingServiceSid = messagingServiceSid;
    }
    else if (fromNumber) {
        sendParams.from = fromNumber;
    }
    else {
        throw new Error('Twilio not configured: set TWILIO_MESSAGING_SERVICE_SID or TWILIO_FROM_NUMBER');
    }
    const client = getTwilioClient();
    try {
        await client.messages.create(sendParams);
    }
    catch (err) {
        logger.error({ err, toPhoneE164 }, 'Failed to send OTP via Twilio');
        throw err;
    }
}
