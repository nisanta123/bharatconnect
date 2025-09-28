import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'dart:convert'; // Import for jsonEncode and jsonDecode
import 'package:bharatconnect/models/chat_models.dart'; // Import Chat and Message models
import 'package:bharatconnect/models/search_models.dart'; // Import User model
import 'package:bharatconnect/models/status_model.dart'; // Import Status model
import 'package:bharatconnect/models/user_profile_model.dart'; // Import UserProfile model

class LocalDataStore {
  static Database? _database;
  static const String _databaseName = 'bharatconnect_app.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  static const String statusesTable = 'statuses';
  static const String decryptedMessagesTable = 'decrypted_messages'; // For decrypted content
  static const String usersTable = 'users'; // Add this line
  static const String chatRequestsTable = 'chat_requests'; // Chat requests table

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    debugPrint('LocalDataStore: Creating database tables.');
    // Chats table
    await db.execute(
      "CREATE TABLE $chatsTable("
      "id TEXT PRIMARY KEY,"
      "type TEXT,"
      "participants TEXT,"
      "participantInfo TEXT,"
      "lastMessage TEXT,"
      "updatedAt INTEGER,"
      "contactUserId TEXT,"
      "requestStatus TEXT,"
      "requesterId TEXT,"
      "acceptedTimestamp INTEGER,"
      "name TEXT,"
      "avatarUrl TEXT,"
      "typingStatus TEXT,"
      "chatSpecificPresence TEXT"
      ")",
    );

    // Messages table
    await db.execute(
      "CREATE TABLE $messagesTable("
      "id TEXT PRIMARY KEY,"
      "clientTempId TEXT,"
      "chatId TEXT,"
      "senderId TEXT,"
      "timestamp INTEGER,"
      "type TEXT,"
      "readBy TEXT,"
      "text TEXT,"
      "mediaInfo TEXT,"
      "error TEXT,"
      "iv TEXT,"
      "encryptedText TEXT,"
      "encryptedKeys TEXT,"
      "keyId TEXT"
      ")",
    );

    // Statuses table (simplified for now)
    await db.execute(
      "CREATE TABLE $statusesTable("
      "id TEXT PRIMARY KEY,"
      "userId TEXT,"
      "imageUrl TEXT,"
      "caption TEXT,"
      "timestamp INTEGER"
      ")",
    );

    // Decrypted messages table (for caching decrypted content)
    await db.execute(
      "CREATE TABLE $decryptedMessagesTable("
      "messageId TEXT PRIMARY KEY,"
      "decryptedText TEXT"
      ")",
    );

    // Users table
    await db.execute(
      "CREATE TABLE $usersTable("
      "id TEXT PRIMARY KEY,"
      "name TEXT,"
      "username TEXT,"
      "email TEXT,"
      "avatarUrl TEXT,"
      "currentAuraId TEXT,"
      "status TEXT,"
      "hasViewedStatus INTEGER,"
      "onboardingComplete INTEGER,"
      "bio TEXT"
      ")",
    );

    // Chat Requests table
    await db.execute(
      "CREATE TABLE $chatRequestsTable("
      "id TEXT PRIMARY KEY,"
      "senderId TEXT,"
      "receiverId TEXT,"
      "status TEXT,"
      "timestamp INTEGER"
      ")",
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('LocalDataStore: Upgrading database from version $oldVersion to $newVersion.');
    // Implement migration logic here if schema changes in future versions
  }

  // Generic insert/update method
  Future<void> insertOrUpdate(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('LocalDataStore: Inserted/Updated into $tableName: ${data['id'] ?? data['messageId']}');
  }

  // Generic retrieve method
  Future<List<Map<String, dynamic>>> retrieve(String tableName, {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    final db = await database;
    return await db.query(tableName, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  // Generic delete method
  Future<void> delete(String tableName, String idColumn, String idValue) async {
    final db = await database;
    await db.delete(
      tableName,
      where: '$idColumn = ?',
      whereArgs: [idValue],
    );
    debugPrint('LocalDataStore: Deleted from $tableName where $idColumn = $idValue');
  }

  // Specific methods for decrypted messages
  Future<void> saveDecryptedMessage(String messageId, String decryptedText) async {
    await insertOrUpdate(
      decryptedMessagesTable,
      {'messageId': messageId, 'decryptedText': decryptedText},
    );
  }

  Future<String?> getDecryptedMessage(String messageId) async {
    List<Map<String, dynamic>> results = await retrieve(
      decryptedMessagesTable,
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    if (results.isNotEmpty) {
      return results.first['decryptedText'] as String;
    }
    return null;
  }

  // Specific methods for Chat
  Future<void> saveChat(Chat chat) async {
    await insertOrUpdate(
      chatsTable,
      {
        'id': chat.id,
        'type': chat.type,
        'participants': jsonEncode(chat.participants),
        'participantInfo': jsonEncode(chat.participantInfo.map((key, value) => MapEntry(key, {
              'name': value.name,
              'avatarUrl': value.avatarUrl,
              'currentAuraId': value.currentAuraId,
              'hasActiveUnviewedStatus': value.hasActiveUnviewedStatus,
              'hasActiveViewedStatus': value.hasActiveViewedStatus,
            }))),
        'lastMessage': chat.lastMessage != null ? jsonEncode(chat.lastMessage!.toFirestoreMap()) : null,
        'updatedAt': chat.updatedAt,
        'contactUserId': chat.contactUserId,
        'requestStatus': chat.requestStatus?.toString(),
        'requesterId': chat.requesterId,
        'acceptedTimestamp': chat.acceptedTimestamp,
        'name': chat.name,
        'avatarUrl': chat.avatarUrl,
        'typingStatus': chat.typingStatus != null ? jsonEncode(chat.typingStatus) : null,
        'chatSpecificPresence': chat.chatSpecificPresence != null ? jsonEncode(chat.chatSpecificPresence!.map((key, value) => MapEntry(key, {
              'state': value.state,
              'lastChanged': value.lastChanged,
            }))) : null,
      },
    );
  }

  Future<Chat?> getChat(String chatId) async {
    List<Map<String, dynamic>> results = await retrieve(
      chatsTable,
      where: 'id = ?',
      whereArgs: [chatId],
    );
    if (results.isNotEmpty) {
      final data = results.first;
      return Chat(
        id: data['id'] as String,
        type: data['type'] as String,
        participants: List<String>.from(jsonDecode(data['participants'])),
        participantInfo: (jsonDecode(data['participantInfo']) as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, ParticipantInfo(
            name: value['name'] as String,
            avatarUrl: value['avatarUrl'] as String?,
            currentAuraId: value['currentAuraId'] as String?,
            hasActiveUnviewedStatus: value['hasActiveUnviewedStatus'] as bool? ?? false,
            hasActiveViewedStatus: value['hasActiveViewedStatus'] as bool? ?? false,
          )),
        ),
        lastMessage: data['lastMessage'] != null ? Message.fromFirestore(jsonDecode(data['lastMessage'])) : null, // Assuming fromFirestore can take a Map
        updatedAt: data['updatedAt'] as int,
        contactUserId: data['contactUserId'] as String?,
        requestStatus: data['requestStatus'] != null ? ChatRequestStatus.values.firstWhere((e) => e.toString() == data['requestStatus']) : null,
        requesterId: data['requesterId'] as String?,
        acceptedTimestamp: data['acceptedTimestamp'] as int?,
        name: data['name'] as String?,
        avatarUrl: data['avatarUrl'] as String?,
        typingStatus: data['typingStatus'] != null ? (jsonDecode(data['typingStatus']) as Map<String, dynamic>).map((key, value) => MapEntry(key, value as bool)) : null,
        chatSpecificPresence: data['chatSpecificPresence'] != null ? (jsonDecode(data['chatSpecificPresence']) as Map<String, dynamic>).map((key, value) => MapEntry(key, ChatSpecificPresence(
              state: value['state'] as String,
              lastChanged: value['lastChanged'] as int,
            ))) : null,
      );
    }
    return null;
  }

  Future<void> deleteChat(String chatId) async {
    await delete(chatsTable, 'id', chatId);
  }

  // Specific methods for Message
  Future<void> saveMessage(Message message) async {
    await insertOrUpdate(
      messagesTable,
      {
        'id': message.id,
        'clientTempId': message.clientTempId,
        'chatId': message.chatId,
        'senderId': message.senderId,
        'timestamp': message.timestamp,
        'type': message.type.toString(),
        'readBy': jsonEncode(message.readBy),
        'text': message.text,
        'mediaInfo': message.mediaInfo != null ? jsonEncode({
              'fileName': message.mediaInfo!.fileName,
              'fileType': message.mediaInfo!.fileType,
              'fileId': message.mediaInfo!.fileId,
              'thumbnailUrl': message.mediaInfo!.thumbnailUrl,
              'fileSize': message.mediaInfo!.fileSize,
            }) : null,
        'error': message.error,
        'iv': message.iv,
        'encryptedText': message.encryptedText,
        'encryptedKeys': message.encryptedKeys != null ? jsonEncode(message.encryptedKeys) : null,
        'keyId': message.keyId,
      },
    );
  }

  Future<Message?> getMessage(String messageId) async {
    List<Map<String, dynamic>> results = await retrieve(
      messagesTable,
      where: 'id = ?',
      whereArgs: [messageId],
    );
    if (results.isNotEmpty) {
      final data = results.first;
      return Message(
        id: data['id'] as String,
        clientTempId: data['clientTempId'] as String?,
        chatId: data['chatId'] as String,
        senderId: data['senderId'] as String,
        timestamp: data['timestamp'] as int,
        type: MessageType.values.firstWhere((e) => e.toString() == data['type']),
        readBy: List<String>.from(jsonDecode(data['readBy'])),
        text: data['text'] as String?,
        mediaInfo: data['mediaInfo'] != null ? MediaInfo(
              fileName: jsonDecode(data['mediaInfo'])['fileName'] as String,
              fileType: jsonDecode(data['mediaInfo'])['fileType'] as String,
              fileId: jsonDecode(data['mediaInfo'])['fileId'] as String,
              thumbnailUrl: jsonDecode(data['mediaInfo'])['thumbnailUrl'] as String?,
              fileSize: jsonDecode(data['mediaInfo'])['fileSize'] as int?,
            ) : null,
        error: data['error'] as String?,
        iv: data['iv'] as String?,
        encryptedText: data['encryptedText'] as String?,
        encryptedKeys: data['encryptedKeys'] != null ? jsonDecode(data['encryptedKeys']) as Map<String, dynamic> : null,
        keyId: data['keyId'] as String?,
      );
    }
    return null;
  }

  Future<List<Message>> getMessagesForChat(String chatId) async {
    List<Map<String, dynamic>> results = await retrieve(
      messagesTable,
      where: 'chatId = ?',
      whereArgs: [chatId],
      orderBy: 'timestamp ASC',
    );
    return results.map((data) => Message(
      id: data['id'] as String,
      clientTempId: data['clientTempId'] as String?,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      timestamp: data['timestamp'] as int,
      type: MessageType.values.firstWhere((e) => e.toString() == data['type']),
      readBy: List<String>.from(jsonDecode(data['readBy'])),
      text: data['text'] as String?,
      mediaInfo: data['mediaInfo'] != null ? MediaInfo(
            fileName: jsonDecode(data['mediaInfo'])['fileName'] as String,
            fileType: jsonDecode(data['mediaInfo'])['fileType'] as String,
            fileId: jsonDecode(data['mediaInfo'])['fileId'] as String,
            thumbnailUrl: jsonDecode(data['mediaInfo'])['thumbnailUrl'] as String?,
            fileSize: jsonDecode(data['mediaInfo'])['fileSize'] as int?,
          ) : null,
      error: data['error'] as String?,
      iv: data['iv'] as String?,
      encryptedText: data['encryptedText'] as String?,
      encryptedKeys: data['encryptedKeys'] != null ? jsonDecode(data['encryptedKeys']) as Map<String, dynamic> : null,
      keyId: data['keyId'] as String?,
    )).toList();
  }

  Future<void> deleteMessage(String messageId) async {
    await delete(messagesTable, 'id', messageId);
  }

  // Specific methods for User
  Future<void> saveUser(UserProfile user) async {
    await insertOrUpdate(
      usersTable,
      {
        'id': user.id,
        'name': user.displayName,
        'username': user.username,
        'email': user.email,
        'avatarUrl': user.avatarUrl,
        'currentAuraId': user.activeAuraId,
        'status': user.status, // Re-add status
        'onboardingComplete': user.onboardingComplete == true ? 1 : 0,
        'bio': user.bio,
      },
    );
  }

  Future<UserProfile?> getUser(String userId) async {
    List<Map<String, dynamic>> results = await retrieve(
      usersTable,
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (results.isNotEmpty) {
      final data = results.first;
      return UserProfile(
        id: data['id'] as String,
        email: data['email'] as String,
        displayName: data['name'] as String,
        username: data['username'] as String?,
        avatarUrl: data['avatarUrl'] as String?,
        activeAuraId: data['currentAuraId'] as String?,
        status: data['status'] as String?, // Re-add status
        onboardingComplete: (data['onboardingComplete'] as int) == 1 ? true : false,
        bio: data['bio'] as String?,
      );
    }
    return null;
  }

  Future<void> deleteUser(String userId) async {
    await delete(usersTable, 'id', userId);
  }

  // Specific methods for ChatRequest
  Future<void> saveChatRequest(ChatRequest request) async {
    await insertOrUpdate(
      chatRequestsTable,
      {
        'id': request.id,
        'senderId': request.senderId,
        'receiverId': request.receiverId,
        'status': request.status.toString(),
        'timestamp': request.timestamp.millisecondsSinceEpoch,
      },
    );
  }

  Future<ChatRequest?> getChatRequest(String requestId) async {
    List<Map<String, dynamic>> results = await retrieve(
      chatRequestsTable,
      where: 'id = ?',
      whereArgs: [requestId],
    );
    if (results.isNotEmpty) {
      final data = results.first;
      return ChatRequest.fromMap(data, data['id'] as String);
    }
    return null;
  }

  Future<void> deleteChatRequest(String requestId) async {
    await delete(chatRequestsTable, 'id', requestId);
  }

  // Specific methods for Status
  Future<void> saveStatus(Status status) async {
    await insertOrUpdate(
      statusesTable,
      {
        'id': status.id,
        'userId': status.userId,
        'text': status.text,
        'fontFamily': status.fontFamily,
        'backgroundColor': status.backgroundColor,
        'createdAt': status.createdAt.millisecondsSinceEpoch,
        'expiresAt': status.expiresAt.millisecondsSinceEpoch,
      },
    );
  }

  Future<Status?> getStatus(String statusId) async {
    List<Map<String, dynamic>> results = await retrieve(
      statusesTable,
      where: 'id = ?',
      whereArgs: [statusId],
    );
    if (results.isNotEmpty) {
      final data = results.first;
      return Status.fromMap(data, data['id'] as String);
    }
    return null;
  }

  Future<void> deleteStatus(String statusId) async {
    await delete(statusesTable, 'id', statusId);
  }

  // For development: Clear all chat-related tables
  Future<void> clearAllChatData() async {
    final db = await database;
    await db.delete(chatsTable);
    await db.delete(messagesTable);
    await db.delete(chatRequestsTable);
    debugPrint('LocalDataStore: Cleared all chat-related data.');
  }
}
