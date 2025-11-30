const { verifyToken } = require("../utils/generateToken");
const User = require("../models/User");
const Admin = require("../models/Admin");

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  red: "\x1b[31m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
};

/**
 * JWT Authentication Middleware
 * Protects routes by verifying JWT token
 */
const authenticate = async (req, res, next) => {
  try {
    let token;

    // Get token from header
    if (
      req.headers.authorization &&
      req.headers.authorization.startsWith("Bearer")
    ) {
      token = req.headers.authorization.split(" ")[1];
    }

    if (!token) {
      console.log(
        `${colors.red}❌ Authentication failed: No token provided${colors.reset}`
      );
      return res.status(401).json({
        success: false,
        message: "Access denied. No token provided.",
      });
    }

    // Verify token
    const decoded = verifyToken(token);

    // Find user based on role
    let user;
    if (decoded.role === "admin") {
      user = await Admin.findById(decoded.id).select("-password");
    } else {
      user = await User.findById(decoded.id).select("-password");
    }

    if (!user) {
      console.log(
        `${colors.red}❌ Authentication failed: User not found${colors.reset}`
      );
      return res.status(401).json({
        success: false,
        message: "User not found.",
      });
    }

    // Add user to request object
    req.user = user;

    console.log(
      `${colors.green}✅ Authentication successful: ${user.email} (${user.role})${colors.reset}`
    );
    next();
  } catch (error) {
    console.error(
      `${colors.red}❌ Authentication error:${colors.reset}`,
      error.message
    );
    return res.status(401).json({
      success: false,
      message: "Invalid token.",
    });
  }
};

/**
 * Admin Authorization Middleware
 * Restricts access to admin users only
 */
const authorizeAdmin = (req, res, next) => {
  if (req.user && req.user.role === "admin") {
    console.log(
      `${colors.green}✅ Admin authorization granted: ${req.user.email}${colors.reset}`
    );
    next();
  } else {
    console.log(
      `${colors.red}❌ Admin authorization failed: ${req.user?.email}${colors.reset}`
    );
    return res.status(403).json({
      success: false,
      message: "Access denied. Admin privileges required.",
    });
  }
};

/**
 * User Authorization Middleware
 * Restricts access to regular users
 */
const authorizeUser = (req, res, next) => {
  if (req.user && req.user.role === "user") {
    console.log(
      `${colors.green}✅ User authorization granted: ${req.user.email}${colors.reset}`
    );
    next();
  } else {
    console.log(
      `${colors.red}❌ User authorization failed: ${req.user?.email}${colors.reset}`
    );
    return res.status(403).json({
      success: false,
      message: "Access denied. User privileges required.",
    });
  }
};

module.exports = {
  authenticate,
  authorizeAdmin,
  authorizeUser,
};
