// import 'package:flutter/material.dart';
// import '../../../../app/core/utils/responsive.dart';

// class AuthHeaderWidget extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final Widget? logo;
//   final Color? titleColor;
//   final Color? subtitleColor;

//   const AuthHeaderWidget({
//     Key? key,
//     required this.title,
//     required this.subtitle,
//     this.logo,
//     this.titleColor,
//     this.subtitleColor,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Logo o ícono
//         if (logo != null)
//           logo!
//         else
//           Container(
//             width: context.isMobile ? 80 : 100,
//             height: context.isMobile ? 80 : 100,
//             decoration: BoxDecoration(
//               color: Theme.of(context).primaryColor.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Icon(
//               Icons.desktop_windows,
//               size: context.isMobile ? 40 : 50,
//               color: Theme.of(context).primaryColor,
//             ),
//           ),

//         SizedBox(height: context.verticalSpacing),

//         // Título
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(
//               context,
//               mobile: 28,
//               tablet: 32,
//               desktop: 36,
//             ),
//             fontWeight: FontWeight.bold,
//             color:
//                 titleColor ?? Theme.of(context).textTheme.headlineLarge?.color,
//           ),
//           textAlign: TextAlign.center,
//         ),

//         SizedBox(height: context.verticalSpacing / 2),

//         // Subtítulo
//         Text(
//           subtitle,
//           style: TextStyle(
//             fontSize: Responsive.getFontSize(
//               context,
//               mobile: 16,
//               tablet: 18,
//               desktop: 20,
//             ),
//             color: subtitleColor ?? Colors.grey.shade600,
//           ),
//           textAlign: TextAlign.center,
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../../../../app/core/utils/responsive.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? logo;
  final Color? titleColor;
  final Color? subtitleColor;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.logo,
    this.titleColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo o ícono
        if (logo != null)
          logo!
        else
          Container(
            width: context.isMobile ? 80 : 100,
            height: context.isMobile ? 80 : 100,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.desktop_windows,
              size: context.isMobile ? 40 : 50,
              color: Theme.of(context).primaryColor,
            ),
          ),

        SizedBox(height: context.verticalSpacing),

        // Título
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 28,
              tablet: 32,
              desktop: 36,
            ),
            fontWeight: FontWeight.bold,
            color:
                titleColor ?? Theme.of(context).textTheme.headlineLarge?.color,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: context.verticalSpacing / 2),

        // Subtítulo
        Text(
          subtitle,
          style: TextStyle(
            fontSize: Responsive.getFontSize(
              context,
              mobile: 16,
              tablet: 18,
              desktop: 20,
            ),
            color: subtitleColor ?? Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
