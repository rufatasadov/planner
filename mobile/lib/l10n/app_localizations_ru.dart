// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'OneLinePlanner';

  @override
  String get tagline => 'Одно дело за раз. Планируйте день на одной линии.';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get name => 'Имя';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get forgot => 'Забыли пароль?';

  @override
  String get welcomeLoginHint => 'Войдите и продолжите свой день.';

  @override
  String get welcomeRegisterHint => '14 дней Pro бесплатно. Карта не нужна.';

  @override
  String get invalidEmail => 'Введите корректный email';

  @override
  String get passwordTooShort => 'Минимум 6 символов';

  @override
  String get nameRequired => 'Введите имя';

  @override
  String get showPassword => 'Показать пароль';

  @override
  String get hidePassword => 'Скрыть пароль';

  @override
  String get forgotTitle => 'Восстановление пароля';

  @override
  String get forgotText => 'Введите email, с которым вы регистрировались, и мы пришлём ссылку для нового пароля.';

  @override
  String get sendLink => 'Отправить ссылку';

  @override
  String forgotSent(String email) {
    return 'Если аккаунт для $email существует, ссылка уже отправлена. Ссылка откроет сайт.';
  }

  @override
  String get backToLogin => 'Вернуться ко входу';

  @override
  String get tabPlan => 'План дня';

  @override
  String get tabProjects => 'Проекты';

  @override
  String get tabNotes => 'Заметки';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get comingTitle => 'Следующий шаг';

  @override
  String get comingPlan => 'Шкала дня, перетаскивание и таймер — следующий шаг.';

  @override
  String get comingProjects => 'Проекты и задачи появятся здесь.';

  @override
  String get comingNotes => 'Рабочие заметки появятся здесь.';

  @override
  String get planToday => 'Сегодня';

  @override
  String get planEmpty => 'На этот день пока ничего нет.';

  @override
  String get planAdd => 'Добавить блок';

  @override
  String get planEdit => 'Изменить';

  @override
  String get planEditTitle => 'Редактировать план';

  @override
  String get planProject => 'Проект';

  @override
  String get planProjectName => 'Название проекта';

  @override
  String get planNewProject => 'Новый проект';

  @override
  String get planStart => 'Начало';

  @override
  String get planEnd => 'Конец';

  @override
  String get planNote => 'Заметка';

  @override
  String get planSave => 'Сохранить';

  @override
  String get planDelete => 'Удалить';

  @override
  String get planMoved => 'Время обновлено';

  @override
  String get planNoFreeTime => 'В рабочем дне не осталось свободного времени.';

  @override
  String get planHistoryLocked => 'Этот день старше бесплатной истории. Планы не удалены.';

  @override
  String get planRetry => 'Попробовать снова';

  @override
  String get planSchedule => 'Расписание';

  @override
  String get planClickToAdd => 'Нажмите на пустое место, чтобы добавить блок. Удерживайте блок, чтобы сдвинуть.';

  @override
  String get planViewStrip => 'Лента';

  @override
  String get planViewColumn => 'День';

  @override
  String get planViewFit => 'Вместить';

  @override
  String get planViewStripHint => 'Листайте день вбок. Все блоки перечислены ниже.';

  @override
  String get planViewColumnHint => 'Часы идут сверху вниз. Нажмите блок, чтобы открыть, удерживайте — чтобы изменить.';

  @override
  String get planViewFitHint => 'Весь рабочий день помещается на экран. Названия — в списке ниже.';

  @override
  String get planSelectBlock => 'Нажмите блок, чтобы увидеть задачи.';

  @override
  String get planNow => 'Сейчас';

  @override
  String get planNext => 'Дальше';

  @override
  String get planThen => 'Затем';

  @override
  String get planNoActive => 'Сейчас нет активного плана';

  @override
  String get planNoTasks => 'В этом блоке нет задач.';

  @override
  String get planLeft => 'осталось';

  @override
  String get planUntilStart => 'до старта';

  @override
  String get planAlmostOver => 'Скоро закончится';

  @override
  String get planDistribution => 'Распределение';

  @override
  String planFilled(int p) {
    return '$p% занято';
  }

  @override
  String get planSyncTasks => 'Добавить новые задачи';

  @override
  String get planPostpone => 'Перенести';

  @override
  String get planPostponeToday => 'Сегодня';

  @override
  String get planPostponeTomorrow => 'Завтра';

  @override
  String get planPostponeIn2 => 'Через 2 дня';

  @override
  String get planPostponeWeek => 'Через неделю';

  @override
  String get planPostponed => 'План перенесён';

  @override
  String get trackStart => 'Старт';

  @override
  String get trackPause => 'Пауза';

  @override
  String get trackResume => 'Продолжить';

  @override
  String get trackEnded => 'План закончился';

  @override
  String get trackEffective => 'Эффективно';

  @override
  String get trackBreaks => 'Перерывы';

  @override
  String get trackSessions => 'Сессии';

  @override
  String get trackEfficiency => 'Эффективность';

  @override
  String trackOnBreak(String time) {
    return 'Перерыв: $time';
  }

  @override
  String get trackFailed => 'Таймер не обновился';

  @override
  String get taskTodo => 'Ожидает';

  @override
  String get taskDoing => 'В работе';

  @override
  String get taskDone => 'Готово';

  @override
  String get taskCancelled => 'Отменено';

  @override
  String get planPlanned => 'Запланировано';

  @override
  String get planFreeTime => 'Свободно';

  @override
  String get planTasks => 'Задачи';

  @override
  String planHours(int h, int m) {
    return '$h ч $m мин';
  }

  @override
  String planMinutes(int m) {
    return '$m мин';
  }

  @override
  String get projectsTitle => 'Проекты';

  @override
  String get projectsNew => 'Новый проект';

  @override
  String get projectsEdit => 'Редактировать проект';

  @override
  String get projectsCreate => 'Создать проект';

  @override
  String get projectsEmpty => 'Проектов пока нет. Создайте первый.';

  @override
  String get projectsNoDescription => 'Нет описания';

  @override
  String get projectsOpen => 'открыто';

  @override
  String get projectsDone => 'готово';

  @override
  String get projectsTotal => 'всего';

  @override
  String projectsCompleted(int p) {
    return 'Выполнено $p%';
  }

  @override
  String get projectsName => 'Название';

  @override
  String get projectsDescription => 'Описание';

  @override
  String get projectsColor => 'Цвет';

  @override
  String get projectsCreated => 'Проект создан';

  @override
  String get projectsUpdated => 'Проект обновлён';

  @override
  String get projectsDeleted => 'Проект удалён';

  @override
  String projectsConfirmDelete(String name) {
    return 'Удалить проект «$name» вместе с задачами и планами?';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get tasksAdd => 'Добавить';

  @override
  String get tasksAddPlaceholder => 'Новая задача…';

  @override
  String get tasksAddFailed => 'Не удалось добавить задачу';

  @override
  String get tasksStatusFailed => 'Не удалось изменить статус';

  @override
  String tasksConfirmDelete(String title) {
    return 'Удалить «$title»?';
  }

  @override
  String tasksConfirmDeleteSubs(String title, int n) {
    return 'Удалить «$title» и её подзадачи ($n)?';
  }

  @override
  String get tasksEmptyFilter => 'Нет задач для этого фильтра.';

  @override
  String get tasksFilterOpen => 'Открытые';

  @override
  String get tasksFilterDone => 'Готовые';

  @override
  String get tasksFilterCancelled => 'Отменённые';

  @override
  String get tasksFilterAll => 'Все';

  @override
  String get tasksAddSubtask => 'Подзадача';

  @override
  String get tasksSubtaskPlaceholder => 'Подзадача…';

  @override
  String tasksParentDone(String title) {
    return 'Все подзадачи выполнены — «$title» отмечена как готовая';
  }

  @override
  String tasksParentReopened(String title) {
    return '«$title» снова в работе';
  }

  @override
  String get tasksMove => 'Переместить';

  @override
  String tasksMoveTitle(String title) {
    return 'Переместить: $title';
  }

  @override
  String get tasksMoveTo => 'Поместить под задачу';

  @override
  String get tasksIndependent => 'Самостоятельная задача';

  @override
  String get tasksCannotNest => 'У этой задачи есть свои подзадачи, поэтому она может быть только самостоятельной.';

  @override
  String tasksMovedUnder(String title) {
    return 'Перемещено под «$title»';
  }

  @override
  String get tasksMadeIndependent => 'Задача стала самостоятельной';

  @override
  String get tasksRename => 'Переименовать';

  @override
  String get tasksMoveUp => 'Выше';

  @override
  String get tasksMoveDown => 'Ниже';

  @override
  String get notesTitle => 'Заметки';

  @override
  String get notesToday => 'Сегодня';

  @override
  String get notesWeek => 'Неделя';

  @override
  String get notesMonth => 'Месяц';

  @override
  String get notesEmpty => 'В этом диапазоне заметок нет.';

  @override
  String get notesEmptyFilter => 'Нет заметок по выбранному фильтру.';

  @override
  String get notesSearch => 'Поиск';

  @override
  String get notesAll => 'Все';

  @override
  String get notesAllProjects => 'Все проекты';

  @override
  String notesSummary(int n, int tasks) {
    return '$n заметок · $tasks задач';
  }

  @override
  String get notesEdited => 'изменено';

  @override
  String get notesConfirmDelete => 'Удалить эту заметку?';

  @override
  String get notesPlan => 'План';

  @override
  String get notesAdd => 'Добавить заметку';

  @override
  String get notesPlaceholder => 'Что сделали?';

  @override
  String get notesSaved => 'Заметка сохранена';

  @override
  String get notesTaskEmpty => 'Для этой задачи заметок пока нет.';

  @override
  String get settingsWorkHours => 'Рабочие часы';

  @override
  String get settingsWorkHoursHint => 'План дня составляется только в этом интервале.';

  @override
  String settingsWorkDay(String d) {
    return 'Рабочий день: $d';
  }

  @override
  String get settingsEndAfterStart => 'Конец должен быть позже начала.';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsNotifyBefore => 'За сколько минут до начала и конца плана';

  @override
  String get settingsTracking => 'Учёт времени';

  @override
  String get settingsEfficiencyHint => 'Эффективность = реально отработанное время ÷ прошедшее время плана.';

  @override
  String get settingsAutoStop => 'Останавливать таймер автоматически, когда план заканчивается';

  @override
  String get settingsAutoStopHint => 'Завершённый план нельзя запустить повторно.';

  @override
  String get settingsTarget => 'Целевая эффективность';

  @override
  String get settingsBreakReminder => 'Напомнить, если перерыв длится дольше';

  @override
  String get settingsIdlePause => 'Автопауза после такого простоя за компьютером';

  @override
  String get settingsIdleHint => 'Автопауза работает в браузере, если таймер запущен там.';

  @override
  String get settingsOff => 'Выключено';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get settingsSubscription => 'Подписка';

  @override
  String settingsSourceTrial(int n, String date) {
    return 'Пробный Pro: осталось $n дн. (до $date)';
  }

  @override
  String settingsSourceSubscription(String product) {
    return 'Подписка Pro ($product)';
  }

  @override
  String settingsRenews(String date) {
    return 'Следующий платёж: $date';
  }

  @override
  String settingsEndsOn(String date) {
    return 'Подписка заканчивается $date';
  }

  @override
  String get settingsSourcePromo => 'Подарочный Pro';

  @override
  String settingsPromoUntil(String date) {
    return 'до $date';
  }

  @override
  String get settingsPromoForever => 'без срока';

  @override
  String get settingsSourceAdmin => 'Аккаунт администратора — все функции Pro открыты';

  @override
  String settingsFreeText(int projects, int days) {
    return 'Лимиты: $projects проекта, история за последние $days дней.';
  }

  @override
  String get settingsProductMonthly => 'месяц';

  @override
  String get settingsProductYearly => 'год';

  @override
  String get settingsProductGift => 'подарок';

  @override
  String get settingsManageWeb => 'Эта подписка управляется на сайте.';

  @override
  String get settingsManageStore => 'Эта подписка управляется в магазине приложений.';

  @override
  String get aboutTitle => 'О приложении';

  @override
  String get aboutMission => 'OneLinePlanner помогает планировать задачи, занимаясь только одним делом за раз: день — это одна линия, и в каждый момент на ней только одна задача.';

  @override
  String get aboutAuthor => 'Автор';

  @override
  String get aboutContact => 'Контакт';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsAppearance => 'Оформление';

  @override
  String get settingsScheduleView => 'Вид расписания';

  @override
  String get settingsScheduleLocal => 'Хранится на этом устройстве.';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get logout => 'Выйти';

  @override
  String get planFree => 'Free';

  @override
  String get planPro => 'Pro';

  @override
  String planTrial(int days) {
    return 'Пробный Pro · осталось $days дн.';
  }

  @override
  String verifyBanner(String email) {
    return 'Подтвердите email: мы отправили ссылку на $email. Ссылка откроет сайт.';
  }

  @override
  String get resend => 'Отправить снова';

  @override
  String get resent => 'Письмо отправлено';

  @override
  String get tasksDrag => 'Перетащите, чтобы изменить порядок';

  @override
  String get planCopyToWeek => 'Скопировать на другие дни';

  @override
  String get generateTitle => 'Скопировать этот день';

  @override
  String generateIntro(String date, int n) {
    return 'Источник: $date ($n блоков). В каждый новый блок попадают открытые задачи проекта.';
  }

  @override
  String get generateThisWeek => 'Эта неделя';

  @override
  String get generateNextWeek => 'Следующая неделя';

  @override
  String get generateRestWorkdays => 'Оставшиеся будни';

  @override
  String get generateRestDays => 'Оставшиеся дни недели';

  @override
  String get generateClear => 'Очистить';

  @override
  String get generateModeSkip => 'Пропускать пересекающиеся блоки';

  @override
  String get generateModeReplace => 'Заменить планы этих дней';

  @override
  String generateSubmit(int n) {
    return 'Скопировать на $n дн.';
  }

  @override
  String generateCreated(int n) {
    return 'Создано блоков: $n';
  }

  @override
  String generateSkipped(int n) {
    return 'Пропущено из-за пересечения: $n';
  }

  @override
  String get generateFailed => 'Не удалось скопировать день';

  @override
  String get notifyChannel => 'Планы';

  @override
  String notifyStartTitle(String name, int m) {
    return '$name начнётся через $m мин';
  }

  @override
  String notifyEndTitle(String name, int m) {
    return '$name: осталось $m мин';
  }

  @override
  String notifyBody(String range) {
    return 'План $range';
  }

  @override
  String notifyNext(String name, String time) {
    return 'Дальше: $name ($time)';
  }

  @override
  String get paywallProjectsTitle => 'Достигнут лимит проектов';

  @override
  String paywallProjectsText(int n) {
    return 'На бесплатном плане можно создать не больше $n проектов. Pro снимает лимит. Данные сохраняются.';
  }

  @override
  String get paywallHistoryTitle => 'Старая история входит в Pro';

  @override
  String paywallHistoryText(int n) {
    return 'Бесплатно видны последние $n дней. Старые планы не удалены.';
  }

  @override
  String get paywallDefaultTitle => 'OneLinePlanner Pro';

  @override
  String get paywallDefaultText => 'Безлимитные проекты, полная история и следующие возможности Pro.';

  @override
  String get paywallMore => 'Что входит в Pro';

  @override
  String get paywallClose => 'Закрыть';

  @override
  String get paywallUnlimited => 'Безлимит';

  @override
  String get paywallSoon => 'Скоро';

  @override
  String paywallDays(int n) {
    return '$n дн.';
  }

  @override
  String get paywallFeatureProjects => 'Проекты';

  @override
  String get paywallFeatureHistory => 'История планов';

  @override
  String get paywallFeatureTimeline => 'Расписание дня';

  @override
  String get paywallFeatureTracking => 'Учёт времени';

  @override
  String get paywallFeatureNotes => 'Подзадачи и заметки';

  @override
  String get paywallFeatureCalendar => 'Синхронизация календаря';

  @override
  String get paywallFeatureExport => 'Экспорт';

  @override
  String get paywallFeatureTemplates => 'Шаблоны и повторяющиеся планы';

  @override
  String get networkError => 'Не удалось связаться с сервером. Проверьте соединение и попробуйте снова.';

  @override
  String get genericError => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get settingsUpgrade => 'Смотреть Pro';

  @override
  String get settingsRestore => 'Восстановить покупки';

  @override
  String get settingsOpenStore => 'Управлять в магазине';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get settingsDeleteAccountText => 'Планы, проекты и заметки удаляются. Подписка App Store или Google Play здесь не отменяется. Если не хотите, чтобы списания продолжались, сначала отмените её в магазине.';

  @override
  String get settingsDeletePassword => 'Пароль';

  @override
  String get settingsDeleteConfirm => 'Удалить';

  @override
  String get paywallMonthly => 'Месяц';

  @override
  String get paywallYearly => 'Год';

  @override
  String get paywallBuy => 'Подписаться';

  @override
  String get paywallRestore => 'Восстановить покупки';

  @override
  String get paywallRestored => 'Покупки проверены';

  @override
  String get paywallPurchased => 'Оплата принята. Pro включится после подтверждения магазина.';

  @override
  String get paywallPurchaseFailed => 'Покупка не прошла. Попробуйте ещё раз.';

  @override
  String get paywallPriceUnavailable => 'Магазин не вернул цену. Попробуйте чуть позже.';

  @override
  String get paywallStoreUnavailable => 'В этой сборке покупки в магазине не подключены.';
}
