
const User = require("../models/User");

async function searchUsers(req, res) {
  try {
    const q = typeof req.query.q === "string"
      ? req.query.q.trim()
      : "";

    if (q.length < 2) {
      return res.status(400).json({
        message: "Tu khoa tim kiem phai co it nhat 2 ky tu",
      });
    }

    const safeQuery = q.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    const users = await User.find({
      _id: { $ne: req.userId },
      $or: [
        { fullName: { $regex: safeQuery, $options: "i" } },
        { email: { $regex: safeQuery, $options: "i" } },
      ],
    })
      .select("_id fullName email avatarUrl")
      .limit(20)
      .lean();

    return res.status(200).json({
      count: users.length,
      users,
    });
  } catch (error) {
    console.error("Search users error:", error.message);

    return res.status(500).json({
      message: "Khong the tim kiem nguoi dung",
    });
  }
}

module.exports = { searchUsers };
