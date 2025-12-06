import 'package:flutter/material.dart';

class InterestsField extends StatefulWidget {
  final List<String> initialInterests;
  final Function(List<String> interests) onInterestsUpdated;
  final Function()? onSaveToDatabase;

  const InterestsField({
    super.key,
    this.initialInterests = const [],
    required this.onInterestsUpdated,
    this.onSaveToDatabase,
  });

  @override
  State<InterestsField> createState() => _InterestsFieldState();
}

class _InterestsFieldState extends State<InterestsField> {
  List<String> _interests = [];
  final TextEditingController _interestsController = TextEditingController();
  final FocusNode _interestsFocusNode = FocusNode();
  bool _showinterestHint = true;

  @override
  void initState() {
    super.initState();
   _interests = List.from(widget.initialInterests);
    _interestsFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _interestsFocusNode.removeListener(_onFocusChange);
    _interestsController.dispose();
    _interestsFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
    });
  }

  void _addInterestsFromText() {
    final text = _interestsController.text.trim();
    if (text.isEmpty) {
      if (_interests.isEmpty) {
        _showSnackBar('Введите хотя бы один интерес', isError: true);
      }
      _interestsFocusNode.unfocus();
      return;
    }

    final List<String> newInterests = text
        .split(';')
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toList();

    if (newInterests.isEmpty) {
      _showSnackBar('Не найдено интересов для добавления', isError: true);
      _interestsFocusNode.unfocus();
      return;
    }
    int addedCount = 0;
    List<String> duplicates = [];

    for (final interest in newInterests) {
      final normalizedinterest = interest.toLowerCase();
      if (!_interests.any((s) => s.toLowerCase() == normalizedinterest)) {
        setState(() {
          _interests.add(interest);
        });
        addedCount++;
      } else {
        duplicates.add(interest);
      }
    }

    _interestsController.clear();
    _interestsFocusNode.unfocus();
    setState(() {
      _showinterestHint = true;
    });


    widget.onInterestsUpdated(_interests);

  
    if (widget.onSaveToDatabase != null) {
      widget.onSaveToDatabase!();
    }


    if (addedCount > 0) {
      String message;
      if (duplicates.isEmpty) {
        message = addedCount == 1 
            ? 'Добавлен 1 новый интерес' 
            : 'Добавлено $addedCount новых интересов';
      } else {
        message = addedCount == 1
            ? 'Добавлен 1 новый интерес, ${duplicates.length} уже существует'
            : 'Добавлено $addedCount новых интересов, ${duplicates.length} уже существует';
      }
      
      _showSnackBar(message, isError: false);
    } else if (duplicates.isNotEmpty) {
      _showSnackBar(
        'Все введенные интересы (${duplicates.length}) уже существуют',
        isError: true,
      );
    }
  }

  void _removeinterest(int index) {
    setState(() {
      _interests.removeAt(index);
    });
    

    widget.onInterestsUpdated(_interests);
    

    if (widget.onSaveToDatabase != null) {
      widget.onSaveToDatabase!();
    }
    
    _showSnackBar('Интерес удален', isError: false);
  }

  void _clearAllInterests() {
    if (_interests.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все интересы?'),
        content: const Text('Вы уверены, что хотите удалить все интересы? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _interests.clear();
              });
              widget.onInterestsUpdated(_interests);
              if (widget.onSaveToDatabase != null) {
                widget.onSaveToDatabase!();
              }
              _showSnackBar('Все интересы удалены', isError: false);
            },
            child: const Text(
              'Очистить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildinterestChip(String interest, int index) {
    return Chip(
      label: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        child: Text(
          interest,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 47, 47, 100),
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: Colors.grey[400],
      ),
      onDeleted: () => _removeinterest(index),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> chipsAndInput = [];

    if (_interests.isNotEmpty) {
      chipsAndInput.addAll(
        _interests.asMap().entries.map((entry) {
          return _buildinterestChip(entry.value, entry.key);
        }).toList(),
      );
    }


    chipsAndInput.add(

      ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 100,
          maxWidth: MediaQuery.of(context).size.width, 
        ),
        child: IntrinsicWidth( 
          child: TextField(
            controller: _interestsController,
            focusNode: _interestsFocusNode,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              isDense: true, 
              contentPadding: const EdgeInsets.only(top: 8, bottom: 8), 
              border: InputBorder.none,
              hintText: _interests.isEmpty ? 'Ввести интересы...' : '', 
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            onChanged: (text) {
              setState(() {
                _showinterestHint = text.isEmpty;
              });
            },
            onEditingComplete: _addInterestsFromText,
          ),
        ),
      ),
    );

    Widget inputArea = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(40, 40, 56, 1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _interestsFocusNode.hasFocus 
              ? const Color.fromARGB(255, 78, 75, 134) 
              : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 8, 
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center, 
        children: chipsAndInput,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Интересы",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_interests.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 75, 134),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _interests.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (_interests.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: _clearAllInterests,
                tooltip: 'Очистить все интересы',
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        inputArea,

        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4), 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, 
            children: [
              
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _interestsController.text.trim().isNotEmpty 
                    ? _addInterestsFromText
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _interestsController.text.trim().isNotEmpty
                      ?  const Color.fromARGB(255, 93, 87, 209)
                      : Colors.grey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 40),
                ),
                child: const Text(
                  'Добавить интересы',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
  
        if (_showinterestHint && _interests.isEmpty && _interestsController.text.isEmpty) 
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline, 
                  color: Color.fromARGB(255, 78, 75, 134), 
                  size: 16
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Вводите интересы через точку с запятой.',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ), 
      ],
    );
  }
}