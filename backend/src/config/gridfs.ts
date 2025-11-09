import { GridFSBucket } from "mongodb";
import { getDb } from "./mongo.js";

let audioBucket: GridFSBucket | null = null;
let videoBucket: GridFSBucket | null = null;
let imageBucket: GridFSBucket | null = null;
let mediaBucket: GridFSBucket | null = null;

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

export function getImageBucket(): GridFSBucket {
  if (!imageBucket) {
    const db = getDb();
    imageBucket = new GridFSBucket(db, { bucketName: process.env.GRIDFS_IMAGE_BUCKET || "image" });
  }
  return imageBucket;
}

export function getMediaBucket(): GridFSBucket {
  if (!mediaBucket) {
    const db = getDb();
    mediaBucket = new GridFSBucket(db, { bucketName: process.env.GRIDFS_MEDIA_BUCKET || "media" });
  }
  return mediaBucket;
}



