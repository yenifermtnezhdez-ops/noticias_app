
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/comment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/comment_provider.dart';

class CommentCard extends StatefulWidget {
  final CommentModel comment;

  const CommentCard({
    super.key,
    required this.comment,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _isEditing = false;
  bool _confirmingDelete = false;

  String _editedContent = '';

  @override
  void didUpdateWidget(covariant CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.comment.content != widget.comment.content &&
        !_isEditing) {
      _editedContent = widget.comment.content;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year · $hour:$minute';
  }

  void _startEditing() {
    setState(() {
      _editedContent = widget.comment.content;
      _isEditing = true;
      _confirmingDelete = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editedContent = widget.comment.content;
    });

    FocusScope.of(context).unfocus();
  }

  Future<void> _saveComment() async {
    final content = _editedContent.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El comentario no puede estar vacío.'),
        ),
      );
      return;
    }

    if (content.length > 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El comentario no puede superar los 1000 caracteres.',
          ),
        ),
      );
      return;
    }

    final provider = context.read<CommentProvider>();

    if (provider.isWriting) return;

    FocusScope.of(context).unfocus();

    final success = await provider.updateComment(
      commentId: widget.comment.id,
      content: content,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isEditing = false;
      });
    }

    final message = success
        ? 'Comentario actualizado correctamente.'
        : context.read<CommentProvider>().errorMessage ??
            'No fue posible editar el comentario.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final provider = context.read<CommentProvider>();

    if (provider.isWriting) return;

    final success = await provider.deleteComment(
      commentId: widget.comment.id,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _confirmingDelete = false;
      });
    }

    final message = success
        ? 'Comentario eliminado correctamente.'
        : context.read<CommentProvider>().errorMessage ??
            'No fue posible eliminar el comentario.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final currentUserId =
        context.watch<AuthProvider>().user?.uid;

    final isOwner = currentUserId != null &&
        currentUserId == widget.comment.userId;

    final commentProvider = context.watch<CommentProvider>();

    final isBusy = commentProvider.isWriting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
         
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment.userName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatDate(widget.comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

               
                if (isOwner && !_isEditing && !_confirmingDelete)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar comentario',
                        onPressed: isBusy ? null : _startEditing,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Eliminar comentario',
                        onPressed: isBusy
                            ? null
                            : () {
                                setState(() {
                                  _confirmingDelete = true;
                                });
                              },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

           
            if (_isEditing) ...[
              TextFormField(
                key: ValueKey('edit-${widget.comment.id}'),
                initialValue: _editedContent,
                enabled: !isBusy,
                minLines: 2,
                maxLines: 5,
                maxLength: 1000,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  _editedContent = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Escribe tu comentario...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isBusy ? null : _cancelEditing,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: isBusy ? null : _saveComment,
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      isBusy ? 'Guardando...' : 'Guardar',
                    ),
                  ),
                ],
              ),
            ]

           
            else if (_confirmingDelete) ...[
              Text(
                '¿Deseas eliminar este comentario?',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            setState(() {
                              _confirmingDelete = false;
                            });
                          },
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                    onPressed: isBusy ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      isBusy ? 'Eliminando...' : 'Eliminar',
                    ),
                  ),
                ],
              ),
            ]

            
            else ...[
              Text(
                widget.comment.content,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              if (widget.comment.updatedAt.isAfter(
                widget.comment.createdAt,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Editado',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
