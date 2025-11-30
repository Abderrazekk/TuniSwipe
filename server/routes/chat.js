const express = require("express");
const { authenticate } = require("../middleware/auth");
const { getChatHistory, getChatConversations } = require("../controllers/chatController");

const router = express.Router();

// Protected chat routes
router.get("/conversations", authenticate, getChatConversations);
router.get("/history/:otherUserId", authenticate, getChatHistory);

module.exports = router;