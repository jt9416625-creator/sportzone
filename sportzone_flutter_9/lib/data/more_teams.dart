import 'package:flutter/material.dart';

import '../models/models.dart';

// Equipos, peleadores y tenistas extra para elegir como favoritos SIN internet.
// Con internet, ESPN completa la lista con TODOS los equipos de cada liga
// (EspnApi.loadAllTeams) y reemplaza estos escudos por los oficiales.

const _fd = 'https://crests.football-data.org';
const _nba = 'https://a.espncdn.com/i/teamlogos/nba/500';

Team _fb(String id, String name, String short, int color, {int? alt, int? crest, String country = ''}) => Team(
      id: id,
      name: name,
      short: short,
      sport: Sport.football,
      color: Color(color),
      altColor: alt == null ? null : Color(alt),
      crestUrl: crest == null ? null : '$_fd/$crest.png',
      country: country,
    );

Team _nb(String id, String name, String abbr, int color, int alt) => Team(
      id: id,
      name: name,
      short: abbr.toUpperCase(),
      sport: Sport.basketball,
      color: Color(color),
      altColor: Color(alt),
      crestUrl: '$_nba/$abbr.png',
      country: 'EE. UU.',
    );

Team _tn(String id, String name, String short, String flag, int color) =>
    Team(id: id, name: name, short: short, sport: Sport.tennis, color: Color(color), country: flag);

Team _ufc(String id, String name, String short, String flag, String weight, int color) =>
    Team(id: id, name: name, short: short, sport: Sport.ufc, color: Color(color), country: '$flag $weight');

/// (equipo, liga). La liga se usa en los filtros del buscador.
final List<(Team, String)> extraTeams = [
  // ── Premier League ──
  (_fb('x_mun', 'Manchester United', 'MUN', 0xFFDA291C, alt: 0xFFFBE122, crest: 66), 'Premier League'),
  (_fb('x_che', 'Chelsea', 'CHE', 0xFF034694, alt: 0xFFFFFFFF, crest: 61), 'Premier League'),
  (_fb('x_tot', 'Tottenham Hotspur', 'TOT', 0xFF132257, alt: 0xFFFFFFFF, crest: 73), 'Premier League'),
  (_fb('x_new', 'Newcastle United', 'NEW', 0xFF241F20, alt: 0xFFFFFFFF, crest: 67), 'Premier League'),
  (_fb('x_avl', 'Aston Villa', 'AVL', 0xFF670E36, alt: 0xFF95BFE5, crest: 58), 'Premier League'),
  (_fb('x_whu', 'West Ham United', 'WHU', 0xFF7A263A, alt: 0xFF1BB1E7, crest: 563), 'Premier League'),
  (_fb('x_bha', 'Brighton & Hove Albion', 'BHA', 0xFF0057B8, alt: 0xFFFFFFFF, crest: 397), 'Premier League'),
  // ── LaLiga ──
  (_fb('x_sev', 'Sevilla', 'SEV', 0xFFFFFFFF, alt: 0xFFD4021D, crest: 559), 'LaLiga'),
  (_fb('x_rso', 'Real Sociedad', 'RSO', 0xFF0067B1, alt: 0xFFFFFFFF, crest: 92), 'LaLiga'),
  (_fb('x_vil', 'Villarreal', 'VIL', 0xFFFFE667, alt: 0xFF005187, crest: 94), 'LaLiga'),
  (_fb('x_ath', 'Athletic Club', 'ATH', 0xFFEE2523, alt: 0xFFFFFFFF, crest: 77), 'LaLiga'),
  (_fb('x_bet', 'Real Betis', 'BET', 0xFF00954C, alt: 0xFFFFFFFF, crest: 90), 'LaLiga'),
  (_fb('x_val', 'Valencia', 'VAL', 0xFFFFFFFF, alt: 0xFFEE3524, crest: 95), 'LaLiga'),
  // ── Serie A ──
  (_fb('x_int', 'Inter de Milán', 'INT', 0xFF010E80, alt: 0xFF000000, crest: 108), 'Serie A'),
  (_fb('x_nap', 'Napoli', 'NAP', 0xFF12A0D7, alt: 0xFFFFFFFF, crest: 113), 'Serie A'),
  (_fb('x_rom', 'AS Roma', 'ROM', 0xFF8E1F2F, alt: 0xFFF0BC42, crest: 100), 'Serie A'),
  (_fb('x_laz', 'Lazio', 'LAZ', 0xFF87D8F7, alt: 0xFFFFFFFF, crest: 110), 'Serie A'),
  (_fb('x_ata', 'Atalanta', 'ATA', 0xFF1E71B8, alt: 0xFF000000, crest: 102), 'Serie A'),
  // ── Bundesliga ──
  (_fb('x_bvb', 'Borussia Dortmund', 'BVB', 0xFFFDE100, alt: 0xFF000000, crest: 4), 'Bundesliga'),
  (_fb('x_b04', 'Bayer Leverkusen', 'B04', 0xFFE32221, alt: 0xFF000000, crest: 3), 'Bundesliga'),
  (_fb('x_rbl', 'RB Leipzig', 'RBL', 0xFFFFFFFF, alt: 0xFFDD0741, crest: 721), 'Bundesliga'),
  (_fb('x_sge', 'Eintracht Frankfurt', 'SGE', 0xFFE1000F, alt: 0xFF000000, crest: 19), 'Bundesliga'),
  // ── Ligue 1 ──
  (_fb('x_om', 'Marseille', 'OM', 0xFF2FAEE0, alt: 0xFFFFFFFF, crest: 516), 'Ligue 1'),
  (_fb('x_asm', 'AS Monaco', 'ASM', 0xFFE7192B, alt: 0xFFFFFFFF, crest: 548), 'Ligue 1'),
  (_fb('x_ol', 'Lyon', 'OL', 0xFFFFFFFF, alt: 0xFF1A2E5B, crest: 523), 'Ligue 1'),
  (_fb('x_losc', 'Lille', 'LIL', 0xFFE01E13, alt: 0xFF1A2B4C, crest: 521), 'Ligue 1'),
  // ── Portugal / Países Bajos ──
  (_fb('x_ben', 'Benfica', 'BEN', 0xFFE83030, alt: 0xFFFFFFFF, crest: 1903), 'Liga Portugal'),
  (_fb('x_por', 'FC Porto', 'POR', 0xFF00428C, alt: 0xFFFFFFFF, crest: 503), 'Liga Portugal'),
  (_fb('x_scp', 'Sporting CP', 'SCP', 0xFF008057, alt: 0xFFFFFFFF, crest: 498), 'Liga Portugal'),
  (_fb('x_aja', 'Ajax', 'AJA', 0xFFD2122E, alt: 0xFFFFFFFF, crest: 678), 'Eredivisie'),
  (_fb('x_psv', 'PSV Eindhoven', 'PSV', 0xFFED1C24, alt: 0xFFFFFFFF, crest: 674), 'Eredivisie'),
  (_fb('x_fey', 'Feyenoord', 'FEY', 0xFFE4002B, alt: 0xFFFFFFFF, crest: 675), 'Eredivisie'),
  // ── Liga BetPlay (Colombia) ──
  (_fb('x_nac', 'Atlético Nacional', 'NAC', 0xFF00843D, alt: 0xFFFFFFFF, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_mil', 'Millonarios', 'MIL', 0xFF0033A0, alt: 0xFFFFFFFF, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_ame', 'América de Cali', 'AME', 0xFFD50032, alt: 0xFFFFFFFF, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_jun', 'Junior', 'JUN', 0xFFD52B1E, alt: 0xFFFFFFFF, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_cal', 'Deportivo Cali', 'CAL', 0xFF00873E, alt: 0xFFFFFFFF, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_sfe', 'Independiente Santa Fe', 'SFE', 0xFFC8102E, alt: 0xFFFFFFFF, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_dim', 'Independiente Medellín', 'DIM', 0xFFCE1126, alt: 0xFF0033A0, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_onc', 'Once Caldas', 'ONC', 0xFFFFFFFF, alt: 0xFF000000, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_tol', 'Deportes Tolima', 'TOL', 0xFF7B1C2E, alt: 0xFFF2C300, country: 'Colombia'), 'Liga BetPlay'),
  (_fb('x_buc', 'Atlético Bucaramanga', 'BUC', 0xFFFFD100, alt: 0xFF00843D, country: 'Colombia'), 'Liga BetPlay'),
  // ── Sudamérica ──
  (_fb('x_boc', 'Boca Juniors', 'BOC', 0xFF103F79, alt: 0xFFF3B229, country: 'Argentina'), 'Liga Profesional'),
  (_fb('x_riv', 'River Plate', 'RIV', 0xFFFFFFFF, alt: 0xFFE30613, country: 'Argentina'), 'Liga Profesional'),
  (_fb('x_rac', 'Racing Club', 'RAC', 0xFF6CACE4, alt: 0xFFFFFFFF, country: 'Argentina'), 'Liga Profesional'),
  (_fb('x_ind', 'Independiente', 'IND', 0xFFE30613, alt: 0xFFFFFFFF, country: 'Argentina'), 'Liga Profesional'),
  (_fb('x_fla', 'Flamengo', 'FLA', 0xFFC4122E, alt: 0xFF000000, country: 'Brasil'), 'Brasileirão'),
  (_fb('x_pal', 'Palmeiras', 'PAL', 0xFF006437, alt: 0xFFFFFFFF, country: 'Brasil'), 'Brasileirão'),
  (_fb('x_cor', 'Corinthians', 'COR', 0xFF111111, alt: 0xFFFFFFFF, country: 'Brasil'), 'Brasileirão'),
  (_fb('x_spa', 'São Paulo', 'SAO', 0xFFFFFFFF, alt: 0xFFE30613, country: 'Brasil'), 'Brasileirão'),
  // ── Liga MX / MLS ──
  (_fb('x_cam', 'Club América', 'AME', 0xFFFFE600, alt: 0xFF002D72, country: 'México'), 'Liga MX'),
  (_fb('x_gdl', 'Guadalajara', 'GDL', 0xFFCD1F2D, alt: 0xFF002D72, country: 'México'), 'Liga MX'),
  (_fb('x_cru', 'Cruz Azul', 'CAZ', 0xFF0047BB, alt: 0xFFFFFFFF, country: 'México'), 'Liga MX'),
  (_fb('x_tig', 'Tigres UANL', 'TIG', 0xFFFDB913, alt: 0xFF003DA5, country: 'México'), 'Liga MX'),
  (_fb('x_mty', 'Monterrey', 'MTY', 0xFF002D72, alt: 0xFFFFFFFF, country: 'México'), 'Liga MX'),
  (_fb('x_mia', 'Inter Miami', 'MIA', 0xFFF7B5CD, alt: 0xFF231F20, country: 'EE. UU.'), 'MLS'),
  (_fb('x_lag', 'LA Galaxy', 'LA', 0xFF00245D, alt: 0xFFFFD200, country: 'EE. UU.'), 'MLS'),
  (_fb('x_laf', 'LAFC', 'LAFC', 0xFF000000, alt: 0xFFC39E6D, country: 'EE. UU.'), 'MLS'),
  (_fb('x_sea', 'Seattle Sounders', 'SEA', 0xFF5D9741, alt: 0xFF005595, country: 'EE. UU.'), 'MLS'),

  // ── NBA (las 30 franquicias junto con las de mock_data) ──
  (_nb('x_atl', 'Atlanta Hawks', 'atl', 0xFFE03A3E, 0xFFFFFFFF), 'NBA'),
  (_nb('x_bkn', 'Brooklyn Nets', 'bkn', 0xFF000000, 0xFFFFFFFF), 'NBA'),
  (_nb('x_cha', 'Charlotte Hornets', 'cha', 0xFF1D1160, 0xFF00788C), 'NBA'),
  (_nb('x_chi_nba', 'Chicago Bulls', 'chi', 0xFFCE1141, 0xFF000000), 'NBA'),
  (_nb('x_cle', 'Cleveland Cavaliers', 'cle', 0xFF860038, 0xFFFDBB30), 'NBA'),
  (_nb('x_dal', 'Dallas Mavericks', 'dal', 0xFF00538C, 0xFFB8C4CA), 'NBA'),
  (_nb('x_det', 'Detroit Pistons', 'det', 0xFFC8102E, 0xFF1D42BA), 'NBA'),
  (_nb('x_hou', 'Houston Rockets', 'hou', 0xFFCE1141, 0xFFFFFFFF), 'NBA'),
  (_nb('x_ind_nba', 'Indiana Pacers', 'ind', 0xFF002D62, 0xFFFDBB30), 'NBA'),
  (_nb('x_lac', 'LA Clippers', 'lac', 0xFFC8102E, 0xFF1D428A), 'NBA'),
  (_nb('x_mem', 'Memphis Grizzlies', 'mem', 0xFF5D76A9, 0xFF12173F), 'NBA'),
  (_nb('x_min', 'Minnesota Timberwolves', 'min', 0xFF0C2340, 0xFF78BE20), 'NBA'),
  (_nb('x_nop', 'New Orleans Pelicans', 'no', 0xFF0C2340, 0xFFC8102E), 'NBA'),
  (_nb('x_okc', 'Oklahoma City Thunder', 'okc', 0xFF007AC1, 0xFFEF3B24), 'NBA'),
  (_nb('x_orl', 'Orlando Magic', 'orl', 0xFF0077C0, 0xFFC4CED4), 'NBA'),
  (_nb('x_phi', 'Philadelphia 76ers', 'phi', 0xFF006BB6, 0xFFED174C), 'NBA'),
  (_nb('x_phx', 'Phoenix Suns', 'phx', 0xFF1D1160, 0xFFE56020), 'NBA'),
  (_nb('x_por_nba', 'Portland Trail Blazers', 'por', 0xFFE03A3E, 0xFF000000), 'NBA'),
  (_nb('x_sac', 'Sacramento Kings', 'sac', 0xFF5A2D81, 0xFF63727A), 'NBA'),
  (_nb('x_sas', 'San Antonio Spurs', 'sa', 0xFF000000, 0xFFC4CED4), 'NBA'),
  (_nb('x_tor', 'Toronto Raptors', 'tor', 0xFFCE1141, 0xFF000000), 'NBA'),
  (_nb('x_uta', 'Utah Jazz', 'utah', 0xFF002B5C, 0xFFF9A01B), 'NBA'),
  (_nb('x_was', 'Washington Wizards', 'wsh', 0xFF002B5C, 0xFFE31837), 'NBA'),

  // ── Tenis ATP ──
  (_tn('x_zve', 'Alexander Zverev', 'ZVE', '🇩🇪', 0xFF34495E), 'Tenis ATP'),
  (_tn('x_fri', 'Taylor Fritz', 'FRI', '🇺🇸', 0xFF2471A3), 'Tenis ATP'),
  (_tn('x_dra', 'Jack Draper', 'DRA', '🇬🇧', 0xFF1F618D), 'Tenis ATP'),
  (_tn('x_rud', 'Casper Ruud', 'RUD', '🇳🇴', 0xFFC0392B), 'Tenis ATP'),
  (_tn('x_run', 'Holger Rune', 'RUN', '🇩🇰', 0xFFE74C3C), 'Tenis ATP'),
  (_tn('x_dem', 'Alex de Minaur', 'DEM', '🇦🇺', 0xFF1E8449), 'Tenis ATP'),
  (_tn('x_she', 'Ben Shelton', 'SHE', '🇺🇸', 0xFF2E86C1), 'Tenis ATP'),
  (_tn('x_tsi', 'Stefanos Tsitsipas', 'TSI', '🇬🇷', 0xFF2874A6), 'Tenis ATP'),
  (_tn('x_rub', 'Andrey Rublev', 'RUB', '🇷🇺', 0xFF7D3C98), 'Tenis ATP'),
  (_tn('x_mus', 'Lorenzo Musetti', 'MUS', '🇮🇹', 0xFF117A65), 'Tenis ATP'),
  (_tn('x_fon', 'João Fonseca', 'FON', '🇧🇷', 0xFF229954), 'Tenis ATP'),
  (_tn('x_cer', 'Francisco Cerúndolo', 'CER', '🇦🇷', 0xFF5DADE2), 'Tenis ATP'),
  // ── Tenis WTA ──
  (_tn('x_sab', 'Aryna Sabalenka', 'SAB', '🇧🇾', 0xFFCB4335), 'Tenis WTA'),
  (_tn('x_swi', 'Iga Świątek', 'SWI', '🇵🇱', 0xFFC0392B), 'Tenis WTA'),
  (_tn('x_gau', 'Coco Gauff', 'GAU', '🇺🇸', 0xFF2E86C1), 'Tenis WTA'),
  (_tn('x_ryb', 'Elena Rybakina', 'RYB', '🇰🇿', 0xFF2471A3), 'Tenis WTA'),
  (_tn('x_peg', 'Jessica Pegula', 'PEG', '🇺🇸', 0xFF1A5276), 'Tenis WTA'),
  (_tn('x_pao', 'Jasmine Paolini', 'PAO', '🇮🇹', 0xFF148F77), 'Tenis WTA'),
  (_tn('x_and', 'Mirra Andreeva', 'AND', '🇷🇺', 0xFF884EA0), 'Tenis WTA'),
  (_tn('x_key', 'Madison Keys', 'KEY', '🇺🇸', 0xFF2E4053), 'Tenis WTA'),
  (_tn('x_zhe', 'Qinwen Zheng', 'ZHE', '🇨🇳', 0xFFB03A2E), 'Tenis WTA'),
  (_tn('x_oso', 'Camila Osorio', 'OSO', '🇨🇴', 0xFFF4D03F), 'Tenis WTA'),

  // ── UFC ──
  (_ufc('x_jon', 'Jon Jones', 'JJ', '🇺🇸', 'Peso pesado', 0xFF2C3E50), 'UFC'),
  (_ufc('x_asp', 'Tom Aspinall', 'TA', '🇬🇧', 'Peso pesado', 0xFF1F618D), 'UFC'),
  (_ufc('x_gan', 'Ciryl Gane', 'CG', '🇫🇷', 'Peso pesado', 0xFF2471A3), 'UFC'),
  (_ufc('x_ank', 'Magomed Ankalaev', 'MA', '🇷🇺', 'Peso semipesado', 0xFF7B241C), 'UFC'),
  (_ufc('x_hil', 'Jamahal Hill', 'JH', '🇺🇸', 'Peso semipesado', 0xFF1C2833), 'UFC'),
  (_ufc('x_khc', 'Khamzat Chimaev', 'KC', '🇦🇪', 'Peso mediano', 0xFF145A32), 'UFC'),
  (_ufc('x_ade', 'Israel Adesanya', 'IA', '🇳🇿', 'Peso mediano', 0xFF212F3D), 'UFC'),
  (_ufc('x_whi', 'Robert Whittaker', 'RW', '🇦🇺', 'Peso mediano', 0xFF1A5276), 'UFC'),
  (_ufc('x_bel', 'Belal Muhammad', 'BM', '🇵🇸', 'Peso wélter', 0xFF196F3D), 'UFC'),
  (_ufc('x_edw', 'Leon Edwards', 'LE', '🇬🇧', 'Peso wélter', 0xFF1B2631), 'UFC'),
  (_ufc('x_jdm', 'Jack Della Maddalena', 'JDM', '🇦🇺', 'Peso wélter', 0xFF117864), 'UFC'),
  (_ufc('x_rak', 'Shavkat Rakhmonov', 'SR', '🇰🇿', 'Peso wélter', 0xFF2E86C1), 'UFC'),
  (_ufc('x_tsa', 'Arman Tsarukyan', 'AT', '🇦🇲', 'Peso ligero', 0xFFB9770E), 'UFC'),
  (_ufc('x_poi', 'Dustin Poirier', 'DP', '🇺🇸', 'Peso ligero', 0xFF922B21), 'UFC'),
  (_ufc('x_gae', 'Justin Gaethje', 'JG', '🇺🇸', 'Peso ligero', 0xFF633974), 'UFC'),
  (_ufc('x_mcg', 'Conor McGregor', 'CM', '🇮🇪', 'Peso ligero', 0xFF1E8449), 'UFC'),
  (_ufc('x_vol', 'Alexander Volkanovski', 'AV', '🇦🇺', 'Peso pluma', 0xFF1F618D), 'UFC'),
  (_ufc('x_lop', 'Diego Lopes', 'DL', '🇧🇷', 'Peso pluma', 0xFF229954), 'UFC'),
  (_ufc('x_mer', 'Merab Dvalishvili', 'MD', '🇬🇪', 'Peso gallo', 0xFFB03A2E), 'UFC'),
  (_ufc('x_oma', "Sean O'Malley", 'SO', '🇺🇸', 'Peso gallo', 0xFF8E44AD), 'UFC'),
  (_ufc('x_umr', 'Umar Nurmagomedov', 'UN', '🇷🇺', 'Peso gallo', 0xFF1C2833), 'UFC'),
  (_ufc('x_pan', 'Alexandre Pantoja', 'AP', '🇧🇷', 'Peso mosca', 0xFF239B56), 'UFC'),
  (_ufc('x_mor', 'Brandon Moreno', 'BMO', '🇲🇽', 'Peso mosca', 0xFF1D8348), 'UFC'),
  (_ufc('x_shev', 'Valentina Shevchenko', 'VS', '🇰🇬', 'Peso mosca (F)', 0xFFC0392B), 'UFC'),
  (_ufc('x_zha', 'Zhang Weili', 'ZW', '🇨🇳', 'Peso paja (F)', 0xFFCB4335), 'UFC'),
  (_ufc('x_har', 'Kayla Harrison', 'KH', '🇺🇸', 'Peso gallo (F)', 0xFF2874A6), 'UFC'),
  (_ufc('x_pen', 'Julianna Peña', 'JP', '🇺🇸', 'Peso gallo (F)', 0xFF5B2C6F), 'UFC'),
];

/// Liga de los equipos de ejemplo que ya existían.
const Map<String, String> baseTeamLeagues = {
  'rma': 'LaLiga', 'fcb': 'LaLiga', 'atm': 'LaLiga',
  'mci': 'Premier League', 'ars': 'Premier League', 'liv': 'Premier League',
  'bay': 'Bundesliga', 'psg': 'Ligue 1', 'juv': 'Serie A', 'acm': 'Serie A',
  'lal': 'NBA', 'bos': 'NBA', 'gsw': 'NBA', 'den': 'NBA', 'mia': 'NBA', 'mil': 'NBA', 'nyk': 'NBA',
  'alc': 'Tenis ATP', 'sin': 'Tenis ATP', 'djo': 'Tenis ATP', 'med': 'Tenis ATP',
};
