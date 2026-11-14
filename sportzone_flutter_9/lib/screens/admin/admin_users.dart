import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/app_theme.dart';
import '../../data/avatar_catalog.dart';
import '../../models/user_models.dart';
import '../../services/album_service.dart';
import '../../services/local_backend.dart';
import '../../services/support_store.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/common.dart';
import 'admin_panel_screen.dart';
import 'admin_support.dart';

/// Buscador de perfiles para moderar.
class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _q = TextEditingController();
  String _filter = 'all'; // all | suspended | muted | lost | admin

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: backend,
      builder: (context, _) {
        final list = backend.searchUsers(_q.text).where((u) => switch (_filter) {
              'suspended' => u.suspended,
              'muted' => u.muted,
              'lost' => u.lostStreak > 0,
              'admin' => u.isAdmin,
              _ => true,
            }).toList();
        Widget chip(String key, String label) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(label),
                selected: _filter == key,
                showCheckmark: false,
                onSelected: (_) => setState(() => _filter = key),
              ),
            );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: TextField(
                controller: _q,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Buscar por @usuario o correo',
                  prefixIcon: const Icon(Icons.person_search),
                  suffixIcon: _q.text.isEmpty
                      ? null
                      : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(_q.clear)),
                  filled: true,
                  fillColor: context.cardColor2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                children: [
                  chip('all', 'Todos'),
                  chip('lost', 'Perdieron racha'),
                  chip('suspended', 'Suspendidos'),
                  chip('muted', 'Silenciados'),
                  chip('admin', 'Admins'),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text('Ningún perfil coincide.', style: TextStyle(color: context.muted)))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) => _UserTile(user: list[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final u = user;
    return ListTile(
      leading: AvatarBubble(equipped: u.equipped, size: 46),
      title: Row(children: [
        Flexible(child: Text(u.handle, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
        if (u.isAdmin) const _Tag('ADMIN', AppColors.gold),
        if (u.suspended) const _Tag('SUSPENDIDO', AppColors.live),
        if (u.muted) const _Tag('SILENCIADO', Colors.blueGrey),
      ]),
      subtitle: Text(
        '${u.email ?? 'sin correo'} · 🔥 ${u.streak}${u.lostStreak > 0 ? ' (perdió ${u.lostStreak})' : ''}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(uid: u.uid))),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

/// Ficha de un usuario: racha, moderación, inventario e historial.
class AdminUserDetailScreen extends StatelessWidget {
  final String uid;
  const AdminUserDetailScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([backend, supportStore]),
      builder: (context, _) {
        final u = backend.userById(uid);
        if (u == null) return const Scaffold(body: Center(child: Text('Usuario no encontrado')));
        final admin = appState.user;
        final self = u.uid == admin.uid;
        final ticket = supportStore.currentFor(u.uid);

        void guard(VoidCallback action, String ok) {
          try {
            action();
            adminToast(context, ok);
          } on BackendException catch (e) {
            adminToast(context, e.message);
          }
        }

        return Scaffold(
          appBar: AppBar(title: Text(u.handle)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 30),
            children: [
              // ── Cabecera ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AppCard(
                  child: Row(
                    children: [
                      SizedBox(height: 120, child: AvatarView(equipped: u.equipped)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.handle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                            Text(u.email ?? 'Sin correo (registro con usuario)', style: TextStyle(fontSize: 12, color: context.muted)),
                            const SizedBox(height: 6),
                            Text('ID: ${u.uid} · Nivel ${u.xp ~/ 500 + 1} · ${u.xp} XP', style: TextStyle(fontSize: 12, color: context.muted)),
                            Text('Rol: ${u.role.label}', style: TextStyle(fontSize: 12, color: context.muted)),
                            if (ticket != null)
                              TextButton.icon(
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTicketScreen(ticketId: ticket.id))),
                                icon: const Icon(Icons.support_agent, size: 18),
                                label: Text('Ver ticket #${ticket.id.substring(1)}'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Racha ──
              const AdminSection('RACHA DE CONEXIÓN', subtitle: 'Corrige la racha si se perdió por un fallo de la app'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  borderColor: AppColors.fire.withValues(alpha: 0.4),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat('${u.streak}', 'Actual', AppColors.fire),
                          _Stat('${u.bestStreak}', 'Mejor', AppColors.gold),
                          _Stat('${u.lostStreak}', 'Perdida', u.lostStreak > 0 ? AppColors.live : Colors.grey),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: u.streak > 0 ? () => backend.setStreak(admin, u, u.streak - 1, reason: 'ajuste manual') : null,
                            icon: const Icon(Icons.remove),
                          ),
                          const SizedBox(width: 6),
                          IconButton.outlined(
                            onPressed: () => backend.setStreak(admin, u, u.streak + 1, reason: 'ajuste manual'),
                            icon: const Icon(Icons.add),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editStreak(context, u),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Fijar valor'),
                            ),
                          ),
                        ],
                      ),
                      if (u.lostStreak > 0) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.fire, foregroundColor: Colors.white),
                            onPressed: () => guard(() => backend.restoreLostStreak(admin, u), 'Racha restaurada ✅'),
                            icon: const Icon(Icons.restore),
                            label: Text('Restaurar racha perdida (${u.lostStreak} + ${u.streak} actuales)'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Álbum ──
              AdminSection('ÁLBUM Y SOBRES', subtitle: '${u.album.packs} sobres sin abrir · ${u.album.owned.length}/62 láminas'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  for (final n in const [1, 3, 5])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilledButton.tonalIcon(
                          onPressed: () => guard(() => album.giftPacks(admin, u, n), '🎁 $n ${n == 1 ? 'sobre regalado' : 'sobres regalados'} a ${u.handle}'),
                          icon: const Icon(Icons.mail, size: 18),
                          label: Text('+$n'),
                        ),
                      ),
                    ),
                ]),
              ),

              // ── Moderación ──
              const AdminSection('MODERACIÓN'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.block, color: AppColors.live),
                        title: const Text('Cuenta suspendida'),
                        subtitle: Text(u.suspended ? 'Motivo: ${u.moderationNote ?? 'sin motivo'}' : 'No puede iniciar sesión mientras esté activa'),
                        value: u.suspended,
                        onChanged: self
                            ? null
                            : (v) async {
                                if (v) {
                                  final note = await _askText(context, 'Motivo de la suspensión', 'Ej: spam, insultos...');
                                  if (note == null) return;
                                  if (!context.mounted) return;
                                  guard(() => backend.setSuspended(admin, u, true, note: note), '@${u.username} suspendido');
                                } else {
                                  guard(() => backend.setSuspended(admin, u, false), '@${u.username} reactivado');
                                }
                              },
                      ),
                      SwitchListTile(
                        secondary: const Icon(Icons.voice_over_off),
                        title: const Text('Silenciado en los chats'),
                        subtitle: const Text('Puede usar la app, pero no escribir en los chats de partidos'),
                        value: u.muted,
                        onChanged: (v) => guard(() => backend.setMuted(admin, u, v), v ? 'Usuario silenciado' : 'Silencio retirado'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.shield_outlined),
                        title: const Text('Rol'),
                        subtitle: self ? const Text('No puedes cambiar tu propio rol') : null,
                        trailing: DropdownButton<UserRole>(
                          value: u.role,
                          onChanged: self
                              ? null
                              : (r) {
                                  if (r == null) return;
                                  guard(() => backend.setRole(admin, u, r), 'Rol actualizado: ${r.label}');
                                },
                          items: [for (final r in UserRole.values) DropdownMenuItem(value: r, child: Text(r.label))],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Inventario ──
              AdminSection(
                'INVENTARIO DE AVATAR',
                subtitle: 'Regala prendas exclusivas o bloquéale prendas a este perfil',
                trailing: TextButton.icon(
                  onPressed: () => _blockAny(context, u),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Bloquear otra'),
                ),
              ),
              for (final item in avatarCatalog.where((i) => i.exclusive || u.blockedItems.contains(i.id)))
                InventoryRow(user: u, item: item),

              // ── Historial ──
              const AdminSection('HISTORIAL DE MODERACIÓN'),
              ...() {
                final entries = backend.log.where((e) => e.targetUid == u.uid).toList();
                if (entries.isEmpty) {
                  return [Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('Sin acciones todavía.', style: TextStyle(color: context.muted)))];
                }
                return [
                  for (final e in entries)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 20),
                      title: Text(e.action),
                      subtitle: Text('por @${e.admin} · hace ${timeAgo(e.time)}'),
                    ),
                ];
              }(),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editStreak(BuildContext context, AppUser u) async {
    final c = TextEditingController(text: '${u.streak}');
    final reason = TextEditingController(text: 'Fallo técnico de la app');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Racha de ${u.handle}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: c,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            decoration: const InputDecoration(labelText: 'Días de racha', suffixText: 'días'),
          ),
          TextField(controller: reason, decoration: const InputDecoration(labelText: 'Motivo (queda en el historial)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    final v = int.tryParse(c.text);
    if (ok == true && v != null) {
      backend.setStreak(appState.user, u, v, reason: reason.text.trim());
      if (context.mounted) adminToast(context, 'Racha de ${u.handle}: $v días');
    }
    c.dispose();
    reason.dispose();
  }

  Future<void> _blockAny(BuildContext context, AppUser u) async {
    final item = await showModalBottomSheet<AvatarItem>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        children: [
          for (final i in avatarCatalog.where((i) => i.slot != AvatarSlot.body && !u.blockedItems.contains(i.id)))
            ListTile(
              leading: Image.asset(i.thumb, width: 40, height: 40),
              title: Text(i.name),
              subtitle: Text('${i.category.label} · ${i.slot.label}'),
              onTap: () => Navigator.pop(ctx, i),
            ),
        ],
      ),
    );
    if (item != null) {
      backend.blockItemForUser(appState.user, u, item.id);
      if (context.mounted) adminToast(context, '${item.name} bloqueada para ${u.handle}');
    }
  }
}

/// Una prenda en el inventario de un usuario con sus acciones.
class InventoryRow extends StatelessWidget {
  final AppUser user;
  final AvatarItem item;
  const InventoryRow({super.key, required this.user, required this.item});

  @override
  Widget build(BuildContext context) {
    final admin = appState.user;
    final has = user.inventory.contains(item.id);
    final blocked = user.blockedItems.contains(item.id);
    final status = blocked ? 'Bloqueada' : (has ? 'En su inventario' : (item.exclusive ? 'No la tiene' : 'Disponible'));
    return ListTile(
      leading: Image.asset(item.thumb, width: 44, height: 44),
      title: Row(children: [
        Flexible(child: Text(item.name)),
        if (item.exclusive) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.star, size: 15, color: AppColors.gold)),
      ]),
      subtitle: Text('$status · ${item.category.label}',
          style: TextStyle(color: blocked ? AppColors.live : (has ? AppColors.green : context.muted))),
      trailing: Wrap(
        spacing: 4,
        children: [
          if (blocked)
            TextButton(onPressed: () => backend.unblockItemForUser(admin, user, item.id), child: const Text('Desbloquear'))
          else ...[
            if (item.exclusive && !has)
              FilledButton.tonalIcon(
                onPressed: () {
                  backend.giftItem(admin, user, item.id);
                  adminToast(context, '🎁 ${item.name} regalada a ${user.handle}');
                },
                icon: const Icon(Icons.card_giftcard, size: 18),
                label: const Text('Regalar'),
              ),
            IconButton(
              tooltip: has ? 'Quitar y bloquear' : 'Bloquear',
              onPressed: () => backend.blockItemForUser(admin, user, item.id),
              icon: const Icon(Icons.block, color: AppColors.live),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _Stat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: display(32, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: context.muted)),
      ]);
}

Future<String?> _askText(BuildContext context, String title, String hint) async {
  final c = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: hint)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmar')),
      ],
    ),
  );
  final text = c.text;
  c.dispose();
  return ok == true ? text : null;
}
