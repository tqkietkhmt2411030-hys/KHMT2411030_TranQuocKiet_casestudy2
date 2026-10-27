
const mongoose = require("mongoose");

async function connectDatabase() {
  const uri = process.env.MONGODB_URI;

  if (!uri) {
    throw new Error("Thieu MONGODB_URI trong file .env");
  }

  await mongoose.connect(uri, {
    serverSelectionTimeoutMS: 10000,
  });

  console.log("MongoDB Atlas connected successfully!");
}

module.exports = connectDatabase;
