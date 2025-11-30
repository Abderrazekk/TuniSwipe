const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  red: "\x1b[31m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
};

// Ensure uploads directory exists
const uploadsDir = path.join(__dirname, "../uploads");
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
  console.log(`${colors.green}✅ Created uploads directory${colors.reset}`);
}

// Configure multer for file upload
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    // Create unique filename with user ID if available
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    const fileExtension = path.extname(file.originalname).toLowerCase();

    // Include user ID in filename if user is authenticated, otherwise use "signup"
    const userPrefix = req.user ? `user-${req.user._id}-` : "signup-";
    cb(null, userPrefix + uniqueSuffix + fileExtension);
  },
});

// Improved file filter for images only
const fileFilter = (req, file, cb) => {
  console.log(
    `${colors.blue}📁 Processing file: ${file.originalname}${colors.reset}`
  );
  console.log(`${colors.blue}📁 MIME type: ${file.mimetype}${colors.reset}`);

  // Check if file is an image
  if (file.mimetype.startsWith("image/")) {
    console.log(
      `${colors.green}✅ File accepted: ${file.originalname}${colors.reset}`
    );
    cb(null, true);
  } else {
    console.log(
      `${colors.red}❌ File rejected: ${file.originalname} - Not an image${colors.reset}`
    );
    cb(new Error("Only image files are allowed!"), false);
  }
};

const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit
  },
});

// Middleware to handle single file upload (for profile photo)
const uploadSingle = upload.single("photo");

// Middleware to handle multiple media files (max 6)
const uploadMedia = upload.array("media", 6);

// Custom middleware to handle upload errors for single file
const handleUpload = (req, res, next) => {
  uploadSingle(req, res, function (err) {
    if (err instanceof multer.MulterError) {
      console.log(`${colors.red}❌ Multer Error: ${err.code}${colors.reset}`);

      if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(400).json({
          success: false,
          message: "File too large. Maximum size is 5MB.",
        });
      }

      if (err.code === "LIMIT_UNEXPECTED_FILE") {
        return res.status(400).json({
          success: false,
          message:
            'Unexpected file field. Please use "photo" as the field name.',
        });
      }

      return res.status(400).json({
        success: false,
        message: `Upload error: ${err.message}`,
      });
    } else if (err) {
      console.log(
        `${colors.red}❌ Upload Error: ${err.message}${colors.reset}`
      );
      return res.status(400).json({
        success: false,
        message: err.message,
      });
    }

    // Log file upload success
    if (req.file) {
      console.log(
        `${colors.green}✅ File uploaded successfully: ${req.file.filename}${colors.reset}`
      );

      // Log user info if available (for authenticated requests)
      if (req.user) {
        console.log(
          `${colors.blue}📁 Uploaded for authenticated user: ${req.user.email}${colors.reset}`
        );
      } else {
        console.log(
          `${colors.blue}📁 Uploaded for signup process${colors.reset}`
        );
      }
    } else {
      console.log(`${colors.yellow}⚠️ No file uploaded${colors.reset}`);
    }

    next();
  });
};

// Custom middleware to handle media uploads (requires authentication)
const handleMediaUpload = (req, res, next) => {
  // Check if user is authenticated (media uploads require auth)
  if (!req.user) {
    console.log(
      `${colors.red}❌ Media upload failed: User not authenticated${colors.reset}`
    );
    return res.status(401).json({
      success: false,
      message: "Authentication required for media upload",
    });
  }

  uploadMedia(req, res, function (err) {
    if (err instanceof multer.MulterError) {
      console.log(
        `${colors.red}❌ Multer Media Error: ${err.code}${colors.reset}`
      );

      if (err.code === "LIMIT_FILE_SIZE") {
        return res.status(400).json({
          success: false,
          message:
            "One or more files are too large. Maximum size is 5MB per file.",
        });
      }

      if (err.code === "LIMIT_FILE_COUNT") {
        return res.status(400).json({
          success: false,
          message: "Too many files. Maximum 6 files allowed.",
        });
      }

      if (err.code === "LIMIT_UNEXPECTED_FILE") {
        return res.status(400).json({
          success: false,
          message:
            'Unexpected file field. Please use "media" as the field name.',
        });
      }

      return res.status(400).json({
        success: false,
        message: `Upload error: ${err.message}`,
      });
    } else if (err) {
      console.log(
        `${colors.red}❌ Media Upload Error: ${err.message}${colors.reset}`
      );
      return res.status(400).json({
        success: false,
        message: err.message,
      });
    }

    // Log media upload success
    if (req.files && req.files.length > 0) {
      console.log(
        `${colors.green}✅ ${req.files.length} media files uploaded successfully${colors.reset}`
      );
      console.log(
        `${colors.blue}📁 Uploaded for user: ${req.user.email}${colors.reset}`
      );
      req.files.forEach((file, index) => {
        console.log(
          `${colors.blue}   ${index + 1}. ${file.filename}${colors.reset}`
        );
      });
    } else {
      console.log(`${colors.yellow}⚠️ No media files uploaded${colors.reset}`);
    }

    next();
  });
};

module.exports = {
  handleUpload,
  handleMediaUpload,
};
