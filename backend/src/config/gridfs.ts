import { GridFSBucket } from "mongodb";
import { getDb } from "./mongo.js";

let audioBucket: GridFSBucket | null = null;
let videoBucket: GridFSBucket | null = null;

export function getAudioBucket(): GridFSBucket {
  if (!audioBucket) {
    const db = getDb();
    audioBucket = new GridFSBucket(db, { bucketName: process.env.GRIDFS_AUDIO_BUCKET || "audio" });
  }
  return audioBucket;
}

export function getVideoBucket(): GridFSBucket {
  if (!videoBucket) {
    const db = getDb();
    videoBucket = new GridFSBucket(db, { bucketName: process.env.GRIDFS_VIDEO_BUCKET || "video" });
  }
  return videoBucket;
}



