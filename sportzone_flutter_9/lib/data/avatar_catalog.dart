import '../models/user_models.dart';

/// Catálogo de prendas del avatar. Cada id tiene su PNG en assets/avatar/.
/// Los PNG se generan con `tool/generate_avatar_assets.py`.
/// Las prendas OFICIALES de cada club no están aquí: vienen de la API
/// (ver lib/services/merch_api.dart).
const List<AvatarItem> avatarCatalog = [
  // ── Base: cuerpo, cabello, cara y básicos ──
  AvatarItem('body_pale', 'Piel muy clara', AvatarSlot.body, AvatarCategory.base),
  AvatarItem('body_light', 'Piel clara', AvatarSlot.body, AvatarCategory.base),
  AvatarItem('body_medium', 'Piel media', AvatarSlot.body, AvatarCategory.base),
  AvatarItem('body_tan', 'Piel morena', AvatarSlot.body, AvatarCategory.base),
  AvatarItem('body_dark', 'Piel oscura', AvatarSlot.body, AvatarCategory.base),
  AvatarItem('hair_short_brown', 'Corto castaño', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_short_black', 'Corto negro', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_short_blond', 'Corto rubio', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_buzz', 'Rapado', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_afro', 'Afro', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_curly_red', 'Rizado pelirrojo', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_long_brown', 'Largo castaño', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_long_blond', 'Largo rubio', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_bun', 'Moño', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('hair_mohawk', 'Cresta', AvatarSlot.hair, AvatarCategory.base),
  AvatarItem('face_beard', 'Barba castaña', AvatarSlot.face, AvatarCategory.base),
  AvatarItem('face_beard_black', 'Barba negra', AvatarSlot.face, AvatarCategory.base),
  AvatarItem('face_stubble', 'Barba de 3 días', AvatarSlot.face, AvatarCategory.base),
  AvatarItem('face_sunglasses', 'Gafas de sol', AvatarSlot.face, AvatarCategory.base),
  AvatarItem('top_basic_white', 'Camiseta blanca', AvatarSlot.top, AvatarCategory.base),
  AvatarItem('top_basic_gray', 'Camiseta gris', AvatarSlot.top, AvatarCategory.base),
  AvatarItem('top_basic_black', 'Camiseta negra SZ', AvatarSlot.top, AvatarCategory.base),
  AvatarItem('neck_chain', 'Cadena dorada', AvatarSlot.neck, AvatarCategory.base),
  AvatarItem('neck_medal_gold', 'Medalla de oro', AvatarSlot.neck, AvatarCategory.base, exclusive: true),
  AvatarItem('head_crown', 'Corona de campeón', AvatarSlot.head, AvatarCategory.base, exclusive: true),

  // ── Fútbol ──
  AvatarItem('top_fb_red', 'Camiseta roja', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_blue', 'Camiseta azul', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_white', 'Camiseta blanca', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_green', 'Camiseta verde', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_yellow', 'Camiseta amarilla', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_stripes', 'Rayas blanquinegras', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_sky', 'Rayas celestes', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_redblack', 'Rayas rojinegras', AvatarSlot.top, AvatarCategory.football),
  AvatarItem('top_fb_gold', 'Camiseta dorada leyenda', AvatarSlot.top, AvatarCategory.football, exclusive: true),
  AvatarItem('bottom_fb_white', 'Short blanco y medias', AvatarSlot.bottom, AvatarCategory.football),
  AvatarItem('bottom_fb_black', 'Short negro y medias', AvatarSlot.bottom, AvatarCategory.football),
  AvatarItem('bottom_fb_blue', 'Short azul y medias', AvatarSlot.bottom, AvatarCategory.football),
  AvatarItem('bottom_fb_green', 'Short verde y medias', AvatarSlot.bottom, AvatarCategory.football),
  AvatarItem('neck_fb_scarf_red', 'Bufanda roja', AvatarSlot.neck, AvatarCategory.football),
  AvatarItem('neck_fb_scarf_green', 'Bufanda verde', AvatarSlot.neck, AvatarCategory.football),
  AvatarItem('face_paint', 'Pintura tricolor', AvatarSlot.face, AvatarCategory.football),
  AvatarItem('hand_fb_ball', 'Balón de fútbol', AvatarSlot.hand, AvatarCategory.football),
  AvatarItem('hand_fb_gloves', 'Guantes de portero', AvatarSlot.hand, AvatarCategory.football),
  AvatarItem('hand_fb_captain', 'Brazalete de capitán', AvatarSlot.hand, AvatarCategory.football),

  // ── NBA ──
  AvatarItem('top_nba_purple', 'Jersey morado', AvatarSlot.top, AvatarCategory.nba),
  AvatarItem('top_nba_green', 'Jersey verde', AvatarSlot.top, AvatarCategory.nba),
  AvatarItem('top_nba_red', 'Jersey rojo', AvatarSlot.top, AvatarCategory.nba),
  AvatarItem('top_nba_blue', 'Jersey azul', AvatarSlot.top, AvatarCategory.nba),
  AvatarItem('top_nba_black', 'Jersey negro', AvatarSlot.top, AvatarCategory.nba),
  AvatarItem('top_nba_allstar', 'Jersey All-Star', AvatarSlot.top, AvatarCategory.nba, exclusive: true),
  AvatarItem('bottom_nba_purple', 'Pantaloneta morada', AvatarSlot.bottom, AvatarCategory.nba),
  AvatarItem('bottom_nba_green', 'Pantaloneta verde', AvatarSlot.bottom, AvatarCategory.nba),
  AvatarItem('bottom_nba_red', 'Pantaloneta roja', AvatarSlot.bottom, AvatarCategory.nba),
  AvatarItem('bottom_nba_blue', 'Pantaloneta azul', AvatarSlot.bottom, AvatarCategory.nba),
  AvatarItem('bottom_nba_black', 'Pantaloneta negra', AvatarSlot.bottom, AvatarCategory.nba),
  AvatarItem('head_nba_headband', 'Cinta blanca', AvatarSlot.head, AvatarCategory.nba),
  AvatarItem('head_nba_headband_black', 'Cinta negra', AvatarSlot.head, AvatarCategory.nba),
  AvatarItem('neck_nba_chain', 'Cadena de estrella', AvatarSlot.neck, AvatarCategory.nba),
  AvatarItem('hand_nba_ball', 'Balón de básquet', AvatarSlot.hand, AvatarCategory.nba),
  AvatarItem('hand_nba_wristbands', 'Muñequeras', AvatarSlot.hand, AvatarCategory.nba),

  // ── Tenis ──
  AvatarItem('top_tn_white', 'Polo blanco', AvatarSlot.top, AvatarCategory.tennis),
  AvatarItem('top_tn_orange', 'Polo naranja', AvatarSlot.top, AvatarCategory.tennis),
  AvatarItem('top_tn_blue', 'Polo azul', AvatarSlot.top, AvatarCategory.tennis),
  AvatarItem('top_tn_pink', 'Polo rosado', AvatarSlot.top, AvatarCategory.tennis),
  AvatarItem('bottom_tn_shorts', 'Short de tenis', AvatarSlot.bottom, AvatarCategory.tennis),
  AvatarItem('bottom_tn_skirt', 'Falda de tenis', AvatarSlot.bottom, AvatarCategory.tennis),
  AvatarItem('head_tn_cap', 'Gorra azul', AvatarSlot.head, AvatarCategory.tennis),
  AvatarItem('head_tn_cap_white', 'Gorra blanca', AvatarSlot.head, AvatarCategory.tennis),
  AvatarItem('head_tn_visor', 'Visera', AvatarSlot.head, AvatarCategory.tennis),
  AvatarItem('head_tn_headband', 'Cinta roja', AvatarSlot.head, AvatarCategory.tennis),
  AvatarItem('hand_tn_racket', 'Raqueta', AvatarSlot.hand, AvatarCategory.tennis),
  AvatarItem('hand_tn_wristbands', 'Muñequeras verdes', AvatarSlot.hand, AvatarCategory.tennis),
  AvatarItem('hand_tn_gold_racket', 'Raqueta de oro', AvatarSlot.hand, AvatarCategory.tennis, exclusive: true),

  // ── UFC: peleador ──
  AvatarItem('bottom_ufc_red', 'Pantaloneta roja', AvatarSlot.bottom, AvatarCategory.ufc),
  AvatarItem('bottom_ufc_blue', 'Pantaloneta azul', AvatarSlot.bottom, AvatarCategory.ufc),
  AvatarItem('bottom_ufc_black', 'Pantaloneta negra y oro', AvatarSlot.bottom, AvatarCategory.ufc),
  AvatarItem('bottom_ufc_white', 'Pantaloneta blanca', AvatarSlot.bottom, AvatarCategory.ufc),
  AvatarItem('top_ufc_rashguard', 'Rashguard negro', AvatarSlot.top, AvatarCategory.ufc),
  AvatarItem('top_ufc_rashguard_blue', 'Rashguard azul', AvatarSlot.top, AvatarCategory.ufc),
  AvatarItem('top_ufc_walkout', 'Camiseta de salida', AvatarSlot.top, AvatarCategory.ufc),
  AvatarItem('hand_ufc_gloves', 'Guantes MMA negros', AvatarSlot.hand, AvatarCategory.ufc),
  AvatarItem('hand_ufc_gloves_red', 'Guantes MMA rojos', AvatarSlot.hand, AvatarCategory.ufc),
  AvatarItem('hand_ufc_wraps', 'Vendas de mano', AvatarSlot.hand, AvatarCategory.ufc),
  AvatarItem('tattoo_tribal', 'Tatuaje tribal', AvatarSlot.tattoo, AvatarCategory.ufc),
  AvatarItem('tattoo_sleeves', 'Mangas tatuadas', AvatarSlot.tattoo, AvatarCategory.ufc),
  AvatarItem('tattoo_chest', 'Alas en el pecho', AvatarSlot.tattoo, AvatarCategory.ufc),
  AvatarItem('tattoo_rose', 'Rosa en el brazo', AvatarSlot.tattoo, AvatarCategory.ufc),
  AvatarItem('tattoo_full', 'Tatuajes completos', AvatarSlot.tattoo, AvatarCategory.ufc),
  AvatarItem('face_ufc_blackeye', 'Ojo morado', AvatarSlot.face, AvatarCategory.ufc),
  AvatarItem('face_ufc_mouthguard', 'Protector bucal', AvatarSlot.face, AvatarCategory.ufc),
  AvatarItem('waist_ufc_belt_silver', 'Cinturón interino', AvatarSlot.waist, AvatarCategory.ufc),
  AvatarItem('waist_ufc_belt', 'Cinturón de campeón', AvatarSlot.waist, AvatarCategory.ufc, exclusive: true),
];

AvatarItem? avatarItemById(String? id) {
  if (id == null) return null;
  for (final i in avatarCatalog) {
    if (i.id == id) return i;
  }
  return null;
}
