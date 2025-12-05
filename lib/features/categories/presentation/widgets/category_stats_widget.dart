// // lib/features/categories/presentation/widgets/category_stats_widget.dart
// import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';
// import 'package:flutter/material.dart';
// import '../../../../app/core/utils/responsive.dart';
// import '../../../../app/shared/widgets/custom_card.dart';
// import '../../domain/repositories/category_repository.dart';

// class CategoryStatsWidget extends StatelessWidget {
//   final CategoryStats stats;
//   final bool isCompact;

//   const CategoryStatsWidget({
//     Key? key,
//     required this.stats,
//     this.isCompact = false,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     if (isCompact) {
//       return _buildCompactStats(context);
//     }

//     return ResponsiveLayout(
//       mobile: _buildMobileStats(context),
//       tablet: _buildTabletStats(context),
//       desktop: _buildDesktopStats(context),
//     );
//   }

//   Widget _buildCompactStats(BuildContext context) {
//     return CustomCard(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildCompactStatItem(
//             context,
//             'Total',
//             stats.total.toString(),
//             Icons.category,
//             Theme.of(context).primaryColor,
//           ),
//           _buildVerticalDivider(),
//           _buildCompactStatItem(
//             context,
//             'Activas',
//             stats.active.toString(),
//             Icons.check_circle,
//             Colors.green,
//           ),
//           _buildVerticalDivider(),
//           _buildCompactStatItem(
//             context,
//             'Padre',
//             stats.parents.toString(),
//             Icons.account_tree,
//             Colors.blue,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMobileStats(BuildContext context) {
//     return Column(
//       children: [
//         // Fila 1: Total y Activas
//         Row(
//           children: [
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Total de Categorías',
//                 stats.total.toString(),
//                 Icons.category,
//                 Theme.of(context).primaryColor,
//               ),
//             ),
//             const SizedBox(width: 8), // ✅ Reducido de 12 a 8
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Categorías Activas',
//                 stats.active.toString(),
//                 Icons.check_circle,
//                 Colors.green,
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 8), // ✅ Reducido de 12 a 8

//         // Fila 2: Padres y Hijos
//         Row(
//           children: [
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Categorías Padre',
//                 stats.parents.toString(),
//                 Icons.account_tree,
//                 Colors.blue,
//               ),
//             ),
//             const SizedBox(width: 8), // ✅ Reducido de 12 a 8
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Subcategorías',
//                 stats.children.toString(),
//                 Icons.subdirectory_arrow_right,
//                 Colors.orange,
//               ),
//             ),
//           ],
//         ),

//         if (stats.inactive > 0 || stats.deleted > 0) ...[
//           const SizedBox(height: 8), // ✅ Reducido de 12 a 8

//           // Fila 3: Inactivas y Eliminadas (si existen)
//           Row(
//             children: [
//               if (stats.inactive > 0)
//                 Expanded(
//                   child: _buildStatCard(
//                     context,
//                     'Inactivas',
//                     stats.inactive.toString(),
//                     Icons.pause_circle,
//                     Colors.orange,
//                   ),
//                 ),
//               if (stats.inactive > 0 && stats.deleted > 0)
//                 const SizedBox(width: 8), // ✅ Reducido de 12 a 8
//               if (stats.deleted > 0)
//                 Expanded(
//                   child: _buildStatCard(
//                     context,
//                     'Eliminadas',
//                     stats.deleted.toString(),
//                     Icons.delete,
//                     Colors.red,
//                   ),
//                 ),
//             ],
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildTabletStats(BuildContext context) {
//     return Column(
//       children: [
//         // Estadísticas principales en una fila
//         Row(
//           children: [
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Total de Categorías',
//                 stats.total.toString(),
//                 Icons.category,
//                 Theme.of(context).primaryColor,
//               ),
//             ),
//             const SizedBox(width: 10), // ✅ Reducido de 16 a 10
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Categorías Activas',
//                 stats.active.toString(),
//                 Icons.check_circle,
//                 Colors.green,
//               ),
//             ),
//             const SizedBox(width: 10), // ✅ Reducido de 16 a 10
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Categorías Padre',
//                 stats.parents.toString(),
//                 Icons.account_tree,
//                 Colors.blue,
//               ),
//             ),
//           ],
//         ),

//         const SizedBox(height: 10), // ✅ Reducido de 16 a 10

//         // Estadísticas secundarias
//         Row(
//           children: [
//             Expanded(
//               child: _buildStatCard(
//                 context,
//                 'Subcategorías',
//                 stats.children.toString(),
//                 Icons.subdirectory_arrow_right,
//                 Colors.orange,
//               ),
//             ),
//             const SizedBox(width: 10), // ✅ Reducido de 16 a 10
//             if (stats.inactive > 0)
//               Expanded(
//                 child: _buildStatCard(
//                   context,
//                   'Inactivas',
//                   stats.inactive.toString(),
//                   Icons.pause_circle,
//                   Colors.orange.shade300,
//                 ),
//               ),
//             if (stats.inactive > 0) const SizedBox(width: 16),
//             if (stats.deleted > 0)
//               Expanded(
//                 child: _buildStatCard(
//                   context,
//                   'Eliminadas',
//                   stats.deleted.toString(),
//                   Icons.delete,
//                   Colors.red,
//                 ),
//               ),
//             if (stats.inactive == 0 && stats.deleted == 0)
//               const Expanded(flex: 2, child: SizedBox()),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildDesktopStats(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildStatCard(
//             context,
//             'Total de Categorías',
//             stats.total.toString(),
//             Icons.category,
//             Theme.of(context).primaryColor,
//           ),
//         ),
//         const SizedBox(width: 12), // ✅ Reducido de 20 a 12
//         Expanded(
//           child: _buildStatCard(
//             context,
//             'Categorías Activas',
//             stats.active.toString(),
//             Icons.check_circle,
//             Colors.green,
//           ),
//         ),
//         const SizedBox(width: 12), // ✅ Reducido de 20 a 12
//         Expanded(
//           child: _buildStatCard(
//             context,
//             'Categorías Padre',
//             stats.parents.toString(),
//             Icons.account_tree,
//             Colors.blue,
//           ),
//         ),
//         const SizedBox(width: 12), // ✅ Reducido de 20 a 12
//         Expanded(
//           child: _buildStatCard(
//             context,
//             'Subcategorías',
//             stats.children.toString(),
//             Icons.subdirectory_arrow_right,
//             Colors.orange,
//           ),
//         ),
//         if (stats.inactive > 0) ...[
//           const SizedBox(width: 12), // ✅ Reducido de 20 a 12
//           Expanded(
//             child: _buildStatCard(
//               context,
//               'Inactivas',
//               stats.inactive.toString(),
//               Icons.pause_circle,
//               Colors.orange.shade300,
//             ),
//           ),
//         ],
//         if (stats.deleted > 0) ...[
//           const SizedBox(width: 12), // ✅ Reducido de 20 a 12
//           Expanded(
//             child: _buildStatCard(
//               context,
//               'Eliminadas',
//               stats.deleted.toString(),
//               Icons.delete,
//               Colors.red,
//             ),
//           ),
//         ],
//       ],
//     );
//   }

//   Widget _buildStatCard(
//     BuildContext context,
//     String title,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return CustomCard(
//       padding: EdgeInsets.all(context.isMobile ? 16 : 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Icon(
//                   icon,
//                   color: color,
//                   size: context.isMobile ? 20 : 24,
//                 ),
//               ),
//               const Spacer(),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: Responsive.getFontSize(
//                     context,
//                     mobile: 24,
//                     tablet: 28,
//                     desktop: 32,
//                   ),
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: context.isMobile ? 8 : 12),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: Responsive.getFontSize(
//                 context,
//                 mobile: 12,
//                 tablet: 14,
//                 desktop: 16,
//               ),
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCompactStatItem(
//     BuildContext context,
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(6),
//           ),
//           child: Icon(icon, color: color, size: 16),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }

//   Widget _buildVerticalDivider() {
//     return Container(height: 40, width: 1, color: Colors.grey.shade300);
//   }

//   // Método helper para obtener porcentaje
//   double _getPercentage(int value, int total) {
//     if (total == 0) return 0.0;
//     return (value / total) * 100;
//   }

//   // Widget adicional para mostrar porcentajes (opcional)
//   Widget _buildPercentageIndicator(
//     BuildContext context,
//     String label,
//     int value,
//     int total,
//     Color color,
//   ) {
//     final percentage = _getPercentage(value, total);

//     return CustomCard(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: Responsive.getFontSize(context),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//               Text(
//                 '${percentage.toStringAsFixed(1)}%',
//                 style: TextStyle(
//                   fontSize: Responsive.getFontSize(context),
//                   fontWeight: FontWeight.bold,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           LinearProgressIndicator(
//             value: percentage / 100,
//             backgroundColor: Colors.grey.shade200,
//             valueColor: AlwaysStoppedAnimation<Color>(color),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             '$value de $total',
//             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//           ),
//         ],
//       ),
//     );
//   }
// }

// lib/features/categories/presentation/widgets/category_stats_widget.dart
import 'package:baudex_desktop/features/categories/domain/entities/category_stats.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';
import '../../../../app/shared/widgets/custom_card.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryStatsWidget extends StatelessWidget {
  final CategoryStats stats;
  final bool isCompact;

  const CategoryStatsWidget({
    super.key,
    required this.stats,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactStats(context);
    }

    return ResponsiveLayout(
      mobile: _buildMobileStats(context),
      tablet: _buildTabletStats(context),
      desktop: _buildDesktopStats(context),
    );
  }

  Widget _buildCompactStats(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(8), // ✅ Reducido de 12 a 8
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCompactStatItem(
            context,
            'Total',
            stats.total.toString(),
            Icons.category,
            Theme.of(context).primaryColor,
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            context,
            'Activas',
            stats.active.toString(),
            Icons.check_circle,
            Colors.green,
          ),
          _buildVerticalDivider(),
          _buildCompactStatItem(
            context,
            'Padre', // ✅ CORRECCIÓN: Solo categorías padre reales
            stats.parents.toString(),
            Icons.account_tree,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStats(BuildContext context) {
    return Column(
      children: [
        // Fila 1: Total y Activas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total de Categorías',
                stats.total.toString(),
                Icons.category,
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 8), // ✅ Reducido de 12 a 8
            Expanded(
              child: _buildStatCard(
                context,
                'Categorías Activas',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8), // ✅ Reducido de 12 a 8
        // Fila 2: Padres y Subcategorías
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Categorías Padre', // ✅ Solo las que NO tienen parentId
                stats.parents.toString(),
                Icons.account_tree,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8), // ✅ Reducido de 12 a 8
            Expanded(
              child: _buildStatCard(
                context,
                'Subcategorías', // ✅ Las que SÍ tienen parentId
                stats.children.toString(),
                Icons.subdirectory_arrow_right,
                Colors.orange,
              ),
            ),
          ],
        ),

        if (stats.inactive > 0 || stats.deleted > 0) ...[
          const SizedBox(height: 8), // ✅ Reducido de 12 a 8
          // Fila 3: Inactivas y Eliminadas (si existen)
          Row(
            children: [
              if (stats.inactive > 0)
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Inactivas',
                    stats.inactive.toString(),
                    Icons.pause_circle,
                    Colors.orange,
                  ),
                ),
              if (stats.inactive > 0 && stats.deleted > 0)
                const SizedBox(width: 8), // ✅ Reducido de 12 a 8
              if (stats.deleted > 0)
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Eliminadas',
                    stats.deleted.toString(),
                    Icons.delete,
                    Colors.red,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTabletStats(BuildContext context) {
    return Column(
      children: [
        // Estadísticas principales en una fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total de Categorías',
                stats.total.toString(),
                Icons.category,
                Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 10), // ✅ Reducido de 16 a 10
            Expanded(
              child: _buildStatCard(
                context,
                'Categorías Activas',
                stats.active.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 10), // ✅ Reducido de 16 a 10
            Expanded(
              child: _buildStatCard(
                context,
                'Categorías Padre', // ✅ CORRECCIÓN
                stats.parents.toString(),
                Icons.account_tree,
                Colors.blue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10), // ✅ Reducido de 16 a 10
        // Estadísticas secundarias
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Subcategorías', // ✅ CORRECCIÓN
                stats.children.toString(),
                Icons.subdirectory_arrow_right,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 10), // ✅ Reducido de 16 a 10
            if (stats.inactive > 0)
              Expanded(
                child: _buildStatCard(
                  context,
                  'Inactivas',
                  stats.inactive.toString(),
                  Icons.pause_circle,
                  Colors.orange.shade300,
                ),
              ),
            if (stats.inactive > 0) const SizedBox(width: 16),
            if (stats.deleted > 0)
              Expanded(
                child: _buildStatCard(
                  context,
                  'Eliminadas',
                  stats.deleted.toString(),
                  Icons.delete,
                  Colors.red,
                ),
              ),
            if (stats.inactive == 0 && stats.deleted == 0)
              const Expanded(flex: 2, child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopStats(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total de Categorías',
            stats.total.toString(),
            Icons.category,
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12), // ✅ Reducido de 20 a 12
        Expanded(
          child: _buildStatCard(
            context,
            'Categorías Activas',
            stats.active.toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12), // ✅ Reducido de 20 a 12
        Expanded(
          child: _buildStatCard(
            context,
            'Categorías Padre', // ✅ CORRECCIÓN: Solo las padre reales
            stats.parents.toString(),
            Icons.account_tree,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12), // ✅ Reducido de 20 a 12
        Expanded(
          child: _buildStatCard(
            context,
            'Subcategorías', // ✅ CORRECCIÓN: Solo las subcategorías
            stats.children.toString(),
            Icons.subdirectory_arrow_right,
            Colors.orange,
          ),
        ),
        if (stats.inactive > 0) ...[
          const SizedBox(width: 12), // ✅ Reducido de 20 a 12
          Expanded(
            child: _buildStatCard(
              context,
              'Inactivas',
              stats.inactive.toString(),
              Icons.pause_circle,
              Colors.orange.shade300,
            ),
          ),
        ],
        if (stats.deleted > 0) ...[
          const SizedBox(width: 12), // ✅ Reducido de 20 a 12
          Expanded(
            child: _buildStatCard(
              context,
              'Eliminadas',
              stats.deleted.toString(),
              Icons.delete,
              Colors.red,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      padding: EdgeInsets.all(context.isMobile ? 8 : 10), // ✅ Reducido 65%
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Evita overflow
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4), // ✅ Reducido de 8 a 4
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6), // ✅ Reducido de 8 a 6
                ),
                child: Icon(
                  icon,
                  color: color,
                  size:
                      context.isMobile ? 14 : 16, // ✅ Reducido de 20/24 a 14/16
                ),
              ),
              const SizedBox(width: 6), // ✅ Reducido de 8 a 6
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.getFontSize(
                      context,
                      mobile: 16, // ✅ Reducido de 20 a 16
                      tablet: 18, // ✅ Reducido de 24 a 18
                      desktop: 20, // ✅ Reducido de 28 a 20
                    ),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
            height: context.isMobile ? 4 : 6,
          ), // ✅ Reducido de 8/12 a 4/6
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.getFontSize(
                context,
                mobile: 10, // ✅ Reducido de 12 a 10
                tablet: 11, // ✅ Reducido de 14 a 11
                desktop: 12, // ✅ Reducido de 16 a 12
              ),
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4), // ✅ Reducido de 6 a 4
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4), // ✅ Reducido de 6 a 4
          ),
          child: Icon(icon, color: color, size: 12), // ✅ Reducido de 16 a 12
        ),
        const SizedBox(height: 3), // ✅ Reducido de 4 a 3
        Text(
          value,
          style: TextStyle(
            fontSize: 12, // ✅ Reducido de 16 a 12
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.grey.shade600,
          ), // ✅ Reducido de 10 a 8
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 25,
      width: 1,
      color: Colors.grey.shade300,
    ); // ✅ Reducido de 40 a 25
  }

  // ✅ NUEVO: Método para debugging de estadísticas
  void debugStats() {
    print('📊 CATEGORY STATS DEBUG:');
    print('   Total: ${stats.total}');
    print('   Active: ${stats.active}');
    print('   Inactive: ${stats.inactive}');
    print('   Parents: ${stats.parents} (solo categorías padre reales)');
    print('   Children: ${stats.children} (subcategorías)');
    print('   Deleted: ${stats.deleted}');
    print(
      '   ✅ Parents + Children = ${stats.parents + stats.children} (should equal total)',
    );
  }
}
