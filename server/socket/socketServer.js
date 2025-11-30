const socketIO = require("socket.io");
const jwt = require("jsonwebtoken");
const User = require("../models/User");
const Admin = require("../models/Admin");
const Message = require("../models/Message");

// Color codes for console logs
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  red: "\x1b[31m",
};

// Store online users
const onlineUsers = new Map();

const initializeSocket = (server) => {
  const io = socketIO(server, {
    cors: {
      origin: ["http://localhost:3000", "http://10.0.2.2:3000", "http://127.0.0.1:3000"],
      methods: ["GET", "POST"]
    }
  });

  // Authentication middleware for sockets
  io.use(async (socket, next) => {
    try {
      // Check both auth object and query parameters for token
      let token = socket.handshake.auth.token;
      
      if (!token) {
        // Try to get token from query parameters
        token = socket.handshake.query.token;
        console.log(`${colors.yellow}⚠️ Token not in auth, checking query: ${token ? 'Found' : 'Not found'}${colors.reset}`);
      }

      if (!token) {
        console.log(`${colors.red}❌ Socket connection rejected: No token provided${colors.reset}`);
        return next(new Error("Authentication error: No token provided"));
      }

      // Verify token
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      
      // Find user
      let user;
      if (decoded.role === "admin") {
        user = await Admin.findById(decoded.id).select("-password");
      } else {
        user = await User.findById(decoded.id).select("-password");
      }

      if (!user) {
        console.log(`${colors.red}❌ Socket authentication failed: User not found${colors.reset}`);
        return next(new Error("User not found"));
      }

      // Add user to socket
      socket.userId = user._id.toString();
      socket.user = user;

      console.log(
        `${colors.green}✅ Socket authentication successful: ${user.email} (${user.role})${colors.reset}`
      );
      next();
      
    } catch (error) {
      console.error(
        `${colors.red}❌ Socket authentication error:${colors.reset}`,
        error.message
      );
      
      if (error.name === 'JsonWebTokenError') {
        return next(new Error("Invalid token"));
      } else if (error.name === 'TokenExpiredError') {
        return next(new Error("Token expired"));
      }
      
      next(new Error("Authentication failed"));
    }
  });

  io.on("connection", (socket) => {
    console.log(
      `${colors.green}✅ User connected: ${socket.user.name} (${socket.userId})${colors.reset}`
    );

    // Add user to online users
    onlineUsers.set(socket.userId, {
      socketId: socket.id,
      user: socket.user,
      lastSeen: new Date()
    });

    // Join user's personal room for notifications
    socket.join(socket.userId);

    // Handle joining chat room
    socket.on("join_chat_room", (otherUserId) => {
      const roomId = Message.getRoomId(socket.userId, otherUserId);
      socket.join(roomId);
      console.log(
        `${colors.blue}🚪 User ${socket.userId} joined room: ${roomId}${colors.reset}`
      );
    });

    // Handle sending message
    socket.on("send_message", async (data) => {
      try {
        const { receiverId, message, messageType = "text" } = data;
        
        console.log(
          `${colors.blue}📨 Message from ${socket.userId} to ${receiverId}: ${message}${colors.reset}`
        );

        const roomId = Message.getRoomId(socket.userId, receiverId);

        // Save message to database
        const newMessage = new Message({
          roomId,
          sender: socket.userId,
          receiver: receiverId,
          message,
          messageType
        });

        await newMessage.save();

        // Populate sender info for the response
        await newMessage.populate("sender", "name photo");
        await newMessage.populate("receiver", "name photo");

        // Emit to the room
        io.to(roomId).emit("new_message", {
          success: true,
          data: newMessage
        });

        // Notify receiver if online
        const receiverOnline = onlineUsers.get(receiverId);
        if (receiverOnline) {
          io.to(receiverId).emit("message_notification", {
            message: newMessage,
            unreadCount: 1
          });
        }

        console.log(
          `${colors.green}✅ Message delivered to room: ${roomId}${colors.reset}`
        );

      } catch (error) {
        console.error(
          `${colors.red}💥 Send message error:${colors.reset}`,
          error.message
        );
        socket.emit("message_error", {
          success: false,
          message: "Failed to send message"
        });
      }
    });

    // Handle message read receipt
    socket.on("mark_messages_read", async (data) => {
      try {
        const { roomId } = data;
        
        await Message.updateMany(
          {
            roomId,
            receiver: socket.userId,
            isRead: false
          },
          {
            $set: {
              isRead: true,
              readAt: new Date()
            }
          }
        );

        // Notify the other user that messages were read
        socket.to(roomId).emit("messages_read", {
          roomId,
          readerId: socket.userId
        });

        console.log(
          `${colors.green}✅ Messages marked as read in room: ${roomId}${colors.reset}`
        );

      } catch (error) {
        console.error(
          `${colors.red}💥 Mark read error:${colors.reset}`,
          error.message
        );
      }
    });

    // Handle typing indicators
    socket.on("typing_start", (data) => {
      const { roomId } = data;
      socket.to(roomId).emit("user_typing", {
        userId: socket.userId,
        userName: socket.user.name,
        isTyping: true
      });
    });

    socket.on("typing_stop", (data) => {
      const { roomId } = data;
      socket.to(roomId).emit("user_typing", {
        userId: socket.userId,
        userName: socket.user.name,
        isTyping: false
      });
    });

    // Handle user online status
    socket.on("user_online", () => {
      onlineUsers.set(socket.userId, {
        socketId: socket.id,
        user: socket.user,
        lastSeen: new Date(),
        isOnline: true
      });

      // Notify user's matches that they're online
      socket.broadcast.emit("user_status_changed", {
        userId: socket.userId,
        isOnline: true
      });
    });

    // Handle disconnect
    socket.on("disconnect", (reason) => {
      console.log(
        `${colors.yellow}⚠️ User disconnected: ${socket.user.name} (${reason})${colors.reset}`
      );

      // Update user status to offline
      onlineUsers.set(socket.userId, {
        ...onlineUsers.get(socket.userId),
        isOnline: false,
        lastSeen: new Date()
      });

      // Notify user's matches that they're offline
      socket.broadcast.emit("user_status_changed", {
        userId: socket.userId,
        isOnline: false,
        lastSeen: new Date()
      });
    });

    // Handle connection error
    socket.on("error", (error) => {
      console.error(
        `${colors.red}💥 Socket error for ${socket.user.name}:${colors.reset}`,
        error
      );
    });
  });

  return io;
};

module.exports = {
  initializeSocket,
  onlineUsers
};