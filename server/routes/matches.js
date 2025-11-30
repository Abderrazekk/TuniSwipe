// routes/matches.js - Complete rewrite
const express = require("express");
const { authenticate } = require("../middleware/auth");
const User = require("../models/User");
const Swipe = require("../models/Swipe");

const router = express.Router();

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
};

/**
 * Get potential matches for the current user
 * Excludes current user and already swiped users
 */
const getPotentialMatches = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const currentUser = await User.findById(currentUserId);

    console.log(
      `${colors.blue}🎯 Getting potential matches for: ${currentUser.email} (${currentUser.gender})${colors.reset}`
    );

    // Get all users that current user has already swiped
    const userSwipes = await Swipe.find({ swiper: currentUserId });
    const swipedUserIds = userSwipes.map((swipe) => swipe.swiped.toString());

    // Add current user to excluded list
    swipedUserIds.push(currentUserId.toString());

    console.log(
      `${colors.yellow}📋 Excluding ${swipedUserIds.length} users (already swiped + self)${colors.reset}`
    );

    // Determine target gender based on current user's gender
    let targetGender;
    if (currentUser.gender === "male") {
      targetGender = "female";
    } else if (currentUser.gender === "female") {
      targetGender = "male";
    } else {
      targetGender = { $in: ["male", "female"] };
    }

    console.log(
      `${colors.blue}🎯 Looking for ${targetGender} profiles${colors.reset}`
    );

    // Build base query
    const query = {
      _id: { $nin: swipedUserIds },
    };

    // Add gender filter
    if (targetGender) {
      if (typeof targetGender === "string") {
        query.gender = targetGender;
      } else {
        query.gender = targetGender;
      }
    }

    // ADD LOCATION FILTERING
    if (currentUser.location && currentUser.locationEnabled) {
      const maxDistance = currentUser.maxDistance || 50; // Default to 50KM if not set

      query.location = {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: currentUser.location.coordinates,
          },
          $maxDistance: maxDistance * 1000, // Convert KM to meters
        },
      };
      query.locationEnabled = true;

      console.log(
        `${colors.blue}📍 Filtering by location: ${maxDistance} KM radius${colors.reset}`
      );
    } else {
      console.log(
        `${colors.yellow}⚠️ Location filtering disabled or no location set${colors.reset}`
      );
    }

    // Get users who are not swiped, not current user, match target gender, and within distance
    const potentialMatches = await User.find(query)
      .select("-password")
      .limit(20);

    console.log(
      `${colors.green}✅ Found ${potentialMatches.length} potential matches${colors.reset}`
    );

    // Calculate distance for each match and add to response
    const matchesWithLocation = await Promise.all(
      potentialMatches.map(async (user) => {
        const userObj = user.toObject();

        // Use first media item as main photo if available
        userObj.mainPhoto =
          user.media && user.media.length > 0
            ? user.media[0].filename
            : user.photo;

        // Calculate distance if both users have locations
        if (currentUser.location && user.location) {
          userObj.distance = calculateDistance(
            currentUser.location.coordinates[1], // lat
            currentUser.location.coordinates[0], // lng
            user.location.coordinates[1], // lat
            user.location.coordinates[0] // lng
          );
        }

        return userObj;
      })
    );

    // Sort by distance (closest first)
    matchesWithLocation.sort((a, b) => {
      if (a.distance && b.distance) {
        return a.distance - b.distance;
      }
      return 0;
    });

    res.json({
      success: true,
      data: matchesWithLocation,
      message: "Potential matches retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Get matches error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving potential matches",
    });
  }
};

/**
 * Calculate distance between two coordinates using Haversine formula
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371; // Earth's radius in KM
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  return Math.round(distance * 10) / 10; // Round to 1 decimal place
};

/**
 * Handle swipe action (like/dislike) with mutual matching
 */
const handleSwipe = async (req, res) => {
  try {
    const { targetUserId, action } = req.body; // action: 'like' or 'dislike'
    const currentUserId = req.user._id;

    console.log(
      `${colors.blue}💕 Swipe action: ${action} by ${currentUserId} on ${targetUserId}${colors.reset}`
    );

    // Check if target user exists
    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Check if already swiped
    const existingSwipe = await Swipe.findOne({
      swiper: currentUserId,
      swiped: targetUserId,
    });

    if (existingSwipe) {
      return res.status(400).json({
        success: false,
        message: "Already swiped on this user",
      });
    }

    // Save the swipe
    const swipe = new Swipe({
      swiper: currentUserId,
      swiped: targetUserId,
      action: action,
    });

    await swipe.save();

    let isMatch = false;
    let matchMessage = null;

    // Check for mutual like only if current action is 'like'
    if (action === "like") {
      // Check if the target user has also liked the current user
      const mutualSwipe = await Swipe.findOne({
        swiper: targetUserId,
        swiped: currentUserId,
        action: "like",
      });

      if (mutualSwipe) {
        isMatch = true;
        matchMessage = `It's a match! You and ${targetUser.name} have liked each other! 🎉`;
        console.log(
          `${colors.green}💑 MATCH FOUND: ${currentUserId} and ${targetUserId}${colors.reset}`
        );
      }
    }

    console.log(
      `${colors.green}✅ Swipe recorded: ${action} by ${currentUserId} on ${targetUserId}${colors.reset}`
    );
    console.log(
      `${colors.blue}🤝 Match status: ${isMatch ? "MATCH!" : "No match"}${
        colors.reset
      }`
    );

    res.json({
      success: true,
      data: {
        action,
        isMatch,
        matchMessage,
        targetUser: {
          id: targetUser._id,
          name: targetUser.name,
          photo: targetUser.photo,
        },
      },
      message: action === "like" ? "Profile liked!" : "Profile passed",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Swipe error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error processing swipe",
    });
  }
};

/**
 * Get user's matches (mutual likes)
 */
const getUserMatches = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    console.log(
      `${colors.blue}💑 Getting matches for user: ${currentUserId}${colors.reset}`
    );

    // Get all likes by current user
    const userLikes = await Swipe.find({
      swiper: currentUserId,
      action: "like",
    }).populate("swiped", "name email photo age gender bio");

    // Get all users who liked current user
    const likedByUsers = await Swipe.find({
      swiped: currentUserId,
      action: "like",
    }).populate("swiper", "name email photo age gender bio");

    // Find mutual likes (matches)
    const matches = [];

    for (const like of userLikes) {
      const mutualLike = likedByUsers.find(
        (l) => l.swiper._id.toString() === like.swiped._id.toString()
      );

      if (mutualLike) {
        matches.push({
          user: like.swiped,
          matchedAt: mutualLike.createdAt,
        });
      }
    }

    console.log(
      `${colors.green}✅ Found ${matches.length} matches for user ${currentUserId}${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        matches,
        totalMatches: matches.length,
      },
      message: "Matches retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Get matches error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving matches",
    });
  }
};

/**
 * Get user profile by ID for card display
 */
const getUserProfileForCard = async (req, res) => {
  try {
    const { userId } = req.params;

    console.log(
      `${colors.blue}👤 Getting profile for card: ${userId}${colors.reset}`
    );

    const user = await User.findById(userId).select("-password").lean();

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Get first media item as main photo if available
    const userWithMedia = await User.findById(userId).select("media");
    user.mainPhoto =
      userWithMedia.media.length > 0
        ? userWithMedia.media[0].filename
        : user.photo;

    console.log(
      `${colors.green}✅ Profile retrieved for card: ${user.name}${colors.reset}`
    );

    res.json({
      success: true,
      data: user,
      message: "User profile retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Get profile error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving user profile",
    });
  }
};

// routes/matches.js - Add these new functions

/**
 * Get users who liked the current user (only non-matches)
 */
const getUsersWhoLikedMe = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const currentUser = await User.findById(currentUserId);

    console.log(
      `${colors.blue}💖 Getting users who liked: ${currentUser.email}${colors.reset}`
    );

    // Find all swipes where current user was swiped and action was 'like'
    const likes = await Swipe.find({
      swiped: currentUserId,
      action: "like",
    }).populate(
      "swiper",
      "name email photo age gender bio interests school jobTitle livingIn"
    );

    console.log(
      `${colors.yellow}📋 Found ${likes.length} total likes${colors.reset}`
    );

    // Filter out mutual matches (only show users I haven't liked back yet)
    const nonMutualLikes = [];

    for (let like of likes) {
      // Check if current user has also liked this user (mutual like)
      const mutualLike = await Swipe.findOne({
        swiper: currentUserId,
        swiped: like.swiper._id,
        action: "like",
      });

      // Only include if NOT a mutual like (user hasn't liked back yet)
      if (!mutualLike) {
        const swiper = like.swiper.toObject();
        const swiperWithMedia = await User.findById(swiper._id).select("media");

        swiper.mainPhoto =
          swiperWithMedia.media && swiperWithMedia.media.length > 0
            ? swiperWithMedia.media[0].filename
            : swiper.photo;

        nonMutualLikes.push({
          user: swiper,
          likedAt: like.createdAt,
          swipeId: like._id, // Include swipe ID for reference
        });
      }
    }

    console.log(
      `${colors.green}✅ Returning ${nonMutualLikes.length} non-mutual likes${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        likes: nonMutualLikes,
      },
      message: "Likes retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Get likes error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving likes",
    });
  }
};

/**
 * Get mutual matches (both users liked each other)
 */
const getMutualMatches = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    console.log(
      `${colors.blue}💑 Getting mutual matches for: ${currentUserId}${colors.reset}`
    );

    // Get all likes by current user
    const userLikes = await Swipe.find({
      swiper: currentUserId,
      action: "like",
    }).populate(
      "swiped",
      "name email photo age gender bio interests school jobTitle livingIn"
    );

    // Get mutual matches
    const matches = [];

    for (const like of userLikes) {
      // Check if the liked user has also liked the current user
      const mutualLike = await Swipe.findOne({
        swiper: like.swiped._id,
        swiped: currentUserId,
        action: "like",
      });

      if (mutualLike) {
        const matchedUser = like.swiped.toObject();
        const matchedUserWithMedia = await User.findById(
          matchedUser._id
        ).select("media");

        matchedUser.mainPhoto =
          matchedUserWithMedia.media && matchedUserWithMedia.media.length > 0
            ? matchedUserWithMedia.media[0].filename
            : matchedUser.photo;

        matches.push({
          user: matchedUser,
          matchedAt: mutualLike.createdAt,
          matchId: mutualLike._id,
        });
      }
    }

    console.log(
      `${colors.green}✅ Found ${matches.length} mutual matches${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        matches,
      },
      message: "Mutual matches retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Get matches error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving matches",
    });
  }
};

router.get("/potential", authenticate, getPotentialMatches);
router.post("/swipe", authenticate, handleSwipe);
router.get("/matches", authenticate, getUserMatches);
router.get("/user/:userId", authenticate, getUserProfileForCard);

router.get("/likes", authenticate, getUsersWhoLikedMe);
router.get("/matches", authenticate, getMutualMatches);

module.exports = router;
