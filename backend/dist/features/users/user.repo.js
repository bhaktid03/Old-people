import { getDb } from "../../config/mongo.js";
const COLLECTION = "users";
export async function listUsers(limit = 50) {
    const db = getDb();
    const cursor = db.collection(COLLECTION)
        .find({}, { limit, sort: { createdAt: -1 } });
    return await cursor.toArray();
}
export async function getUserById(userId) {
    const db = getDb();
    return await db.collection(COLLECTION).findOne({ _id: userId });
}
export async function createUser(user) {
    const db = getDb();
    const now = new Date();
    const doc = { ...user, createdAt: now, updatedAt: now };
    await db.collection(COLLECTION).insertOne(doc);
    return doc;
}
export async function updateUser(userId, update) {
    const db = getDb();
    const toSet = { ...update, updatedAt: new Date() };
    const res = await db.collection(COLLECTION)
        .findOneAndUpdate({ _id: userId }, { $set: toSet }, { returnDocument: "after" });
    const value = (res && res.value) ? res.value : null;
    return value;
}
export async function deleteUser(userId) {
    const db = getDb();
    const res = await db.collection(COLLECTION).deleteOne({ _id: userId });
    return res.deletedCount === 1;
}
