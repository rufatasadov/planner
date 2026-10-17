// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get appName => 'OneLinePlanner';

  @override
  String get tagline => 'Bir anda bir iş. Gününüzü bir xətt üzərində planlayın.';

  @override
  String get login => 'Daxil ol';

  @override
  String get register => 'Qeydiyyat';

  @override
  String get createAccount => 'Hesab yarat';

  @override
  String get name => 'Ad';

  @override
  String get email => 'Email';

  @override
  String get password => 'Şifrə';

  @override
  String get forgot => 'Şifrəni unutmusunuz?';

  @override
  String get welcomeLoginHint => 'Gününüzə qaldığınız yerdən davam edin.';

  @override
  String get welcomeRegisterHint => '14 günlük Pro sınağı. Kart tələb olunmur.';

  @override
  String get invalidEmail => 'Düzgün email yazın';

  @override
  String get passwordTooShort => 'Ən azı 6 simvol';

  @override
  String get nameRequired => 'Adınızı yazın';

  @override
  String get showPassword => 'Şifrəni göstər';

  @override
  String get hidePassword => 'Şifrəni gizlət';

  @override
  String get forgotTitle => 'Şifrənin bərpası';

  @override
  String get forgotText => 'Qeydiyyatdan keçdiyiniz emaili yazın, yeni şifrə üçün link göndərək.';

  @override
  String get sendLink => 'Link göndər';

  @override
  String forgotSent(String email) {
    return '$email üçün hesab varsa, bərpa linki göndərildi. Link saytı açır.';
  }

  @override
  String get backToLogin => 'Girişə qayıt';

  @override
  String get tabPlan => 'Günlük plan';

  @override
  String get tabProjects => 'Layihələr';

  @override
  String get tabNotes => 'Qeydlər';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get comingTitle => 'Növbəti addım';

  @override
  String get comingPlan => 'Gün xətti, sürüşdürmə və taymer növbəti addımdır.';

  @override
  String get comingProjects => 'Layihələr və tapşırıqlar burada olacaq.';

  @override
  String get comingNotes => 'İş qeydləri burada olacaq.';

  @override
  String get planToday => 'Bu gün';

  @override
  String get planEmpty => 'Bu gün hələ boşdur.';

  @override
  String get planAdd => 'Blok əlavə et';

  @override
  String get planEdit => 'Redaktə';

  @override
  String get planEditTitle => 'Planı redaktə et';

  @override
  String get planProject => 'Layihə';

  @override
  String get planProjectName => 'Layihənin adı';

  @override
  String get planNewProject => 'Yeni layihə';

  @override
  String get planStart => 'Başlanğıc';

  @override
  String get planEnd => 'Son';

  @override
  String get planNote => 'Qeyd';

  @override
  String get planSave => 'Saxla';

  @override
  String get planDelete => 'Sil';

  @override
  String get planMoved => 'Vaxt yeniləndi';

  @override
  String get planNoFreeTime => 'İş günündə boş vaxt qalmayıb.';

  @override
  String get planHistoryLocked => 'Bu gün pulsuz tarixçədən köhnədir. Planlar silinməyib.';

  @override
  String get planRetry => 'Yenidən cəhd et';

  @override
  String get planSchedule => 'Cədvəl';

  @override
  String get planClickToAdd => 'Boş yerə toxunub blok əlavə et. Bloku tutub sürüşdür.';

  @override
  String get planViewStrip => 'Xətt';

  @override
  String get planViewColumn => 'Gün';

  @override
  String get planViewFit => 'Sığdır';

  @override
  String get planViewStripHint => 'Günü sağa sürüşdür. Bütün bloklar aşağıda siyahıdadır.';

  @override
  String get planViewColumnHint => 'Saatlar yuxarıdan aşağı gedir. Bloka toxunub aç, uzun basıb redaktə et.';

  @override
  String get planViewFitHint => 'Bütün iş günü ekrana sığır. Adlar altdakı siyahıdadır.';

  @override
  String get planSelectBlock => 'Tapşırıqları görmək üçün bloka toxun.';

  @override
  String get planNow => 'İndi';

  @override
  String get planNext => 'Növbəti';

  @override
  String get planThen => 'Sonra';

  @override
  String get planNoActive => 'Hazırda aktiv plan yoxdur';

  @override
  String get planNoTasks => 'Bu blokda tapşırıq yoxdur.';

  @override
  String get planLeft => 'qaldı';

  @override
  String get planUntilStart => 'başlamağa';

  @override
  String get planAlmostOver => 'Vaxtın bitməsinə az qalıb';

  @override
  String get planDistribution => 'Vaxt bölgüsü';

  @override
  String planFilled(int p) {
    return '$p% dolu';
  }

  @override
  String get planSyncTasks => 'Yeni tapşırıqları əlavə et';

  @override
  String get planPostpone => 'Təxirə sal';

  @override
  String get planPostponeToday => 'Bu gün';

  @override
  String get planPostponeTomorrow => 'Sabah';

  @override
  String get planPostponeIn2 => '2 günə';

  @override
  String get planPostponeWeek => '1 həftəyə';

  @override
  String get planPostponed => 'Plan təxirə salındı';

  @override
  String get trackStart => 'Başla';

  @override
  String get trackPause => 'Fasilə';

  @override
  String get trackResume => 'Davam et';

  @override
  String get trackEnded => 'Plan bitib';

  @override
  String get trackEffective => 'Effektiv vaxt';

  @override
  String get trackBreaks => 'Fasilələr';

  @override
  String get trackSessions => 'Sessiyalar';

  @override
  String get trackEfficiency => 'Effektivlik';

  @override
  String trackOnBreak(String time) {
    return 'Fasilə: $time';
  }

  @override
  String get trackFailed => 'Taymer yenilənmədi';

  @override
  String get taskTodo => 'Gözləyir';

  @override
  String get taskDoing => 'İcrada';

  @override
  String get taskDone => 'Bitib';

  @override
  String get taskCancelled => 'Ləğv edilib';

  @override
  String get planPlanned => 'Planlanan';

  @override
  String get planFreeTime => 'Boş';

  @override
  String get planTasks => 'Tapşırıqlar';

  @override
  String planHours(int h, int m) {
    return '$h saat $m dəq';
  }

  @override
  String planMinutes(int m) {
    return '$m dəq';
  }

  @override
  String get projectsTitle => 'Layihələr';

  @override
  String get projectsNew => 'Yeni layihə';

  @override
  String get projectsEdit => 'Layihəni redaktə et';

  @override
  String get projectsCreate => 'Layihə yarat';

  @override
  String get projectsEmpty => 'Hələ layihə yoxdur. Birincisini yaradın.';

  @override
  String get projectsNoDescription => 'Təsvir yoxdur';

  @override
  String get projectsOpen => 'açıq';

  @override
  String get projectsDone => 'bitib';

  @override
  String get projectsTotal => 'cəmi';

  @override
  String projectsCompleted(int p) {
    return '$p% tamamlanıb';
  }

  @override
  String get projectsName => 'Ad';

  @override
  String get projectsDescription => 'Təsvir';

  @override
  String get projectsColor => 'Rəng';

  @override
  String get projectsCreated => 'Layihə yaradıldı';

  @override
  String get projectsUpdated => 'Layihə yeniləndi';

  @override
  String get projectsDeleted => 'Layihə silindi';

  @override
  String projectsConfirmDelete(String name) {
    return '\"$name\" layihəsi, onun tapşırıqları və planları silinsin?';
  }

  @override
  String get cancel => 'Ləğv et';

  @override
  String get tasksAdd => 'Əlavə et';

  @override
  String get tasksAddPlaceholder => 'Yeni tapşırıq əlavə et…';

  @override
  String get tasksAddFailed => 'Tapşırıq əlavə olunmadı';

  @override
  String get tasksStatusFailed => 'Status dəyişmədi';

  @override
  String tasksConfirmDelete(String title) {
    return '\"$title\" silinsin?';
  }

  @override
  String tasksConfirmDeleteSubs(String title, int n) {
    return '\"$title\" və onun $n alt tapşırığı silinsin?';
  }

  @override
  String get tasksEmptyFilter => 'Bu filtrdə tapşırıq yoxdur.';

  @override
  String get tasksFilterOpen => 'Açıq';

  @override
  String get tasksFilterDone => 'Bitmiş';

  @override
  String get tasksFilterCancelled => 'Ləğv';

  @override
  String get tasksFilterAll => 'Hamısı';

  @override
  String get tasksAddSubtask => 'Alt tapşırıq';

  @override
  String get tasksSubtaskPlaceholder => 'Alt tapşırıq…';

  @override
  String tasksParentDone(String title) {
    return 'Bütün alt tapşırıqlar bitdi — \"$title\" bitmiş sayıldı';
  }

  @override
  String tasksParentReopened(String title) {
    return '\"$title\" yenidən icraya qaytarıldı';
  }

  @override
  String get tasksMove => 'Köçür';

  @override
  String tasksMoveTitle(String title) {
    return 'Köçür: $title';
  }

  @override
  String get tasksMoveTo => 'Tapşırığın altına qoy';

  @override
  String get tasksIndependent => 'Müstəqil tapşırıq';

  @override
  String get tasksCannotNest => 'Bu tapşırığın öz alt tapşırıqları var, ona görə yalnız müstəqil qala bilər.';

  @override
  String tasksMovedUnder(String title) {
    return '\"$title\" altına köçürüldü';
  }

  @override
  String get tasksMadeIndependent => 'Tapşırıq müstəqil oldu';

  @override
  String get tasksRename => 'Adını dəyiş';

  @override
  String get tasksMoveUp => 'Yuxarı';

  @override
  String get tasksMoveDown => 'Aşağı';

  @override
  String get notesTitle => 'Qeydlər';

  @override
  String get notesToday => 'Bu gün';

  @override
  String get notesWeek => 'Həftə';

  @override
  String get notesMonth => 'Ay';

  @override
  String get notesEmpty => 'Bu aralıqda qeyd yoxdur.';

  @override
  String get notesEmptyFilter => 'Seçilmiş filtrə uyğun qeyd yoxdur.';

  @override
  String get notesSearch => 'Axtar';

  @override
  String get notesAll => 'Hamısı';

  @override
  String get notesAllProjects => 'Bütün layihələr';

  @override
  String notesSummary(int n, int tasks) {
    return '$n qeyd · $tasks tapşırıq';
  }

  @override
  String get notesEdited => 'redaktə olunub';

  @override
  String get notesConfirmDelete => 'Bu qeyd silinsin?';

  @override
  String get notesPlan => 'Plan';

  @override
  String get notesAdd => 'Qeyd əlavə et';

  @override
  String get notesPlaceholder => 'Nə etdiniz?';

  @override
  String get notesSaved => 'Qeyd saxlanıldı';

  @override
  String get notesTaskEmpty => 'Bu tapşırıq üçün hələ qeyd yoxdur.';

  @override
  String get settingsWorkHours => 'İş saatları';

  @override
  String get settingsWorkHoursHint => 'Günlük plan yalnız bu aralıqda tərtib olunur.';

  @override
  String settingsWorkDay(String d) {
    return 'İş günü: $d';
  }

  @override
  String get settingsEndAfterStart => 'Son başlanğıcdan sonra olmalıdır.';

  @override
  String get settingsNotifications => 'Bildirişlər';

  @override
  String get settingsNotifyBefore => 'Plan başlamazdan və bitməzdən neçə dəqiqə əvvəl';

  @override
  String get settingsTracking => 'Vaxt izləmə';

  @override
  String get settingsEfficiencyHint => 'Effektivlik = real işlənmiş vaxt ÷ planın keçmiş vaxtı.';

  @override
  String get settingsAutoStop => 'Plan bitəndə taymeri avtomatik dayandır';

  @override
  String get settingsAutoStopHint => 'Bitmiş plan üçün taymeri yenidən başlatmaq olmaz.';

  @override
  String get settingsTarget => 'Hədəf effektivlik';

  @override
  String get settingsBreakReminder => 'Fasilə bu qədər uzananda xatırlat';

  @override
  String get settingsIdlePause => 'Kompüterdə bu qədər aktivlik olmayanda avtomatik fasilə';

  @override
  String get settingsIdleHint => 'Avtomatik fasilə taymeri brauzerdə başlatdıqda işləyir.';

  @override
  String get settingsOff => 'Söndürülüb';

  @override
  String get settingsSaved => 'Ayarlar yadda saxlanıldı';

  @override
  String get settingsSubscription => 'Abunə';

  @override
  String settingsSourceTrial(int n, String date) {
    return 'Pro sınağı: $n gün qalıb ($date-dək)';
  }

  @override
  String settingsSourceSubscription(String product) {
    return 'Pro abunə ($product)';
  }

  @override
  String settingsRenews(String date) {
    return 'Növbəti ödəniş: $date';
  }

  @override
  String settingsEndsOn(String date) {
    return 'Abunə $date tarixində bitir';
  }

  @override
  String get settingsSourcePromo => 'Hədiyyə Pro';

  @override
  String settingsPromoUntil(String date) {
    return '$date-dək';
  }

  @override
  String get settingsPromoForever => 'müddətsiz';

  @override
  String get settingsSourceAdmin => 'Admin hesabı — bütün Pro funksiyalar açıqdır';

  @override
  String settingsFreeText(int projects, int days) {
    return 'Limitlər: $projects layihə, son $days günün tarixçəsi.';
  }

  @override
  String get settingsProductMonthly => 'aylıq';

  @override
  String get settingsProductYearly => 'illik';

  @override
  String get settingsProductGift => 'hədiyyə';

  @override
  String get settingsManageWeb => 'Bu abunə veb saytda idarə olunur.';

  @override
  String get settingsManageStore => 'Bu abunə tətbiq mağazasında idarə olunur.';

  @override
  String get aboutTitle => 'Haqqında';

  @override
  String get aboutMission => 'OneLinePlanner eyni anda yalnız bir işlə məşğul olaraq tapşırıqları planlamaq üçündür: gün bir xəttdir və hər an onun üzərində tək bir iş olur.';

  @override
  String get aboutAuthor => 'Müəllif';

  @override
  String get aboutContact => 'Əlaqə';

  @override
  String get settingsAccount => 'Hesab';

  @override
  String get settingsAppearance => 'Görünüş';

  @override
  String get settingsScheduleView => 'Cədvəl görünüşü';

  @override
  String get settingsScheduleLocal => 'Bu cihazda saxlanılır.';

  @override
  String get language => 'Dil';

  @override
  String get theme => 'Tema';

  @override
  String get themeLight => 'Açıq';

  @override
  String get themeDark => 'Tünd';

  @override
  String get logout => 'Çıxış';

  @override
  String get planFree => 'Free';

  @override
  String get planPro => 'Pro';

  @override
  String planTrial(int days) {
    return 'Pro sınağı · $days gün qaldı';
  }

  @override
  String verifyBanner(String email) {
    return 'Emailinizi təsdiqləyin: $email ünvanına link göndərdik. Link saytı açır.';
  }

  @override
  String get resend => 'Yenidən göndər';

  @override
  String get resent => 'Məktub göndərildi';

  @override
  String get tasksDrag => 'Sıranı dəyişmək üçün tutub sürüşdür';

  @override
  String get planCopyToWeek => 'Başqa günlərə köçür';

  @override
  String get generateTitle => 'Bu günü köçür';

  @override
  String generateIntro(String date, int n) {
    return 'Mənbə: $date ($n plan). Hər yeni plana proyektin açıq tapşırıqları əlavə olunur.';
  }

  @override
  String get generateThisWeek => 'Bu həftə';

  @override
  String get generateNextWeek => 'Gələn həftə';

  @override
  String get generateRestWorkdays => 'Həftənin qalan iş günləri';

  @override
  String get generateRestDays => 'Həftənin qalan günləri';

  @override
  String get generateClear => 'Təmizlə';

  @override
  String get generateModeSkip => 'Kəsişən planları ötür';

  @override
  String get generateModeReplace => 'Həmin günlərin planlarını sil və əvəz et';

  @override
  String generateSubmit(int n) {
    return '$n günə köçür';
  }

  @override
  String generateCreated(int n) {
    return '$n plan yaradıldı';
  }

  @override
  String generateSkipped(int n) {
    return '$n plan kəsişdiyi üçün ötürüldü';
  }

  @override
  String get generateFailed => 'Gün köçürülmədi';

  @override
  String get notifyChannel => 'Planlar';

  @override
  String notifyStartTitle(String name, int m) {
    return '$name $m dəq sonra başlayır';
  }

  @override
  String notifyEndTitle(String name, int m) {
    return '$name: $m dəq qaldı';
  }

  @override
  String notifyBody(String range) {
    return 'Plan $range';
  }

  @override
  String notifyNext(String name, String time) {
    return 'Növbəti: $name ($time)';
  }

  @override
  String get paywallProjectsTitle => 'Layihə limitinə çatdınız';

  @override
  String paywallProjectsText(int n) {
    return 'Pulsuz planda ən çox $n layihə yaratmaq olar. Pro limiti götürür. Məlumatlarınız qalır.';
  }

  @override
  String get paywallHistoryTitle => 'Köhnə tarixçə Pro-dadır';

  @override
  String paywallHistoryText(int n) {
    return 'Pulsuz planda son $n gün görünür. Köhnə planlar silinməyib.';
  }

  @override
  String get paywallDefaultTitle => 'OneLinePlanner Pro';

  @override
  String get paywallDefaultText => 'Limitsiz layihələr, tam tarixçə və sonrakı Pro imkanları.';

  @override
  String get paywallMore => 'Pro-da nələr var';

  @override
  String get paywallClose => 'Bağla';

  @override
  String get paywallUnlimited => 'Limitsiz';

  @override
  String get paywallSoon => 'Tezliklə';

  @override
  String paywallDays(int n) {
    return '$n gün';
  }

  @override
  String get paywallFeatureProjects => 'Layihələr';

  @override
  String get paywallFeatureHistory => 'Plan tarixçəsi';

  @override
  String get paywallFeatureTimeline => 'Gün qrafiki';

  @override
  String get paywallFeatureTracking => 'Vaxt ölçmə';

  @override
  String get paywallFeatureNotes => 'Alt tapşırıqlar və qeydlər';

  @override
  String get paywallFeatureCalendar => 'Təqvim sinxronu';

  @override
  String get paywallFeatureExport => 'Eksport';

  @override
  String get paywallFeatureTemplates => 'Şablonlar və təkrarlanan planlar';

  @override
  String get networkError => 'Serverə çatmaq olmadı. Bağlantını yoxlayıb yenidən cəhd edin.';

  @override
  String get genericError => 'Xəta baş verdi. Yenidən cəhd edin.';

  @override
  String get settingsUpgrade => 'Pro-ya bax';

  @override
  String get settingsRestore => 'Satınalmanı bərpa et';

  @override
  String get settingsOpenStore => 'Abunəni mağazada idarə et';

  @override
  String get settingsDeleteAccount => 'Hesabı sil';

  @override
  String get settingsDeleteAccountText => 'Planlar, layihələr və qeydlər silinir. App Store və ya Google Play abunəsi burada ləğv olunmur. Ödənişin davam etməsini istəmirsinizsə, əvvəl onu mağazada dayandırın.';

  @override
  String get settingsDeletePassword => 'Şifrə';

  @override
  String get settingsDeleteConfirm => 'Sil';

  @override
  String get paywallMonthly => 'Aylıq';

  @override
  String get paywallYearly => 'İllik';

  @override
  String get paywallBuy => 'Abunə ol';

  @override
  String get paywallRestore => 'Satınalmanı bərpa et';

  @override
  String get paywallRestored => 'Satınalmalar yoxlanıldı';

  @override
  String get paywallPurchased => 'Ödəniş qəbul olundu. Pro, mağaza təsdiqindən sonra açılır.';

  @override
  String get paywallPurchaseFailed => 'Ödəniş alınmadı. Yenidən cəhd edin.';

  @override
  String get paywallPriceUnavailable => 'Mağaza qiyməti gəlmədi. Bir az sonra yenidən cəhd edin.';

  @override
  String get paywallStoreUnavailable => 'Bu quruluşda mağaza alışları qoşulmayıb.';
}
