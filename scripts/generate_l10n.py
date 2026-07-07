#!/usr/bin/env python3
"""Generate lib/l10n/app_strings.dart from inline translation data."""

from pathlib import Path

LANGS = ["en", "tr", "de", "fr", "es", "it", "ja", "zh", "ko", "nl", "ru"]
OUT = Path(__file__).resolve().parents[1] / "lib" / "l10n" / "app_strings.dart"

DATA: dict[str, list[str]] = {}


def add(key: str, *values: str) -> None:
    if len(values) != 11:
        raise ValueError(f"{key}: expected 11 values, got {len(values)}")
    DATA[key] = list(values)


def esc(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("\n", "\\n")
    )


def emit_map(values: list[str]) -> str:
    lines = [f"    '{lang}': '{esc(val)}'," for lang, val in zip(LANGS, values)]
    return "  {\n" + "\n".join(lines) + "\n  }"


# --- translations ---
add("ok", "OK", "Tamam", "OK", "OK", "OK", "OK", "OK", "确定", "확인", "OK", "ОК")
add("close", "Close", "Kapat", "Schließen", "Fermer", "Cerrar", "Chiudi", "閉じる", "关闭", "닫기", "Sluiten", "Закрыть")
add("cancel", "Cancel", "İptal", "Abbrechen", "Annuler", "Cancelar", "Annulla", "キャンセル", "取消", "취소", "Annuleren", "Отмена")
add("save", "Save", "Kaydet", "Speichern", "Enregistrer", "Guardar", "Salva", "保存", "保存", "저장", "Opslaan", "Сохранить")
add("error", "Error", "Hata", "Fehler", "Erreur", "Error", "Errore", "エラー", "错误", "오류", "Fout", "Ошибка")
add("errorWithMessage", "Error: {message}", "Hata: {message}", "Fehler: {message}", "Erreur : {message}", "Error: {message}", "Errore: {message}", "エラー: {message}", "错误：{message}", "오류: {message}", "Fout: {message}", "Ошибка: {message}")
add("appName", *["Pandoku"] * 11)

add("settings", "Settings", "Ayarlar", "Einstellungen", "Paramètres", "Ajustes", "Impostazioni", "設定", "设置", "설정", "Instellingen", "Настройки")
add("appSettings", "App Settings", "Uygulama Ayarları", "App-Einstellungen", "Paramètres de l'app", "Ajustes de la app", "Impostazioni app", "アプリ設定", "应用设置", "앱 설정", "App-instellingen", "Настройки приложения")
add("theme", "Theme", "Tema", "Design", "Thème", "Tema", "Tema", "テーマ", "主题", "테마", "Thema", "Тема")
add("themeSystem", "System", "Sistem", "System", "Système", "Sistema", "Sistema", "システム", "系统", "시스템", "Systeem", "Системная")
add("themeLight", "Light", "Açık", "Hell", "Clair", "Claro", "Chiaro", "ライト", "浅色", "라이트", "Licht", "Светлая")
add("themeDark", "Dark", "Koyu", "Dunkel", "Sombre", "Oscuro", "Scuro", "ダーク", "深色", "다크", "Donker", "Тёмная")
add("themeSelection", "Theme Selection", "Tema Seçimi", "Designauswahl", "Sélection du thème", "Selección de tema", "Selezione tema", "テーマ選択", "主题选择", "테마 선택", "Themakeuze", "Выбор темы")
add("selectTheme", "Select a theme", "Tema seçin", "Design wählen", "Choisir un thème", "Selecciona un tema", "Seleziona un tema", "テーマを選択", "选择主题", "테마 선택", "Kies een thema", "Выберите тему")
add("themeSystemSubtitle", "Use your device theme", "Cihaz temasını kullan", "Gerätedesign verwenden", "Utiliser le thème de l'appareil", "Usar el tema del dispositivo", "Usa il tema del dispositivo", "端末のテーマを使用", "使用设备主题", "기기 테마 사용", "Gebruik apparaatthema", "Использовать тему устройства")
add("themeLightSubtitle", "Use light theme", "Açık temayı kullan", "Helles Design verwenden", "Utiliser le thème clair", "Usar tema claro", "Usa tema chiaro", "ライトテーマを使用", "使用浅色主题", "라이트 테마 사용", "Licht thema gebruiken", "Использовать светлую тему")
add("themeDarkSubtitle", "Use dark theme", "Koyu temayı kullan", "Dunkles Design verwenden", "Utiliser le thème sombre", "Usar tema oscuro", "Usa tema scuro", "ダークテーマを使用", "使用深色主题", "다크 테마 사용", "Donker thema gebruiken", "Использовать тёмную тему")
add("language", "Language", "Dil", "Sprache", "Langue", "Idioma", "Lingua", "言語", "语言", "언어", "Taal", "Язык")
add("languageSubtitle", "App display language", "Uygulama görüntüleme dili", "Anzeigesprache der App", "Langue d'affichage", "Idioma de la app", "Lingua dell'app", "表示言語", "应用显示语言", "앱 표시 언어", "Weergavetaal", "Язык интерфейса")
add("langSystem", "System default", "Sistem varsayılanı", "Systemstandard", "Par défaut du système", "Predeterminado del sistema", "Predefinito di sistema", "システムデフォルト", "系统默认", "시스템 기본값", "Systeemstandaard", "Системный")
add("langEnglish", "English", "İngilizce", "Englisch", "Anglais", "Inglés", "Inglese", "英語", "英语", "영어", "Engels", "Английский")
add("langTurkish", "Turkish", "Türkçe", "Türkisch", "Turc", "Turco", "Turco", "トルコ語", "土耳其语", "터키어", "Turks", "Турецкий")
add("langGerman", "German", "Almanca", "Deutsch", "Allemand", "Alemán", "Tedesco", "ドイツ語", "德语", "독일어", "Duits", "Немецкий")
add("langFrench", "French", "Fransızca", "Französisch", "Français", "Francés", "Francese", "フランス語", "法语", "프랑스어", "Frans", "Французский")
add("langSpanish", "Spanish", "İspanyolca", "Spanisch", "Espagnol", "Español", "Spagnolo", "スペイン語", "西班牙语", "스페인어", "Spaans", "Испанский")
add("langItalian", "Italian", "İtalyanca", "Italienisch", "Italien", "Italiano", "Italiano", "イタリア語", "意大利语", "이탈리아어", "Italiaans", "Итальянский")
add("langJapanese", "Japanese", "Japonca", "Japanisch", "Japonais", "Japonés", "Giapponese", "日本語", "日语", "일본어", "Japans", "Японский")
add("langChinese", "Chinese", "Çince", "Chinesisch", "Chinois", "Chino", "Cinese", "中国語", "中文", "중국어", "Chinees", "Китайский")
add("langKorean", "Korean", "Korece", "Koreanisch", "Coréen", "Coreano", "Coreano", "韓国語", "韩语", "한국어", "Koreaans", "Корейский")
add("langDutch", "Dutch", "Flemenkçe", "Niederländisch", "Néerlandais", "Neerlandés", "Olandese", "オランダ語", "荷兰语", "네덜란드어", "Nederlands", "Нидерландский")
add("langRussian", "Russian", "Rusça", "Russisch", "Russe", "Ruso", "Russo", "ロシア語", "俄语", "러시아어", "Russisch", "Русский")
add("sound", "Sound", "Ses", "Ton", "Son", "Sonido", "Suono", "サウンド", "声音", "소리", "Geluid", "Звук")
add("soundSubtitle", "Enable/disable sound effects", "Ses efektlerini aç/kapat", "Soundeffekte ein/aus", "Activer/désactiver les effets sonores", "Activar/desactivar efectos de sonido", "Attiva/disattiva effetti sonori", "効果音のオン/オフ", "开启/关闭音效", "효과음 켜기/끄기", "Geluidseffecten aan/uit", "Включить/выключить звуки")
add("highlightColor", "Highlight Color", "Vurgu Rengi", "Hervorhebungsfarbe", "Couleur de surbrillance", "Color de resaltado", "Colore evidenziazione", "ハイライト色", "高亮颜色", "강조 색상", "Accentkleur", "Цвет выделения")
add("selectedColor", "Selected: {name}", "Seçili: {name}", "Ausgewählt: {name}", "Sélectionné : {name}", "Seleccionado: {name}", "Selezionato: {name}", "選択: {name}", "已选：{name}", "선택: {name}", "Geselecteerd: {name}", "Выбрано: {name}")

add("profileVisibility", "Profile Visibility", "Profil Görünürlüğü", "Profilsichtbarkeit", "Visibilité du profil", "Visibilidad del perfil", "Visibilità profilo", "プロフィール公開", "资料可见性", "프로필 공개", "Profielzichtbaarheid", "Видимость профиля")
add("showName", "Show Name", "İsmi Göster", "Name anzeigen", "Afficher le nom", "Mostrar nombre", "Mostra nome", "名前を表示", "显示姓名", "이름 표시", "Naam tonen", "Показывать имя")
add("showNameSubtitle", "Display your name on profile", "Profilde ismini göster", "Deinen Namen im Profil anzeigen", "Afficher votre nom sur le profil", "Mostrar tu nombre en el perfil", "Mostra il nome sul profilo", "プロフィールに名前を表示", "在资料中显示姓名", "프로필에 이름 표시", "Toon je naam op profiel", "Показывать имя в профиле")
add("showEmail", "Show Email", "E-postayı Göster", "E-Mail anzeigen", "Afficher l'e-mail", "Mostrar correo", "Mostra email", "メールを表示", "显示邮箱", "이메일 표시", "E-mail tonen", "Показывать email")
add("showEmailSubtitle", "Display your email on profile", "Profilde e-postanı göster", "Deine E-Mail im Profil anzeigen", "Afficher votre e-mail sur le profil", "Mostrar tu correo en el perfil", "Mostra email sul profilo", "プロフィールにメールを表示", "在资料中显示邮箱", "프로필에 이메일 표시", "Toon e-mail op profiel", "Показывать email в профиле")
add("statisticsVisibility", "Statistics Visibility", "İstatistik Görünürlüğü", "Statistik-Sichtbarkeit", "Visibilité des statistiques", "Visibilidad de estadísticas", "Visibilità statistiche", "統計の公開", "统计可见性", "통계 공개", "Statistiekzichtbaarheid", "Видимость статистики")
add("visibilityOnlyMe", "Only Me", "Sadece Ben", "Nur ich", "Moi seulement", "Solo yo", "Solo io", "自分のみ", "仅自己", "나만", "Alleen ik", "Только я")
add("visibilityFriends", "My Friends", "Arkadaşlarım", "Meine Freunde", "Mes amis", "Mis amigos", "I miei amici", "友達", "好友", "친구", "Mijn vrienden", "Мои друзья")
add("visibilityEveryone", "Everyone", "Herkes", "Alle", "Tout le monde", "Todos", "Tutti", "全員", "所有人", "모두", "Iedereen", "Все")
add("displayName", "Display Name", "Görünen Ad", "Anzeigename", "Nom affiché", "Nombre visible", "Nome visualizzato", "表示名", "显示名称", "표시 이름", "Weergavenaam", "Отображаемое имя")
add("displayNameNotSet", "Not set", "Ayarlanmadı", "Nicht festgelegt", "Non défini", "Sin definir", "Non impostato", "未設定", "未设置", "미설정", "Niet ingesteld", "Не задано")
add("profileColor", "Profile Color", "Profil Rengi", "Profilfarbe", "Couleur du profil", "Color del perfil", "Colore profilo", "プロフィール色", "资料颜色", "프로필 색상", "Profielkleur", "Цвет профиля")
add("profileColorSubtitle", "Choose profile avatar color", "Profil avatar rengini seç", "Avatar-Farbe wählen", "Choisir la couleur de l'avatar", "Elegir color del avatar", "Scegli colore avatar", "アバターの色を選択", "选择头像颜色", "아바타 색상 선택", "Kies avatarkleur", "Выберите цвет аватара")
add("profileColorUpdated", "Profile color updated successfully", "Profil rengi güncellendi", "Profilfarbe aktualisiert", "Couleur du profil mise à jour", "Color del perfil actualizado", "Colore profilo aggiornato", "プロフィール色を更新しました", "资料颜色已更新", "프로필 색상이 업데이트되었습니다", "Profielkleur bijgewerkt", "Цвет профиля обновлён")
add("setDisplayName", "Set Display Name", "Görünen Ad Belirle", "Anzeigename festlegen", "Définir le nom affiché", "Establecer nombre visible", "Imposta nome visualizzato", "表示名を設定", "设置显示名称", "표시 이름 설정", "Weergavenaam instellen", "Задать отображаемое имя")
add("displayNameHint", "Enter your display name", "Görünen adınızı girin", "Anzeigename eingeben", "Entrez votre nom affiché", "Introduce tu nombre visible", "Inserisci nome visualizzato", "表示名を入力", "输入显示名称", "표시 이름 입력", "Voer weergavenaam in", "Введите отображаемое имя")
add("displayNamePersonalSubtitle", "Only visible on your own profile", "Yalnızca kendi profilinde görünür", "Nur auf deinem eigenen Profil sichtbar", "Visible uniquement sur votre propre profil", "Solo visible en tu propio perfil", "Visibile solo sul tuo profilo", "自分のプロフィールでのみ表示", "仅在自己的资料中显示", "본인 프로필에서만 표시", "Alleen zichtbaar op je eigen profiel", "Видно только в вашем профиле")
add("displayNameUpdated", "Display name updated successfully", "Görünen ad güncellendi", "Anzeigename aktualisiert", "Nom affiché mis à jour", "Nombre visible actualizado", "Nome visualizzato aggiornato", "表示名を更新しました", "显示名称已更新", "표시 이름이 업데이트되었습니다", "Weergavenaam bijgewerkt", "Отображаемое имя обновлено")

for key, vals in [
    ("colorPurple", ["Purple", "Mor", "Lila", "Violet", "Morado", "Viola", "紫", "紫色", "보라", "Paars", "Фиолетовый"]),
    ("colorBlue", ["Blue", "Mavi", "Blau", "Bleu", "Azul", "Blu", "青", "蓝色", "파랑", "Blauw", "Синий"]),
    ("colorRed", ["Red", "Kırmızı", "Rot", "Rouge", "Rojo", "Rosso", "赤", "红色", "빨강", "Rood", "Красный"]),
    ("colorGreen", ["Green", "Yeşil", "Grün", "Vert", "Verde", "Verde", "緑", "绿色", "초록", "Groen", "Зелёный"]),
    ("colorOrange", ["Orange", "Turuncu", "Orange", "Orange", "Naranja", "Arancione", "オレンジ", "橙色", "주황", "Oranje", "Оранжевый"]),
    ("colorPink", ["Pink", "Pembe", "Rosa", "Rose", "Rosa", "Rosa", "ピンク", "粉色", "분홍", "Roze", "Розовый"]),
    ("colorTeal", ["Teal", "Camgöbeği", "Blaugrün", "Sarcelle", "Verde azulado", "Verde acqua", "ティール", "青色", "청록", "Groenblauw", "Бирюзовый"]),
    ("colorCyan", ["Cyan", "Camgöbeği", "Cyan", "Cyan", "Cian", "Ciano", "シアン", "青色", "시안", "Cyaan", "Голубой"]),
    ("colorIndigo", ["Indigo", "İndigo", "Indigo", "Indigo", "Índigo", "Indaco", "インディゴ", "靛蓝", "남색", "Indigo", "Индиго"]),
    ("colorAmber", ["Amber", "Kehribar", "Bernstein", "Ambre", "Ámbar", "Ambra", "アンバー", "琥珀色", "호박", "Amber", "Янтарный"]),
    ("colorBrown", ["Brown", "Kahverengi", "Braun", "Marron", "Marrón", "Marrone", "茶", "棕色", "갈색", "Bruin", "Коричневый"]),
    ("colorGrey", ["Grey", "Gri", "Grau", "Gris", "Gris", "Grigio", "グレー", "灰色", "회색", "Grijs", "Серый"]),
    ("colorCustom", ["Custom", "Özel", "Benutzerdefiniert", "Personnalisé", "Personalizado", "Personalizzato", "カスタム", "自定义", "사용자 지정", "Aangepast", "Свой"]),
    ("colorUnknown", ["Unknown", "Bilinmiyor", "Unbekannt", "Inconnu", "Desconocido", "Sconosciuto", "不明", "未知", "알 수 없음", "Onbekend", "Неизвестно"]),
]:
    add(key, *vals)

add("play", "Play", "Oyna", "Spielen", "Jouer", "Jugar", "Gioca", "プレイ", "开始", "플레이", "Spelen", "Играть")
add("continueGame", "Continue", "Devam Et", "Fortsetzen", "Continuer", "Continuar", "Continua", "続ける", "继续", "계속", "Doorgaan", "Продолжить")
add("newGame", "New Game", "Yeni Oyun", "Neues Spiel", "Nouvelle partie", "Nueva partida", "Nuova partita", "新しいゲーム", "新游戏", "새 게임", "Nieuw spel", "Новая игра")
add("todaysGame", "Today's Game", "Günün Oyunu", "Spiel des Tages", "Jeu du jour", "Juego del día", "Gioco del giorno", "今日のゲーム", "今日游戏", "오늘의 게임", "Spel van vandaag", "Игра дня")
add("logout", "Logout", "Çıkış Yap", "Abmelden", "Déconnexion", "Cerrar sesión", "Esci", "ログアウト", "退出登录", "로그아웃", "Uitloggen", "Выйти")
add("deleteAccount", "Delete Account", "Hesabı Sil", "Konto löschen", "Supprimer le compte", "Eliminar cuenta", "Elimina account", "アカウントを削除", "删除账户", "계정 삭제", "Account verwijderen", "Удалить аккаунт")
add("deleteAccountSubtitle", "Permanently delete your profile and game data", "Profilinizi ve oyun verilerinizi kalıcı olarak silin", "Profil und Spieldaten dauerhaft löschen", "Supprimer définitivement votre profil et vos données", "Eliminar permanentemente tu perfil y datos de juego", "Elimina definitivamente profilo e dati di gioco", "プロフィールとゲームデータを完全に削除", "永久删除您的个人资料和游戏数据", "프로필과 게임 데이터를 영구 삭제", "Profiel en spelgegevens permanent verwijderen", "Навсегда удалить профиль и игровые данные")
add("deleteAccountConfirmTitle", "Delete account?", "Hesap silinsin mi?", "Konto löschen?", "Supprimer le compte ?", "¿Eliminar cuenta?", "Eliminare l'account?", "アカウントを削除しますか？", "确定删除账户？", "계정을 삭제하시겠습니까?", "Account verwijderen?", "Удалить аккаунт?")
add("deleteAccountConfirmMessage", "This action cannot be undone. Your profile, scores, and statistics will be permanently deleted.", "Bu işlem geri alınamaz. Profiliniz, skorlarınız ve istatistikleriniz kalıcı olarak silinecek.", "Diese Aktion kann nicht rückgängig gemacht werden. Profil, Punkte und Statistiken werden dauerhaft gelöscht.", "Cette action est irréversible. Votre profil, scores et statistiques seront supprimés définitivement.", "Esta acción no se puede deshacer. Tu perfil, puntuaciones y estadísticas se eliminarán permanentemente.", "Questa azione non può essere annullata. Profilo, punteggi e statistiche verranno eliminati definitivamente.", "この操作は元に戻せません。プロフィール、スコア、統計が完全に削除されます。", "此操作无法撤销。您的个人资料、分数和统计数据将被永久删除。", "이 작업은 취소할 수 없습니다. 프로필, 점수 및 통계가 영구 삭제됩니다.", "Deze actie kan niet ongedaan worden gemaakt. Je profiel, scores en statistieken worden permanent verwijderd.", "Это действие нельзя отменить. Ваш профиль, очки и статистика будут удалены навсегда.")
add("deleteAccountSuccess", "Your account has been deleted", "Hesabınız silindi", "Ihr Konto wurde gelöscht", "Votre compte a été supprimé", "Tu cuenta ha sido eliminada", "Il tuo account è stato eliminato", "アカウントが削除されました", "您的账户已删除", "계정이 삭제되었습니다", "Je account is verwijderd", "Ваш аккаунт удалён")
add("deleteAccountFailed", "Could not delete account", "Hesap silinemedi", "Konto konnte nicht gelöscht werden", "Impossible de supprimer le compte", "No se pudo eliminar la cuenta", "Impossibile eliminare l'account", "アカウントを削除できませんでした", "无法删除账户", "계정을 삭제할 수 없습니다", "Account kon niet worden verwijderd", "Не удалось удалить аккаунт")
add("loggedOutSuccess", "Logged out successfully", "Başarıyla çıkış yapıldı", "Erfolgreich abgemeldet", "Déconnexion réussie", "Sesión cerrada correctamente", "Disconnessione riuscita", "ログアウトしました", "已成功退出", "로그아웃되었습니다", "Succesvol uitgelogd", "Выход выполнен")
add("selectDifficulty", "Select Difficulty Level", "Zorluk Seviyesi Seç", "Schwierigkeitsgrad wählen", "Choisir la difficulté", "Seleccionar dificultad", "Seleziona difficoltà", "難易度を選択", "选择难度", "난이도 선택", "Kies moeilijkheidsgraad", "Выберите сложность")
add("easy", "Easy", "Kolay", "Leicht", "Facile", "Fácil", "Facile", "かんたん", "简单", "쉬움", "Makkelijk", "Лёгкий")
add("medium", "Medium", "Orta", "Mittel", "Moyen", "Medio", "Medio", "ふつう", "中等", "보통", "Gemiddeld", "Средний")
add("hard", "Hard", "Zor", "Schwer", "Difficile", "Difícil", "Difficile", "むずかしい", "困难", "어려움", "Moeilijk", "Сложный")
add("sendFeedback", "Send Feedback", "Geri Bildirim Gönder", "Feedback senden", "Envoyer un avis", "Enviar comentarios", "Invia feedback", "フィードバックを送る", "发送反馈", "피드백 보내기", "Feedback sturen", "Отправить отзыв")

add("guideSkip", "Skip", "Atla", "Überspringen", "Passer", "Omitir", "Salta", "スキップ", "跳过", "건너뛰기", "Overslaan", "Пропустить")
add("guideNext", "Next", "İleri", "Weiter", "Suivant", "Siguiente", "Avanti", "次へ", "下一步", "다음", "Volgende", "Далее")
add("guideDone", "Got it", "Tamam", "Verstanden", "Compris", "Entendido", "Capito", "了解", "知道了", "확인", "Begrepen", "Понятно")
add("guidePlayTitle", "Start Playing", "Oyuna Başla", "Spiel starten", "Commencer à jouer", "Empezar a jugar", "Inizia a giocare", "プレイを開始", "开始游戏", "플레이 시작", "Begin met spelen", "Начать игру")
add("guidePlayDesc", "Tap Play to choose a difficulty and start a new Sudoku game.", "Oyna'ya basarak zorluk seçip yeni bir Sudoku oyunu başlatabilirsin.", "Tippe auf Spielen, wähle eine Schwierigkeit und starte ein neues Sudoku.", "Appuyez sur Jouer pour choisir une difficulté et commencer.", "Toca Jugar para elegir dificultad y empezar un Sudoku.", "Tocca Gioca per scegliere la difficoltà e iniziare.", "プレイをタップして難易度を選び、新しい数独を始めましょう。", "点击开始，选择难度并开始新的数独游戏。", "플레이를 눌러 난이도를 선택하고 새 스도쿠를 시작하세요.", "Tik op Spelen om een moeilijkheid te kiezen.", "Нажмите «Играть», выберите сложность и начните игру.")
add("guideDailyTitle", "Today's Game", "Günün Oyunu", "Spiel des Tages", "Jeu du jour", "Juego del día", "Gioco del giorno", "今日のゲーム", "今日游戏", "오늘의 게임", "Spel van vandaag", "Игра дня")
add("guideDailyDesc", "Everyone gets the same daily puzzle. Come back every day!", "Herkes aynı günlük bulmacayı çözer. Her gün geri gel!", "Jeden Tag dasselbe Rätsel für alle.", "Tout le monde a le même puzzle quotidien.", "Todos tienen el mismo puzzle diario.", "Tutti hanno lo stesso puzzle giornaliero.", "みんな同じデイリーパズル。", "所有人相同的每日谜题。", "모두 같은 일일 퍼즐입니다.", "Iedereen krijgt dezelfde dagpuzzel.", "У всех одинаковая ежедневная головоломка.")
add("guideCalendarTitle", "Game Calendar", "Oyun Takvimi", "Spielkalender", "Calendrier de jeux", "Calendario de juegos", "Calendario giochi", "ゲームカレンダー", "游戏日历", "게임 캘린더", "Spelkalender", "Календарь игр")
add("guideCalendarDesc", "See past daily games and play days you missed.", "Geçmiş günlük oyunları gör, kaçırdığın günleri oyna.", "Sieh vergangene Tages-Spiele und spiele verpasste Tage.", "Voir les jeux passés et jouer les jours manqués.", "Ve juegos pasados y juega días perdidos.", "Vedi giochi passati e gioca giorni persi.", "過去のデイリーゲームを見て、逃した日をプレイ。", "查看过去的每日游戏，补玩错过的日子。", "지난 일일 게임을 보고 놓친 날을 플레이하세요.", "Bekijk eerdere dagspellen en speel gemiste dagen.", "Смотрите прошлые игры и играйте пропущенные дни.")
add("guideProfileTitle", "Your Profile", "Profilin", "Dein Profil", "Votre profil", "Tu perfil", "Il tuo profilo", "あなたのプロフィール", "你的资料", "내 프로필", "Je profiel", "Ваш профиль")
add("guideProfileDesc", "View your stats and customize your profile.", "İstatistiklerini gör ve profilini ayarla.", "Sieh Statistiken und passe dein Profil an.", "Voir vos stats et personnaliser votre profil.", "Ve tus estadísticas y personaliza tu perfil.", "Vedi statistiche e personalizza il profilo.", "統計を見て、プロフィールを設定。", "查看统计并自定义资料。", "통계를 보고 프로필을 설정하세요.", "Bekijk statistieken en pas je profiel aan.", "Смотрите статистику и настройте профиль.")
add("guideFeedbackTitle", "Send Feedback", "Geri Bildirim", "Feedback senden", "Envoyer un avis", "Enviar comentarios", "Invia feedback", "フィードバック", "发送反馈", "피드백", "Feedback", "Отзыв")
add("guideFeedbackDesc", "Have an idea or found a bug? Let us know!", "Bir fikrin mi var veya hata mı buldun? Bize yaz!", "Idee oder Bug gefunden? Schreib uns!", "Une idée ou un bug ? Écrivez-nous !", "¿Idea o error? ¡Escríbenos!", "Hai un'idea o un bug? Scrivici!", "アイデアやバグはお知らせください！", "有想法或发现错误？告诉我们！", "아이디어나 버그가 있나요? 알려주세요!", "Idee of bug? Laat het weten!", "Есть идея или ошибка? Напишите!")
add("guideSettingsTitle", "Settings", "Ayarlar", "Einstellungen", "Paramètres", "Ajustes", "Impostazioni", "設定", "设置", "설정", "Instellingen", "Настройки")
add("guideSettingsDesc", "Change theme, language, sounds, and profile visibility.", "Tema, dil, ses ve profil görünürlüğünü ayarla.", "Ändere Design, Sprache, Ton und Sichtbarkeit.", "Changez thème, langue, sons et visibilité.", "Cambia tema, idioma, sonidos y visibilidad.", "Cambia tema, lingua, suoni e visibilità.", "テーマ、言語、音、公開設定を変更。", "更改主题、语言、声音和可见性。", "테마, 언어, 소리, 공개 설정.", "Wijzig thema, taal, geluid en zichtbaarheid.", "Меняйте тему, язык, звук и видимость.")
add("showGuide", "Show guide", "Rehberi göster", "Anleitung anzeigen", "Afficher le guide", "Mostrar guía", "Mostra guida", "ガイドを表示", "显示指南", "가이드 보기", "Gids tonen", "Показать гид")

add("profile", "Profile", "Profil", "Profil", "Profil", "Perfil", "Profilo", "プロフィール", "资料", "프로필", "Profiel", "Профиль")
add("myFriends", "My Friends", "Arkadaşlarım", "Meine Freunde", "Mes amis", "Mis amigos", "I miei amici", "友達", "好友", "친구", "Mijn vrienden", "Мои друзья")
add("addFriend", "Add Friend", "Arkadaş Ekle", "Freund hinzufügen", "Ajouter un ami", "Añadir amigo", "Aggiungi amico", "友達を追加", "添加好友", "친구 추가", "Vriend toevoegen", "Добавить друга")
add("comingSoon", "Coming soon", "Yakında", "Demnächst", "Bientôt", "Próximamente", "In arrivo", "近日公開", "即将推出", "곧 출시", "Binnenkort", "Скоро")
add("statistics", "Statistics", "İstatistikler", "Statistiken", "Statistiques", "Estadísticas", "Statistiche", "統計", "统计", "통계", "Statistieken", "Статистика")
add("gamesByDifficulty", "Games by Difficulty", "Zorluğa Göre Oyunlar", "Spiele nach Schwierigkeit", "Jeux par difficulté", "Juegos por dificultad", "Giochi per difficoltà", "難易度別ゲーム", "按难度分类", "난이도별 게임", "Spellen per moeilijkheid", "Игры по сложности")
add("noProfileAvailable", "No profile available", "Profil bulunamadı", "Kein Profil verfügbar", "Aucun profil disponible", "No hay perfil disponible", "Nessun profilo disponibile", "プロフィールがありません", "无可用资料", "프로필 없음", "Geen profiel beschikbaar", "Профиль недоступен")
add("noStatisticsAvailable", "No statistics available", "İstatistik bulunamadı", "Keine Statistiken verfügbar", "Aucune statistique disponible", "No hay estadísticas disponibles", "Nessuna statistica disponibile", "統計がありません", "无统计数据", "통계 없음", "Geen statistieken beschikbaar", "Статистика недоступна")
add("statOverall", "Overall", "Genel", "Gesamt", "Global", "General", "Totale", "全体", "总计", "전체", "Totaal", "Общее")
add("statTotalGames", "Total Games", "Toplam Oyun", "Spiele gesamt", "Parties totales", "Partidas totales", "Partite totali", "総ゲーム数", "总游戏数", "총 게임", "Totaal spellen", "Всего игр")
add("statTotalScore", "Total Score", "Toplam Skor", "Punkte gesamt", "Score total", "Puntuación total", "Punteggio totale", "総スコア", "总分数", "총 점수", "Totale score", "Общий счёт")
add("statBestScore", "Best Score", "En İyi Skor", "Beste Punktzahl", "Meilleur score", "Mejor puntuación", "Miglior punteggio", "最高スコア", "最高分", "최고 점수", "Beste score", "Лучший счёт")
add("statAverageScore", "Average Score", "Ortalama Skor", "Durchschnittspunktzahl", "Score moyen", "Puntuación media", "Punteggio medio", "平均スコア", "平均分", "평균 점수", "Gemiddelde score", "Средний счёт")
add("statTotalTime", "Total Time", "Toplam Süre", "Gesamtzeit", "Temps total", "Tiempo total", "Tempo totale", "総プレイ時間", "总时间", "총 시간", "Totale tijd", "Общее время")
add("statGamesPlayed", "{count} games", "{count} oyun", "{count} Spiele", "{count} parties", "{count} partidas", "{count} partite", "{count} ゲーム", "{count} 场游戏", "{count}게임", "{count} spellen", "{count} игр")
add("anonymousUser", "Anonymous user", "İsimsiz kullanıcı", "Anonymer Benutzer", "Utilisateur anonyme", "Usuario anónimo", "Utente anonimo", "匿名ユーザー", "匿名用户", "익명 사용자", "Anonieme gebruiker", "Анонимный пользователь")

# Login / register / feedback - batch shorter keys
login_keys = [
    ("loginTitle", ["Login to Pandoku", "Pandoku'ya Giriş", "Bei Pandoku anmelden", "Connexion à Pandoku", "Iniciar sesión en Pandoku", "Accedi a Pandoku", "Pandokuにログイン", "登录 Pandoku", "Pandoku 로그인", "Inloggen bij Pandoku", "Вход в Pandoku"]),
    ("welcomeBack", ["Welcome Back!", "Tekrar Hoş Geldin!", "Willkommen zurück!", "Bon retour !", "¡Bienvenido de nuevo!", "Bentornato!", "おかえりなさい！", "欢迎回来！", "다시 오신 것을 환영합니다!", "Welkom terug!", "С возвращением!"]),
    ("loginSubtitle", ["Login with your Pandaccount", "Pandaccount ile giriş yap", "Mit Pandaccount anmelden", "Connectez-vous avec Pandaccount", "Inicia sesión con Pandaccount", "Accedi con Pandaccount", "Pandaccountでログイン", "使用 Pandaccount 登录", "Pandaccount로 로그인", "Log in met Pandaccount", "Войдите через Pandaccount"]),
    ("email", ["Email", "E-posta", "E-Mail", "E-mail", "Correo", "Email", "メール", "邮箱", "이메일", "E-mail", "Email"]),
    ("emailHint", ["Enter your email", "E-postanızı girin", "E-Mail eingeben", "Entrez votre e-mail", "Introduce tu correo", "Inserisci email", "メールを入力", "输入邮箱", "이메일 입력", "Voer e-mail in", "Введите email"]),
    ("password", ["Password", "Şifre", "Passwort", "Mot de passe", "Contraseña", "Password", "パスワード", "密码", "비밀번호", "Wachtwoord", "Пароль"]),
    ("passwordHint", ["Enter your password", "Şifrenizi girin", "Passwort eingeben", "Entrez votre mot de passe", "Introduce tu contraseña", "Inserisci password", "パスワードを入力", "输入密码", "비밀번호 입력", "Voer wachtwoord in", "Введите пароль"]),
    ("login", ["Login", "Giriş Yap", "Anmelden", "Connexion", "Iniciar sesión", "Accedi", "ログイン", "登录", "로그인", "Inloggen", "Войти"]),
    ("noAccount", ["Don't have an account? Create one", "Hesabın yok mu? Oluştur", "Kein Konto? Erstelle eines", "Pas de compte ? Créez-en un", "¿No tienes cuenta? Crea una", "Nessun account? Creane uno", "アカウントがない？作成", "没有账户？创建一个", "계정이 없나요? 만들기", "Geen account? Maak er een", "Нет аккаунта? Создайте"]),
    ("loggedInSuccess", ["Logged in successfully!", "Başarıyla giriş yapıldı!", "Erfolgreich angemeldet!", "Connexion réussie !", "¡Sesión iniciada!", "Accesso riuscito!", "ログインしました！", "登录成功！", "로그인 성공!", "Succesvol ingelogd!", "Вход выполнен!"]),
    ("enterEmail", ["Please enter your email", "Lütfen e-postanızı girin", "Bitte E-Mail eingeben", "Veuillez entrer votre e-mail", "Introduce tu correo", "Inserisci la tua email", "メールを入力してください", "请输入邮箱", "이메일을 입력하세요", "Voer je e-mail in", "Введите email"]),
    ("validEmail", ["Please enter a valid email", "Geçerli bir e-posta girin", "Bitte gültige E-Mail eingeben", "E-mail valide requis", "Introduce un correo válido", "Inserisci email valida", "有効なメールを入力", "请输入有效邮箱", "유효한 이메일을 입력하세요", "Voer een geldig e-mailadres in", "Введите корректный email"]),
    ("enterPassword", ["Please enter your password", "Lütfen şifrenizi girin", "Bitte Passwort eingeben", "Veuillez entrer votre mot de passe", "Introduce tu contraseña", "Inserisci la password", "パスワードを入力してください", "请输入密码", "비밀번호를 입력하세요", "Voer je wachtwoord in", "Введите пароль"]),
    ("createAccount", ["Create Pandaccount", "Pandaccount Oluştur", "Pandaccount erstellen", "Créer un Pandaccount", "Crear Pandaccount", "Crea Pandaccount", "Pandaccountを作成", "创建 Pandaccount", "Pandaccount 만들기", "Pandaccount aanmaken", "Создать Pandaccount"]),
    ("sendVerificationCode", ["Send Verification Code", "Doğrulama Kodu Gönder", "Bestätigungscode senden", "Envoyer le code", "Enviar código", "Invia codice", "認証コードを送信", "发送验证码", "인증 코드 보내기", "Verificatiecode sturen", "Отправить код"]),
    ("resendCode", ["Resend Code", "Kodu Tekrar Gönder", "Code erneut senden", "Renvoyer le code", "Reenviar código", "Reinvia codice", "コードを再送信", "重新发送", "코드 재전송", "Code opnieuw sturen", "Отправить снова"]),
    ("verificationCode", ["Verification Code", "Doğrulama Kodu", "Bestätigungscode", "Code de vérification", "Código de verificación", "Codice di verifica", "認証コード", "验证码", "인증 코드", "Verificatiecode", "Код подтверждения"]),
    ("verificationCodeHint", ["Enter verification code", "Doğrulama kodunu girin", "Code eingeben", "Entrez le code", "Introduce el código", "Inserisci codice", "認証コードを入力", "输入验证码", "인증 코드 입력", "Voer code in", "Введите код"]),
    ("firstName", ["First Name", "Ad", "Vorname", "Prénom", "Nombre", "Nome", "名", "名", "이름", "Voornaam", "Имя"]),
    ("firstNameHint", ["Enter your first name", "Adınızı girin", "Vorname eingeben", "Entrez votre prénom", "Introduce tu nombre", "Inserisci nome", "名を入力", "输入名字", "이름 입력", "Voer voornaam in", "Введите имя"]),
    ("lastName", ["Last Name", "Soyad", "Nachname", "Nom", "Apellido", "Cognome", "姓", "姓", "성", "Achternaam", "Фамилия"]),
    ("lastNameHint", ["Enter your last name", "Soyadınızı girin", "Nachname eingeben", "Entrez votre nom", "Introduce tu apellido", "Inserisci cognome", "姓を入力", "输入姓氏", "성 입력", "Voer achternaam in", "Введите фамилию"]),
    ("confirmPassword", ["Confirm Password", "Şifreyi Onayla", "Passwort bestätigen", "Confirmer le mot de passe", "Confirmar contraseña", "Conferma password", "パスワード確認", "确认密码", "비밀번호 확인", "Bevestig wachtwoord", "Подтвердите пароль"]),
    ("confirmPasswordHint", ["Confirm your password", "Şifrenizi onaylayın", "Passwort bestätigen", "Confirmez le mot de passe", "Confirma tu contraseña", "Conferma password", "パスワードを確認", "确认密码", "비밀번호 확인", "Bevestig wachtwoord", "Подтвердите пароль"]),
    ("birthDate", ["Birth Date", "Doğum Tarihi", "Geburtsdatum", "Date de naissance", "Fecha de nacimiento", "Data di nascita", "生年月日", "出生日期", "생년월일", "Geboortedatum", "Дата рождения"]),
    ("selectBirthDateHelp", ["Select Birth Date", "Doğum Tarihi Seç", "Geburtsdatum wählen", "Choisir la date de naissance", "Seleccionar fecha de nacimiento", "Seleziona data di nascita", "生年月日を選択", "选择出生日期", "생년월일 선택", "Kies geboortedatum", "Выберите дату рождения"]),
    ("selectBirthDate", ["Select your birth date", "Doğum tarihinizi seçin", "Wähle dein Geburtsdatum", "Sélectionnez votre date de naissance", "Selecciona tu fecha de nacimiento", "Seleziona la data di nascita", "生年月日を選択してください", "请选择出生日期", "생년월일을 선택하세요", "Selecteer je geboortedatum", "Выберите дату рождения"]),
    ("chooseAvatarColor", ["Choose Avatar Color", "Avatar Rengi Seç", "Avatar-Farbe wählen", "Choisir la couleur de l'avatar", "Elegir color del avatar", "Scegli colore avatar", "アバターの色を選択", "选择头像颜色", "아바타 색상 선택", "Kies avatarkleur", "Выберите цвет аватара"]),
    ("accountCreated", ["Account created successfully!", "Hesap başarıyla oluşturuldu!", "Konto erfolgreich erstellt!", "Compte créé avec succès !", "¡Cuenta creada!", "Account creato!", "アカウントを作成しました！", "账户创建成功！", "계정이 생성되었습니다!", "Account aangemaakt!", "Аккаунт создан!"]),
    ("codeVerified", ["Code verified successfully!", "Kod başarıyla doğrulandı!", "Code erfolgreich bestätigt!", "Code vérifié !", "¡Código verificado!", "Codice verificato!", "コードを確認しました！", "验证码已确认！", "코드가 확인되었습니다!", "Code geverifieerd!", "Код подтверждён!"]),
    ("invalidCode", ["Invalid verification code", "Geçersiz doğrulama kodu", "Ungültiger Code", "Code invalide", "Código inválido", "Codice non valido", "無効な認証コード", "验证码无效", "잘못된 인증 코드", "Ongeldige code", "Неверный код"]),
    ("verificationCodeTitle", ["Verification Code", "Doğrulama Kodu", "Bestätigungscode", "Code de vérification", "Código de verificación", "Codice di verifica", "認証コード", "验证码", "인증 코드", "Verificatiecode", "Код подтверждения"]),
    ("yourVerificationCode", ["Your verification code is:", "Doğrulama kodunuz:", "Dein Bestätigungscode:", "Votre code :", "Tu código:", "Il tuo codice:", "認証コード:", "您的验证码：", "인증 코드:", "Je verificatiecode:", "Ваш код:"]),
    ("sending", ["Sending...", "Gönderiliyor...", "Wird gesendet...", "Envoi...", "Enviando...", "Invio...", "送信中...", "发送中...", "전송 중...", "Verzenden...", "Отправка..."]),
    ("selectBirthDateError", ["Select your birth date", "Doğum tarihinizi seçin", "Wähle dein Geburtsdatum", "Sélectionnez votre date de naissance", "Selecciona tu fecha de nacimiento", "Seleziona la data di nascita", "生年月日を選択してください", "请选择出生日期", "생년월일을 선택하세요", "Selecteer je geboortedatum", "Выберите дату рождения"]),
    ("fillRequiredFields", ["Fill in all required fields correctly", "Zorunlu alanları doğru doldurun", "Alle Pflichtfelder korrekt ausfüllen", "Remplissez tous les champs requis", "Completa todos los campos obligatorios", "Compila tutti i campi obbligatori", "必須項目を正しく入力", "请正确填写所有必填项", "필수 항목을 올바르게 입력하세요", "Vul alle verplichte velden correct in", "Заполните все обязательные поля"]),
    ("sendCodeFirst", ["Tap \"Send Verification Code\" for your email first", "Önce e-postanıza doğrulama kodu gönderin", "Sende zuerst den Bestätigungscode", "Envoyez d'abord le code", "Envía primero el código", "Invia prima il codice", "先に認証コードを送信", "请先发送验证码", "먼저 인증 코드를 보내세요", "Stuur eerst de verificatiecode", "Сначала отправьте код"]),
    ("enterSixDigitCode", ["Enter the 6-digit verification code", "6 haneli doğrulama kodunu girin", "6-stelligen Code eingeben", "Entrez le code à 6 chiffres", "Introduce el código de 6 dígitos", "Inserisci il codice a 6 cifre", "6桁の認証コードを入力", "输入6位验证码", "6자리 인증 코드 입력", "Voer de 6-cijferige code in", "Введите 6-значный код"]),
    ("verifyCodeFirst", ["Tap the check icon to verify your code", "Kodu doğrulamak için onay ikonuna basın", "Tippe auf Häkchen zur Bestätigung", "Appuyez sur la coche pour vérifier", "Toca el icono de verificación", "Tocca l'icona di verifica", "チェックアイコンで確認", "点击勾选图标验证", "확인 아이콘을 눌러 인증", "Tik op het vinkje om te verifiëren", "Нажмите галочку для проверки"]),
    ("enterFirstName", ["Please enter your first name", "Lütfen adınızı girin", "Bitte Vorname eingeben", "Veuillez entrer votre prénom", "Introduce tu nombre", "Inserisci il nome", "名を入力してください", "请输入名字", "이름을 입력하세요", "Voer je voornaam in", "Введите имя"]),
    ("enterLastName", ["Please enter your last name", "Lütfen soyadınızı girin", "Bitte Nachname eingeben", "Veuillez entrer votre nom", "Introduce tu apellido", "Inserisci il cognome", "姓を入力してください", "请输入姓氏", "성을 입력하세요", "Voer je achternaam in", "Введите фамилию"]),
    ("passwordMinLength", ["Password must be at least 6 characters", "Şifre en az 6 karakter olmalı", "Passwort mindestens 6 Zeichen", "Mot de passe : 6 caractères min.", "La contraseña debe tener al menos 6 caracteres", "La password deve avere almeno 6 caratteri", "パスワードは6文字以上", "密码至少6个字符", "비밀번호는 6자 이상", "Wachtwoord minimaal 6 tekens", "Пароль не менее 6 символов"]),
    ("confirmPasswordRequired", ["Please confirm your password", "Lütfen şifrenizi onaylayın", "Bitte Passwort bestätigen", "Veuillez confirmer le mot de passe", "Confirma tu contraseña", "Conferma la password", "パスワードを確認してください", "请确认密码", "비밀번호를 확인하세요", "Bevestig je wachtwoord", "Подтвердите пароль"]),
    ("passwordsDoNotMatch", ["Passwords do not match", "Şifreler eşleşmiyor", "Passwörter stimmen nicht überein", "Les mots de passe ne correspondent pas", "Las contraseñas no coinciden", "Le password non corrispondono", "パスワードが一致しません", "密码不匹配", "비밀번호가 일치하지 않습니다", "Wachtwoorden komen niet overeen", "Пароли не совпадают"]),
    ("verifyCodeRequired", ["Please verify code", "Lütfen kodu doğrulayın", "Bitte Code bestätigen", "Veuillez vérifier le code", "Verifica el código", "Verifica il codice", "コードを確認してください", "请验证验证码", "코드를 확인하세요", "Verifieer de code", "Подтвердите код"]),
    ("codeSixDigits", ["Code must be 6 digits", "Kod 6 haneli olmalı", "Code muss 6 Ziffern haben", "Le code doit avoir 6 chiffres", "El código debe tener 6 dígitos", "Il codice deve avere 6 cifre", "コードは6桁", "验证码必须为6位", "코드는 6자리", "Code moet 6 cijfers zijn", "Код должен быть из 6 цифр"]),
    ("enterValidEmail", ["Please enter a valid email address", "Geçerli bir e-posta adresi girin", "Bitte gültige E-Mail-Adresse", "Adresse e-mail valide requise", "Introduce un correo válido", "Inserisci email valida", "有効なメールアドレスを入力", "请输入有效邮箱地址", "유효한 이메일 주소를 입력하세요", "Voer een geldig e-mailadres in", "Введите корректный email"]),
    ("enterEmailAddress", ["Please enter your email address", "Lütfen e-posta adresinizi girin", "Bitte E-Mail-Adresse eingeben", "Veuillez entrer votre e-mail", "Introduce tu correo", "Inserisci il tuo indirizzo email", "メールアドレスを入力", "请输入邮箱地址", "이메일 주소를 입력하세요", "Voer je e-mailadres in", "Введите адрес email"]),
    ("enterSixDigitCodeShort", ["Please enter a 6-digit code", "Lütfen 6 haneli kod girin", "Bitte 6-stelligen Code eingeben", "Entrez un code à 6 chiffres", "Introduce un código de 6 dígitos", "Inserisci un codice a 6 cifre", "6桁のコードを入力", "请输入6位验证码", "6자리 코드를 입력하세요", "Voer een 6-cijferige code in", "Введите 6-значный код"]),
    ("profileAlreadyExists", ["Profile already exists for this email", "Bu e-posta için profil zaten var", "Profil existiert bereits", "Un profil existe déjà", "Ya existe un perfil", "Profilo già esistente", "プロフィールは既に存在します", "该邮箱已有资料", "이미 존재하는 프로필", "Profiel bestaat al", "Профиль уже существует"]),
    ("profileNotFound", ["Profile not found", "Profil bulunamadı", "Profil nicht gefunden", "Profil introuvable", "Perfil no encontrado", "Profilo non trovato", "プロフィールが見つかりません", "未找到资料", "프로필을 찾을 수 없음", "Profiel niet gevonden", "Профиль не найден"]),
    ("invalidPassword", ["Invalid password", "Geçersiz şifre", "Ungültiges Passwort", "Mot de passe invalide", "Contraseña inválida", "Password non valida", "パスワードが無効です", "密码无效", "잘못된 비밀번호", "Ongeldig wachtwoord", "Неверный пароль"]),
    ("feedbackIntro", ["Share your ideas, suggestions, or report issues. Your feedback helps make Pandoku better!", "Fikirlerini, önerilerini paylaş veya sorun bildir. Geri bildirimin Pandoku'yu geliştirmemize yardımcı olur!", "Teile Ideen und melde Probleme.", "Partagez vos idées et signalez des problèmes.", "Comparte ideas y reporta problemas.", "Condividi idee e segnala problemi.", "アイデアや問題をお知らせください。", "分享想法或报告问题。", "아이디어나 문제를 알려주세요.", "Deel ideeën en meld problemen.", "Делитесь идеями и сообщайте о проблемах."]),
    ("category", ["Category", "Kategori", "Kategorie", "Catégorie", "Categoría", "Categoria", "カテゴリ", "类别", "카테고리", "Categorie", "Категория"]),
    ("message", ["Message", "Mesaj", "Nachricht", "Message", "Mensaje", "Messaggio", "メッセージ", "消息", "메시지", "Bericht", "Сообщение"]),
    ("messageHint", ["Tell us what you think...", "Ne düşündüğünü yaz...", "Was denkst du?", "Dites-nous ce que vous pensez...", "Cuéntanos qué piensas...", "Dicci cosa ne pensi...", "ご意見をお聞かせください...", "告诉我们您的想法...", "의견을 알려주세요...", "Vertel ons wat je denkt...", "Расскажите, что думаете..."]),
    ("feedbackThanks", ["Thank you! Your feedback has been sent.", "Teşekkürler! Geri bildirimin gönderildi.", "Danke! Feedback gesendet.", "Merci ! Votre avis a été envoyé.", "¡Gracias! Comentario enviado.", "Grazie! Feedback inviato.", "ありがとうございます！", "谢谢！反馈已发送。", "감사합니다! 피드백이 전송되었습니다.", "Bedankt! Feedback verzonden.", "Спасибо! Отзыв отправлен."]),
    ("suggestion", ["Suggestion", "Öneri", "Vorschlag", "Suggestion", "Sugerencia", "Suggerimento", "提案", "建议", "제안", "Suggestie", "Предложение"]),
    ("bugReport", ["Bug Report", "Hata Bildirimi", "Fehlerbericht", "Rapport de bug", "Informe de error", "Segnalazione bug", "バグ報告", "错误报告", "버그 신고", "Bugrapport", "Сообщение об ошибке"]),
    ("general", ["General", "Genel", "Allgemein", "Général", "General", "Generale", "一般", "一般", "일반", "Algemeen", "Общее"]),
    ("enterMessage", ["Please enter a message", "Lütfen bir mesaj girin", "Bitte Nachricht eingeben", "Veuillez entrer un message", "Introduce un mensaje", "Inserisci un messaggio", "メッセージを入力", "请输入消息", "메시지를 입력하세요", "Voer een bericht in", "Введите сообщение"]),
    ("messageMinLength", ["Please write at least 10 characters", "En az 10 karakter yazın", "Mindestens 10 Zeichen", "Au moins 10 caractères", "Escribe al menos 10 caracteres", "Scrivi almeno 10 caratteri", "10文字以上入力", "至少输入10个字符", "10자 이상 입력", "Schrijf minstens 10 tekens", "Напишите не менее 10 символов"]),
    ("feedbackNotConfigured", ["Feedback service is not configured.", "Geri bildirim servisi yapılandırılmamış.", "Feedback-Dienst nicht konfiguriert.", "Service de feedback non configuré.", "Servicio de comentarios no configurado.", "Servizio feedback non configurato.", "フィードバックサービスが設定されていません。", "反馈服务未配置。", "피드백 서비스가 구성되지 않았습니다.", "Feedbackservice niet geconfigureerd.", "Служба отзывов не настроена."]),
    ("feedbackSendFailed", ["Could not send feedback.", "Geri bildirim gönderilemedi.", "Feedback konnte nicht gesendet werden.", "Impossible d'envoyer l'avis.", "No se pudo enviar el comentario.", "Impossibile inviare feedback.", "フィードバックを送信できませんでした。", "无法发送反馈。", "피드백을 보낼 수 없습니다.", "Kon feedback niet verzenden.", "Не удалось отправить отзыв."]),
    ("feedbackConnectionError", ["Could not send feedback. Please check your connection.", "Geri bildirim gönderilemedi. Bağlantınızı kontrol edin.", "Feedback nicht gesendet. Verbindung prüfen.", "Impossible d'envoyer. Vérifiez votre connexion.", "No se pudo enviar. Comprueba tu conexión.", "Impossibile inviare. Controlla la connessione.", "送信できませんでした。接続を確認してください。", "发送失败，请检查网络。", "전송 실패. 연결을 확인하세요.", "Verzenden mislukt. Controleer verbinding.", "Не удалось отправить. Проверьте соединение."]),
]
for key, vals in login_keys:
    add(key, *vals)

add("gameScore", "Score", "Skor", "Punkte", "Score", "Puntuación", "Punteggio", "スコア", "分数", "점수", "Score", "Счёт")
add("gameError", "Error", "Hata", "Fehler", "Erreur", "Error", "Errore", "エラー", "错误", "오류", "Fout", "Ошибка")
add("gameCongratulations", "Congratulations!", "Tebrikler!", "Glückwunsch!", "Félicitations !", "¡Felicidades!", "Congratulazioni!", "おめでとう！", "恭喜！", "축하합니다!", "Gefeliciteerd!", "Поздравляем!")
add("gameCompletionMessage", "You have successfully completed the Sudoku!\n\nScore: {score}", "Sudoku'yu başarıyla tamamladın!\n\nSkor: {score}", "Sudoku erfolgreich gelöst!\n\nPunkte: {score}", "Vous avez terminé le Sudoku !\n\nScore : {score}", "¡Has completado el Sudoku!\n\nPuntuación: {score}", "Hai completato il Sudoku!\n\nPunteggio: {score}", "数独をクリアしました！\n\nスコア: {score}", "你成功完成了数独！\n\n分数：{score}", "스도쿠를 완료했습니다!\n\n점수: {score}", "Je hebt de Sudoku voltooid!\n\nScore: {score}", "Вы завершили судоку!\n\nСчёт: {score}")
add("backToHome", "Back to Home", "Ana Sayfaya Dön", "Zur Startseite", "Retour à l'accueil", "Volver al inicio", "Torna alla home", "ホームに戻る", "返回首页", "홈으로", "Terug naar home", "На главную")
add("gameOver", "Game Over", "Oyun Bitti", "Spiel vorbei", "Partie terminée", "Fin del juego", "Game over", "ゲームオーバー", "游戏结束", "게임 오버", "Game over", "Игра окончена")
add("gameOverMessage", "You made 3 errors. Game lost!", "3 hata yaptın. Oyun kaybedildi!", "3 Fehler. Spiel verloren!", "3 erreurs. Partie perdue !", "3 errores. ¡Partida perdida!", "3 errori. Partita persa!", "3回のミス。ゲームオーバー！", "犯了3个错误，游戏失败！", "3번의 실수. 게임 패배!", "3 fouten. Spel verloren!", "3 ошибки. Игра проиграна!")
add("sudoku", "Sudoku", "Sudoku", "Sudoku", "Sudoku", "Sudoku", "Sudoku", "数独", "数独", "스도쿠", "Sudoku", "Судоку")

add("dailyCalendarTitle", "Daily Sudoku Calendar", "Günlük Sudoku Takvimi", "Täglicher Sudoku-Kalender", "Calendrier Sudoku quotidien", "Calendario Sudoku diario", "Calendario Sudoku giornaliero", "デイリー数独カレンダー", "每日数独日历", "일일 스도쿠 캘린더", "Dagelijkse Sudoku-kalender", "Календарь ежедневного судоку")
add("futureDateUnavailable", "Future Date - Not Available", "Gelecek Tarih - Kullanılamaz", "Zukünftiges Datum - nicht verfügbar", "Date future - non disponible", "Fecha futura - no disponible", "Data futura - non disponibile", "未来の日付 - 利用不可", "未来日期 - 不可用", "미래 날짜 - 사용 불가", "Toekomstige datum - niet beschikbaar", "Будущая дата - недоступно")
add("completed", "Completed", "Tamamlandı", "Abgeschlossen", "Terminé", "Completado", "Completato", "完了", "已完成", "완료", "Voltooid", "Завершено")
add("playTodaysGame", "Play Today's Game", "Günün Oyununu Oyna", "Spiel des Tages spielen", "Jouer au jeu du jour", "Jugar el juego de hoy", "Gioca il gioco di oggi", "今日のゲームをプレイ", "玩今日游戏", "오늘의 게임 플레이", "Speel het spel van vandaag", "Играть в игру дня")
add("playDaysGame", "Play This Day's Game", "Bu Günün Oyununu Oyna", "Spiel dieses Tages spielen", "Jouer au jeu de ce jour", "Jugar el juego de este día", "Gioca il gioco di questo giorno", "この日のゲームをプレイ", "玩这天的游戏", "이 날의 게임 플레이", "Speel het spel van deze dag", "Играть в игру этого дня")
add("difficultyLabel", "Difficulty: {difficulty}", "Zorluk: {difficulty}", "Schwierigkeit: {difficulty}", "Difficulté : {difficulty}", "Dificultad: {difficulty}", "Difficoltà: {difficulty}", "難易度: {difficulty}", "难度：{difficulty}", "난이도: {difficulty}", "Moeilijkheid: {difficulty}", "Сложность: {difficulty}")

add("otherApps", "Other Apps", "Diğer Uygulamalar", "Weitere Apps", "Autres apps", "Otras apps", "Altre app", "その他のアプリ", "其他应用", "기타 앱", "Andere apps", "Другие приложения")
add("followOnInstagram", "Follow Us on Instagram", "Instagram'da Bizi Takip Et", "Folge uns auf Instagram", "Suivez-nous sur Instagram", "Síguenos en Instagram", "Seguici su Instagram", "Instagramでフォロー", "在 Instagram 关注我们", "Instagram에서 팔로우", "Volg ons op Instagram", "Подписывайтесь в Instagram")
add("instagramLinkComingSoon", "Instagram link will be available soon", "Instagram bağlantısı yakında", "Instagram-Link demnächst verfügbar", "Lien Instagram bientôt disponible", "Enlace de Instagram próximamente", "Link Instagram in arrivo", "Instagramリンクは近日公開", "Instagram 链接即将推出", "Instagram 링크 곧 제공", "Instagram-link binnenkort beschikbaar", "Ссылка на Instagram скоро")
add("moreApps", "More Apps", "Daha Fazla Uygulama", "Weitere Apps", "Plus d'apps", "Más apps", "Altre app", "その他のアプリ", "更多应用", "더 많은 앱", "Meer apps", "Больше приложений")
add("moreAppsComingSoon", "More apps coming soon", "Daha fazla uygulama yakında", "Weitere Apps demnächst", "Plus d'apps bientôt", "Más apps próximamente", "Altre app in arrivo", "その他のアプリは近日公開", "更多应用即将推出", "더 많은 앱 곧 출시", "Meer apps binnenkort", "Больше приложений скоро")

add("statYearly", "Yearly", "Yıllık", "Jährlich", "Annuel", "Anual", "Annuale", "年間", "年度", "연간", "Jaarlijks", "За год")
add("statMonthly", "Monthly", "Aylık", "Monatlich", "Mensuel", "Mensual", "Mensile", "月間", "月度", "월간", "Maandelijks", "За месяц")
add("statWeekly", "Weekly", "Haftalık", "Wöchentlich", "Hebdomadaire", "Semanal", "Settimanale", "週間", "周度", "주간", "Wekelijks", "За неделю")
add("weeklyCompletedGames", "Weekly Completed Games", "Haftalık Tamamlanan Oyunlar", "Wöchentlich abgeschlossene Spiele", "Jeux terminés par semaine", "Juegos completados semanales", "Giochi completati settimanali", "週間クリアゲーム", "本周完成的游戏", "주간 완료 게임", "Wekelijks voltooide spellen", "Завершённые игры за неделю")

weekdays = [
    ("Mon", "Pzt", "Mo", "Lun", "Lun", "Lun", "月", "一", "월", "Ma", "Пн"),
    ("Tue", "Sal", "Di", "Mar", "Mar", "Mar", "火", "二", "화", "Di", "Вт"),
    ("Wed", "Çar", "Mi", "Mer", "Mié", "Mer", "水", "三", "수", "Wo", "Ср"),
    ("Thu", "Per", "Do", "Jeu", "Jue", "Gio", "木", "四", "목", "Do", "Чт"),
    ("Fri", "Cum", "Fr", "Ven", "Vie", "Ven", "金", "五", "금", "Vr", "Пт"),
    ("Sat", "Cmt", "Sa", "Sam", "Sáb", "Sab", "土", "六", "토", "Za", "Сб"),
    ("Sun", "Paz", "So", "Dim", "Dom", "Dom", "日", "日", "일", "Zo", "Вс"),
]
for i, vals in enumerate(weekdays):
    add(f"day{i}", *vals)

add("durationHoursMinutes", "{hours}h {minutes}m", "{hours}s {minutes}dk", "{hours}h {minutes}m", "{hours}h {minutes}m", "{hours}h {minutes}m", "{hours}h {minutes}m", "{hours}時間{minutes}分", "{hours}小时{minutes}分", "{hours}시간 {minutes}분", "{hours}u {minutes}m", "{hours}ч {minutes}м")
add("durationMinutesSeconds", "{minutes}m {seconds}s", "{minutes}dk {seconds}sn", "{minutes}m {seconds}s", "{minutes}m {seconds}s", "{minutes}m {seconds}s", "{minutes}m {seconds}s", "{minutes}分{seconds}秒", "{minutes}分{seconds}秒", "{minutes}분 {seconds}초", "{minutes}m {seconds}s", "{minutes}м {seconds}с")
add("durationSeconds", "{seconds}s", "{seconds}sn", "{seconds}s", "{seconds}s", "{seconds}s", "{seconds}s", "{seconds}秒", "{seconds}秒", "{seconds}초", "{seconds}s", "{seconds}с")


def main() -> None:
    lines = [
        "// GENERATED by scripts/generate_l10n.py — do not edit by hand.",
        "class AppStrings {",
        "  AppStrings._();",
        "",
        "  static const supportedLanguageCodes = [",
        "    'en', 'tr', 'de', 'fr', 'es', 'it', 'ja', 'zh', 'ko', 'nl', 'ru',",
        "  ];",
        "",
        "  static String get(String key, String languageCode) {",
        "    final lang = supportedLanguageCodes.contains(languageCode)",
        "        ? languageCode",
        "        : 'en';",
        "    return _strings[key]?[lang] ?? _strings[key]?['en'] ?? key;",
        "  }",
        "",
        "  static const Map<String, Map<String, String>> _strings = {",
    ]
    for key in sorted(DATA.keys()):
        lines.append(f"    '{key}': {emit_map(DATA[key])},")
    lines.extend(["  };", "}", ""])

    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({len(DATA)} keys, {len(lines)} lines)")


if __name__ == "__main__":
    main()
