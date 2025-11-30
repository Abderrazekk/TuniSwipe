// controllers/locationController.js
const User = require("../models/User");

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
};

/**
 * Update user location
 */
const updateUserLocation = async (req, res) => {
  try {
    const { latitude, longitude, maxDistance } = req.body;
    const currentUserId = req.user._id;

    console.log(
      `${colors.blue}📍 Location update for user: ${currentUserId}${colors.reset}`
    );
    console.log(`${colors.blue}   Coordinates: ${latitude}, ${longitude}${colors.reset}`);
    console.log(`${colors.blue}   Max Distance: ${maxDistance} KM${colors.reset}`);

    // Validate coordinates
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: "Latitude and longitude are required",
      });
    }

    // Validate coordinates range
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return res.status(400).json({
        success: false,
        message: "Invalid coordinates",
      });
    }

    // Validate max distance
    const userMaxDistance = maxDistance || 50;
    if (userMaxDistance < 1 || userMaxDistance > 1000) {
      return res.status(400).json({
        success: false,
        message: "Max distance must be between 1 and 1000 KM",
      });
    }

    // Update user location
    const updatedUser = await User.findByIdAndUpdate(
      currentUserId,
      {
        location: {
          type: "Point",
          coordinates: [longitude, latitude], // MongoDB uses [long, lat]
        },
        locationEnabled: true,
        maxDistance: userMaxDistance,
        lastLocationUpdate: new Date(),
      },
      { new: true, runValidators: true }
    );

    console.log(
      `${colors.green}✅ Location updated successfully for user: ${currentUserId}${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        location: updatedUser.location,
        maxDistance: updatedUser.maxDistance,
        locationEnabled: updatedUser.locationEnabled,
        lastLocationUpdate: updatedUser.lastLocationUpdate,
      },
      message: "Location updated successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Location update error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error updating location",
    });
  }
};

/**
 * Get users within radius (for testing/debugging)
 */
const getNearbyUsers = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const { maxDistance = 50 } = req.query;

    const currentUser = await User.findById(currentUserId);

    if (!currentUser.location || !currentUser.locationEnabled) {
      return res.status(400).json({
        success: false,
        message: "User location not available",
      });
    }

    const nearbyUsers = await User.find({
      _id: { $ne: currentUserId },
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: currentUser.location.coordinates,
          },
          $maxDistance: maxDistance * 1000, // Convert KM to meters
        },
      },
      locationEnabled: true,
    }).select("name email age gender location");

    console.log(
      `${colors.green}✅ Found ${nearbyUsers.length} users within ${maxDistance} KM${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        users: nearbyUsers,
        count: nearbyUsers.length,
        maxDistance: parseInt(maxDistance),
      },
      message: "Nearby users retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Nearby users error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving nearby users",
    });
  }
};

/**
 * Get user location settings
 */
const getUserLocationSettings = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    const user = await User.findById(currentUserId).select(
      "location locationEnabled maxDistance lastLocationUpdate"
    );

    res.json({
      success: true,
      data: {
        location: user.location,
        locationEnabled: user.locationEnabled,
        maxDistance: user.maxDistance,
        lastLocationUpdate: user.lastLocationUpdate,
      },
      message: "Location settings retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Get location settings error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving location settings",
    });
  }
};

module.exports = {
  updateUserLocation,
  getNearbyUsers,
  getUserLocationSettings,
};