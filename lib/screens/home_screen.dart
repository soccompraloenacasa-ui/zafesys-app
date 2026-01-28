import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/helpers.dart';
import '../widgets/installation_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadInstallations();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != provider.selectedDate) {
      provider.setSelectedDate(picked);
    }
  }

  String _getDateLabel(AppProvider provider) {
    final now = DateTime.now();
    final selected = provider.selectedDate;
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));

    if (selected.year == now.year && 
        selected.month == now.month && 
        selected.day == now.day) {
      return 'Instalaciones de hoy';
    } else if (selected.year == yesterday.year && 
               selected.month == yesterday.month && 
               selected.day == yesterday.day) {
      return 'Instalaciones de ayer';
    } else if (selected.year == tomorrow.year && 
               selected.month == tomorrow.month && 
               selected.day == tomorrow.day) {
      return 'Instalaciones de manana';
    } else {
      return 'Instalaciones';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();
    final installations = provider.todayInstallations;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => provider.loadInstallations(),
        color: theme.colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            // Custom App Bar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: theme.colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withAlpha(200),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    provider.currentTechnician?.name.isNotEmpty == true
                                        ? provider.currentTechnician!.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hola,',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      provider.currentTechnician?.name ?? 'Tecnico',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => provider.toggleTheme(),
                  icon: Icon(
                    provider.themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: Colors.white,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) async {
                    if (value == 'logout') {
                      final navigator = Navigator.of(context);
                      await provider.logout();
                      if (mounted) {
                        navigator.pushReplacementNamed('/login');
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: theme.colorScheme.error),
                          const SizedBox(width: 12),
                          Text('Cerrar sesion', style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Date Header with Navigation
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Fila principal con calendario
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _getDateLabel(provider),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  Helpers.formatDate(provider.selectedDate),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withAlpha(200),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              '${installations.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Fila de navegación entre días
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botón día anterior
                        TextButton.icon(
                          onPressed: () => provider.previousDay(),
                          icon: Icon(
                            Icons.chevron_left,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          label: Text(
                            'Anterior',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        // Botón Hoy (solo si no es hoy)
                        if (!provider.isToday)
                          TextButton(
                            onPressed: () => provider.goToToday(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Hoy',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                        else
                          const SizedBox(width: 50),
                        // Botón día siguiente
                        TextButton.icon(
                          onPressed: () => provider.nextDay(),
                          icon: Text(
                            'Siguiente',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 13,
                            ),
                          ),
                          label: Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Installations List
            if (provider.isLoading && installations.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (installations.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(theme, provider),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final installation = installations[index];
                      return InstallationCard(
                        installation: installation,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/installation',
                            arguments: installation.id,
                          );
                        },
                      );
                    },
                    childCount: installations.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, AppProvider provider) {
    final isToday = provider.isToday;
    final isPast = provider.selectedDate.isBefore(DateTime.now());
    
    String title;
    String subtitle;
    
    if (isToday) {
      title = 'Sin instalaciones';
      subtitle = 'No tienes instalaciones programadas para hoy.\nDesliza hacia abajo para actualizar.';
    } else if (isPast) {
      title = 'Sin registros';
      subtitle = 'No hay instalaciones registradas para esta fecha.';
    } else {
      title = 'Sin programacion';
      subtitle = 'No tienes instalaciones programadas para este dia.';
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPast ? Icons.history_rounded : Icons.event_available_rounded,
                size: 64,
                color: theme.colorScheme.primary.withAlpha(150),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (!isToday) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => provider.goToToday(),
                icon: const Icon(Icons.today, size: 18),
                label: const Text('Ir a hoy'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
