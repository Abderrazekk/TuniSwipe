const jwt = require('jsonwebtoken');

// Color codes for console logs
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
};

/**
 * Generate JWT token
 * @param {string} id - User ID
 * @param {string} role - User role (admin/user)
 * @param {string} email - User email
 * @returns {string} JWT token
 */
const generateToken = (id, role, email = '') => {
  const token = jwt.sign(
    { 
      id, 
      role,
      email 
    }, 
    process.env.JWT_SECRET, 
    { 
      expiresIn: '30d' 
    }
  );
  
  console.log(`${colors.blue}🔐 Token generated for: ${email} (${role})${colors.reset}`);
  console.log(`${colors.green}🆔 User ID: ${id}${colors.reset}`);
  
  return token;
};

/**
 * Verify JWT token
 * @param {string} token - JWT token to verify
 * @returns {Object} Decoded token payload
 */
const verifyToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    console.log(`${colors.green}✅ Token verified for: ${decoded.email}${colors.reset}`);
    return decoded;
  } catch (error) {
    console.error(`${colors.red}❌ Token verification failed:${colors.reset}`, error.message);
    throw new Error('Invalid token');
  }
};

module.exports = {
  generateToken,
  verifyToken
};