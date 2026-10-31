
const mongoose = require("mongoose");
const Task = require("../models/Task");
const TaskShare = require("../models/TaskShare");
const User = require("../models/User");

function validId(id) {
  return mongoose.isValidObjectId(id);
}

// Kiem tra nguoi tao cong viec
function isOwner(task, userId) {
  return task.createdBy.toString() === userId.toString();
}

// Chi chu so huu duoc quan ly chia se
async function getOwnedTask(taskId, userId, res) {
  if (!validId(taskId)) {
    res.status(400).json({
      message: "Ma cong viec khong hop le",
    });
    return null;
  }

  const task = await Task.findById(taskId);

  if (!task) {
    res.status(404).json({
      message: "Khong tim thay cong viec",
    });
    return null;
  }

  if (!isOwner(task, userId)) {
    res.status(403).json({
      message: "Chi chu so huu moi duoc quan ly chia se",
    });
    return null;
  }

  return task;
}

// GET /tasks/:id/shares
async function getShares(req, res) {
  try {
    const taskId = req.params.id;

    if (!validId(taskId)) {
      return res.status(400).json({
        message: "Ma cong viec khong hop le",
      });
    }

    const task = await Task.findById(taskId);

    if (!task) {
      return res.status(404).json({
        message: "Khong tim thay cong viec",
      });
    }

    const isSharedUser = await TaskShare.exists({
      taskId,
      userId: req.userId,
    });

    const isAssigned = task.assigneeIds.some(
      (id) => id.toString() === req.userId.toString()
    );

    if (!isOwner(task, req.userId) && !isSharedUser && !isAssigned) {
      return res.status(403).json({
        message: "Ban khong co quyen xem danh sach chia se",
      });
    }

    const shares = await TaskShare.find({ taskId })
      .populate("userId", "fullName email avatarUrl")
      .populate("sharedBy", "fullName email")
      .sort({ createdAt: -1 })
      .lean();

    return res.status(200).json({
      count: shares.length,
      shares,
    });
  } catch (error) {
    console.error("Get shares error:", error.message);

    return res.status(500).json({
      message: "Khong the lay danh sach chia se",
    });
  }
}

// POST /tasks/:id/shares
// Body: { userIds: [], permission: "viewer" | "editor" }
async function addShares(req, res) {
  try {
    const task = await getOwnedTask(
      req.params.id,
      req.userId,
      res
    );

    if (!task) return;

    const { userIds, permission } = req.body;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        message: "Vui long chon nguoi duoc chia se",
      });
    }

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        message: "Quyen chia se phai la viewer hoac editor",
      });
    }

    if (
      !userIds.every(
        (id) => typeof id === "string" && validId(id)
      )
    ) {
      return res.status(400).json({
        message: "Ma nguoi dung khong hop le",
      });
    }

    const uniqueIds = [...new Set(userIds.map(String))];

    if (uniqueIds.includes(task.createdBy.toString())) {
      return res.status(400).json({
        message: "Khong the chia se cong viec cho chinh minh",
      });
    }

    const users = await User.find({
      _id: { $in: uniqueIds },
    }).select("_id");

    if (users.length !== uniqueIds.length) {
      return res.status(404).json({
        message: "Mot hoac nhieu nguoi dung khong ton tai",
      });
    }

    // Tao moi hoac cap nhat quyen neu da chia se truoc do
    const operations = uniqueIds.map((userId) => ({
      updateOne: {
        filter: {
          taskId: task._id,
          userId,
        },
        update: {
          $set: {
            permission,
            sharedBy: req.userId,
          },
        },
        upsert: true,
      },
    }));

    await TaskShare.bulkWrite(operations);

    const shares = await TaskShare.find({
      taskId: task._id,
    })
      .populate("userId", "fullName email avatarUrl")
      .populate("sharedBy", "fullName email")
      .lean();

    return res.status(200).json({
      message: "Chia se cong viec thanh cong",
      count: shares.length,
      shares,
    });
  } catch (error) {
    console.error("Add shares error:", error.message);

    return res.status(500).json({
      message: "Khong the chia se cong viec",
    });
  }
}

// PATCH /tasks/:id/shares/:shareId
// Body: { permission: "viewer" | "editor" }
async function updateShare(req, res) {
  try {
    const task = await getOwnedTask(
      req.params.id,
      req.userId,
      res
    );

    if (!task) return;

    const { shareId } = req.params;
    const { permission } = req.body;

    if (!validId(shareId)) {
      return res.status(400).json({
        message: "Ma chia se khong hop le",
      });
    }

    if (!["viewer", "editor"].includes(permission)) {
      return res.status(400).json({
        message: "Quyen chia se khong hop le",
      });
    }

    const share = await TaskShare.findOne({
      _id: shareId,
      taskId: task._id,
    });

    if (!share) {
      return res.status(404).json({
        message: "Khong tim thay ban ghi chia se",
      });
    }

    share.permission = permission;
    await share.save();

    return res.status(200).json({
      message: "Cap nhat quyen chia se thanh cong",
      share,
    });
  } catch (error) {
    console.error("Update share error:", error.message);

    return res.status(500).json({
      message: "Khong the cap nhat quyen chia se",
    });
  }
}

// DELETE /tasks/:id/shares/:shareId
async function removeShare(req, res) {
  try {
    const task = await getOwnedTask(
      req.params.id,
      req.userId,
      res
    );

    if (!task) return;

    const { shareId } = req.params;

    if (!validId(shareId)) {
      return res.status(400).json({
        message: "Ma chia se khong hop le",
      });
    }

    const share = await TaskShare.findOneAndDelete({
      _id: shareId,
      taskId: task._id,
    });

    if (!share) {
      return res.status(404).json({
        message: "Khong tim thay ban ghi chia se",
      });
    }

    return res.status(200).json({
      message: "Thu hoi quyen chia se thanh cong",
    });
  } catch (error) {
    console.error("Remove share error:", error.message);

    return res.status(500).json({
      message: "Khong the thu hoi quyen chia se",
    });
  }
}

module.exports = {
  getShares,
  addShares,
  updateShare,
  removeShare,
};
