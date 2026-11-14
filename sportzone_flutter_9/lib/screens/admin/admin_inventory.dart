import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../data/avatar_catalog.dart';
import '../../models/user_models.dart';
import '../../services/local_backend.dart';
import '../../widgets/avatar_view.dart';
import 'admin_panel_screen.dart';

/// Inventario de avatares: habilitar/bloquear prendas para todos y
/// regalar las exclusivas a perfiles específicos.
class AdminInventoryTab extends StatelessWidget {
  const AdminInventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: backend,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 30),
          children: [
            for (final cat in AvatarCategory.values) ...[
              AdminSection(cat.label.toUpperCase(), subtitle: cat == AvatarCategory.base ? 'Cuerpos y accesorios generales' : null),
              for (final item in avatarCatalog.where((i) => i.category == cat)) _CatalogRow(item: item),
            ],
          ],
        );
      },
    );
  }
}

class _CatalogRow extends StatelessWidget {
  final AvatarItem item;
  const _CatalogRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final enabled = backend.itemEnabled(item.id);
    final owners = backend.allUsers.where((u) => u.inventory.contains(item.id)).length;
    final wearing = backend.allUsers.where((u) => u.equipped[item.slot] == item.id).length;
    final isBody = item.slot == AvatarSlot.body;
    return ListTile(
      leading: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Image.asset(item.thumb, width: 46, height: 46),
      ),
      title: Row(children: [
        Flexible(child: Text(item.name, overflow: TextOverflow.ellipsis)),
        if (item.exclusive) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star, size: 15, color: AppColors.gold)),
      ]),
      subtitle: Text(
        '${item.slot.label} · $wearing la usan${item.exclusive ? ' · $owners la tienen' : ''}${enabled ? '' : ' · BLOQUEADA'}',
        style: TextStyle(fontSize: 12, color: enabled ? context.muted : AppColors.live),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (item.exclusive)
            IconButton(
              tooltip: 'Regalar a un usuario',
              icon: const Icon(Icons.card_giftcard),
              onPressed: enabled ? () => _gift(context) : null,
            ),
          Tooltip(
            message: isBody ? 'Los cuerpos base no se pueden bloquear' : (enabled ? 'Bloquear para todos' : 'Habilitar'),
            child: Switch(
              value: enabled,
              onChanged: isBody
                  ? null
                  : (v) {
                      backend.setItemEnabled(appState.user, item.id, v);
                      adminToast(context, v ? '${item.name} habilitada' : '${item.name} bloqueada para todos (se le quitó a quien la tenía puesta)');
                    },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _gift(BuildContext context) async {
    final target = await pickUser(context, title: 'Regalar "${item.name}" a...');
    if (target == null || !context.mounted) return;
    if (target.inventory.contains(item.id)) {
      adminToast(context, '${target.handle} ya tiene esta prenda');
      return;
    }
    backend.giftItem(appState.user, target, item.id);
    adminToast(context, '🎁 ${item.name} regalada a ${target.handle}');
  }
}

/// Hoja inferior con buscador para elegir un usuario.
Future<AppUser?> pickUser(BuildContext context, {required String title}) {
  return showModalBottomSheet<AppUser>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _UserPicker(title: title),
  );
}

class _UserPicker extends StatefulWidget {
  final String title;
  const _UserPicker({required this.title});

  @override
  State<_UserPicker> createState() => _UserPickerState();
}

class _UserPickerState extends State<_UserPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final list = backend.searchUsers(_q);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Text(widget.title, style: display(20)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: '@usuario o correo', border: OutlineInputBorder()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => ListTile(
                  leading: AvatarBubble(equipped: list[i].equipped, size: 40),
                  title: Text(list[i].handle),
                  subtitle: Text(list[i].email ?? 'sin correo'),
                  onTap: () => Navigator.pop(context, list[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
