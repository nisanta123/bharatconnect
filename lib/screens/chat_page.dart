import 'package:flutter/material.dart';
import 'package:bharatconnect/models/chat_models.dart';
import 'package:bharatconnect/models/search_models.dart';
import 'package:bharatconnect/widgets/chat/chat_page_header.dart';
import 'package:bharatconnect/widgets/chat/message_area.dart';
import 'package:bharatconnect/widgets/chat/chat_input_zone.dart';
import 'package:bharatconnect/widgets/chat/chat_request_display.dart';
import 'package:bharatconnect/widgets/chat/emoji_picker.dart';
import 'package:bharatconnect/widgets/chat/encrypted_chat_banner.dart';
import 'package:bharatconnect/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:bharatconnect/models/user_profile_model.dart';
import 'package:bharatconnect/services/encryption_service.dart';
import 'package:bharatconnect/services/aura_service.dart'; // Import AuraService
import 'package:bharatconnect/models/aura_models.dart'; // Import UserAura from aura_models.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bharatconnect/widgets/chat/emoji_manager.dart'; // Import EmojiManager

const double EMOJI_PICKER_HEIGHT_PX = 250.0;

class ChatPage extends StatefulWidget {
  final String chatId;
  final UserProfile? currentUserProfile;

  const ChatPage({Key? key, required this.chatId, this.currentUserProfile}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver { // Add WidgetsBindingObserver
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode(); // Declare FocusNode

  final UserService _userService = UserService(); // Initialize UserService
  final EncryptionService _encryptionService = EncryptionService(); // Instantiate EncryptionService
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Initialize Firestore
  final AuraService _auraService = AuraService(); // Instantiate AuraService

  User? _authUser; // Will be set from currentUserProfile
  bool _isAuthenticated = false;
  bool _isAuthLoading = true;

  // Page State
  bool _isPageLoading = true;
  bool _isChatReady = false;
  String? _effectiveChatId;
  Chat? _chatDetails;
  UserProfile? _contact;
  List<Message> _messages = [];
  String _newMessage = '';
  late EmojiManager _emojiManager; // Declare EmojiManager
  dynamic _fileToSend; // Placeholder for File
  String? _filePreviewUrl;
  bool _isProcessingRequestAction = false;
  UserAura? _contactActiveAura;
  bool _isContactTyping = false;
  ChatSpecificPresence? _contactPresence;
  bool? _localKeysExist;
  List<StreamSubscription> _requestSubscriptions = [];
  bool _showEncryptionBanner = true; // Add this line

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _emojiManager = EmojiManager(_messageFocusNode); // Initialize EmojiManager

    _messageFocusNode.addListener(() {
      if (_messageFocusNode.hasFocus && _emojiManager.isEmojiOpen) {
        setState(() {
          _emojiManager.isEmojiOpen = false;
        });
      }
    });

    // Automatically request focus on the message input when the chat page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _messageFocusNode.requestFocus();
    });

    if (widget.currentUserProfile != null) {
      _authUser = User(
        id: widget.currentUserProfile!.id,
        name: widget.currentUserProfile!.displayName ?? widget.currentUserProfile!.username ?? '',
        avatarUrl: widget.currentUserProfile!.avatarUrl,
      );
      _isAuthenticated = true;
    }
    _isAuthLoading = false; // Set to false after auth check
    // _localKeysExist = hasLocalKeys(_authUser!.id); // This will be handled by EncryptionService
    _initializeChat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose(); // Dispose FocusNode
    for (var subscription in _requestSubscriptions) {
      subscription.cancel();
    }
    // _filePreviewUrl is just a string, no need to revoke in Flutter
    super.dispose();
  }

  // Removed didChangeMetrics as it's no longer needed with reverse: true

  Future<void> _initializeChat() async {
    setState(() {
      _isPageLoading = true;
      _isChatReady = false;
    });

    if (_authUser == null) {
      // Handle case where _authUser is not set (e.g., not logged in)
      setState(() {
        _isPageLoading = false;
      });
      return;
    }

    try {
      // Check for local keys and generate if not present
      _localKeysExist = await _encryptionService.hasLocalKeys(_authUser!.id);
      if (!(_localKeysExist ?? false)) {
        await _encryptionService.generateAndStoreKeys(_authUser!.id);
        _localKeysExist = true; // Keys are now generated
      }

      // Fetch chat details
      final chatStream = _userService.streamUserChats(_authUser!.id).map((chats) {
        return chats.firstWhere((chat) => chat.id == widget.chatId, orElse: () => throw Exception('Chat not found'));
      });

      _requestSubscriptions.add(chatStream.listen((chat) async {
        setState(() {
          _chatDetails = chat;
          _effectiveChatId = chat.id;
        });

        // Determine the other participant
        final otherParticipantId = chat.participants.firstWhere(
          (id) => id != _authUser!.id,
          orElse: () => 'Unknown',
        );

        // Fetch contact user details
        final contactUser = await _userService.getUserById(otherParticipantId);
        setState(() {
          _contact = contactUser;
          _isChatReady = true;
          _isPageLoading = false;
        });

        // Stream contact's active aura
        _requestSubscriptions.add(
          _auraService.getConnectedUsersAuras([otherParticipantId]).listen((auras) {
            if (auras.isNotEmpty) {
              setState(() {
                _contactActiveAura = auras.first.auraStyle; // Assuming DisplayAura has an auraStyle property
              });
            } else {
              setState(() {
                _contactActiveAura = null;
              });
            }
          }),
        );

        // Stream messages for the chat
        _requestSubscriptions.add(
          _userService.streamChatMessages(chat.id).listen((firestoreMessages) {
            setState(() {
              final Map<String, Message> finalMessagesMap = {};

              // 1. Add all confirmed Firestore messages to the map.
              // These are the authoritative versions, and their status should be 'sent'.
              for (var firestoreMsg in firestoreMessages) {
                finalMessagesMap[firestoreMsg.id] = firestoreMsg.copyWith(status: MessageStatus.sent);
              }

              // 2. Iterate through the *current* _messages list to preserve unconfirmed local messages.
              for (var localMsg in _messages) {
                if (localMsg.status == MessageStatus.sending || localMsg.status == MessageStatus.failed) {
                  // Check if this local message has been confirmed by a Firestore message.
                  // A Firestore message confirms a local one if it has the same clientTempId.
                  final bool isConfirmedByFirestore = firestoreMessages.any(
                    (fm) => localMsg.clientTempId != null && fm.clientTempId == localMsg.clientTempId,
                  );

                  if (!isConfirmedByFirestore) {
                    // If the local sending/failed message is NOT yet confirmed by Firestore,
                    // keep it in the map. Use clientTempId as key to avoid conflicts with actual IDs.
                    finalMessagesMap[localMsg.clientTempId!] = localMsg;
                  }
                }
              }

              // 3. Convert map values back to a list and sort by timestamp ascending.
              final List<Message> newMessagesList = finalMessagesMap.values.toList()
                ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort descending (newest first) for reversed list

              // Determine if a new message was added to trigger scroll
              // final bool shouldScrollToBottom = _messages.length < newMessagesList.length; // No longer needed

              _messages = newMessagesList;

              if (_messages.isNotEmpty) _showEncryptionBanner = false;

              // Handle initial load scroll (no explicit scroll needed with reverse: true)
              if (_isPageLoading) {
                _isPageLoading = false;
                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   Future.delayed(const Duration(milliseconds: 250), () {
                //     _scrollToBottom(animated: false); // Instant scroll on initial load
                //   });
                // });
              }
              // else if (shouldScrollToBottom) {
              //   _scrollToBottom(animated: true);
              // }
            });
          }),
        );
      }));
    } catch (e) {
      print('Error initializing chat: $e');
      setState(() {
        _isPageLoading = false;
        _isChatReady = false;
      });
    }
  }

  void _onNewMessageChange(String value) {
    setState(() {
      _newMessage = value;
    });
  }

  void _onSendMessage() async {
    if (_newMessage.trim().isEmpty && _fileToSend == null) return;
    if (_effectiveChatId == null || _authUser == null || _contact == null) return; // Ensure chat, user, and contact are ready

    final messageText = _newMessage.trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempId = 'local_$timestamp'; // Temporary ID for local tracking

    // 1️⃣ Create local message (optimistic UI)
    final tempMessage = Message(
      id: tempId,
      clientTempId: tempId,
      chatId: _effectiveChatId!,
      senderId: _authUser!.id,
      timestamp: timestamp,
      type: MessageType.text,
      text: messageText,
      readBy: [_authUser!.id],
      status: MessageStatus.sending,
    );

    setState(() {
      _messages.insert(0, tempMessage); // Insert at index 0 for reversed list
      _newMessage = '';
      _fileToSend = null;
      _filePreviewUrl = null;
      _showEncryptionBanner = false;
    });

    _messageController.clear();
    // _scrollToBottom(animated: true); // Removed as reverse: true handles this

    // 2️⃣ Encrypt and send in background
    _encryptAndSend(tempMessage);
  }

  Future<void> _encryptAndSend(Message localMessage) async {
    try {
      final encryptedData = await _encryptionService.encryptMessage(
        localMessage.text!,
        [_contact!.id],
        _authUser!.id,
      );

      // Upload encrypted message to Firestore
      final docRef = await _firestore
          .collection('chats')
          .doc(_effectiveChatId)
          .collection('messages')
          .add({
        'chatId': _effectiveChatId,
        'senderId': _authUser!.id,
        'timestamp': localMessage.timestamp,
        'type': MessageType.text.toString(),
        'readBy': [_authUser!.id],
        'text': null,
        'encryptedText': encryptedData['encryptedText'],
        'keyId': encryptedData['keyId'],
        'iv': encryptedData['iv'],
        'encryptedKeys': encryptedData['encryptedKeys'],
        'clientTempId': localMessage.clientTempId,
        'status': MessageStatus.sent.toString(),
      });

      // Update chat lastMessage
      await _firestore.collection('chats').doc(_effectiveChatId).update({
        'lastMessage': {
          'id': docRef.id,
          'chatId': _effectiveChatId,
          'senderId': _authUser!.id,
          'timestamp': localMessage.timestamp,
          'type': MessageType.text.toString(),
          'readBy': [_authUser!.id],
          'text': null,
          'encryptedText': encryptedData['encryptedText'],
          'keyId': encryptedData['keyId'],
          'iv': encryptedData['iv'],
          'encryptedKeys': encryptedData['encryptedKeys'],
          'status': MessageStatus.sent.toString(),
        },
        'updatedAt': localMessage.timestamp,
      });

    } catch (e) {
      print('Error sending message: $e');
      // Mark local message as failed
      if (mounted) {
        setState(() {
          final index =
              _messages.indexWhere((msg) => msg.clientTempId == localMessage.clientTempId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(status: MessageStatus.failed);
          }
        });
      }
    }
  }

  void _onToggleEmojiPicker() {
    _emojiManager.toggleEmojiPicker(() => setState(() {}));
    // Removed explicit _scrollToBottom call as reverse: true handles this
    // Future.delayed(const Duration(milliseconds: 50), () {
    //   _scrollToBottom(animated: true); // Scroll to bottom when emoji picker opens
    // });
  }

  void _onFileSelect(dynamic file) {
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
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    setState(() {
      _newMessage = newText;
    });
    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(offset: selection.start + emoji.length);
  }

  void _handleAcceptRequest() {
    setState(() {
      _chatDetails = _chatDetails?.copyWith(requestStatus: ChatRequestStatus.accepted);
    });
    // TODO: Update Firestore chat request status to accepted
    print('Request accepted');
  }

  void _handleRejectRequest() {
    setState(() {
      _chatDetails = _chatDetails?.copyWith(requestStatus: ChatRequestStatus.rejected);
    });
    // TODO: Update Firestore chat request status to rejected
    print('Request rejected');
  }

  void _handleCancelRequest() {
    setState(() {
      _chatDetails = _chatDetails?.copyWith(requestStatus: ChatRequestStatus.rejected);
    });
    // TODO: Update Firestore chat request status to cancelled
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
    final headerContactName = _contact?.displayName ?? _chatDetails?.name ?? 'Chat';
    final headerContactAvatar = _contact?.avatarUrl ?? _chatDetails?.avatarUrl;

    return Scaffold(
      appBar: ChatPageHeader(
        contactName: headerContactName,
        contactId: _contact?.id,
        contactAvatarUrl: headerContactAvatar,
        contactStatusText: contactStatusText,
        isChatActive: isChatActive,
        contactActiveAura: _contactActiveAura, // Pass the contact's active aura
        onMoreOptionsClick: () {
          print('More options clicked');
        },
      ),
      body: Column(
        children: [
          if ((_localKeysExist == false || _showEncryptionBanner) && _messages.isEmpty) const EncryptedChatBanner(),
          if (showRequestSpecificUI && _chatDetails != null && _contact != null && _authUser!.id != null)
            ChatRequestDisplay(
              chatDetails: _chatDetails!,
              contact: toUser(_contact!), // Convert UserProfile to User
              currentUserId: _authUser!.id,
              onAcceptRequest: _handleAcceptRequest,
              onRejectRequest: _handleRejectRequest,
              onCancelRequest: _handleCancelRequest,
              isProcessing: _isProcessingRequestAction,
            )
          else ...[
            Expanded(
              child: MessageArea(
                messages: _messages,
                currentUserId: _authUser!.id,
                contactId: _contact?.id,
                // dynamicPaddingBottom: _isEmojiPickerOpen ? EMOJI_PICKER_HEIGHT_PX : 0.0, // Removed
                isContactTyping: _isContactTyping,
                scrollController: _scrollController,
                padding: const EdgeInsets.only(top: 10.0),
                encryptionService: _encryptionService,
              ),
            ),
            if (showInputArea)
              ChatInputZone(
                newMessage: _newMessage,
                onNewMessageChange: _onNewMessageChange,
                onSendMessage: _onSendMessage,
                onToggleEmojiPicker: () {
                  _emojiManager.toggleEmojiPicker(() => setState(() {}));
                },
                isEmojiPickerOpen: _emojiManager.isEmojiOpen,
                onFileSelect: _onFileSelect,
                textareaRef: _messageController,
                focusNode: _messageFocusNode, // Pass the FocusNode
                isDisabled: !_isChatReady || !isChatActive,
                filePreviewUrl: _filePreviewUrl,
                onClearFileSelection: _onClearFileSelection,
              ),
            if (showInputArea && _emojiManager.isEmojiOpen) // Use _emojiManager.isEmojiOpen
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
