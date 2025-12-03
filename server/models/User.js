// models/User.js
const mongoose = require("mongoose");
const bcrypt = require("bcryptjs");

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, "Name is required"],
      trim: true,
      minlength: [2, "Name must be at least 2 characters long"],
    },
    email: {
      type: String,
      required: [true, "Email is required"],
      unique: true,
      lowercase: true,
      match: [
        /^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/,
        "Please enter a valid email",
      ],
    },
    password: {
      type: String,
      required: [true, "Password is required"],
      minlength: [6, "Password must be at least 6 characters long"],
    },
    role: {
      type: String,
      default: "user",
      enum: ["user"],
    },
    bio: {
      type: String,
      default: "",
    },
    gender: {
      type: String,
      enum: ["male", "female", "other"],
      required: true,
    },
    interests: [
      {
        type: String,
      },
    ],
    photo: {
      type: String,
      default: "",
    },
    age: {
      type: Number,
      required: true,
      min: [13, "User must be at least 13 years old"],
      max: [120, "Please enter a valid age"],
    },
    media: [
      {
        filename: String,
        originalName: String,
        uploadDate: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    school: {
      type: String,
      default: "",
    },
    height: {
      type: Number,
      default: null,
      min: [100, "Height must be at least 100 cm"],
      max: [250, "Height must be at most 250 cm"],
    },
    jobTitle: {
      type: String,
      default: "",
    },
    livingIn: {
      type: String,
      default: "",
    },
    topArtist: {
      type: String,
      default: "",
    },
    company: {
      type: String,
      default: "",
    },
    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number],
        default: null,
      },
    },
    locationEnabled: {
      type: Boolean,
      default: false,
    },
    locationRadius: {
      type: Number,
      default: 50,
      min: 0,
      max: 150,
    },
    locationAccuracy: {
      type: Number,
      default: null,
    },
    locationTimestamp: {
      type: Date,
      default: null,
    },
    locationProvider: {
      type: String,
      enum: ["gps", "network", "passive", "fused", null],
      default: null,
    },
    ageFilterEnabled: {
      type: Boolean,
      default: false,
    },
    minAgeFilter: {
      type: Number,
      default: 10,
      min: 10,
      max: 100,
    },
    maxAgeFilter: {
      type: Number,
      default: 100,
      min: 10,
      max: 100,
    },
  },
  {
    timestamps: true,
  }
);

// Create a 2dsphere index for geospatial queries
userSchema.index({ location: "2dsphere" });

// Hash password before saving
userSchema.pre("save", async function (next) {
  if (!this.isModified("password")) {
    next();
  }
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Method to compare password
userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

// NEW: Get all images for swipe cards (profile + media)
userSchema.methods.getAllImages = function () {
  const images = [];

  // Add profile photo first if exists
  if (this.photo && this.photo.trim() !== "") {
    images.push({
      type: "profile",
      filename: this.photo,
      originalName: "Profile Photo",
      uploadDate: this.updatedAt,
    });
  }

  // Add media images
  if (this.media && this.media.length > 0) {
    images.push(
      ...this.media.map((media) => ({
        type: "media",
        ...media.toObject(),
      }))
    );
  }

  return images;
};

userSchema.methods.getAllImagesForSwipe = function () {
  const images = [];

  // Add profile photo as first image if exists
  if (this.photo && this.photo.trim() !== "") {
    images.push({
      _id: "profile",
      type: "profile",
      filename: this.photo,
      originalName: "Profile Photo",
      uploadDate: this.updatedAt,
      isProfile: true,
    });
  }

  // Add media images in chronological order
  if (this.media && this.media.length > 0) {
    const sortedMedia = [...this.media].sort(
      (a, b) => new Date(a.uploadDate) - new Date(b.uploadDate)
    );

    sortedMedia.forEach((media) => {
      images.push({
        _id: media._id || media.filename,
        type: "media",
        filename: media.filename,
        originalName: media.originalName,
        uploadDate: media.uploadDate,
        isProfile: false,
      });
    });
  }

  return images;
};

// Get optimized data for swipe cards
userSchema.methods.getSwipeCardData = function (distance = null) {
  return {
    _id: this._id,
    name: this.name,
    age: this.age,
    bio: this.bio,
    gender: this.gender,
    interests: this.interests,
    images: this.getAllImagesForSwipe(), // Use unified images
    school: this.school,
    height: this.height,
    jobTitle: this.jobTitle,
    livingIn: this.livingIn,
    topArtist: this.topArtist,
    company: this.company,
    locationEnabled: this.locationEnabled,
    locationRadius: this.locationRadius,
    distance: distance,
    totalImages: this.getAllImagesForSwipe().length,
  };
};

// Remove password from JSON output
userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  return user;
};

module.exports = mongoose.model("User", userSchema);
