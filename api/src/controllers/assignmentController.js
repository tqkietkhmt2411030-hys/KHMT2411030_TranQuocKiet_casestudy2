
const mongoose = require("mongoose");
const Task = require("../models/Task");
const User = require("../models/User");
const TaskShare = require("../models/TaskShare");

function validId(id) {
  return mongoose.isValidObjectId(id);
}

function isOwner(task, userId) {
  return task.createdBy.toString() === userId.toString();
}

async function findTaskForOwner(id, userId, res) {
  if (!validId(id)) {
    res.status(400).json({
      message: "Ma cong viec khong hop le",
    });
    return null;
  }

  const task = await Task.findById(id);

  if (!task) {
    res.status(404).json({
      message: "Khong tim thay cong viec",
    });
    return null;
  }

  if (!isOwner(task, userId)) {
    res.status(403).json({
      message: "Chi nguoi tao moi duoc quan ly nguoi duoc giao",
    });
    return null;
  }

  return task;
}

// GET /tasks/:id/assignees
async function getAssignees(req, res) {
  try {
    const { id } = req.params;

    if (!validId(id)) {
      return res.status(400).json({
        message: "Ma cong viec khong hop le",
      });
    }

    const task = await Task.findById(id);

    if (!task) {
      return res.status(404).json({
        message: "Khong tim thay cong viec",
      });
    }

    const isAssigned = task.assigneeIds.some(
      (userId) => userId.toString() === req.userId.toString()
    );

    const isShared = await TaskShare.exists({
      taskId: id,
      userId: req.userId,
    });

    if (!isOwner(task, req.userId) && !isAssigned && !isShared) {
      return res.status(403).json({
        message: "Ban khong co quyen xem danh sach nguoi duoc giao",
      });
    }

    const populatedTask = await Task.findById(id)
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl")
      .lean();

    return res.status(200).json({
      count: populatedTask.assigneeIds.length,
      assignees: populatedTask.assigneeIds,
      primaryAssignee: populatedTask.primaryAssigneeId,
    });
  } catch (error) {
    console.error("Get assignees error:", error.message);

    return res.status(500).json({
      message: "Khong the lay danh sach nguoi duoc giao",
    });
  }
}

// POST /tasks/:id/assignees
// Body: { userIds: [], primaryAssigneeId: "..." }
async function assignUsers(req, res) {
  try {
    const task = await findTaskForOwner(
      req.params.id,
      req.userId,
      res
    );

    if (!task) return;

    const { userIds, primaryAssigneeId } = req.body;

    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({
        message: "Vui long chon it nhat mot nguoi duoc giao",
      });
    }

    if (
      !userIds.every(
        (id) => typeof id === "string" && validId(id)
      )
    ) {
      return res.status(400).json({
        message: "Danh sach ma nguoi dung khong hop le",
      });
    }

    const uniqueIds = [...new Set(userIds.map(String))];

    const users = await User.find({
      _id: { $in: uniqueIds },
    }).select("_id fullName email");

    if (users.length !== uniqueIds.length) {
      return res.status(404).json({
        message: "Mot hoac nhieu nguoi dung khong ton tai",
      });
    }

    const existingIds = task.assigneeIds.map(
      (id) => id.toString()
    );

    const mergedIds = [
      ...new Set([...existingIds, ...uniqueIds]),
    ];

    task.assigneeIds = mergedIds;

    if (primaryAssigneeId !== undefined) {
      if (primaryAssigneeId === null || primaryAssigneeId === "") {
        task.primaryAssigneeId = null;
      } else {
        if (
          !validId(primaryAssigneeId) ||
          !mergedIds.includes(primaryAssigneeId.toString())
        ) {
          return res.status(400).json({
            message: "Nguoi phu trach chinh phai nam trong danh sach duoc giao",
          });
        }

        task.primaryAssigneeId = primaryAssigneeId;
      }
    }

    await task.save();

    const updatedTask = await Task.findById(task._id)
      .populate("assigneeIds", "fullName email avatarUrl")
      .populate("primaryAssigneeId", "fullName email avatarUrl")
      .lean();

    return res.status(200).json({
      message: "Giao cong viec thanh cong",
      task: updatedTask,
    });
  } catch (error) {
    console.error("Assign users error:", error.message);

    return res.status(500).json({
      message: "Khong the giao cong viec",
    });
  }
}

// PATCH /tasks/:id/assignees/:userId
// Body: { isPrimary: true | false }
async function updateAssignee(req, res) {
  try {
    const task = await findTaskForOwner(
      req.params.id,
      req.userId,
      res
    );

    if (!task) return;

    const { userId } = req.params;
    const { isPrimary } = req.body;

    if (!validId(userId)) {
      return res.status(400).json({
        message: "Ma nguoi dung khong hop le",
      });
    }

    if (typeof isPrimary !== "boolean") {
      return res.status(400).json({
        message: "isPrimary phai la true hoac false",
      });
    }

    const assigned = task.assigneeIds.some(
      (id) => id.toString() === userId
    );

    if (!assigned) {
      return res.status(404).json({
        message: "Nguoi dung chua duoc giao cong viec",
      });
    }

    if (isPrimary) {
      task.primaryAssigneeId = userId;
    } else if (
      task.primaryAssigneeId?.toString() === userId
    ) {
      task.primaryAssigneeId = null;
    }

    await task.save();

    return res.status(200).json({
      message: "Cap nhat nguoi phu trach thanh cong",
      primaryAssigneeId: task.primaryAssigneeId,
    });
  } catch (error) {
    console.error("Update assignee error:", error.message);

    return res.status(500).json({
      message: "Khong the cap nhat nguoi duoc giao",
    });
  }
}

// DELETE /tasks/:id/assignees/:userId
async function removeAssignee(req, res) {
  try {
    const task = await findTaskForOwner(
      req.params.id,
      req.userId,
      res
    );

    if (!task) return;

    const { userId } = req.params;

    if (!validId(userId)) {
      return res.status(400).json({
        message: "Ma nguoi dung khong hop le",
      });
    }

    const exists = task.assigneeIds.some(
      (id) => id.toString() === userId
    );

    if (!exists) {
      return res.status(404).json({
        message: "Nguoi dung khong nam trong danh sach duoc giao",
      });
    }

    task.assigneeIds = task.assigneeIds.filter(
      (id) => id.toString() !== userId
    );

    if (task.primaryAssigneeId?.toString() === userId) {
      task.primaryAssigneeId = null;
    }

    await task.save();

    return res.status(200).json({
      message: "Huy giao viec thanh cong",
      assigneeIds: task.assigneeIds,
      primaryAssigneeId: task.primaryAssigneeId,
    });
  } catch (error) {
    console.error("Remove assignee error:", error.message);

    return res.status(500).json({
      message: "Khong the huy giao viec",
    });
  }
}

module.exports = {
  getAssignees,
  assignUsers,
  updateAssignee,
  removeAssignee,
};
