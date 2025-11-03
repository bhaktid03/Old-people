import dotenv from 'dotenv';
dotenv.config();

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

export const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 4000),
  mongoUri: requireEnv('MONGODB_URI'),
  mongoDbName: process.env.MONGODB_DB || 'chaupal',
  gridfsAudioBucket: process.env.GRIDFS_AUDIO_BUCKET || 'audio',
  gridfsTtsBucket: process.env.GRIDFS_TTS_BUCKET || 'tts'
};


