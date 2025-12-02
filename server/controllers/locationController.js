// controllers/locationController.js
const User = require("../models/User");

const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
};

/**
 * Update or initialize user location
 */
const updateUserLocation = async (req, res) => {
  try {
    const { 
      latitude, 
      longitude, 
      accuracy, 
      provider,
      forceUpdate = false 
    } = req.body;
    
    const currentUserId = req.user._id;

    console.log(`${colors.blue}📍 Location update for user: ${currentUserId}${colors.reset}`);
    console.log(`${colors.blue}   Coordinates: ${latitude}, ${longitude}${colors.reset}`);

    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: "Latitude and longitude are required",
      });
    }

    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return res.status(400).json({
        success: false,
        message: "Invalid coordinates",
      });
    }

    const currentUser = await User.findById(currentUserId);
    
    if (currentUser.location && !forceUpdate) {
      const lastUpdate = currentUser.locationTimestamp;
      const now = new Date();
      const hoursDiff = (now - lastUpdate) / (1000 * 60 * 60);
      
      if (hoursDiff < 1) {
        console.log(`${colors.yellow}⚠️ Location updated recently, skipping update${colors.reset}`);
        
        return res.json({
          success: true,
          data: {
            location: currentUser.location,
            locationEnabled: currentUser.locationEnabled,
            locationRadius: currentUser.locationRadius,
            locationTimestamp: currentUser.locationTimestamp,
            message: "Location already updated recently",
          },
        });
      }
    }

    const updateData = {
      location: {
        type: "Point",
        coordinates: [parseFloat(longitude), parseFloat(latitude)],
      },
      locationEnabled: true,
      locationTimestamp: new Date(),
    };

    if (accuracy) updateData.locationAccuracy = accuracy;
    if (provider) updateData.locationProvider = provider;

    const updatedUser = await User.findByIdAndUpdate(
      currentUserId,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    console.log(`${colors.green}✅ Location updated successfully${colors.reset}`);

    res.json({
      success: true,
      data: {
        location: updatedUser.location,
        locationEnabled: updatedUser.locationEnabled,
        locationRadius: updatedUser.locationRadius,
        locationAccuracy: updatedUser.locationAccuracy,
        locationTimestamp: updatedUser.locationTimestamp,
        locationProvider: updatedUser.locationProvider,
      },
      message: "Location updated successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Location update error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error updating location",
    });
  }
};

/**
 * Update location radius settings
 */
const updateLocationRadius = async (req, res) => {
  try {
    const { radius } = req.body;
    const currentUserId = req.user._id;

    console.log(`${colors.blue}📏 Radius update: ${radius} KM${colors.reset}`);

    if (radius === undefined || radius < 0 || radius > 150) {
      return res.status(400).json({
        success: false,
        message: "Radius must be between 0 and 150 KM",
      });
    }

    const updatedUser = await User.findByIdAndUpdate(
      currentUserId,
      { 
        $set: { 
          locationRadius: parseInt(radius),
          locationEnabled: radius > 0
        } 
      },
      { new: true, runValidators: true }
    );

    console.log(`${colors.green}✅ Radius updated: ${updatedUser.locationRadius} KM${colors.reset}`);

    res.json({
      success: true,
      data: {
        locationRadius: updatedUser.locationRadius,
        locationEnabled: updatedUser.locationEnabled,
      },
      message: "Location radius updated successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Radius update error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error updating location radius",
    });
  }
};

/**
 * Get location settings
 */
const getLocationSettings = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    const user = await User.findById(currentUserId).select(
      "location locationEnabled locationRadius locationAccuracy locationTimestamp locationProvider"
    );

    res.json({
      success: true,
      data: {
        location: user.location,
        locationEnabled: user.locationEnabled,
        locationRadius: user.locationRadius,
        locationAccuracy: user.locationAccuracy,
        locationTimestamp: user.locationTimestamp,
        locationProvider: user.locationProvider,
        hasLocation: !!user.location && !!user.location.coordinates,
      },
      message: "Location settings retrieved successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Get location settings error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error retrieving location settings",
    });
  }
};

/**
 * Toggle location enabled/disabled
 */
const toggleLocationEnabled = async (req, res) => {
  try {
    const { enabled } = req.body;
    const currentUserId = req.user._id;

    const updatedUser = await User.findByIdAndUpdate(
      currentUserId,
      { $set: { locationEnabled: enabled } },
      { new: true, runValidators: true }
    );

    console.log(`${colors.green}✅ Location ${enabled ? 'enabled' : 'disabled'}${colors.reset}`);

    res.json({
      success: true,
      data: {
        locationEnabled: updatedUser.locationEnabled,
      },
      message: `Location ${enabled ? 'enabled' : 'disabled'} successfully`,
    });
  } catch (error) {
    console.error(`${colors.red}💥 Toggle location error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error toggling location",
    });
  }
};

/**
 * Calculate distance between two coordinates
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
 * Get users within radius with distance calculation
 */
const getUsersWithinRadius = async (req, res) => {
  try {
    const currentUserId = req.user._id;
    const { radius } = req.query;

    const currentUser = await User.findById(currentUserId);

    if (!currentUser.location || !currentUser.locationEnabled) {
      return res.status(400).json({
        success: false,
        message: "User location not available or disabled",
      });
    }

    const searchRadius = radius || currentUser.locationRadius || 50;

    console.log(`${colors.blue}📍 Finding users within ${searchRadius} KM${colors.reset}`);

    const nearbyUsers = await User.find({
      _id: { $ne: currentUserId },
      location: {
        $near: {
          $geometry: {
            type: "Point",
            coordinates: currentUser.location.coordinates,
          },
          $maxDistance: searchRadius * 1000,
        },
      },
      locationEnabled: true,
    }).select("-password");

    const usersWithDistance = nearbyUsers.map(user => {
      const userObj = user.toObject();
      
      if (user.location && user.location.coordinates) {
        const [lon1, lat1] = currentUser.location.coordinates;
        const [lon2, lat2] = user.location.coordinates;
        userObj.distance = calculateDistance(lat1, lon1, lat2, lon2);
      }
      
      return userObj;
    });

    usersWithDistance.sort((a, b) => {
      if (a.distance && b.distance) {
        return a.distance - b.distance;
      }
      return 0;
    });

    console.log(`${colors.green}✅ Found ${usersWithDistance.length} users${colors.reset}`);

    res.json({
      success: true,
      data: {
        users: usersWithDistance,
        count: usersWithDistance.length,
        radius: searchRadius,
      },
      message: "Users within radius retrieved successfully",
    });
  } catch (error) {
    console.error(`${colors.red}💥 Get users error:${colors.reset}`, error.message);
    res.status(500).json({
      success: false,
      message: "Error retrieving users within radius",
    });
  }
};

module.exports = {
  updateUserLocation,
  updateLocationRadius,
  getLocationSettings,
  toggleLocationEnabled,
  getUsersWithinRadius,
  calculateDistance,
};