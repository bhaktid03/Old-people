import { MongoClient, Db, GridFSBucket } from 'mongodb';
import { env } from './env.js';
import { logger } from '../services/logger.js';

let client: MongoClient | undefined;
let db: Db | undefined;
let audioBucket: GridFSBucket | undefined;
let ttsBucket: GridFSBucket | undefined;

export async function connectMongo(): Promise<{ db: Db; audioBucket: GridFSBucket; ttsBucket: GridFSBucket; client: MongoClient; }> {
  if (db && audioBucket && ttsBucket && client) {
    return { db, audioBucket, ttsBucket, client };
  }

  client = new MongoClient(env.mongoUri, { serverSelectionTimeoutMS: 10000 });
  await client.connect();
  db = client.db(env.mongoDbName);
  audioBucket = new GridFSBucket(db, { bucketName: env.gridfsAudioBucket });
  ttsBucket = new GridFSBucket(db, { bucketName: env.gridfsTtsBucket });

  const { databaseName } = db;
  logger.info({ databaseName, audioBucket: env.gridfsAudioBucket, ttsBucket: env.gridfsTtsBucket }, 'Connected to MongoDB Atlas');

  return { db, audioBucket, ttsBucket, client };
}

export async function disconnectMongo(): Promise<void> {
  if (client) {
    await client.close();
    client = undefined;
    db = undefined;
    audioBucket = undefined;
    ttsBucket = undefined;
    logger.info('Disconnected from MongoDB');
  }
}

export function getDb(): Db {
  if (!db) throw new Error('MongoDB is not connected');
  return db;
}

export function getAudioBucket(): GridFSBucket {
  if (!audioBucket) throw new Error('MongoDB is not connected');
  return audioBucket;
}

export function getTtsBucket(): GridFSBucket {
  if (!ttsBucket) throw new Error('MongoDB is not connected');
  return ttsBucket;
}


