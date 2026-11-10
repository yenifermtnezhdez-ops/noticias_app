
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
          content: Text(
            'El comentario no puede estar vacío.',
          ),
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

  Widget _buildOwnerActions(
    BuildContext context,
    bool isBusy,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: isBusy ? null : _startEditing,
          tooltip: 'Editar comentario',
          style: IconButton.styleFrom(
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.primary,
            minimumSize: const Size(36, 36),
            maximumSize: const Size(36, 36),
          ),
          icon: const Icon(
            Icons.edit_outlined,
            size: 17,
          ),
        ),
        const SizedBox(width: 7),
        IconButton(
          onPressed: isBusy
              ? null
              : () {
                  setState(() {
                    _confirmingDelete = true;
                  });
                },
          tooltip: 'Eliminar comentario',
          style: IconButton.styleFrom(
            backgroundColor: colors.errorContainer,
            foregroundColor: colors.error,
            minimumSize: const Size(36, 36),
            maximumSize: const Size(36, 36),
          ),
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildEditingContent(
    BuildContext context,
    bool isBusy,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          decoration: InputDecoration(
            hintText: 'Escribe tu comentario...',
            alignLabelWithHint: true,
            filled: true,
            fillColor: colors.surfaceContainerHighest
                .withValues(alpha: 0.45),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
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
                isBusy ? 'Guardando...' : 'Guardar cambios',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeleteConfirmation(
    BuildContext context,
    bool isBusy,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿Deseas eliminar este comentario?',
            style: TextStyle(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
                icon: const Icon(
                  Icons.delete_outline_rounded,
                ),
                label: Text(
                  isBusy ? 'Eliminando...' : 'Eliminar',
                ),
              ),
            ],
          ),
        ],
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

    final commentProvider =
        context.watch<CommentProvider>();

    final isBusy = commentProvider.isWriting;

    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(
          color: colors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
         
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.person_rounded,
                    color: colors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comment.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: colors.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(
                          widget.comment.createdAt,
                        ),
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                if (isOwner &&
                    !_isEditing &&
                    !_confirmingDelete)
                  _buildOwnerActions(context, isBusy),
              ],
            ),

            const SizedBox(height: 15),

           
            if (_isEditing)
              _buildEditingContent(context, isBusy)
            else if (_confirmingDelete)
              _buildDeleteConfirmation(context, isBusy)
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest
                      .withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.comment.content,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ),

              if (widget.comment.updatedAt.isAfter(
                widget.comment.createdAt,
              ))
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        color: colors.onSurfaceVariant,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Editado',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
