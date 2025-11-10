import { getDb } from "../../config/mongo.js";
export async function getUserLanguage(userId) {
    const db = getDb();
    const doc = await db.collection("profiles").findOne({ _id: userId }, { projection: { language: 1 } });
    return doc?.language ?? null;
}
