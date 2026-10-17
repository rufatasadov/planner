// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'OneLinePlanner';

  @override
  String get tagline => 'One thing at a time. Plan your day on a single line.';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Sign up';

  @override
  String get createAccount => 'Create account';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgot => 'Forgot password?';

  @override
  String get welcomeLoginHint => 'Sign in to pick up your day.';

  @override
  String get welcomeRegisterHint => '14-day Pro trial. No card needed.';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Use at least 6 characters';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get forgotTitle => 'Reset your password';

  @override
  String get forgotText => 'Enter the email you signed up with and we will send you a link to set a new password.';

  @override
  String get sendLink => 'Send link';

  @override
  String forgotSent(String email) {
    return 'If an account exists for $email, a reset link is on its way. The link opens the website.';
  }

  @override
  String get backToLogin => 'Back to log in';

  @override
  String get tabPlan => 'Daily plan';

  @override
  String get tabProjects => 'Projects';

  @override
  String get tabNotes => 'Notes';

  @override
  String get tabSettings => 'Settings';

  @override
  String get comingTitle => 'Coming next';

  @override
  String get comingPlan => 'The day timeline, drag and drop and the timer are the next step.';

  @override
  String get comingProjects => 'Projects and tasks will appear here.';

  @override
  String get comingNotes => 'Work notes will appear here.';

  @override
  String get planToday => 'Today';

  @override
  String get planEmpty => 'Nothing on this day yet.';

  @override
  String get planAdd => 'Add block';

  @override
  String get planEdit => 'Edit';

  @override
  String get planEditTitle => 'Edit plan';

  @override
  String get planProject => 'Project';

  @override
  String get planProjectName => 'Project name';

  @override
  String get planNewProject => 'New project';

  @override
  String get planStart => 'Start';

  @override
  String get planEnd => 'End';

  @override
  String get planNote => 'Note';

  @override
  String get planSave => 'Save';

  @override
  String get planDelete => 'Delete';

  @override
  String get planMoved => 'Time updated';

  @override
  String get planNoFreeTime => 'No free time left in the working day.';

  @override
  String get planHistoryLocked => 'This day is older than the Free history. Older plans are still saved.';

  @override
  String get planRetry => 'Try again';

  @override
  String get planSchedule => 'Schedule';

  @override
  String get planClickToAdd => 'Tap an empty spot to add a block. Hold a block to move it.';

  @override
  String get planViewStrip => 'Strip';

  @override
  String get planViewColumn => 'Day';

  @override
  String get planViewFit => 'Fit';

  @override
  String get planViewStripHint => 'Scroll sideways through the day. Every block is listed below.';

  @override
  String get planViewColumnHint => 'Hours run down the page. Tap a block to open it, hold to edit.';

  @override
  String get planViewFitHint => 'The whole working day fits on screen. Names are in the list below.';

  @override
  String get planSelectBlock => 'Tap a block to see its tasks.';

  @override
  String get planNow => 'Now';

  @override
  String get planNext => 'Next';

  @override
  String get planThen => 'Then';

  @override
  String get planNoActive => 'No active plan right now';

  @override
  String get planNoTasks => 'No tasks in this block.';

  @override
  String get planLeft => 'left';

  @override
  String get planUntilStart => 'until start';

  @override
  String get planAlmostOver => 'Almost over';

  @override
  String get planDistribution => 'Distribution';

  @override
  String planFilled(int p) {
    return '$p% filled';
  }

  @override
  String get planSyncTasks => 'Add new tasks';

  @override
  String get planPostpone => 'Postpone';

  @override
  String get planPostponeToday => 'Today';

  @override
  String get planPostponeTomorrow => 'Tomorrow';

  @override
  String get planPostponeIn2 => 'In 2 days';

  @override
  String get planPostponeWeek => 'In a week';

  @override
  String get planPostponed => 'Plan postponed';

  @override
  String get trackStart => 'Start';

  @override
  String get trackPause => 'Pause';

  @override
  String get trackResume => 'Resume';

  @override
  String get trackEnded => 'Plan ended';

  @override
  String get trackEffective => 'Effective';

  @override
  String get trackBreaks => 'Breaks';

  @override
  String get trackSessions => 'Sessions';

  @override
  String get trackEfficiency => 'Efficiency';

  @override
  String trackOnBreak(String time) {
    return 'Break: $time';
  }

  @override
  String get trackFailed => 'The timer could not be updated';

  @override
  String get taskTodo => 'To do';

  @override
  String get taskDoing => 'In progress';

  @override
  String get taskDone => 'Done';

  @override
  String get taskCancelled => 'Cancelled';

  @override
  String get planPlanned => 'Planned';

  @override
  String get planFreeTime => 'Free';

  @override
  String get planTasks => 'Tasks';

  @override
  String planHours(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String planMinutes(int m) {
    return '${m}m';
  }

  @override
  String get projectsTitle => 'Projects';

  @override
  String get projectsNew => 'New project';

  @override
  String get projectsEdit => 'Edit project';

  @override
  String get projectsCreate => 'Create project';

  @override
  String get projectsEmpty => 'No projects yet. Create your first one.';

  @override
  String get projectsNoDescription => 'No description';

  @override
  String get projectsOpen => 'open';

  @override
  String get projectsDone => 'done';

  @override
  String get projectsTotal => 'total';

  @override
  String projectsCompleted(int p) {
    return '$p% completed';
  }

  @override
  String get projectsName => 'Name';

  @override
  String get projectsDescription => 'Description';

  @override
  String get projectsColor => 'Color';

  @override
  String get projectsCreated => 'Project created';

  @override
  String get projectsUpdated => 'Project updated';

  @override
  String get projectsDeleted => 'Project deleted';

  @override
  String projectsConfirmDelete(String name) {
    return 'Delete the \"$name\" project with all its tasks and plans?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get tasksAdd => 'Add';

  @override
  String get tasksAddPlaceholder => 'Add a new task…';

  @override
  String get tasksAddFailed => 'Failed to add task';

  @override
  String get tasksStatusFailed => 'Failed to change status';

  @override
  String tasksConfirmDelete(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String tasksConfirmDeleteSubs(String title, int n) {
    return 'Delete \"$title\" and its $n subtasks?';
  }

  @override
  String get tasksEmptyFilter => 'No tasks for this filter.';

  @override
  String get tasksFilterOpen => 'Open';

  @override
  String get tasksFilterDone => 'Done';

  @override
  String get tasksFilterCancelled => 'Cancelled';

  @override
  String get tasksFilterAll => 'All';

  @override
  String get tasksAddSubtask => 'Add subtask';

  @override
  String get tasksSubtaskPlaceholder => 'Subtask…';

  @override
  String tasksParentDone(String title) {
    return 'All subtasks are done — \"$title\" marked as done';
  }

  @override
  String tasksParentReopened(String title) {
    return '\"$title\" is back in progress';
  }

  @override
  String get tasksMove => 'Move';

  @override
  String tasksMoveTitle(String title) {
    return 'Move: $title';
  }

  @override
  String get tasksMoveTo => 'Put under task';

  @override
  String get tasksIndependent => 'Independent task';

  @override
  String get tasksCannotNest => 'This task has its own subtasks, so it can only stay independent.';

  @override
  String tasksMovedUnder(String title) {
    return 'Moved under \"$title\"';
  }

  @override
  String get tasksMadeIndependent => 'Task is now independent';

  @override
  String get tasksRename => 'Rename';

  @override
  String get tasksMoveUp => 'Move up';

  @override
  String get tasksMoveDown => 'Move down';

  @override
  String get notesTitle => 'Notes';

  @override
  String get notesToday => 'Today';

  @override
  String get notesWeek => 'Week';

  @override
  String get notesMonth => 'Month';

  @override
  String get notesEmpty => 'No notes in this range.';

  @override
  String get notesEmptyFilter => 'No notes match the selected filter.';

  @override
  String get notesSearch => 'Search';

  @override
  String get notesAll => 'All';

  @override
  String get notesAllProjects => 'All projects';

  @override
  String notesSummary(int n, int tasks) {
    return '$n notes · $tasks tasks';
  }

  @override
  String get notesEdited => 'edited';

  @override
  String get notesConfirmDelete => 'Delete this note?';

  @override
  String get notesPlan => 'Plan';

  @override
  String get notesAdd => 'Add note';

  @override
  String get notesPlaceholder => 'What did you do?';

  @override
  String get notesSaved => 'Note saved';

  @override
  String get notesTaskEmpty => 'No notes for this task yet.';

  @override
  String get settingsWorkHours => 'Working hours';

  @override
  String get settingsWorkHoursHint => 'Daily plans can only be made within this range.';

  @override
  String settingsWorkDay(String d) {
    return 'Work day: $d';
  }

  @override
  String get settingsEndAfterStart => 'The end must be after the start.';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotifyBefore => 'How many minutes before a plan starts or ends';

  @override
  String get settingsTracking => 'Time tracking';

  @override
  String get settingsEfficiencyHint => 'Efficiency = time actually worked ÷ elapsed plan time.';

  @override
  String get settingsAutoStop => 'Stop the timer automatically when the plan ends';

  @override
  String get settingsAutoStopHint => 'A finished plan cannot be started again.';

  @override
  String get settingsTarget => 'Target efficiency';

  @override
  String get settingsBreakReminder => 'Remind me when a break lasts longer than';

  @override
  String get settingsIdlePause => 'Auto-pause after this much inactivity on the computer';

  @override
  String get settingsIdleHint => 'Auto-pause runs in the browser, when the timer was started there.';

  @override
  String get settingsOff => 'Off';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String settingsSourceTrial(int n, String date) {
    return 'Pro trial: $n days left (until $date)';
  }

  @override
  String settingsSourceSubscription(String product) {
    return 'Pro subscription ($product)';
  }

  @override
  String settingsRenews(String date) {
    return 'Next payment: $date';
  }

  @override
  String settingsEndsOn(String date) {
    return 'Subscription ends on $date';
  }

  @override
  String get settingsSourcePromo => 'Gifted Pro';

  @override
  String settingsPromoUntil(String date) {
    return 'until $date';
  }

  @override
  String get settingsPromoForever => 'no end date';

  @override
  String get settingsSourceAdmin => 'Admin account — all Pro features are on';

  @override
  String settingsFreeText(int projects, int days) {
    return 'Limits: $projects projects, history of the last $days days.';
  }

  @override
  String get settingsProductMonthly => 'monthly';

  @override
  String get settingsProductYearly => 'yearly';

  @override
  String get settingsProductGift => 'gift';

  @override
  String get settingsManageWeb => 'This subscription is managed on the website.';

  @override
  String get settingsManageStore => 'This subscription is managed in the app store.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutMission => 'OneLinePlanner helps you plan tasks while working on only one thing at a time: the day is a single line, and at any moment there is just one task on it.';

  @override
  String get aboutAuthor => 'Author';

  @override
  String get aboutContact => 'Contact';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsScheduleView => 'Schedule view';

  @override
  String get settingsScheduleLocal => 'Saved on this device.';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get logout => 'Log out';

  @override
  String get planFree => 'Free';

  @override
  String get planPro => 'Pro';

  @override
  String planTrial(int days) {
    return 'Pro trial · $days days left';
  }

  @override
  String verifyBanner(String email) {
    return 'Confirm your email: we sent a link to $email. It opens the website.';
  }

  @override
  String get resend => 'Send again';

  @override
  String get resent => 'Email sent';

  @override
  String get tasksDrag => 'Drag to reorder';

  @override
  String get planCopyToWeek => 'Copy to other days';

  @override
  String get generateTitle => 'Copy this day';

  @override
  String generateIntro(String date, int n) {
    return 'Source: $date ($n blocks). Each new block gets that project\'s open tasks.';
  }

  @override
  String get generateThisWeek => 'This week';

  @override
  String get generateNextWeek => 'Next week';

  @override
  String get generateRestWorkdays => 'Remaining weekdays';

  @override
  String get generateRestDays => 'Remaining days this week';

  @override
  String get generateClear => 'Clear';

  @override
  String get generateModeSkip => 'Skip blocks that overlap';

  @override
  String get generateModeReplace => 'Replace existing plans on those days';

  @override
  String generateSubmit(int n) {
    return 'Copy to $n days';
  }

  @override
  String generateCreated(int n) {
    return '$n blocks created';
  }

  @override
  String generateSkipped(int n) {
    return '$n skipped because they overlap';
  }

  @override
  String get generateFailed => 'Could not copy the day';

  @override
  String get notifyChannel => 'Plans';

  @override
  String notifyStartTitle(String name, int m) {
    return '$name starts in $m min';
  }

  @override
  String notifyEndTitle(String name, int m) {
    return '$name: $m min left';
  }

  @override
  String notifyBody(String range) {
    return 'Plan $range';
  }

  @override
  String notifyNext(String name, String time) {
    return 'Next: $name ($time)';
  }

  @override
  String get paywallProjectsTitle => 'Project limit reached';

  @override
  String paywallProjectsText(int n) {
    return 'The Free plan allows up to $n projects. Pro removes the limit. Your data stays.';
  }

  @override
  String get paywallHistoryTitle => 'Older history is part of Pro';

  @override
  String paywallHistoryText(int n) {
    return 'Free shows the last $n days. Older plans are still saved.';
  }

  @override
  String get paywallDefaultTitle => 'OneLinePlanner Pro';

  @override
  String get paywallDefaultText => 'Unlimited projects, full history, and the Pro features that come next.';

  @override
  String get paywallMore => 'What Pro includes';

  @override
  String get paywallClose => 'Close';

  @override
  String get paywallUnlimited => 'Unlimited';

  @override
  String get paywallSoon => 'Soon';

  @override
  String paywallDays(int n) {
    return '$n days';
  }

  @override
  String get paywallFeatureProjects => 'Projects';

  @override
  String get paywallFeatureHistory => 'Plan history';

  @override
  String get paywallFeatureTimeline => 'Day schedule';

  @override
  String get paywallFeatureTracking => 'Time tracking';

  @override
  String get paywallFeatureNotes => 'Subtasks and notes';

  @override
  String get paywallFeatureCalendar => 'Calendar sync';

  @override
  String get paywallFeatureExport => 'Export';

  @override
  String get paywallFeatureTemplates => 'Templates and repeating plans';

  @override
  String get networkError => 'Could not reach the server. Check your connection and try again.';

  @override
  String get genericError => 'Something went wrong. Please try again.';

  @override
  String get settingsUpgrade => 'See Pro';

  @override
  String get settingsRestore => 'Restore purchases';

  @override
  String get settingsOpenStore => 'Manage in the app store';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountText => 'Plans, projects and notes are deleted. An App Store or Google Play subscription is not cancelled here. Cancel it in the store first if you do not want to be charged.';

  @override
  String get settingsDeletePassword => 'Password';

  @override
  String get settingsDeleteConfirm => 'Delete';

  @override
  String get paywallMonthly => 'Monthly';

  @override
  String get paywallYearly => 'Yearly';

  @override
  String get paywallBuy => 'Subscribe';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallRestored => 'Purchases checked';

  @override
  String get paywallPurchased => 'Payment received. Pro turns on after the store confirms it.';

  @override
  String get paywallPurchaseFailed => 'The purchase did not go through. Try again.';

  @override
  String get paywallPriceUnavailable => 'The store did not return a price. Try again in a moment.';

  @override
  String get paywallStoreUnavailable => 'In-app purchases are not connected on this build.';
}
