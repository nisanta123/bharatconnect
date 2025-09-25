import 'package:flutter/material.dart';
import 'package:bharatconnect/models/chat_models.dart';
import 'package:bharatconnect/models/search_models.dart'; // For User model
import 'package:bharatconnect/widgets/chat/chat_page_header.dart';
import 'package:bharatconnect/widgets/chat/message_area.dart';
import 'package:bharatconnect/widgets/chat/chat_input_zone.dart';
import 'package:bharatconnect/widgets/chat/chat_request_display.dart';
import 'package:bharatconnect/widgets/chat/emoji_picker.dart';
import 'package:bharatconnect/widgets/chat/encrypted_chat_banner.dart';

const double EMOJI_PICKER_HEIGHT_PX = 300.0;

// Mock AURA_OPTIONS for now
const List<UserAura> AURA_OPTIONS = [
  UserAura(id: 'aura1', name: 'Fire', iconUrl: '🔥', primaryColor: Colors.red, secondaryColor: Colors.deepOrange),
  UserAura(id: 'aura2', name: 'Water', iconUrl: '💧', primaryColor: Colors.blue, secondaryColor: Colors.lightBlue),
  UserAura(id: 'aura3', name: 'Earth', iconUrl: '🌳', primaryColor: Colors.green, secondaryColor: Colors.lightGreen),
];

// Placeholder for generateChatId
String generateChatId(String uid1, String uid2) {
  if (uid1.compareTo(uid2) < 0) {
    return '${uid1}_${uid2}';
  } else {
    return '${uid2}_${uid1}';
  }
}

// Placeholder for timestampToMillisSafe
int timestampToMillisSafe(dynamic timestamp, {int? defaultTimestamp}) {
  if (timestamp is int) {
    return timestamp;
  }
  // For now, just return current time or default if not int
  return defaultTimestamp ?? DateTime.now().millisecondsSinceEpoch;
}

// Placeholder for encryption services
Future<Map<String, dynamic>> encryptMessage(String text, List<String> recipientIds, String senderId) async {
  return {
    'encryptedText': 'encrypted($text)',
    'keyId': 'mockKeyId',
    'iv': 'mockIv',
    'encryptedKeys': {},
  };
}

Future<String> decryptMessage(Map<String, dynamic> messageData, String currentUserId) async {
  return messageData['encryptedText']?.toString().replaceFirst('encrypted(', '').replaceFirst(')', '') ?? 'Decrypted message';
}

bool hasLocalKeys(String userId) => true; // Mock implementation

Future<Map<String, dynamic>> encryptAndUploadChunks(dynamic file, String chatId, String senderId, List<String> recipientIds, Function(double) onProgress) async {
  return {
    'mediaInfo': MediaInfo(fileName: 'mock_image.jpg', fileType: 'image/jpeg', fileId: 'mockFileId'),
    'encryptedAesKey': {},
    'keyId': 'mockKeyId',
  };
}

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock Auth and Chat Context values
  final User _authUser = User(id: 'currentUserId', name: 'You', avatarUrl: null);
  final bool _isAuthenticated = true;
  final bool _isAuthLoading = false;

  // Mock Chat Context Hook
  final List<Chat> _mockContextChats = []; // You can populate this with mock chats if needed
  Chat? _getChatById(String id) => null; // Placeholder

  // Page State
  bool _isPageLoading = true;
  bool _isChatReady = false;
  String? _effectiveChatId;
  Chat? _chatDetails;
  User? _contact;
  List<Message> _messages = [];
  String _newMessage = '';
  bool _isEmojiPickerOpen = false;
  dynamic _fileToSend; // Placeholder for File
  String? _filePreviewUrl;
  bool _isProcessingRequestAction = false;
  UserAura? _contactActiveAura;
  bool _isContactTyping = false;
  ChatSpecificPresence? _contactPresence;
  bool? _localKeysExist;

  @override
  void initState() {
    super.initState();
    _localKeysExist = hasLocalKeys(_authUser.id);
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_filePreviewUrl != null) {
      // URL.revokeObjectURL(_filePreviewUrl!); // Not applicable in Flutter
    }
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isPageLoading = true;
      _isChatReady = false;
    });

    String determinedChatId = widget.chatId;
    User? contactUserForChat;

    // Mock logic for determining contact and chat ID
    if (widget.chatId.startsWith('req_')) {
      final contactIdFromRequestRoute = widget.chatId.split('_').last;
      contactUserForChat = User(id: contactIdFromRequestRoute, name: 'Mock Contact', avatarUrl: null);
      determinedChatId = generateChatId(_authUser.id, contactIdFromRequestRoute);
    } else {
      final contactIdFromStandardChatId = widget.chatId.split('_').firstWhere((id) => id != _authUser.id, orElse: () => '');
      contactUserForChat = User(id: contactIdFromStandardChatId, name: 'Mock Contact', avatarUrl: null);
      determinedChatId = widget.chatId;
    }

    setState(() {
      _contact = contactUserForChat;
      _effectiveChatId = determinedChatId;
      _isChatReady = true;
      _isPageLoading = false;
      // Mock chat details
      _chatDetails = Chat(
        id: determinedChatId,
        type: 'individual',
        participants: [_authUser.id, _contact!.id],
        participantInfo: {
          _authUser.id: ParticipantInfo(name: _authUser.name, avatarUrl: _authUser.avatarUrl),
          _contact!.id: ParticipantInfo(name: _contact!.name, avatarUrl: _contact!.avatarUrl),
        },
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        requestStatus: ChatRequestStatus.accepted,
      );
      _messages = [
        Message(id: '1', chatId: determinedChatId, senderId: _contact!.id, timestamp: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch, type: MessageType.text, readBy: [_authUser.id], text: 'Hi there!'),
        Message(id: '2', chatId: determinedChatId, senderId: _authUser.id, timestamp: DateTime.now().subtract(const Duration(minutes: 2)).millisecondsSinceEpoch, type: MessageType.text, readBy: [_contact!.id, _authUser.id], text: 'Hello!'),
      ];
    });
  }

  void _onNewMessageChange(String value) {
    setState(() {
      _newMessage = value;
    });
  }

  void _onSendMessage() {
    if (_newMessage.trim().isEmpty && _fileToSend == null) return;

    final messageText = _newMessage.trim();
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();

    final newMessageObject = Message(
      id: messageId,
      chatId: _effectiveChatId!,
      senderId: _authUser.id,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: MessageType.text,
      readBy: [_authUser.id],
      text: messageText,
    );

    debugPrint('Sending message: ${newMessageObject.text}'); // Debug print

    setState(() {
      _messages = List.from(_messages)..add(newMessageObject); // Create a new list instance
      _newMessage = '';
      _fileToSend = null;
      _filePreviewUrl = null;
    });

    _messageController.clear(); // Explicitly clear the text field

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onToggleEmojiPicker() {
    setState(() {
      _isEmojiPickerOpen = !_isEmojiPickerOpen;
    });
  }

  void _onFileSelect(dynamic file) {
    // Placeholder for file selection logic
    setState(() {
      _fileToSend = file;
      _filePreviewUrl = 'https://via.placeholder.com/150'; // Mock preview URL
    });
  }

  void _onClearFileSelection() {
    setState(() {
      _fileToSend = null;
      _filePreviewUrl = null;
    });
  }

  void _handleEmojiSelect(String emoji) {
    setState(() {
      _newMessage += emoji;
    });
  }

  void _handleAcceptRequest() {
    setState(() {
      _chatDetails = _chatDetails?.copyWith(requestStatus: ChatRequestStatus.accepted);
    });
    print('Request accepted');
  }

  void _handleRejectRequest() {
    setState(() {
      _chatDetails = _chatDetails?.copyWith(requestStatus: ChatRequestStatus.rejected);
    });
    print('Request rejected');
  }

  void _handleCancelRequest() {
    setState(() {
      _chatDetails = _chatDetails?.copyWith(requestStatus: ChatRequestStatus.rejected);
    });
    print('Request cancelled');
  }

  String _getDynamicStatus() {
    if (_contact == null) return "Offline";
    if (_isContactTyping) return "Typing...";
    if (_contactPresence?.state == 'online') return 'online';
    return 'Offline'; // Simplified for mock
  }

  @override
  Widget build(BuildContext context) {
    final isChatActive = _chatDetails?.requestStatus == ChatRequestStatus.accepted || (_chatDetails?.requestStatus == null || _chatDetails?.requestStatus == ChatRequestStatus.none);
    final showRequestSpecificUI = _chatDetails?.requestStatus != null &&
        (_chatDetails!.requestStatus == ChatRequestStatus.awaiting_action ||
            _chatDetails!.requestStatus == ChatRequestStatus.pending ||
            _chatDetails!.requestStatus == ChatRequestStatus.rejected);

    if (_isAuthLoading || _isPageLoading || _localKeysExist == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading Chat...'),
            ],
          ),
        ),
      );
    }

    if (!_isAuthenticated && !_isAuthLoading) {
      return const Scaffold(
        body: Center(
          child: Text('Redirecting...'),
        ),
      );
    }

    if (widget.chatId.isEmpty || ((_chatDetails == null && !_isChatReady) || (_contact == null && (isChatActive || showRequestSpecificUI )))) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat Not Found')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.message, size: 60, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text(
                    'Chat Not Found',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The chat (ID: ${widget.chatId}) could not be loaded.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Go to Chats
                    },
                    child: const Text('Go to Chats'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final showInputArea = _localKeysExist == true && isChatActive;

    final contactStatusText = _getDynamicStatus();
    final headerContactName = _contact?.name ?? _chatDetails?.name ?? 'Chat';
    final headerContactAvatar = _contact?.avatarUrl ?? _chatDetails?.avatarUrl;

    return Scaffold(
      appBar: ChatPageHeader(
        contactName: headerContactName,
        contactId: _contact?.id,
        contactAvatarUrl: headerContactAvatar,
        contactStatusText: contactStatusText,
        isChatActive: isChatActive,
        onMoreOptionsClick: () {
          print('More options clicked');
        },
      ),
      body: Column(
        children: [
          if (_localKeysExist == false && isChatActive) const EncryptedChatBanner(),
          if (showRequestSpecificUI && _chatDetails != null && _contact != null && _authUser.id != null)
            ChatRequestDisplay(
              chatDetails: _chatDetails!,
              contact: _contact!,
              currentUserId: _authUser.id,
              onAcceptRequest: _handleAcceptRequest,
              onRejectRequest: _handleRejectRequest,
              onCancelRequest: _handleCancelRequest,
              isProcessing: _isProcessingRequestAction,
            )
          else ...[
            MessageArea(
              messages: _messages,
              currentUserId: _authUser.id,
              contactId: _contact?.id,
              dynamicPaddingBottom: _isEmojiPickerOpen ? EMOJI_PICKER_HEIGHT_PX : 0.0, // Simplified dynamic padding
              isContactTyping: _isContactTyping,
              scrollController: _scrollController,
            ),
            if (showInputArea)
              ChatInputZone(
                newMessage: _newMessage,
                onNewMessageChange: _onNewMessageChange,
                onSendMessage: _onSendMessage,
                onToggleEmojiPicker: _onToggleEmojiPicker,
                isEmojiPickerOpen: _isEmojiPickerOpen,
                onFileSelect: _onFileSelect,
                textareaRef: _messageController, // Pass controller
                isDisabled: !_isChatReady || !isChatActive,
                filePreviewUrl: _filePreviewUrl,
                onClearFileSelection: _onClearFileSelection,
              ),
            if (showInputArea && _isEmojiPickerOpen)
              SizedBox(
                height: EMOJI_PICKER_HEIGHT_PX,
                child: EmojiPicker(onEmojiSelect: _handleEmojiSelect),
              ),
          ],
        ],
      ),
    );
  }
}
