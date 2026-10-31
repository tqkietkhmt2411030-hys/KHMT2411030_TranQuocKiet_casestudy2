
const mongoose = require("mongoose");

const taskShareSchema = new mongoose.Schema(
  {
    taskId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Task",
      required: true,
    },

    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    permission: {
      type: String,
      enum: ["viewer", "editor"],
      default: "viewer",
      required: true,
    },

    sharedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
  },
  {
    timestamps: true,
    collection: "task_shares",
  }
);

// Moi cong viec chi co mot ban ghi chia se cho moi nguoi dung
taskShareSchema.index(
  { taskId: 1, userId: 1 },
  { unique: true }
);

module.exports = mongoose.model("TaskShare", taskShareSchema);
