// routes/auth.js
const express = require("express");
const { authenticate, authorizeAdmin } = require("../middleware/auth");
const { handleUpload, handleMediaUpload } = require("../middleware/upload");
const {
  userSignup,
  userSignin,
  getUserProfile,
  getCompleteUserProfile,
  getAdminStats,
  checkAdminExists,
  updateUserProfile,
  addUserMedia,
  removeUserMedia,
  getUserMedia,
} = require("../controllers/authController");
const {
  updateUserLocation,
  updateLocationRadius,
  getLocationSettings,
  toggleLocationEnabled,
  getUsersWithinRadius,
} = require("../controllers/locationController");

const router = express.Router();

// Public routes
router.post("/user/signup", handleUpload, userSignup);
router.post("/signin", userSignin);
router.get("/check-admin", checkAdminExists);

// Protected routes
router.get("/profile", authenticate, getUserProfile);
router.get("/complete-profile", authenticate, getCompleteUserProfile);
router.put("/profile", authenticate, handleUpload, updateUserProfile);

// Media routes
router.get("/media", authenticate, getUserMedia);
router.post("/media", authenticate, handleMediaUpload, addUserMedia);
router.delete("/media/:filename", authenticate, removeUserMedia);

// Location routes
router.put("/location", authenticate, updateUserLocation);
router.put("/location/radius", authenticate, updateLocationRadius);
router.put("/location/toggle", authenticate, toggleLocationEnabled);
router.get("/location/settings", authenticate, getLocationSettings);
router.get("/location/nearby", authenticate, getUsersWithinRadius);

// Admin routes
router.get("/admin/stats", authenticate, authorizeAdmin, getAdminStats);

// Mount match routes
const matchRoutes = require("./matches");
router.use("/matches", matchRoutes);

// Mount chat routes
const chatRoutes = require("./chat");
router.use("/chat", chatRoutes);

// Add this to routes/auth.js or routes/chat.js
router.get("/debug/matches", authenticate, async (req, res) => {
  try {
    const currentUserId = req.user._id;

    const myLikes = await Swipe.find({
      swiper: currentUserId,
      action: "like",
    }).populate("swiped", "name");

    const likedMe = await Swipe.find({
      swiped: currentUserId,
      action: "like",
    }).populate("swiper", "name");

    // Find mutual matches
    const mutualMatches = [];
    myLikes.forEach((myLike) => {
      const mutual = likedMe.find(
        (like) => like.swiper._id.toString() === myLike.swiped._id.toString()
      );
      if (mutual) {
        mutualMatches.push({
          user: myLike.swiped,
          matchedAt: mutual.createdAt,
        });
      }
    });

    res.json({
      success: true,
      data: {
        myLikes: myLikes.map((like) => ({
          userId: like.swiped._id,
          userName: like.swiped.name,
          likedAt: like.createdAt,
        })),
        likedMe: likedMe.map((like) => ({
          userId: like.swiper._id,
          userName: like.swiper.name,
          likedAt: like.createdAt,
        })),
        mutualMatches: mutualMatches.map((match) => ({
          userId: match.user._id,
          userName: match.user.name,
          matchedAt: match.matchedAt,
        })),
        currentUserId: currentUserId,
      },
    });
  } catch (error) {
    console.error("Debug matches error:", error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
