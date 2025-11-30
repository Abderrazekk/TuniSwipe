const mongoose = require('mongoose');

// Color codes for console logs
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
};

const connectDB = async () => {
  try {
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/TCCnew';
    
    console.log(`${colors.yellow}📡 Connecting to MongoDB...${colors.reset}`);
    
    const conn = await mongoose.connect(MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log(`${colors.green}✅ MongoDB Connected: ${conn.connection.host}${colors.reset}`);
    console.log(`${colors.green}📊 Database: ${conn.connection.name}${colors.reset}`);
    
    return conn;
  } catch (error) {
    console.error(`${colors.red}❌ MongoDB connection error:${colors.reset}`, error.message);
    process.exit(1);
  }
};

// MongoDB event handlers
mongoose.connection.on('connected', () => {
  console.log(`${colors.green}✅ MongoDB connected successfully${colors.reset}`);
});

mongoose.connection.on('error', (err) => {
  console.error(`${colors.red}❌ MongoDB connection error:${colors.reset}`, err);
});

mongoose.connection.on('disconnected', () => {
  console.log(`${colors.yellow}⚠️ MongoDB disconnected${colors.reset}`);
});

module.exports = connectDB;