
const bcrypt = require("bcryptjs");
const { validationResult } = require("express-validator");
const User = require("../models/User");
const jwt = require("jsonwebtoken");

async function register(req, res) {
  // Kiểm tra dữ liệu đầu vào
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    return res.status(400).json({
      message: "Dữ liệu không hợp lệ",
      errors: errors.array(),
    });
  }

  try {
    const { fullName, email, password } = req.body;

    const normalizedEmail = email.trim().toLowerCase();

    // Kiểm tra email đã tồn tại chưa
    const existingUser = await User.findOne({
      email: normalizedEmail,
    });

    if (existingUser) {
      return res.status(409).json({
        message: "Email đã được đăng ký",
      });
    }

    // Băm mật khẩu trước khi lưu
    const passwordHash = await bcrypt.hash(password, 12);

    const user = await User.create({
      fullName: fullName.trim(),
      email: normalizedEmail,
      passwordHash,
    });

    return res.status(201).json({
      message: "Đăng ký tài khoản thành công",
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    // Xử lý trường hợp email trùng do hai yêu cầu đồng thời
    if (error.code === 11000) {
      return res.status(409).json({
        message: "Email đã được đăng ký",
      });
    }

    console.error("Register error:", error.message);

    return res.status(500).json({
      message: "Không thể đăng ký tài khoản lúc này",
    });
  }
}

module.exports = { register, login };

async function login(req, res) {
  const errors = validationResult(req);

  if (!errors.isEmpty()) {
    return res.status(400).json({
      message: "Dữ liệu không hợp lệ",
      errors: errors.array(),
    });
  }

  try {
    const { email, password } = req.body;

    const user = await User.findOne({
      email: email.trim().toLowerCase(),
    }).select("+passwordHash");

    if (!user) {
      return res.status(401).json({
        message: "Email hoặc mật khẩu không chính xác",
      });
    }

    const passwordMatches = await bcrypt.compare(
      password,
      user.passwordHash
    );

    if (!passwordMatches) {
      return res.status(401).json({
        message: "Email hoặc mật khẩu không chính xác",
      });
    }

    if (!process.env.JWT_SECRET) {
      throw new Error("Thieu JWT_SECRET trong file .env");
    }

    const token = jwt.sign(
      { sub: user._id.toString() },
      process.env.JWT_SECRET,
      { expiresIn: "1d" }
    );

    return res.status(200).json({
      message: "Đăng nhập thành công",
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        avatarUrl: user.avatarUrl,
      },
    });
  } catch (error) {
    console.error("Login error:", error.message);

    return res.status(500).json({
      message: "Không thể đăng nhập lúc này",
    });
  }
}

