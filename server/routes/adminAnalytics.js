// routes/adminAnalytics.js
const express = require("express");
const { authenticate, authorizeAdmin } = require("../middleware/auth");
const {
  getAdminAnalytics,
  getHistoricalAnalytics,
  getDashboardStats,
  getUserActivityHeatmap,
} = require("../controllers/adminAnalyticsController");

const router = express.Router();

const colors = {
  reset: "\x1b[0m",
  blue: "\x1b[34m",
};

// All routes require admin authentication
router.use(authenticate, authorizeAdmin);

// Get comprehensive analytics
router.get("/analytics", getAdminAnalytics);

// Get historical analytics
router.get("/analytics/historical", getHistoricalAnalytics);

// Get real-time dashboard stats
router.get("/dashboard", getDashboardStats);

// Get user activity heatmap
router.get("/activity/heatmap", getUserActivityHeatmap);

module.exports = router;