
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/notification_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final colors = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colors.error : null,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  Future<void> _requestPermission(
    BuildContext context,
    NotificationProvider provider,
  ) async {
    final success = await provider.requestPermission();

    if (!context.mounted) return;

    _showMessage(
      context,
      success
          ? 'Permiso concedido. Ya puedes elegir tus categorías.'
          : provider.errorMessage ??
              'No fue posible activar las notificaciones.',
      isError: !success,
    );
  }

  Future<void> _changeSubscription(
    BuildContext context,
    NotificationProvider provider,
    CategoryModel category,
    bool enabled,
  ) async {
    final success = await provider.setCategoryEnabled(
      category,
      enabled,
    );

    if (!context.mounted) return;

    _showMessage(
      context,
      success
          ? enabled
              ? 'Te suscribiste a ${category.name}.'
              : 'Cancelaste la suscripción a ${category.name}.'
          : provider.errorMessage ??
              'No fue posible actualizar la suscripción.',
      isError: !success,
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    NotificationProvider provider,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (provider.hasPermission) {
      return Card(
        child: ListTile(
          leading: Icon(
            Icons.notifications_active,
            color: colors.primary,
            size: 30,
          ),
          title: const Text(
            'Notificaciones activadas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            'Tu dispositivo puede recibir notificaciones.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 28,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Activa las notificaciones',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Permite que Noticias App te envíe avisos '
              'sobre las categorías que selecciones.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: provider.isRequestingPermission
                    ? null
                    : () => _requestPermission(
                          context,
                          provider,
                        ),
                icon: provider.isRequestingPermission
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.notifications_active),
                label: Text(
                  provider.isRequestingPermission
                      ? 'Solicitando permiso...'
                      : 'Permitir notificaciones',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(
    BuildContext context,
    NotificationProvider provider,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                provider.errorMessage!,
                style: TextStyle(
                  color: colors.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Reintentar',
              onPressed: provider.refreshCategories,
              icon: Icon(
                Icons.refresh,
                color: colors.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastMessage(
    BuildContext context,
    NotificationProvider provider,
  ) {
    final message = provider.lastMessage;

    if (message == null) {
      return const SizedBox.shrink();
    }

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Nueva notificación';

    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'Has recibido un nuevo mensaje.';

    return Card(
      child: ListTile(
        leading: const Icon(Icons.mark_email_unread_outlined),
        title: Text(title),
        subtitle: Text(body),
        trailing: IconButton(
          tooltip: 'Cerrar',
          onPressed: provider.clearLastMessage,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    NotificationProvider provider,
    CategoryModel category,
  ) {
    final isSubscribed =
        provider.isCategorySubscribed(category.id);

    final isBusy =
        provider.isCategoryBusy(category.id);

    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
        value: isSubscribed,
        onChanged: isBusy
            ? null
            : (enabled) => _changeSubscription(
                  context,
                  provider,
                  category,
                  enabled,
                ),
        secondary: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          child: Icon(
            Icons.newspaper_outlined,
            color: colors.onPrimaryContainer,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          isBusy
              ? 'Actualizando suscripción...'
              : isSubscribed
                  ? 'Recibirás avisos de esta categoría.'
                  : 'No recibirás avisos de esta categoría.',
        ),
        activeThumbColor: colors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias de notificaciones'),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: provider.refreshCategories,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 42,
                          color: colors.onPrimaryContainer,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mantente informado',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Elige las categorías sobre las '
                                'que deseas recibir notificaciones.',
                                style: TextStyle(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildPermissionCard(context, provider),

                  if (provider.lastMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildLastMessage(context, provider),
                  ],

                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildErrorCard(context, provider),
                  ],

                  const SizedBox(height: 22),

                  const Text(
                    'Categorías de noticias',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'Activa o desactiva los temas que te interesan. '
                    'Puedes cambiar tus preferencias cuando quieras.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (provider.categories.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.category_outlined,
                              size: 42,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No hay categorías disponibles.',
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: provider.refreshCategories,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Volver a intentar'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...provider.categories.map(
                      (category) => _buildCategoryTile(
                        context,
                        provider,
                        category,
                      ),
                    ),

                  const SizedBox(height: 18),

                  Center(
                    child: Text(
                      '${provider.subscribedCategoryIds.length} '
                      'categorías seleccionadas',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
    );
  }
}
