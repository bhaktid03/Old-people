import { Router } from 'express';
import { sendOtpHandler, verifyOtpHandler } from '../controllers/auth.controller.js';

export const authRouter = Router();

authRouter.post('/otp/send', sendOtpHandler);
authRouter.post('/otp/verify', verifyOtpHandler);


