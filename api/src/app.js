
const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/authRoutes");
const taskRoutes = require("./routes/taskRoutes");
const userRoutes = require("./routes/userRoutes");
const assignmentRoutes = require("./routes/assignmentRoutes");
const taskShareRoutes = require("./routes/taskShareRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/tasks", taskRoutes);
app.use("/api/users", userRoutes);
app.use("/api/tasks", assignmentRoutes);
app.use("/api/tasks", taskShareRoutes);

app.get("/", (req, res) => {
  res.json({
    message: "Task Manager API is running",
  });
});

app.get("/api/health", (req, res) => {
  const mongoose = require("mongoose");

  res.json({
    api: "ok",
    database:
      mongoose.connection.readyState === 1
        ? "connected"
        : "disconnected",
  });
});

module.exports = app;
