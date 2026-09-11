import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../role_view_controller.dart';

/// StreamBuilder that automatically refreshes when role changes
class RoleAwareStreamBuilder<T> extends StatelessWidget {

  final Stream<T> Function(String role) streamFactory;
  final Widget Function(BuildContext context, AsyncSnapshot<T> snapshot) builder;

  const RoleAwareStreamBuilder({
    super.key,
    required this.streamFactory,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {

    /// Listen only to role change
    final activeRole =
    context.select<RoleViewController, String>((v) => v.activeRole);

    return StreamBuilder<T>(
      stream: streamFactory(activeRole),
      builder: builder,
    );
  }
}