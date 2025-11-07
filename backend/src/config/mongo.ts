import { MongoClient, Db } from "mongodb";

let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectMongo(uri: string, dbName: string) {
  // Validate URI format
  if (!uri || !uri.startsWith("mongodb")) {
    throw new Error("Invalid MongoDB URI. Must start with 'mongodb://' or 'mongodb+srv://'");
  }

  client = new MongoClient(uri, {
    serverSelectionTimeoutMS: 30000,
    connectTimeoutMS: 30000,
    socketTimeoutMS: 30000,
    // For mongodb+srv, TLS is automatically enabled
    // Only set tls explicitly if using mongodb://
    ...(uri.startsWith("mongodb+srv://") ? {} : { tls: true }),
    retryWrites: true,
    retryReads: true,
  });
  
  try {
    await client.connect();
    // Test the connection
    await client.db("admin").command({ ping: 1 });
    db = client.db(dbName);
    console.log(`✅ Connected to MongoDB: ${dbName}`);
    return db;
  } catch (error: any) {
    console.error("❌ MongoDB connection error:");
    console.error(`   Error: ${error.message}`);
    
    // Provide helpful error messages
    if (error.message?.includes("authentication failed") || error.message?.includes("bad auth")) {
      console.error("   → Check your username and password in MONGODB_URI");
      console.error("   → Make sure password is URL-encoded if it has special characters");
    } else if (error.message?.includes("IP") || error.message?.includes("whitelist")) {
      console.error("   → Your IP address may not be whitelisted in MongoDB Atlas");
      console.error("   → Go to MongoDB Atlas → Network Access → Add IP Address");
    } else if (error.message?.includes("SSL") || error.message?.includes("TLS")) {
      console.error("   → SSL/TLS connection error. Check:");
      console.error("     - MongoDB connection string format");
      console.error("     - IP whitelist in MongoDB Atlas");
      console.error("     - Network/firewall settings");
    }
    
    throw error;
  }
}

export function getDb(): Db {
  if (!db) throw new Error("Mongo DB not initialized");
  return db;
}

