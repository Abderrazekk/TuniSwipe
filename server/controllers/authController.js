const { generateToken } = require("../utils/generateToken");
const User = require("../models/User");
const Admin = require("../models/Admin");
const path = require("path");

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
};

/**
 * User Signup Controller
 */
const userSignup = async (req, res) => {
  const {
    name,
    email,
    password,
    bio,
    gender,
    interests,
    age,
    latitude,
    longitude,
    maxDistance,
  } = req.body;

  console.log(`${colors.blue}👤 User signup attempt: ${email}${colors.reset}`);

  try {
    // Check if user exists
    console.log(
      `${colors.yellow}🔍 Checking if user exists: ${email}${colors.reset}`
    );
    const userExists = await User.findOne({ email });

    if (userExists) {
      console.log(
        `${colors.red}❌ Signup failed: User already exists - ${email}${colors.reset}`
      );
      return res.status(400).json({
        success: false,
        message: "User already exists with this email",
      });
    }

    // Parse interests if it's a string
    let interestsArray = [];
    if (interests) {
      if (typeof interests === "string") {
        try {
          interestsArray = JSON.parse(interests);
        } catch (parseError) {
          console.log(
            `${colors.yellow}⚠️ Could not parse interests as JSON, using as array${colors.reset}`
          );
          interestsArray = [interests];
        }
      } else if (Array.isArray(interests)) {
        interestsArray = interests;
      }
    }

    // Parse and validate age
    const userAge = parseInt(age);
    console.log(
      `${colors.blue}🎂 Age received: ${userAge} (type: ${typeof userAge})${
        colors.reset
      }`
    );

    if (isNaN(userAge) || userAge < 13) {
      console.log(`${colors.red}❌ Invalid age: ${age}${colors.reset}`);
      return res.status(400).json({
        success: false,
        message: "User must be at least 13 years old",
      });
    }

    // Handle photo upload
    let photoPath = "";
    if (req.file) {
      photoPath = req.file.filename;
      console.log(
        `${colors.green}📸 Photo uploaded: ${photoPath}${colors.reset}`
      );
    }

    console.log(
      `${colors.yellow}📝 Creating new user: ${email}${colors.reset}`
    );

    // Handle location data
    let locationData = {};
    if (latitude && longitude) {
      locationData = {
        location: {
          type: "Point",
          coordinates: [parseFloat(longitude), parseFloat(latitude)],
        },
        locationEnabled: true,
        maxDistance: maxDistance || 50,
      };
    }

    // CREATE USER WITHOUT THE NEW FIELDS - THEY WILL BE EMPTY BY DEFAULT
    const user = await User.create({
      name,
      email,
      password,
      bio: bio || "",
      gender,
      interests: interestsArray,
      age: userAge,
      photo: photoPath,
      ...locationData,
      // REMOVED: school, height, jobTitle, livingIn, topArtist, company
    });

    console.log(
      `${colors.green}✅ User created successfully: ${email}${colors.reset}`
    );
    console.log(`${colors.blue}🆔 User ID: ${user._id}${colors.reset}`);
    console.log(`${colors.blue}🎯 Gender: ${gender}${colors.reset}`);
    console.log(`${colors.blue}📅 Age: ${userAge}${colors.reset}`);
    console.log(
      `${colors.blue}🏷️ Interests: ${interestsArray.join(", ")}${colors.reset}`
    );
    console.log(`${colors.blue}📸 Photo: ${photoPath}${colors.reset}`);

    res.status(201).json({
      success: true,
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        bio: user.bio,
        gender: user.gender,
        interests: user.interests,
        age: user.age,
        photo: user.photo,
        // REMOVED: school, height, jobTitle, livingIn, topArtist, company
        token: generateToken(user._id, user.role, user.email),
      },
      message: "User registered successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Signup error for ${email}:${colors.reset}`,
      error.message
    );
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};
/**
 * User/Admin Signin Controller
 */
const userSignin = async (req, res) => {
  const { email, password } = req.body;

  console.log(`${colors.blue}🔐 Signin attempt: ${email}${colors.reset}`);

  try {
    // First check if it's an admin
    console.log(
      `${colors.yellow}🔍 Checking admin collection for: ${email}${colors.reset}`
    );
    let user = await Admin.findOne({ email });

    if (user) {
      console.log(`${colors.green}👑 Admin found: ${email}${colors.reset}`);
      const isMatch = await user.matchPassword(password);

      if (isMatch) {
        console.log(
          `${colors.green}✅ Admin password correct: ${email}${colors.reset}`
        );
        return res.json({
          success: true,
          data: {
            _id: user._id,
            name: user.name || "Administrator",
            email: user.email,
            role: user.role,
            token: generateToken(user._id, user.role, user.email),
          },
          message: "Admin login successful",
        });
      } else {
        console.log(
          `${colors.red}❌ Admin password incorrect: ${email}${colors.reset}`
        );
      }
    }

    // If not admin, check if it's a regular user
    console.log(
      `${colors.yellow}🔍 Checking user collection for: ${email}${colors.reset}`
    );
    user = await User.findOne({ email });

    if (user) {
      console.log(`${colors.green}👤 User found: ${email}${colors.reset}`);
      const isMatch = await user.matchPassword(password);

      if (isMatch) {
        console.log(
          `${colors.green}✅ User password correct: ${email}${colors.reset}`
        );

        // Return complete user data including profile fields
        return res.json({
          success: true,
          data: {
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            bio: user.bio || "",
            gender: user.gender || "",
            interests: user.interests || [],
            age: user.age || 0,
            photo: user.photo || "",
            token: generateToken(user._id, user.role, user.email),
          },
          message: "User login successful",
        });
      } else {
        console.log(
          `${colors.red}❌ User password incorrect: ${email}${colors.reset}`
        );
      }
    }

    // If we get here, credentials are invalid
    console.log(
      `${colors.red}❌ Signin failed: Invalid credentials for ${email}${colors.reset}`
    );
    res.status(401).json({
      success: false,
      message: "Invalid email or password",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Signin error for ${email}:${colors.reset}`,
      error.message
    );
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Get User Profile Controller
 */
const getUserProfile = async (req, res) => {
  console.log(
    `${colors.blue}👤 Profile requested for: ${req.user.email}${colors.reset}`
  );

  res.json({
    success: true,
    data: req.user,
    message: "Profile retrieved successfully",
  });
};

/**
 * Get Admin Stats Controller
 */
const getAdminStats = async (req, res) => {
  console.log(
    `${colors.blue}📊 Admin stats requested by: ${req.user.email}${colors.reset}`
  );

  try {
    const userCount = await User.countDocuments();
    const adminCount = await Admin.countDocuments();

    res.json({
      success: true,
      data: {
        users: userCount,
        admins: adminCount,
        total: userCount + adminCount,
      },
      message: "Admin stats retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Admin stats error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving stats",
    });
  }
};

/**
 * Check Admin Exists Controller
 */
const checkAdminExists = async (req, res) => {
  console.log(`${colors.blue}🔍 Admin check requested${colors.reset}`);

  try {
    const admin = await Admin.findOne({ email: "admin@admin.com" });
    const exists = !!admin;

    console.log(
      `${
        exists
          ? colors.green + "✅ Admin exists"
          : colors.yellow + "⚠️ Admin not found"
      }${colors.reset}`
    );

    res.json({
      success: true,
      exists,
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Admin check error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
/**
 * Get Complete User Profile Controller
 */
const getCompleteUserProfile = async (req, res) => {
  console.log(
    `${colors.blue}👤 Complete profile requested for user ID: ${req.user._id}${colors.reset}`
  );

  try {
    // Find the user by ID and return all fields
    const user = await User.findById(req.user._id);

    if (!user) {
      console.log(
        `${colors.red}❌ User not found: ${req.user._id}${colors.reset}`
      );
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    console.log(
      `${colors.green}✅ Complete user profile retrieved: ${user.email}${colors.reset}`
    );
    console.log(`${colors.blue}   Age: ${user.age}${colors.reset}`);
    console.log(`${colors.blue}   Gender: ${user.gender}${colors.reset}`);
    console.log(`${colors.blue}   Bio: ${user.bio}${colors.reset}`);
    console.log(`${colors.blue}   Interests: ${user.interests}${colors.reset}`);
    console.log(`${colors.blue}   Photo: ${user.photo}${colors.reset}`);

    res.json({
      success: true,
      data: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        bio: user.bio,
        gender: user.gender,
        interests: user.interests,
        age: user.age,
        photo: user.photo,
        school: user.school,
        height: user.height,
        jobTitle: user.jobTitle,
        livingIn: user.livingIn,
        topArtist: user.topArtist,
        company: user.company,
        // Note: We don't include token here as it's already in the request
      },
      message: "Complete profile retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Profile retrieval error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving user profile",
    });
  }
};
/**
 * Update User Profile Controller
 */
const updateUserProfile = async (req, res) => {
  console.log(
    `${colors.blue}✏️ Profile update requested for: ${req.user.email}${colors.reset}`
  );

  try {
    const {
      name,
      age,
      bio,
      interests,
      school,
      height,
      jobTitle,
      livingIn,
      topArtist,
      company,
    } = req.body;

    console.log(`${colors.blue}📦 Update data received:${colors.reset}`);
    console.log(`${colors.blue}   Name: ${name}${colors.reset}`);
    console.log(`${colors.blue}   Age: ${age}${colors.reset}`);
    console.log(`${colors.blue}   Bio: ${bio}${colors.reset}`);
    console.log(`${colors.blue}   Interests: ${interests}${colors.reset}`);
    console.log(`${colors.blue}   School: ${school}${colors.reset}`);
    console.log(`${colors.blue}   Height: ${height}${colors.reset}`);
    console.log(`${colors.blue}   Job Title: ${jobTitle}${colors.reset}`);
    console.log(`${colors.blue}   Living In: ${livingIn}${colors.reset}`);
    console.log(`${colors.blue}   Top Artist: ${topArtist}${colors.reset}`);
    console.log(`${colors.blue}   Company: ${company}${colors.reset}`);
    console.log(`${colors.blue}   Has file: ${!!req.file}${colors.reset}`);

    // Parse and validate age
    const userAge = parseInt(age);
    if (isNaN(userAge) || userAge < 13) {
      console.log(`${colors.red}❌ Invalid age: ${age}${colors.reset}`);
      return res.status(400).json({
        success: false,
        message: "User must be at least 13 years old",
      });
    }

    // Parse and validate height
    let parsedHeight = null;
    if (height) {
      parsedHeight = parseInt(height);
      if (isNaN(parsedHeight) || parsedHeight < 100 || parsedHeight > 250) {
        console.log(`${colors.red}❌ Invalid height: ${height}${colors.reset}`);
        return res.status(400).json({
          success: false,
          message: "Height must be between 100 and 250 cm",
        });
      }
    }

    // Parse interests if it's a string
    let interestsArray = [];
    if (interests) {
      if (typeof interests === "string") {
        try {
          interestsArray = JSON.parse(interests);
        } catch (parseError) {
          console.log(
            `${colors.yellow}⚠️ Could not parse interests as JSON, using as array${colors.reset}`
          );
          interestsArray = [interests];
        }
      } else if (Array.isArray(interests)) {
        interestsArray = interests;
      }
    }

    // Handle photo upload if new file is provided
    let photoUpdate = {};
    if (req.file) {
      photoUpdate.photo = req.file.filename;
      console.log(
        `${colors.green}📸 New photo uploaded: ${req.file.filename}${colors.reset}`
      );
    }

    // Prepare update data
    const updateData = {
      name,
      age: userAge,
      bio: bio || "",
      interests: interestsArray,
      school: school || "",
      height: parsedHeight,
      jobTitle: jobTitle || "",
      livingIn: livingIn || "",
      topArtist: topArtist || "",
      company: company || "",
      ...photoUpdate, // Spread the photo update if it exists
    };

    console.log(
      `${colors.yellow}📝 Updating user profile: ${req.user._id}${colors.reset}`
    );

    // Find and update the user
    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    if (!updatedUser) {
      console.log(
        `${colors.red}❌ User not found for update: ${req.user._id}${colors.reset}`
      );
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    console.log(
      `${colors.green}✅ User profile updated successfully: ${updatedUser.email}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New Name: ${updatedUser.name}${colors.reset}`
    );
    console.log(`${colors.blue}   New Age: ${updatedUser.age}${colors.reset}`);
    console.log(`${colors.blue}   New Bio: ${updatedUser.bio}${colors.reset}`);
    console.log(
      `${colors.blue}   New Interests: ${updatedUser.interests}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New Photo: ${updatedUser.photo}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New School: ${updatedUser.school}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New Height: ${updatedUser.height}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New Job Title: ${updatedUser.jobTitle}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New Living In: ${updatedUser.livingIn}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New Top Artist: ${updatedUser.topArtist}${colors.reset}`
    );
    console.log(
      `${colors.blue}   New Company: ${updatedUser.company}${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        _id: updatedUser._id,
        name: updatedUser.name,
        email: updatedUser.email,
        role: updatedUser.role,
        bio: updatedUser.bio,
        gender: updatedUser.gender,
        interests: updatedUser.interests,
        age: updatedUser.age,
        photo: updatedUser.photo,
        school: updatedUser.school,
        height: updatedUser.height,
        jobTitle: updatedUser.jobTitle,
        livingIn: updatedUser.livingIn,
        topArtist: updatedUser.topArtist,
        company: updatedUser.company,
      },
      message: "Profile updated successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Profile update error:${colors.reset}`,
      error.message
    );
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};
/**
 * Add Media to User Profile
 */
const addUserMedia = async (req, res) => {
  console.log(
    `${colors.blue}📸 Media upload requested for: ${req.user.email}${colors.reset}`
  );

  try {
    if (!req.files || req.files.length === 0) {
      console.log(`${colors.red}❌ No media files provided${colors.reset}`);
      return res.status(400).json({
        success: false,
        message: "No media files provided",
      });
    }

    // Check if user already has 6 or more media files
    const user = await User.findById(req.user._id);
    const currentMediaCount = user.media ? user.media.length : 0;
    const newFilesCount = req.files.length;

    if (currentMediaCount + newFilesCount > 6) {
      console.log(
        `${colors.red}❌ Maximum 6 media files allowed${colors.reset}`
      );
      return res.status(400).json({
        success: false,
        message: `You can only have 6 media files maximum. You currently have ${currentMediaCount} and tried to add ${newFilesCount}.`,
      });
    }

    // Prepare media objects
    const newMedia = req.files.map((file) => ({
      filename: file.filename,
      originalName: file.originalname,
      uploadDate: new Date(),
    }));

    // Add new media to user's media array
    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      {
        $push: {
          media: {
            $each: newMedia,
          },
        },
      },
      { new: true, runValidators: true }
    );

    console.log(
      `${colors.green}✅ Media added successfully: ${newFilesCount} files${colors.reset}`
    );
    console.log(
      `${colors.blue}📊 Total media files: ${updatedUser.media.length}${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        media: updatedUser.media,
      },
      message: `Successfully added ${newFilesCount} media file(s)`,
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Media upload error:${colors.reset}`,
      error.message
    );
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Remove Media from User Profile
 */
const removeUserMedia = async (req, res) => {
  const { filename } = req.params;

  console.log(
    `${colors.blue}🗑️ Media delete requested for: ${filename}${colors.reset}`
  );

  try {
    const user = await User.findById(req.user._id);

    // Find the media to remove
    const mediaToRemove = user.media.find((m) => m.filename === filename);

    if (!mediaToRemove) {
      console.log(
        `${colors.red}❌ Media file not found: ${filename}${colors.reset}`
      );
      return res.status(404).json({
        success: false,
        message: "Media file not found",
      });
    }

    // Remove from database
    const updatedUser = await User.findByIdAndUpdate(
      req.user._id,
      {
        $pull: {
          media: { filename: filename },
        },
      },
      { new: true, runValidators: true }
    );

    // Delete physical file
    const fs = require("fs");
    const path = require("path");
    const filePath = path.join(__dirname, "../uploads", filename);

    if (fs.existsSync(filePath)) {
      fs.unlinkSync(filePath);
      console.log(
        `${colors.green}✅ Physical file deleted: ${filename}${colors.reset}`
      );
    }

    console.log(
      `${colors.green}✅ Media removed successfully: ${filename}${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        media: updatedUser.media,
      },
      message: "Media file removed successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Media removal error:${colors.reset}`,
      error.message
    );
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Get User Media
 */
const getUserMedia = async (req, res) => {
  console.log(
    `${colors.blue}📸 Media requested for: ${req.user.email}${colors.reset}`
  );

  try {
    const user = await User.findById(req.user._id);

    res.json({
      success: true,
      data: {
        media: user.media || [],
      },
      message: "Media retrieved successfully",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Media retrieval error:${colors.reset}`,
      error.message
    );
    res.status(400).json({
      success: false,
      message: error.message,
    });
  }
};

// NEW: Get user data optimized for swipe cards
const getUserForSwipeCard = async (req, res) => {
  const { userId } = req.params;

  console.log(
    `${colors.blue}🃏 Getting user data for swipe card: ${userId}${colors.reset}`
  );

  try {
    const user = await User.findById(userId)
      .select("-password -__v -createdAt -updatedAt -email -role")
      .lean();

    if (!user) {
      console.log(
        `${colors.red}❌ User not found for swipe: ${userId}${colors.reset}`
      );
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Format user data for swipe card
    const swipeData = {
      _id: user._id,
      name: user.name,
      age: user.age,
      bio: user.bio,
      gender: user.gender,
      interests: user.interests,
      photo: user.photo,
      media: user.media || [],
      school: user.school || "",
      height: user.height || null,
      jobTitle: user.jobTitle || "",
      livingIn: user.livingIn || "",
      topArtist: user.topArtist || "",
      company: user.company || "",
      locationEnabled: user.locationEnabled || false,
      locationRadius: user.locationRadius || 50,
    };

    console.log(
      `${colors.green}✅ User data prepared for swipe card${colors.reset}`
    );
    console.log(
      `${colors.blue}📊 Total images: ${1 + (user.media?.length || 0)}${
        colors.reset
      }`
    );

    res.json({
      success: true,
      data: swipeData,
      message: "User data retrieved for swipe card",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Error getting user for swipe:${colors.reset}`,
      error
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving user data",
    });
  }
};

const getPotentialMatchesWithImages = async (req, res) => {
  console.log(
    `${colors.blue}👥 Getting potential matches with images for: ${req.user.email}${colors.reset}`
  );

  try {
    const currentUser = await User.findById(req.user._id);

    if (!currentUser) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Build query based on location settings
    let query = {
      _id: { $ne: currentUser._id }, // Exclude current user
      // Remove locationEnabled filter to get all users
      // locationEnabled: true,
    };

    // If user has location enabled, filter by distance
    if (currentUser.location && currentUser.locationEnabled) {
      const radius = currentUser.locationRadius || 50;
      const radiusInMeters = radius * 1000;

      query.location = {
        $near: {
          $geometry: currentUser.location,
          $maxDistance: radiusInMeters,
        },
      };
    }

    // Get potential matches with optimized data
    let potentialMatches = await User.find(query)
      .select("-password -email -__v -createdAt -updatedAt")
      .lean();

    // Format matches with ALL images
    const formattedMatches = potentialMatches.map((user) => {
      // Calculate distance if location data exists
      let distance = null;
      if (
        currentUser.location &&
        currentUser.location.coordinates &&
        user.location &&
        user.location.coordinates
      ) {
        distance = calculateDistance(
          currentUser.location.coordinates[1], // latitude
          currentUser.location.coordinates[0], // longitude
          user.location.coordinates[1],
          user.location.coordinates[0]
        );
      }

      // Create unified images array
      const allImages = [];

      // Add profile image first
      if (user.photo && user.photo.trim() !== "") {
        allImages.push({
          _id: "profile",
          type: "profile",
          filename: user.photo,
          originalName: "Profile Photo",
          isProfile: true,
        });
      }

      // Add media images
      if (user.media && user.media.length > 0) {
        user.media.forEach((media) => {
          allImages.push({
            _id: media._id || media.filename,
            type: "media",
            filename: media.filename,
            originalName: media.originalName,
            uploadDate: media.uploadDate,
            isProfile: false,
          });
        });
      }

      return {
        _id: user._id,
        name: user.name,
        age: user.age,
        bio: user.bio,
        gender: user.gender,
        interests: user.interests,
        images: allImages, // Unified images array
        school: user.school,
        height: user.height,
        jobTitle: user.jobTitle,
        livingIn: user.livingIn,
        topArtist: user.topArtist,
        company: user.company,
        distance: distance,
        locationEnabled: user.locationEnabled,
        hasImages: allImages.length > 0,
      };
    });

    // Sort by distance if location is enabled
    if (currentUser.locationEnabled) {
      formattedMatches.sort((a, b) => {
        if (a.distance === null) return 1;
        if (b.distance === null) return -1;
        return a.distance - b.distance;
      });
    }

    console.log(
      `${colors.green}✅ Found ${formattedMatches.length} potential matches${colors.reset}`
    );
    console.log(`${colors.blue}📊 Images distribution: ${colors.reset}`);
    formattedMatches.forEach((match, idx) => {
      console.log(
        `${colors.blue}   ${idx + 1}. ${match.name}: ${
          match.images.length
        } images${colors.reset}`
      );
    });

    res.json({
      success: true,
      data: formattedMatches,
      message: "Potential matches retrieved with complete image data",
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Error getting potential matches:${colors.reset}`,
      error
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving potential matches",
    });
  }
};

// Helper function to calculate distance
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in km
}

module.exports = {
  userSignup,
  userSignin,
  getUserProfile,
  getAdminStats,
  checkAdminExists,
  getCompleteUserProfile,
  updateUserProfile,
  addUserMedia,
  removeUserMedia,
  getUserMedia,
  getUserForSwipeCard, // NEW
  getPotentialMatchesWithImages, // NEW
};
