import 'package:flutter/material.dart';
import 'package:bharatconnect/services/status_service.dart';
import 'package:bharatconnect/widgets/custom_toast.dart';

class CreateTextStatusScreen extends StatefulWidget {
  const CreateTextStatusScreen({super.key});

  @override
  State<CreateTextStatusScreen> createState() => _CreateTextStatusScreenState();
}

class _CreateTextStatusScreenState extends State<CreateTextStatusScreen> {
  final TextEditingController _textController = TextEditingController();
  final StatusService _statusService = StatusService();
  String _selectedFontFamily = 'Roboto'; // Default font
  Color _selectedBackgroundColor = Colors.blueGrey.shade800; // Default background
  bool _isLoading = false;

  final List<String> _fontOptions = [
    'Roboto', 'Open Sans', 'Lato', 'Montserrat', 'Playfair Display'
  ];

  final List<Color> _backgroundOptions = [
    Colors.blueGrey.shade800, Colors.deepPurple.shade700, Colors.teal.shade700, Colors.red.shade700, Colors.orange.shade700
  ];

  Future<void> _postStatus() async {
    if (_textController.text.trim().isEmpty) {
      showCustomToast(context, 'Status cannot be empty.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _statusService.createTextStatus(
        text: _textController.text.trim(),
        fontFamily: _selectedFontFamily,
        backgroundColor: _selectedBackgroundColor.value.toRadixString(16), // Store color as hex string
      );
      if (mounted) {
        showCustomToast(context, 'Status posted successfully!');
        Navigator.of(context).pop(); // Go back to StatusScreen
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, 'Failed to post status: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _selectedBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Text Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.font_download, color: Colors.white), // Font icon
            onPressed: () {
              _showFontPicker(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.color_lens, color: Colors.white), // Color icon
            onPressed: () {
              _showColorPicker(context);
            },
          ),
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : IconButton(
                  icon: const Icon(Icons.send, color: Colors.white), // Send icon
                  onPressed: _postStatus,
                ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: TextField(
            controller: _textController,
            autofocus: true,
            maxLines: null, // Allows unlimited lines
            expands: true, // Takes up available vertical space
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: _selectedFontFamily,
            ),
            decoration: const InputDecoration(
              hintText: 'Type your status here...',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  void _showFontPicker(BuildContext context) {
    showModalBottomSheet(context: context, builder: (context) {
      return Container(
        color: Theme.of(context).cardColor,
        child: ListView.builder(
          itemCount: _fontOptions.length,
          itemBuilder: (context, index) {
            final font = _fontOptions[index];
            return ListTile(
              title: Text(font, style: TextStyle(fontFamily: font, color: Theme.of(context).colorScheme.onSurface)),
              trailing: _selectedFontFamily == font ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
              onTap: () {
                setState(() {
                  _selectedFontFamily = font;
                });
                Navigator.of(context).pop();
              },
            );
          },
        ),
      );
    });
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(context: context, builder: (context) {
      return Container(
        color: Theme.of(context).cardColor,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _backgroundOptions.length,
          itemBuilder: (context, index) {
            final color = _backgroundOptions[index];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBackgroundColor = color;
                });
                Navigator.of(context).pop();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: _selectedBackgroundColor == color
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                      : null,
                ),
              ),
            );
          },
        ),
      );
    });
  }
}
