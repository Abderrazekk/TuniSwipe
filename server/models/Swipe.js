// models/Swipe.js
const mongoose = require("mongoose");

const swipeSchema = new mongoose.Schema(
  {
    swiper: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    swiped: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    action: {
      type: String,
      enum: ["like", "dislike"],
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

// Prevent duplicate swipes
swipeSchema.index({ swiper: 1, swiped: 1 }, { unique: true });

module.exports = mongoose.model("Swipe", swipeSchema);
