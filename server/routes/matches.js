// routes/matches.js
const express = require("express");
const { authenticate } = require("../middleware/auth");
const User = require("../models/User");
const Swipe = require("../models/Swipe");

const router = express.Router();

const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
};

/**
 * Calculate distance between coordinates
 */
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371;
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
  return Math.round(distance * 10) / 10;
};

/**
 * Get potential matches with location filtering
 */
const getPotentialMatches = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const currentUser = await User.findById(currentUserId);

    console.log(`${colors.blue}🎯 Potential matches for: ${currentUser.email}${colors.reset}`);
    console.log(`${colors.blue}   Location enabled: ${currentUser.locationEnabled}${colors.reset}`);
    console.log(`${colors.blue}   Location radius: ${currentUser.locationRadius} KM${colors.reset}`);

    const userSwipes = await Swipe.find({ swiper: currentUserId });
    const swipedUserIds = userSwipes.map((swipe) => swipe.swiped.toString());
    swipedUserIds.push(currentUserId.toString());

    let targetGender;
    if (currentUser.gender === "male") {
      targetGender = "female";
    } else if (currentUser.gender === "female") {
      targetGender = "male";
    } else {
      targetGender = { $in: ["male", "female"] };
    }

    const query = {
      _id: { $nin: swipedUserIds },
    };

    if (targetGender) {
      query.gender = targetGender;
    }

    // Location filtering
    if (currentUser.location && currentUser.locationEnabled && currentUser.locationRadius > 0) {
      const maxDistance = currentUser.locationRadius;
      
      query.location = {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: currentUser.location.coordinates,
          },
          $maxDistance: maxDistance * 1000,
        },
      };
      query.locationEnabled = true;

      console.log(`${colors.blue}📍 Filtering by location: ${maxDistance} KM${colors.reset}`);
    } else if (currentUser.locationRadius === 0) {
      console.log(`${colors.yellow}📍 Radius is 0 - showing all users${colors.reset}`);
    } else {
      console.log(`${colors.yellow}⚠️ Location filtering disabled${colors.reset}`);
    }

    const potentialMatches = await User.find(query)
      .select("name email photo age gender bio interests school jobTitle livingIn height topArtist company location")
      .limit(30);

    const matchesWithDetails = await Promise.all(
      potentialMatches.map(async (user) => {
        const userObj = user.toObject();
        
        if (currentUser.location && user.location) {
          const [lon1, lat1] = currentUser.location.coordinates;
          const [lon2, lat2] = user.location.coordinates;
          userObj.distance = calculateDistance(lat1, lon1, lat2, lon2);
        }
        
        const userWithMedia = await User.findById(user._id).select("media");
        userObj.mainPhoto = userWithMedia.media && userWithMedia.media.length > 0
          ? userWithMedia.media[0].filename
          : user.photo;

        return userObj;
      })
    );

    if (currentUser.location && currentUser.locationEnabled && currentUser.locationRadius > 0) {
      matchesWithDetails.sort((a, b) => {
        if (a.distance && b.distance) {
          return a.distance - b.distance;
        }
        return 0;
      });
    }

    console.log(`${colors.green}✅ Found ${matchesWithDetails.length} matches${colors.reset}`);

    res.json({
      success: true,
      data: matchesWithDetails,
      currentUserRadius: currentUser.locationRadius,
      locationFiltering: currentUser.locationEnabled && currentUser.locationRadius > 0,
      message: "Potential matches retrieved successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Get matches error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error retrieving potential matches",
    });
  }
};

/**
 * Handle swipe action
 */
const handleSwipe = async (req, res) => {
  try {
    const { targetUserId, action } = req.body;
    const currentUserId = req.user._id;

    console.log(`${colors.blue}💕 Swipe: ${action} by ${currentUserId} on ${targetUserId}${colors.reset}`);

    const targetUser = await User.findById(targetUserId);
    if (!targetUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

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

    const swipe = new Swipe({
      swiper: currentUserId,
      swiped: targetUserId,
      action: action,
    });

    await swipe.save();

    let isMatch = false;
    let matchMessage = null;

    if (action === "like") {
      const mutualSwipe = await Swipe.findOne({
        swiper: targetUserId,
        swiped: currentUserId,
        action: "like",
      });

      if (mutualSwipe) {
        isMatch = true;
        matchMessage = `It's a match! You and ${targetUser.name} have liked each other! 🎉`;
        console.log(`${colors.green}💑 MATCH FOUND${colors.reset}`);
      }
    }

    console.log(`${colors.green}✅ Swipe recorded${colors.reset}`);

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
 * Get mutual matches
 */
const getMutualMatches = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    console.log(`${colors.blue}💑 Getting matches for: ${currentUserId}${colors.reset}`);

    const userLikes = await Swipe.find({
      swiper: currentUserId,
      action: "like",
    }).populate("swiped", "name email photo age gender bio interests school jobTitle livingIn");

    const likedByUsers = await Swipe.find({
      swiped: currentUserId,
      action: "like",
    }).populate("swiper", "name email photo age gender bio interests school jobTitle livingIn");

    const matches = [];

    for (const like of userLikes) {
      const mutualLike = likedByUsers.find(
        (l) => l.swiper._id.toString() === like.swiped._id.toString()
      );

      if (mutualLike) {
        const matchedUser = like.swiped.toObject();
        const matchedUserWithMedia = await User.findById(matchedUser._id).select("media");

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

    console.log(`${colors.green}✅ Found ${matches.length} mutual matches${colors.reset}`);

    res.json({
      success: true,
      data: {
        matches,
      },
      message: "Mutual matches retrieved successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Get matches error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error retrieving matches",
    });
  }
};

/**
 * Get users who liked current user
 */
const getUsersWhoLikedMe = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    console.log(`${colors.blue}💖 Getting users who liked: ${currentUserId}${colors.reset}`);

    const likes = await Swipe.find({
      swiped: currentUserId,
      action: "like",
    }).populate("swiper", "name email photo age gender bio interests school jobTitle livingIn");

    const nonMutualLikes = [];

    for (let like of likes) {
      const mutualLike = await Swipe.findOne({
        swiper: currentUserId,
        swiped: like.swiper._id,
        action: "like",
      });

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
          swipeId: like._id,
        });
      }
    }

    console.log(`${colors.green}✅ Returning ${nonMutualLikes.length} likes${colors.reset}`);

    res.json({
      success: true,
      data: {
        likes: nonMutualLikes,
      },
      message: "Likes retrieved successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Get likes error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error retrieving likes",
    });
  }
};

router.get("/potential", authenticate, getPotentialMatches);
router.post("/swipe", authenticate, handleSwipe);
router.get("/matches", authenticate, getMutualMatches);
router.get("/likes", authenticate, getUsersWhoLikedMe);

module.exports = router;