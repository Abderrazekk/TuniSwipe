// models/Analytics.js
const mongoose = require("mongoose");

const analyticsSchema = new mongoose.Schema(
  {
    date: {
      type: Date,
      default: Date.now,
      index: true,
    },
    totalUsers: {
      type: Number,
      default: 0,
    },
    activeUsers24h: {
      type: Number,
      default: 0,
    },
    activeUsers7d: {
      type: Number,
      default: 0,
    },
    dailySwipes: {
      type: Number,
      default: 0,
    },
    dailyMatches: {
      type: Number,
      default: 0,
    },
    newUsersToday: {
      type: Number,
      default: 0,
    },
    totalMatches: {
      type: Number,
      default: 0,
    },
    locationStats: [
      {
        city: String,
        country: String,
        userCount: Number,
        coordinates: {
          type: {
            type: String,
            enum: ["Point"],
          },
          coordinates: [Number],
        },
      },
    ],
    genderDistribution: {
      male: { type: Number, default: 0 },
      female: { type: Number, default: 0 },
      other: { type: Number, default: 0 },
    },
    ageDistribution: {
      teens: { type: Number, default: 0 }, // 13-19
      twenties: { type: Number, default: 0 }, // 20-29
      thirties: { type: Number, default: 0 }, // 30-39
      forties: { type: Number, default: 0 }, // 40-49
      fiftiesPlus: { type: Number, default: 0 }, // 50+
    },
  },
  {
    timestamps: true,
  }
);

// Create index for date queries
analyticsSchema.index({ date: 1 });

module.exports = mongoose.model("Analytics", analyticsSchema);