
const express = require("express");
const authMiddleware = require("../middleware/authMiddleware");

const {
  getTasks,
  getTaskById,
} = require("../controllers/taskController");

const router = express.Router();

// GET /api/tasks - Danh sach cong viec
router.get("/", authMiddleware, getTasks);

// GET /api/tasks/:id - Chi tiet cong viec
router.get("/:id", authMiddleware, getTaskById);

module.exports = router;
