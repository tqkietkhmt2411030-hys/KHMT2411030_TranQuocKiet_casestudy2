
const express = require("express");

const authMiddleware = require("../middleware/authMiddleware");

const {
  getShares,
  addShares,
  updateShare,
  removeShare,
} = require("../controllers/taskShareController");

const router = express.Router();

router.use(authMiddleware);

// Lay danh sach nguoi duoc chia se
router.get("/:id/shares", getShares);

// Chia se cong viec cho mot hoac nhieu nguoi
router.post("/:id/shares", addShares);

// Thay doi quyen viewer/editor
router.patch("/:id/shares/:shareId", updateShare);

// Thu hoi quyen chia se
router.delete("/:id/shares/:shareId", removeShare);

module.exports = router;
