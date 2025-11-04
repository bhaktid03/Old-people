import { Request, Response } from 'express';
import { sendOtp, verifyOtp } from '../services/otp.service.js';

function normalizePhone(phone: string): string {
  // Expecting E.164 e.g. +919876543210; basic normalization fallback
  const trimmed = phone.trim();
  if (!trimmed.startsWith('+')) throw new Error('Phone must be in E.164 format, e.g. +919876543210');
  return trimmed;
}

export async function sendOtpHandler(req: Request, res: Response) {
  try {
    const phone = normalizePhone(String(req.body.phone || ''));
    await sendOtp(phone);
    res.json({ ok: true });
  } catch (err: any) {
    res.status(400).json({ ok: false, error: err.message || 'Failed to send OTP' });
  }
}

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


