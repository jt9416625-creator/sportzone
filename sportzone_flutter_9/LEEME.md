# SportZone v7: cómo instalarlo

1. En tu proyecto `sportzone_flutter`, copia encima (reemplazando) estas carpetas y archivos del zip:
   - `lib/`
   - `assets/` (nueva: capas PNG del avatar)
   - `test/` (nueva: pruebas)
   - `tool/` (nueva: script que genera los PNG del avatar)
   - `pubspec.yaml`
   - `android/app/src/main/AndroidManifest.xml`
     (si tu manifest tiene cambios propios, mejor agrega solo esta línea antes de `<application`:
     `<uses-permission android:name="android.permission.INTERNET" />`)
2. En la terminal:
   ```
   flutter pub get
   flutter test
   flutter run
   ```
3. En Chrome, si no salen datos: `flutter run -d chrome --web-browser-flag "--disable-web-security"`.

## Cuentas de prueba (todavía SIN base de datos)
Están en la pantalla de login; tócalas para que se rellenen solas.

| Cuenta | Usuario | Correo | Clave |
|---|---|---|---|
| Admin | `admin` | admin@sportzone.app | `admin123` |
| Usuario | `hincha` | hincha@sportzone.app | `123456` |
| Racha perdida (23 días) | `Camilo_10` | camilo10@correo.com | `123456` |
| Avatar de peleador | `Dani77` | (sin correo) | `123456` |
| Suspendida | `GolDeLeyenda` | gol@correo.com | `123456` |

Todo vive en memoria: al cerrar la app vuelve a estos datos. Cuando conectemos Firebase solo cambian `lib/services/local_backend.dart`, `support_store.dart` y `emergency_store.dart`. Los métodos están marcados con `TODO(firebase)`.

## Novedades de la v7 (arreglos)
- **Hub arreglado:** la marca de agua de la tarjeta del álbum entraba en un ciclo infinito y congelaba la pestaña Hub. Ya no pasa.
- **Caras de jugadores:**
  - Ahora vienen primero de **Wikipedia**, que es gratis, no pide clave y Chrome no la bloquea. Solo se acepta la foto si la página es de un deportista de ese deporte.
  - Si no la encuentra ahí, usa TheSportsDB respetando su límite gratis.
  - Si una foto falla, se reintenta a los 2 minutos.
- **Chrome sin bloqueos:** nuevo intermediario propio (`tool/cors_proxy.dart`). En una terminal aparte corre:
  ```
  dart run tool/cors_proxy.dart
  ```
  y en otra:
  ```
  flutter run -d chrome
  ```
  Con eso cargan resultados, noticias, escudos y caras sin `--disable-web-security`. Solo permite servidores de deportes y solo funciona en tu compu.
- **Bloqueo por servidor:** la app recuerda qué servidor bloqueó Chrome (antes, si ESPN fallaba, también se saltaba Wikipedia).

## Novedades de la v6: Álbum SportZone y misiones

- **Álbum multideporte propio:** portada con marca de agua SportZone, tu @usuario y el % completado, más 9 páginas y 62 láminas:
  - 16 cracks del fútbol
  - 8 escudos de clubes (incluye Atlético Nacional)
  - 12 de NBA
  - 12 de tenis (ATP y WTA)
  - 8 de UFC
  - 6 leyendas doradas
- **Láminas:** cada una trae número, foto en vivo del deportista (TheSportsDB), país, posición o categoría, rareza (común, rara, épica o leyenda) y marca de agua. Las de clubes muestran el escudo oficial.
- **Sobres de 5 láminas:** animación de rasgado y volteo, con confeti si sale épica o leyenda. Se marca cada lámina como NUEVA o REPETIDA.
- **Misiones:**
  - Diarias: leer 5 noticias, reclamar la racha, hacer un pronóstico, ver 2 partidos y cambiar el avatar.
  - Semanales: racha 5 días, seguir 3 equipos, conseguir 10 láminas nuevas y abrir 6 sobres.
- **Reglas:**
  - Máximo 3 sobres al día por misiones diarias.
  - Una noticia solo cuenta si la lees 4 segundos.
  - Garantía de una rara cada 5 sobres.
  - 5 repetidas se canjean por 1 sobre.
- **Premios:**
  - Cada página completa da +1 sobre y +100 XP.
  - El álbum completo da +3 sobres, +500 XP, la insignia "Álbum completo" y la Medalla de oro para el avatar.
- **Accesos:** el botón de álbum en la barra superior (con contador) y la tarjeta en el Hub.
- **Admin:** puede regalar 1, 3 o 5 sobres desde la ficha de cada usuario.
- Cada usuario empieza con 3 sobres de bienvenida.

## Novedades de la v5

### Noticias de ESPN con foto
- La fuente principal ahora es **ESPN** (LaLiga, Premier, Champions, Liga BetPlay, NBA, UFC y ATP), en tiempo real y con la foto de cada nota. Primero se pide en español y, si ESPN no la tiene, sale en inglés.
- Google Noticias queda como segunda fuente. Si una nota no trae foto, `lib/services/news_images.dart` lee el titular, detecta de qué equipo o deportista habla y busca su imagen en TheSportsDB. Si no reconoce a nadie, pone una foto de la liga.
- Las notas de ESPN llevan un ✔ azul.

### Muchos más equipos para elegir
- 8 ligas nuevas: Europa League, Libertadores, Liga Portugal, Eredivisie, Liga Profesional Argentina, Brasileirão, Liga MX y MLS.
- Sin internet ya hay 69 clubes de fútbol (10 de Liga BetPlay), las **30 franquicias NBA**, 35 peleadores UFC y 26 tenistas (ATP y WTA).
- Con internet, `EspnApi.loadAllTeams` trae **todos** los equipos de cada liga desde ESPN, con escudo y colores oficiales.
- La pantalla "Elige tus favoritos" ahora tiene buscador, filtro por deporte y grupos por liga.

### Avatar: merch oficial y UFC
- **Pestaña Oficial:** eliges tu club (de cualquier liga o de la NBA) y tienes:
  - *Diseños del club*: camiseta, bufanda y gorra con sus colores y su escudo oficial. Funciona con todos los equipos.
  - *Camisetas oficiales*: fotos reales de cada temporada (local, visitante, alterna) desde la API de TheSportsDB (`lib/services/merch_api.dart`).
- **Pestaña UFC:** 5 tatuajes, pantalonetas de pelea, rashguards, guantes MMA, vendas, protector bucal, ojo morado y cinturón (el de campeón es exclusivo).
- **Más personalización:** 5 tonos de piel, 10 peinados, barbas, gafas, pintura de cara, cadenas, medalla y más camisetas. En total son 92 prendas en 10 capas.

## Qué trae la v4

### 1. APIs y conexión
- Permiso `INTERNET` en el `AndroidManifest.xml`. Sin él, la app compilada en release no se conecta a nada.
- `net.dart`: **todas** las peticiones pasan por aquí, con timeout de **10 s** y `try-catch` para timeout, sin conexión, CORS y JSON roto. Nunca lanza errores a la pantalla: devuelve `null` y guarda el motivo en `Net.lastError`.
- `sports_api.dart` y `espn_api.dart` también protegen la lectura de los datos, así que si ESPN cambia el formato la app no se cae.
- Si los proveedores no responden, aparece un aviso gris arriba: "Sin conexión con los proveedores…".

### 2. Login y registro duales
- Un solo campo: **correo o nombre de usuario**. Una expresión regular (`lib/core/validators.dart`) decide qué es y lo envía al endpoint correcto (`loginWithEmail` o `loginWithUsername`). Junto al campo aparece una etiqueta que dice "Correo" o "Usuario".
- Registro: si escribes un correo, aparece un campo para elegir el usuario (se sugiere uno a partir del correo). Si escribes un usuario, no se pide correo.
- Tu **@usuario** sale en el Hub, en la tarjeta de racha (`UserStreakHeader` en `gamification.dart`) y en los chats.

### 3. Soporte técnico estilo Messenger
- Botón de **audífonos** en la barra superior (ahora hay una sola barra común en `home_shell.dart`).
- Chat estilo Messenger 2015: barra azul, burbujas azules a la derecha (tú) y grises a la izquierda (soporte), "escribiendo…", "Enviado"/"Visto", botón 👍 y respuestas rápidas.

### 4. Avatar por capas
- Toca tu foto arriba a la derecha (o "Editar avatar" en el Hub).
- `Stack` de 5 capas PNG transparentes: cuerpo, inferior, superior, cabeza y mano. El catálogo de abajo es un `GridView` con pestañas Base / Fútbol / NBA / Tenis. Al tocar una prenda, el avatar cambia al instante.
- Las prendas con ⭐ son exclusivas: solo se consiguen si un admin las regala.

### 5. Panel de administración (solo rol `admin`)
Se entra con el escudo de la barra superior o con la tarjeta dorada del Hub.
- **Mesa de ayuda:** tickets en tiempo real (abiertos/resueltos), responder, marcar como resuelto y restaurar la racha desde el mismo chat.
- **Usuarios:** buscar por @usuario o correo; corregir la racha (+/−, fijar valor, restaurar la racha perdida); suspender, silenciar en chats y cambiar el rol. Cada acción queda en el historial.
- **Inventario:** bloquear o habilitar prendas para todos, regalar exclusivas a un usuario, y bloquear o desbloquear prendas por perfil.
- **Emergencia:** activar el modo emergencia (aviso naranja para todos) y publicar a mano resultados, tablas de clasificación y noticias destacadas. Se muestran aunque ESPN y Google Noticias estén caídos.

## Si algo no carga
Mira el aviso de arriba y el detalle técnico en Resultados (`Net.lastError`). ESPN es una API pública NO oficial: puede cambiar sin avisar.
