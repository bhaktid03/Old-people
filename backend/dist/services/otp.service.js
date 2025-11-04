import crypto from 'node:crypto';
import { getDb } from '../config/mongo.js';
import { sendOtpSms } from './twilio.js';
import { logger } from './logger.js';
function hashCode(code) {
    return crypto.createHash('sha256').update(code).digest('hex');
}
function generateCode() {
    return String(Math.floor(100000 + Math.random() * 900000));
}
export async function sendOtp(phoneE164) {
    const db = getDb();
    const collection = db.collection('otps');
    // Optional: basic rate limit - allow one active OTP per phone; invalidate previous
    await collection.updateMany({ phone: phoneE164, usedAt: { $exists: false }, expiresAt: { $gt: new Date() } }, { $set: { expiresAt: new Date() } });
    const code = generateCode();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    const doc = {
        phone: phoneE164,
        codeHash: hashCode(code),
        purpose: 'login',
        expiresAt,
        createdAt: new Date(),
        attempts: 0
    };
    await collection.insertOne(doc);
    const smsBody = `Your Chaupal verification code is ${code}. It expires in 5 minutes.`;
    try {
        await sendOtpSms(phoneE164, smsBody);
    }
    catch (err) {
        logger.error({ err, phoneE164 }, 'sendOtpSms failed');
        throw new Error('Failed to send OTP. Please try again.');
    }
}
export async function verifyOtp(phoneE164, code) {
    const db = getDb();
    const collection = db.collection('otps');
    const now = new Date();
    const doc = await collection.findOne({ phone: phoneE164 }, { sort: { createdAt: -1 } });
    if (!doc)
        return false;
    if (doc.usedAt)
        return false;
    if (doc.expiresAt <= now)
        return false;
    const ok = doc.codeHash === hashCode(code);
    if (!ok) {
        await collection.updateOne({ _id: doc._id }, { $inc: { attempts: 1 } });
        return false;
    }
    await collection.updateOne({ _id: doc._id }, { $set: { usedAt: now } });
    return true;
}
