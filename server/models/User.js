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
    // ADD MEDIA FIELD
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
    // ADD NEW FIELDS - MAKE THEM OPTIONAL
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
        default: [0, 0], // [longitude, latitude]
      },
    },
    locationEnabled: {
      type: Boolean,
      default: false,
    },
    maxDistance: {
      type: Number,
      default: 50, // Default radius in KM
    },
    lastLocationUpdate: {
      type: Date,
      default: Date.now,
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

// Remove password from JSON output
userSchema.methods.toJSON = function () {
  const user = this.toObject();
  delete user.password;
  return user;
};

module.exports = mongoose.model("User", userSchema);
