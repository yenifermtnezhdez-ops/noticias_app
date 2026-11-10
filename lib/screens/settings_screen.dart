
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
          backgroundColor:
              isError ? colors.error : colors.primary,
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

  
  Widget _buildHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 57,
            height: 57,
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: colors.primary,
              size: 30,
            ),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Personaliza los avisos que recibes '
                  'de Noticias App.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildPermissionCard(
    BuildContext context,
    NotificationProvider provider,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (provider.hasPermission) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificaciones activadas',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tu dispositivo puede recibir avisos.',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: colors.primary,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.notifications_off_outlined,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Activa las notificaciones',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Permite que Noticias App te envíe avisos '
              'sobre las categorías que selecciones.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
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
                    : const Icon(
                        Icons.notifications_active_rounded,
                      ),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Reintentar',
            onPressed: provider.refreshCategories,
            icon: Icon(
              Icons.refresh_rounded,
              color: colors.onErrorContainer,
            ),
          ),
        ],
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

    final colors = Theme.of(context).colorScheme;

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Nueva notificación';

    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'Has recibido un nuevo mensaje.';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Cerrar',
              onPressed: provider.clearLastMessage,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }

 

  Widget _buildSectionHeading(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        value: isSubscribed,
        onChanged: isBusy
            ? null
            : (enabled) => _changeSubscription(
                  context,
                  provider,
                  category,
                  enabled,
                ),
        secondary: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            Icons.newspaper_rounded,
            color: colors.primary,
            size: 21,
          ),
        ),
        title: Text(
          category.name,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          isBusy
              ? 'Actualizando suscripción...'
              : isSubscribed
                  ? 'Recibirás avisos de esta categoría.'
                  : 'Notificaciones desactivadas.',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        activeThumbColor: colors.primary,
      ),
    );
  }

  
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final provider =
        context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: provider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colors.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: provider.refreshCategories,
              color: colors.primary,
              backgroundColor: colors.surface,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  30,
                ),
                children: [
                  _buildHeader(context),

                  const SizedBox(height: 18),

                  _buildPermissionCard(context, provider),

                  if (provider.lastMessage != null) ...[
                    const SizedBox(height: 13),
                    _buildLastMessage(context, provider),
                  ],

                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 13),
                    _buildErrorCard(context, provider),
                  ],

                  const SizedBox(height: 28),

                  _buildSectionHeading(
                    context,
                    'Tus categorías',
                    'Selecciona los temas sobre los que deseas '
                    'recibir notificaciones.',
                  ),

                  if (provider.categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: colors.outline.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 42,
                            color: colors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No hay categorías disponibles.',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: provider.refreshCategories,
                            icon: const Icon(
                              Icons.refresh_rounded,
                            ),
                            label: const Text(
                              'Volver a intentar',
                            ),
                          ),
                        ],
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

                  const SizedBox(height: 17),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          color: colors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            '${provider.subscribedCategoryIds.length} '
                            'categorías seleccionadas',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
