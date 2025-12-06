import 'package:flutter/material.dart';

class SkillsField extends StatefulWidget {
  final List<String> initialSkills;
  final Function(List<String> skills) onSkillsUpdated;
  final Function()? onSaveToDatabase;

  const SkillsField({
    super.key,
    this.initialSkills = const [],
    required this.onSkillsUpdated,
    this.onSaveToDatabase,
  });

  @override
  State<SkillsField> createState() => _SkillsFieldState();
}

class _SkillsFieldState extends State<SkillsField> {
  List<String> _skills = [];
  final TextEditingController _skillsController = TextEditingController();
  final FocusNode _skillsFocusNode = FocusNode();
  bool _showSkillHint = true;

  @override
  void initState() {
    super.initState();
    _skills = List.from(widget.initialSkills);
    _skillsFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _skillsFocusNode.removeListener(_onFocusChange); 
    _skillsController.dispose();
    _skillsFocusNode.dispose();
    super.dispose();
  }
  
  void _onFocusChange() {
    setState(() {
    });
  }

  void _addSkillsFromText() {
    final text = _skillsController.text.trim();
    if (text.isEmpty) {
      if (_skills.isEmpty) {
        _showSnackBar('Введите хотя бы один навык', isError: true);
      }
      _skillsFocusNode.unfocus();
      return;
    }

    final List<String> newSkills = text
        .split(';')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    if (newSkills.isEmpty) {
      _showSnackBar('Не найдено навыков для добавления', isError: true);
      _skillsFocusNode.unfocus();
      return;
    }

    int addedCount = 0;
    List<String> duplicates = [];

    for (final skill in newSkills) {
      final normalizedSkill = skill.toLowerCase();
      if (!_skills.any((s) => s.toLowerCase() == normalizedSkill)) {
        setState(() {
          _skills.add(skill);
        });
        addedCount++;
      } else {
        duplicates.add(skill);
      }
    }

    _skillsController.clear();

    setState(() {
      _showSkillHint = true;
    });

    widget.onSkillsUpdated(_skills);

    if (widget.onSaveToDatabase != null) {
      widget.onSaveToDatabase!();
    }

    if (addedCount > 0) {
      String message;
      if (duplicates.isEmpty) {
        message = addedCount == 1 
            ? 'Добавлен 1 новый навык' 
            : 'Добавлено $addedCount новых навыков';
      } else {
        message = addedCount == 1
            ? 'Добавлен 1 новый навык, ${duplicates.length} уже существует'
            : 'Добавлено $addedCount новых навыков, ${duplicates.length} уже существует';
      }
      
      _showSnackBar(message, isError: false);
    } else if (duplicates.isNotEmpty) {
      _showSnackBar(
        'Все введенные навыки (${duplicates.length}) уже существуют',
        isError: true,
      );
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
    
    widget.onSkillsUpdated(_skills);

    if (widget.onSaveToDatabase != null) {
      widget.onSaveToDatabase!();
    }
    
    _showSnackBar('Навык удален', isError: false);
  }

  void _clearAllSkills() {
    if (_skills.isEmpty && _skillsController.text.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 40, 40, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[800]!),
          ),
          title: const Text(
            'Очистить всё?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Это удалит все добавленные навыки и очистит поле ввода.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Отмена',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _skillsFocusNode.unfocus();
                _skillsController.clear();

                setState(() {
                  _skills.clear();
                  _showSkillHint = true; 
                });

                widget.onSkillsUpdated(_skills);
                if (widget.onSaveToDatabase != null) {
                  widget.onSaveToDatabase!();
                }
                _showSnackBar('Поле полностью очищено', isError: false);
              },
              child: const Text(
                'Очистить',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
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

  Widget _buildSkillChip(String skill, int index) {
    return Chip(
      label: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.6,
        ),
        child: Text(
          skill,
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
      onDeleted: () => _removeSkill(index),
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

    if (_skills.isNotEmpty) {
      chipsAndInput.addAll(
        _skills.asMap().entries.map((entry) {
          return _buildSkillChip(entry.value, entry.key);
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
            controller: _skillsController,
            focusNode: _skillsFocusNode,
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
              hintText: _skills.isEmpty ? 'Ввести навыки...' : '', 
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            onChanged: (text) {
              setState(() {
                _showSkillHint = text.isEmpty;
              });
            },
            onEditingComplete: _addSkillsFromText, 
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
          color: _skillsFocusNode.hasFocus 
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
                  "Навыки",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_skills.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 75, 134),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _skills.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (_skills.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: _clearAllSkills,
                tooltip: 'Очистить все навыки',
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
                onPressed: _skillsController.text.trim().isNotEmpty 
                    ? _addSkillsFromText
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _skillsController.text.trim().isNotEmpty
                      ? const Color.fromARGB(255, 93, 87, 209)
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
                  'Добавить навыки',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        
        
        if (_showSkillHint && _skills.isEmpty && _skillsController.text.isEmpty) 
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline, 
                  color: const Color.fromARGB(255, 78, 75, 134), 
                  size: 16
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Вводите навыки через точку с запятой.',
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