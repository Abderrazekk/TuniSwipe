// controllers/adminAnalyticsController.js
const User = require("../models/User");
const Swipe = require("../models/Swipe");
const Analytics = require("../models/Analytics");
const mongoose = require("mongoose");

const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
  cyan: "\x1b[36m",
  magenta: "\x1b[35m",
};

/**
 * Get comprehensive admin analytics
 */
const getAdminAnalytics = async (req, res) => {
  try {
    console.log(`${colors.cyan}📊 Admin analytics requested${colors.reset}`);

    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const lastWeek = new Date(today);
    lastWeek.setDate(lastWeek.getDate() - 7);

    // 1. Total Users
    const totalUsers = await User.countDocuments();

    // 2. Active Users (last 24 hours)
    const activeUsers24h = await User.countDocuments({
      updatedAt: { $gte: yesterday },
    });

    // 3. Active Users (last 7 days)
    const activeUsers7d = await User.countDocuments({
      updatedAt: { $gte: lastWeek },
    });

    // 4. New Users Today
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const newUsersToday = await User.countDocuments({
      createdAt: { $gte: startOfToday },
    });

    // 5. Daily Swipes
    const dailySwipes = await Swipe.countDocuments({
      createdAt: { $gte: startOfToday },
    });

    // 6. Calculate matches (mutual likes)
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);

    const dailyMatches = await Swipe.aggregate([
      {
        $match: {
          action: "like",
          createdAt: { $gte: todayStart },
        },
      },
      {
        $lookup: {
          from: "swipes",
          let: { swiper: "$swiper", swiped: "$swiped" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$swiper", "$$swiped"] },
                    { $eq: ["$swiped", "$$swiper"] },
                    { $eq: ["$action", "like"] },
                    { $gte: ["$createdAt", todayStart] },
                  ],
                },
              },
            },
          ],
          as: "mutual",
        },
      },
      {
        $match: {
          mutual: { $ne: [] },
        },
      },
      {
        $group: {
          _id: {
            $cond: [
              { $lt: ["$swiper", "$swiped"] },
              { swiper: "$swiper", swiped: "$swiped" },
              { swiper: "$swiped", swiped: "$swiper" },
            ],
          },
          count: { $sum: 1 },
        },
      },
      {
        $match: {
          count: 2,
        },
      },
    ]);

    const dailyMatchesCount = dailyMatches.length;

    // 7. Total Matches
    const totalMatchesAgg = await Swipe.aggregate([
      {
        $match: {
          action: "like",
        },
      },
      {
        $lookup: {
          from: "swipes",
          let: { swiper: "$swiper", swiped: "$swiped" },
          pipeline: [
            {
              $match: {
                $expr: {
                  $and: [
                    { $eq: ["$swiper", "$$swiped"] },
                    { $eq: ["$swiped", "$$swiper"] },
                    { $eq: ["$action", "like"] },
                  ],
                },
              },
            },
          ],
          as: "mutual",
        },
      },
      {
        $match: {
          mutual: { $ne: [] },
        },
      },
      {
        $group: {
          _id: {
            $cond: [
              { $lt: ["$swiper", "$swiped"] },
              { swiper: "$swiper", swiped: "$swiped" },
              { swiper: "$swiped", swiped: "$swiper" },
            ],
          },
          count: { $sum: 1 },
        },
      },
      {
        $match: {
          count: 2,
        },
      },
    ]);

    const totalMatches = totalMatchesAgg.length;

    // 8. Gender Distribution
    const genderDistribution = await User.aggregate([
      {
        $group: {
          _id: "$gender",
          count: { $sum: 1 },
        },
      },
    ]);

    const genderStats = {
      male: 0,
      female: 0,
      other: 0,
    };

    genderDistribution.forEach((item) => {
      if (item._id === "male") genderStats.male = item.count;
      else if (item._id === "female") genderStats.female = item.count;
      else genderStats.other = item.count;
    });

    // 9. Age Distribution
    const ageDistribution = await User.aggregate([
      {
        $bucket: {
          groupBy: "$age",
          boundaries: [13, 20, 30, 40, 50, 121],
          default: "other",
          output: {
            count: { $sum: 1 },
          },
        },
      },
    ]);

    const ageStats = {
      teens: 0,
      twenties: 0,
      thirties: 0,
      forties: 0,
      fiftiesPlus: 0,
    };

    ageDistribution.forEach((item, index) => {
      switch (index) {
        case 0:
          ageStats.teens = item.count;
          break;
        case 1:
          ageStats.twenties = item.count;
          break;
        case 2:
          ageStats.thirties = item.count;
          break;
        case 3:
          ageStats.forties = item.count;
          break;
        case 4:
          ageStats.fiftiesPlus = item.count;
          break;
      }
    });

    // 10. Geolocation Analytics (by city from livingIn field)
    const locationStats = await User.aggregate([
      {
        $match: {
          livingIn: { $exists: true, $ne: "" },
        },
      },
      {
        $group: {
          _id: "$livingIn",
          userCount: { $sum: 1 },
          firstUser: { $first: "$$ROOT" },
        },
      },
      {
        $sort: { userCount: -1 },
      },
      {
        $limit: 20,
      },
      {
        $project: {
          city: "$_id",
          userCount: 1,
          coordinates: "$firstUser.location.coordinates",
          _id: 0,
        },
      },
    ]);

    // Format location data
    const formattedLocationStats = locationStats.map((loc) => ({
      city: loc.city,
      userCount: loc.userCount,
      coordinates: loc.coordinates || null,
    }));

    // 11. Top Cities
    const topCities = formattedLocationStats.slice(0, 10);

    // 12. Save analytics for historical data
    await Analytics.create({
      date: today,
      totalUsers,
      activeUsers24h,
      activeUsers7d,
      dailySwipes,
      dailyMatches: dailyMatchesCount,
      newUsersToday,
      totalMatches,
      locationStats: formattedLocationStats,
      genderDistribution: genderStats,
      ageDistribution: ageStats,
    });

    console.log(`${colors.green}✅ Admin analytics generated${colors.reset}`);

    res.json({
      success: true,
      data: {
        summary: {
          totalUsers,
          activeUsers24h,
          activeUsers7d,
          dailySwipes,
          dailyMatches: dailyMatchesCount,
          newUsersToday,
          totalMatches,
          matchRate: totalUsers > 0 ? ((totalMatches / totalUsers) * 100).toFixed(2) + "%" : "0%",
        },
        genderDistribution: genderStats,
        ageDistribution: ageStats,
        locationAnalytics: {
          totalCities: formattedLocationStats.length,
          topCities,
          detailedStats: formattedLocationStats,
        },
        timestamp: new Date().toISOString(),
      },
      message: "Admin analytics retrieved successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Analytics error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error generating analytics",
      error: process.env.NODE_ENV === "development" ? error.message : undefined,
    });
  }
};

/**
 * Get historical analytics data
 */
const getHistoricalAnalytics = async (req, res) => {
  try {
    const { days = 30 } = req.query;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));

    console.log(`${colors.cyan}📈 Historical analytics for ${days} days${colors.reset}`);

    const historicalData = await Analytics.find({
      date: { $gte: startDate },
    })
      .sort({ date: 1 })
      .select("date totalUsers activeUsers24h dailySwipes dailyMatches newUsersToday")
      .lean();

    // Calculate growth metrics
    let userGrowth = 0;
    let swipeGrowth = 0;
    let matchGrowth = 0;

    if (historicalData.length >= 2) {
      const first = historicalData[0];
      const last = historicalData[historicalData.length - 1];

      userGrowth = last.totalUsers - first.totalUsers;
      swipeGrowth = last.dailySwipes - first.dailySwipes;
      matchGrowth = last.dailyMatches - first.dailyMatches;
    }

    // Format for charts
    const chartData = {
      labels: historicalData.map((d) => new Date(d.date).toLocaleDateString()),
      datasets: [
        {
          label: "Total Users",
          data: historicalData.map((d) => d.totalUsers),
          borderColor: "rgb(75, 192, 192)",
        },
        {
          label: "Daily Swipes",
          data: historicalData.map((d) => d.dailySwipes),
          borderColor: "rgb(255, 99, 132)",
        },
        {
          label: "Daily Matches",
          data: historicalData.map((d) => d.dailyMatches),
          borderColor: "rgb(54, 162, 235)",
        },
        {
          label: "New Users",
          data: historicalData.map((d) => d.newUsersToday),
          borderColor: "rgb(153, 102, 255)",
        },
      ],
    };

    res.json({
      success: true,
      data: {
        historicalData,
        chartData,
        growthMetrics: {
          userGrowth,
          swipeGrowth,
          matchGrowth,
          period: `${days} days`,
        },
        period: {
          start: startDate.toISOString(),
          end: new Date().toISOString(),
          days: parseInt(days),
        },
      },
      message: "Historical analytics retrieved",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Historical analytics error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error retrieving historical analytics",
    });
  }
};

/**
 * Get real-time dashboard stats
 */
const getDashboardStats = async (req, res) => {
  try {
    console.log(`${colors.cyan}📱 Dashboard stats requested${colors.reset}`);

    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const lastHour = new Date(today);
    lastHour.setHours(lastHour.getHours() - 1);

    // Parallel execution for better performance
    const [
      totalUsers,
      onlineUsers,
      newUsersToday,
      swipesLastHour,
      recentMatches,
      topCities,
    ] = await Promise.all([
      User.countDocuments(),
      User.countDocuments({ updatedAt: { $gte: lastHour } }),
      User.countDocuments({ createdAt: { $gte: new Date().setHours(0, 0, 0, 0) } }),
      Swipe.countDocuments({ createdAt: { $gte: lastHour } }),
      Swipe.aggregate([
        {
          $match: {
            action: "like",
            createdAt: { $gte: yesterday },
          },
        },
        {
          $lookup: {
            from: "swipes",
            let: { swiper: "$swiper", swiped: "$swiped" },
            pipeline: [
              {
                $match: {
                  $expr: {
                    $and: [
                      { $eq: ["$swiper", "$$swiped"] },
                      { $eq: ["$swiped", "$$swiper"] },
                      { $eq: ["$action", "like"] },
                      { $gte: ["$createdAt", yesterday] },
                    ],
                  },
                },
              },
            ],
            as: "mutual",
          },
        },
        {
          $match: {
            mutual: { $ne: [] },
          },
        },
        {
          $group: {
            _id: {
              $cond: [
                { $lt: ["$swiper", "$swiped"] },
                { swiper: "$swiper", swiped: "$swiped" },
                { swiper: "$swiped", swiped: "$swiper" },
              ],
            },
            matchedAt: { $max: "$createdAt" },
          },
        },
        {
        $sort: { matchedAt: -1 },
        },
        {
          $limit: 10,
        },
        {
          $lookup: {
            from: "users",
            localField: "_id.swiper",
            foreignField: "_id",
            as: "user1",
          },
        },
        {
          $lookup: {
            from: "users",
            localField: "_id.swiped",
            foreignField: "_id",
            as: "user2",
          },
        },
        {
          $project: {
            user1: { $arrayElemAt: ["$user1", 0] },
            user2: { $arrayElemAt: ["$user2", 0] },
            matchedAt: 1,
          },
        },
      ]),
      User.aggregate([
        {
          $match: {
            livingIn: { $exists: true, $ne: "" },
          },
        },
        {
          $group: {
            _id: "$livingIn",
            count: { $sum: 1 },
          },
        },
        {
          $sort: { count: -1 },
        },
        {
          $limit: 5,
        },
        {
          $project: {
            city: "$_id",
            userCount: "$count",
            _id: 0,
          },
        },
      ]),
    ]);

    const dashboardData = {
      totalUsers,
      onlineUsers,
      newUsersToday,
      swipesLastHour,
      matchRate: totalUsers > 0 ? ((recentMatches.length / totalUsers) * 100).toFixed(2) + "%" : "0%",
      recentMatches: recentMatches.map(match => ({
        user1: { name: match.user1?.name, age: match.user1?.age },
        user2: { name: match.user2?.name, age: match.user2?.age },
        matchedAt: match.matchedAt,
      })),
      topCities,
      lastUpdated: new Date().toISOString(),
    };

    console.log(`${colors.green}✅ Dashboard stats generated${colors.reset}`);

    res.json({
      success: true,
      data: dashboardData,
      message: "Dashboard stats retrieved",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Dashboard stats error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error retrieving dashboard stats",
    });
  }
};

/**
 * Get user activity heatmap
 */
const getUserActivityHeatmap = async (req, res) => {
  try {
    const { days = 7 } = req.query;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - parseInt(days));

    // Get user activity by hour of day
    const activityByHour = await Swipe.aggregate([
      {
        $match: {
          createdAt: { $gte: startDate },
        },
      },
      {
        $group: {
          _id: {
            hour: { $hour: "$createdAt" },
            dayOfWeek: { $dayOfWeek: "$createdAt" },
          },
          count: { $sum: 1 },
        },
      },
      {
        $sort: { "_id.dayOfWeek": 1, "_id.hour": 1 },
      },
    ]);

    // Format for heatmap
    const heatmapData = [];
    for (let day = 1; day <= 7; day++) {
      for (let hour = 0; hour < 24; hour++) {
        const activity = activityByHour.find(
          (a) => a._id.dayOfWeek === day && a._id.hour === hour
        );
        heatmapData.push({
          day,
          hour,
          count: activity ? activity.count : 0,
        });
      }
    }

    res.json({
      success: true,
      data: {
        heatmapData,
        period: `${days} days`,
        maxActivity: Math.max(...heatmapData.map((d) => d.count)),
        totalActivity: heatmapData.reduce((sum, d) => sum + d.count, 0),
      },
      message: "User activity heatmap generated",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Heatmap error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error generating activity heatmap",
    });
  }
};

module.exports = {
  getAdminAnalytics,
  getHistoricalAnalytics,
  getDashboardStats,
  getUserActivityHeatmap,
};