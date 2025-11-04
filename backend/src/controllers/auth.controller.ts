import { Request, Response } from 'express';
import { sendOtp, verifyOtp } from '../services/otp.service.js';

function normalizePhone(phone: string): string {
  // Expecting E.164 e.g. +919876543210; basic normalization fallback
  const trimmed = phone.trim();
  if (!trimmed.startsWith('+')) throw new Error('Phone must be in E.164 format, e.g. +919876543210');
  return trimmed;
}

/**
 * @swagger
 * /auth/otp/send:
 *   post:
 *     summary: Send OTP to phone number
 *     description: Sends an OTP code to the provided phone number via SMS
 *     tags:
 *       - Authentication
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/SendOtpRequest'
 *           example:
 *             phone: "+919876543210"
 *     responses:
 *       200:
 *         description: OTP sent successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       400:
 *         description: Bad request - Invalid phone number or missing required fields
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
export async function sendOtpHandler(req: Request, res: Response) {
  try {
    const phone = normalizePhone(String(req.body.phone || ''));
    await sendOtp(phone);
    res.json({ ok: true });
  } catch (err: any) {
    res.status(400).json({ ok: false, error: err.message || 'Failed to send OTP' });
  }
}

/**
 * @swagger
 * /auth/otp/verify:
 *   post:
 *     summary: Verify OTP code
 *     description: Verifies the OTP code sent to the phone number
 *     tags:
 *       - Authentication
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/VerifyOtpRequest'
 *           example:
 *             phone: "+919876543210"
 *             code: "123456"
 *     responses:
 *       200:
 *         description: OTP verified successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/SuccessResponse'
 *       400:
 *         description: Bad request - Invalid or expired code, or missing required fields
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 *       500:
 *         description: Internal server error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ErrorResponse'
 */
export async function verifyOtpHandler(req: Request, res: Response) {
  try {
    const phone = normalizePhone(String(req.body.phone || ''));
    const code = String(req.body.code || '').trim();
    if (!code) throw new Error('Code is required');
    const ok = await verifyOtp(phone, code);
    if (!ok) return res.status(400).json({ ok: false, error: 'Invalid or expired code' });
    // TODO: issue your JWT here; for now just success flag
    res.json({ ok: true });
  } catch (err: any) {
    res.status(400).json({ ok: false, error: err.message || 'Verification failed' });
  }
}


