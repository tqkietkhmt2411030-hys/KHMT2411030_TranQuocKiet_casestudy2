
const express = require("express");

const authMiddleware = require("../middleware/authMiddleware");

const {
  getAssignees,
  assignUsers,
  updateAssignee,
  removeAssignee,
} = require("../controllers/assignmentController");

const router = express.Router();

router.use(authMiddleware);

// Danh sach nguoi duoc giao
router.get("/:id/assignees", getAssignees);

// Giao cong viec cho mot hoac nhieu nguoi
router.post("/:id/assignees", assignUsers);

// Chon hoac bo nguoi phu trach chinh
router.patch("/:id/assignees/:userId", updateAssignee);

// Huy giao viec cho mot nguoi
router.delete("/:id/assignees/:userId", removeAssignee);

module.exports = router;
