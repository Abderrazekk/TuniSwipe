const Message = require("../models/Message");
const User = require("../models/User");
const Swipe = require("../models/Swipe");
const mongoose = require("mongoose");

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
};

/**
 * Get user's chat conversations list (including matches without messages)
 */
const getChatConversations = async (req, res) => {
  try {
    const currentUserId = req.user._id;

    console.log(
      `${colors.blue}💬 Conversations list requested for: ${currentUserId}${colors.reset}`
    );

    // Get message-based conversations
    const messageConversations = await Message.aggregate([
      {
        $match: {
          $or: [
            { sender: new mongoose.Types.ObjectId(currentUserId) },
            { receiver: new mongoose.Types.ObjectId(currentUserId) }
          ]
        }
      },
      {
        $sort: { createdAt: -1 }
      },
      {
        $group: {
          _id: "$roomId",
          lastMessage: { $first: "$$ROOT" },
          unreadCount: {
            $sum: {
              $cond: [
                { 
                  $and: [
                    { $eq: ["$receiver", new mongoose.Types.ObjectId(currentUserId)] },
                    { $eq: ["$isRead", false] }
                  ]
                },
                1,
                0
              ]
            }
          }
        }
      },
      {
        $lookup: {
          from: "users",
          localField: "lastMessage.sender",
          foreignField: "_id",
          as: "senderInfo"
        }
      },
      {
        $lookup: {
          from: "users",
          localField: "lastMessage.receiver",
          foreignField: "_id",
          as: "receiverInfo"
        }
      },
      {
        $project: {
          roomId: "$_id",
          lastMessage: 1,
          unreadCount: 1,
          otherUser: {
            $cond: [
              { 
                $eq: [
                  { $arrayElemAt: ["$senderInfo._id", 0] }, 
                  new mongoose.Types.ObjectId(currentUserId)
                ] 
              },
              { $arrayElemAt: ["$receiverInfo", 0] },
              { $arrayElemAt: ["$senderInfo", 0] }
            ]
          }
        }
      },
      {
        $project: {
          "otherUser.password": 0,
          "otherUser.email": 0
        }
      }
    ]);

    console.log(
      `${colors.yellow}📋 Found ${messageConversations.length} message-based conversations${colors.reset}`
    );

    // Get mutual matches using a simpler approach
    const mutualSwipes = await Swipe.find({
      $or: [
        { swiper: currentUserId, action: "like" },
        { swiped: currentUserId, action: "like" }
      ]
    });

    console.log(
      `${colors.yellow}🔍 Found ${mutualSwipes.length} total swipes involving current user${colors.reset}`
    );

    // Find mutual matches manually
    const mutualMatchUserIds = new Set();
    
    // Group swipes by target user
    const userSwipes = {};
    mutualSwipes.forEach(swipe => {
      const otherUserId = swipe.swiper.toString() === currentUserId.toString() 
        ? swipe.swiped.toString() 
        : swipe.swiper.toString();
      
      if (!userSwipes[otherUserId]) {
        userSwipes[otherUserId] = { likedByMe: false, likedMe: false };
      }
      
      if (swipe.swiper.toString() === currentUserId.toString()) {
        userSwipes[otherUserId].likedByMe = true;
      } else {
        userSwipes[otherUserId].likedMe = true;
      }
    });

    // Find users where both liked each other
    Object.keys(userSwipes).forEach(userId => {
      if (userSwipes[userId].likedByMe && userSwipes[userId].likedMe) {
        mutualMatchUserIds.add(userId);
      }
    });

    console.log(
      `${colors.yellow}🤝 Found ${mutualMatchUserIds.size} mutual matches${colors.reset}`
    );

    // Get user details for mutual matches
    const mutualMatches = [];
    for (const userId of mutualMatchUserIds) {
      try {
        const user = await User.findById(userId).select("-password -email");
        if (user) {
          // Create roomId (same logic as Message model)
          const sortedIds = [currentUserId.toString(), userId].sort();
          const roomId = `chat_${sortedIds[0]}_${sortedIds[1]}`;
          
          // Check if this match already has messages
          const hasMessages = messageConversations.some(conv => conv.roomId === roomId);
          
          if (!hasMessages) {
            // Get user media for main photo
            const userWithMedia = await User.findById(userId).select("media");
            const userObj = user.toObject();
            userObj.mainPhoto = 
              userWithMedia.media && userWithMedia.media.length > 0 
                ? userWithMedia.media[0].filename 
                : user.photo;
            
            mutualMatches.push({
              roomId,
              otherUser: userObj,
              lastMessage: null,
              unreadCount: 0,
              isMatchWithoutMessages: true
            });
          }
        }
      } catch (error) {
        console.log(`${colors.red}❌ Error processing user ${userId}: ${error.message}${colors.reset}`);
      }
    }

    console.log(
      `${colors.yellow}✅ Processed ${mutualMatches.length} matches without messages${colors.reset}`
    );

    // Combine message conversations and mutual matches
    const allConversations = [...messageConversations, ...mutualMatches];

    // Sort by last message date or match date
    allConversations.sort((a, b) => {
      const dateA = a.lastMessage ? new Date(a.lastMessage.createdAt) : new Date();
      const dateB = b.lastMessage ? new Date(b.lastMessage.createdAt) : new Date();
      return dateB - dateA; // Most recent first
    });

    console.log(
      `${colors.green}✅ Total conversations: ${allConversations.length} (${messageConversations.length} with messages + ${mutualMatches.length} matches without messages)${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        conversations: allConversations
      },
      message: "Conversations retrieved successfully"
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Conversations error:${colors.reset}`,
      error.message
    );
    console.error(error.stack);
    res.status(500).json({
      success: false,
      message: "Error retrieving conversations",
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

/**
 * Get chat history between two users
 */
const getChatHistory = async (req, res) => {
  try {
    const { otherUserId } = req.params;
    const currentUserId = req.user._id;

    console.log(
      `${colors.blue}💬 Chat history requested: ${currentUserId} ↔ ${otherUserId}${colors.reset}`
    );

    // Create roomId using the same logic as before
    const sortedIds = [currentUserId.toString(), otherUserId].sort();
    const roomId = `chat_${sortedIds[0]}_${sortedIds[1]}`;

    // Get messages with pagination
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 50;
    const skip = (page - 1) * limit;

    const messages = await Message.find({ roomId })
      .populate("sender", "name photo")
      .populate("receiver", "name photo")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    // Mark messages as read
    await Message.updateMany(
      {
        roomId,
        receiver: currentUserId,
        isRead: false
      },
      {
        $set: {
          isRead: true,
          readAt: new Date()
        }
      }
    );

    console.log(
      `${colors.green}✅ Chat history retrieved: ${messages.length} messages${colors.reset}`
    );

    res.json({
      success: true,
      data: {
        messages: messages.reverse(), // Reverse to get chronological order
        roomId,
        currentPage: page,
        hasMore: messages.length === limit
      },
      message: "Chat history retrieved successfully"
    });
  } catch (error) {
    console.error(
      `${colors.red}💥 Chat history error:${colors.reset}`,
      error.message
    );
    res.status(500).json({
      success: false,
      message: "Error retrieving chat history"
    });
  }
};

module.exports = {
  getChatHistory,
  getChatConversations
};