const app = require("./app");
const connectDB = require("./config/db");
const Admin = require("./models/Admin");
const { initializeSocket } = require("./socket/socketServer");
require("dotenv").config();

const PORT = process.env.PORT || 5000;

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  red: "\x1b[31m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  magenta: "\x1b[35m",
  cyan: "\x1b[36m",
};

// Auto-create admin account on server start
const createDefaultAdmin = async () => {
  try {
    console.log(
      `${colors.cyan}🔍 Checking for admin account...${colors.reset}`
    );
    const adminExists = await Admin.findOne({ email: "admin@admin.com" });

    if (!adminExists) {
      console.log(
        `${colors.yellow}⚠️ No admin account found. Creating default admin...${colors.reset}`
      );
      await Admin.create({
        email: "admin@admin.com",
        password: "admin123",
      });
      console.log(
        `${colors.green}✅ Default admin account created successfully${colors.reset}`
      );
      console.log(`${colors.blue}📧 Email: admin@admin.com${colors.reset}`);
      console.log(`${colors.blue}🔑 Password: admin123${colors.reset}`);
    } else {
      console.log(
        `${colors.green}✅ Admin account already exists${colors.reset}`
      );
    }
  } catch (error) {
    console.error(
      `${colors.red}❌ Error creating admin account:${colors.reset}`,
      error
    );
  }
};

// Connect to MongoDB and start server
const startServer = async () => {
  try {
    console.log(`${colors.cyan}🚀 Starting server...${colors.reset}`);

    // Connect to MongoDB
    await connectDB();

    // Create default admin
    await createDefaultAdmin();

    // Start Express server
    const server = app.listen(PORT, "0.0.0.0", () => {
      console.log(
        `${colors.green}🎉 Server started successfully!${colors.reset}`
      );
      console.log(`${colors.blue}📍 Port: ${PORT}${colors.reset}`);
      console.log(
        `${colors.blue}🌐 Local: http://localhost:${PORT}${colors.reset}`
      );
      console.log(
        `${colors.blue}📱 Mobile: http://10.0.2.2:${PORT} (Android emulator)${colors.reset}`
      );
      console.log(
        `${colors.blue}🔄 Test: http://localhost:${PORT}/api/test${colors.reset}`
      );
      console.log(
        `${colors.blue}❤️ Health: http://localhost:${PORT}/api/health${colors.reset}`
      );
      console.log(
        `${colors.blue}💬 Socket: ws://localhost:${PORT}${colors.reset}`
      );
      console.log(`${colors.green}🚀 Ready to accept requests!${colors.reset}`);
    });

    // Initialize Socket.io
    initializeSocket(server);

  } catch (error) {
    console.error(
      `${colors.red}💥 Failed to start server:${colors.reset}`,
      error
    );
    process.exit(1);
  }
};

// Handle app termination
process.on("SIGINT", async () => {
  console.log(`${colors.yellow}🛑 Server shutting down...${colors.reset}`);
  const mongoose = require("mongoose");
  await mongoose.connection.close();
  console.log(`${colors.green}✅ MongoDB connection closed${colors.reset}`);
  console.log(`${colors.green}👋 Server stopped gracefully${colors.reset}`);
  process.exit(0);
});

// Start the server
startServer();