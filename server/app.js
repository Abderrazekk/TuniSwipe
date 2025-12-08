const express = require("express");
const cors = require("cors");
const authRoutes = require("./routes/auth");
const adminAnalyticsRoutes = require("./routes/adminAnalytics");
const chatRoutes = require("./routes/chat");
const matchesRoutes = require("./routes/matches");
const path = require("path");

// Create Express app
const app = express();

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  red: "\x1b[31m",
};

// Serve static files from uploads directory
app.use("/uploads", express.static(path.join(__dirname, "uploads")));

// Custom request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(
    `${colors.blue}📨 [${timestamp}] ${req.method} ${req.originalUrl}${colors.reset}`
  );

  // Don't log file upload bodies
  if (!req.originalUrl.includes("/user/signup") || !req.file) {
    if (req.body && Object.keys(req.body).length > 0) {
      const logBody = { ...req.body };
      if (logBody.password) logBody.password = "***";
      if (logBody.confirmPassword) logBody.confirmPassword = "***";
      console.log(`${colors.magenta}📦 Request Body:${colors.reset}`, logBody);
    }
  }

  // Capture response to log when it's sent
  const originalSend = res.send;
  res.send = function (data) {
    const statusColor = res.statusCode >= 400 ? colors.red : colors.green;
    console.log(
      `${statusColor}✅ [${timestamp}] ${req.method} ${req.originalUrl} - Status: ${res.statusCode}${colors.reset}`
    );

    if (res.statusCode >= 400) {
      console.log(
        `${colors.red}❌ Response:${colors.reset}`,
        typeof data === "string" ? data : JSON.stringify(data)
      );
    } else {
      const responsePreview =
        typeof data === "string"
          ? data.substring(0, 100) + (data.length > 100 ? "..." : "")
          : "Object sent";
      console.log(
        `${colors.green}📤 Response:${colors.reset}`,
        responsePreview
      );
    }

    originalSend.call(this, data);
  };

  next();
});

// CORS configuration
app.use(
  cors({
    origin: [
      "http://localhost:3000",
      "http://10.0.2.2:3000",
      "http://127.0.0.1:3000",
    ],
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// Middleware
app.use(express.json());

// Test route
app.get("/api/test", (req, res) => {
  console.log(`${colors.cyan}🧪 Test endpoint called${colors.reset}`);
  res.json({
    success: true,
    message: "Backend API is working!",
    timestamp: new Date().toISOString(),
  });
});

// Health check route
app.get("/api/health", (req, res) => {
  console.log(`${colors.cyan}❤️ Health check requested${colors.reset}`);
  const mongoose = require("mongoose");
  res.json({
    success: true,
    status: "OK",
    database:
      mongoose.connection.readyState === 1 ? "Connected" : "Disconnected",
    timestamp: new Date().toISOString(),
  });
});

// API routes
app.use("/api/auth", authRoutes);
app.use("/api/admin", adminAnalyticsRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/matches", matchesRoutes);

// 404 handler
app.use("*", (req, res) => {
  console.log(
    `${colors.red}❌ [404] Route not found: ${req.originalUrl}${colors.reset}`
  );
  res.status(404).json({
    success: false,
    message: "Route not found",
    path: req.originalUrl,
  });
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error(`${colors.red}💥 Unhandled error:${colors.reset}`, error);
  res.status(500).json({
    success: false,
    message: "Internal server error",
    error:
      process.env.NODE_ENV === "development"
        ? error.message
        : "Something went wrong",
  });
});

module.exports = app;