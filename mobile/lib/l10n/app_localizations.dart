import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OneLinePlanner'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'One thing at a time. Plan your day on a single line.'**
  String get tagline;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @authApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get authApple;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogle;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'The sign-in did not go through. Try again.'**
  String get authSignInFailed;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get register;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot;

  /// No description provided for @welcomeLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in to pick up your day.'**
  String get welcomeLoginHint;

  /// No description provided for @welcomeRegisterHint.
  ///
  /// In en, this message translates to:
  /// **'14-day Pro trial. No card needed.'**
  String get welcomeRegisterHint;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get nameRequired;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get forgotTitle;

  /// No description provided for @forgotText.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with and we will send you a link to set a new password.'**
  String get forgotText;

  /// No description provided for @sendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// No description provided for @forgotSent.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, a reset link is on its way. The link opens the website.'**
  String forgotSent(String email);

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get backToLogin;

  /// No description provided for @tabPlan.
  ///
  /// In en, this message translates to:
  /// **'Daily plan'**
  String get tabPlan;

  /// No description provided for @tabProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get tabProjects;

  /// No description provided for @tabNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tabNotes;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @comingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming next'**
  String get comingTitle;

  /// No description provided for @comingPlan.
  ///
  /// In en, this message translates to:
  /// **'The day timeline, drag and drop and the timer are the next step.'**
  String get comingPlan;

  /// No description provided for @comingProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects and tasks will appear here.'**
  String get comingProjects;

  /// No description provided for @comingNotes.
  ///
  /// In en, this message translates to:
  /// **'Work notes will appear here.'**
  String get comingNotes;

  /// No description provided for @planToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get planToday;

  /// No description provided for @planEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on this day yet.'**
  String get planEmpty;

  /// No description provided for @planAdd.
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get planAdd;

  /// No description provided for @planEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get planEdit;

  /// No description provided for @planEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get planEditTitle;

  /// No description provided for @planProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get planProject;

  /// No description provided for @planProjectName.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get planProjectName;

  /// No description provided for @planNewProject.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get planNewProject;

  /// No description provided for @planStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get planStart;

  /// No description provided for @planEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get planEnd;

  /// No description provided for @planNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get planNote;

  /// No description provided for @planSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get planSave;

  /// No description provided for @planDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get planDelete;

  /// No description provided for @planMoved.
  ///
  /// In en, this message translates to:
  /// **'Time updated'**
  String get planMoved;

  /// No description provided for @planNoFreeTime.
  ///
  /// In en, this message translates to:
  /// **'No free time left in the working day.'**
  String get planNoFreeTime;

  /// No description provided for @planHistoryLocked.
  ///
  /// In en, this message translates to:
  /// **'This day is older than the Free history. Older plans are still saved.'**
  String get planHistoryLocked;

  /// No description provided for @planRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get planRetry;

  /// No description provided for @planSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get planSchedule;

  /// No description provided for @planClickToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap an empty spot to add a block. Hold a block to move it.'**
  String get planClickToAdd;

  /// No description provided for @planViewStrip.
  ///
  /// In en, this message translates to:
  /// **'Strip'**
  String get planViewStrip;

  /// No description provided for @planViewColumn.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get planViewColumn;

  /// No description provided for @planViewFit.
  ///
  /// In en, this message translates to:
  /// **'Fit'**
  String get planViewFit;

  /// No description provided for @planViewStripHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll sideways through the day. Every block is listed below.'**
  String get planViewStripHint;

  /// No description provided for @planViewColumnHint.
  ///
  /// In en, this message translates to:
  /// **'Hours run down the page. Tap a block to open it, hold to edit.'**
  String get planViewColumnHint;

  /// No description provided for @planViewFitHint.
  ///
  /// In en, this message translates to:
  /// **'The whole working day fits on screen. Names are in the list below.'**
  String get planViewFitHint;

  /// No description provided for @planSelectBlock.
  ///
  /// In en, this message translates to:
  /// **'Tap a block to see its tasks.'**
  String get planSelectBlock;

  /// No description provided for @planNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get planNow;

  /// No description provided for @planNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get planNext;

  /// No description provided for @planThen.
  ///
  /// In en, this message translates to:
  /// **'Then'**
  String get planThen;

  /// No description provided for @planNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active plan right now'**
  String get planNoActive;

  /// No description provided for @planNoTasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks in this block.'**
  String get planNoTasks;

  /// No description provided for @planLeft.
  ///
  /// In en, this message translates to:
  /// **'left'**
  String get planLeft;

  /// No description provided for @planUntilStart.
  ///
  /// In en, this message translates to:
  /// **'until start'**
  String get planUntilStart;

  /// No description provided for @planAlmostOver.
  ///
  /// In en, this message translates to:
  /// **'Almost over'**
  String get planAlmostOver;

  /// No description provided for @planDistribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get planDistribution;

  /// No description provided for @planFilled.
  ///
  /// In en, this message translates to:
  /// **'{p}% filled'**
  String planFilled(int p);

  /// No description provided for @planSyncTasks.
  ///
  /// In en, this message translates to:
  /// **'Add new tasks'**
  String get planSyncTasks;

  /// No description provided for @planPostpone.
  ///
  /// In en, this message translates to:
  /// **'Postpone'**
  String get planPostpone;

  /// No description provided for @planPostponeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get planPostponeToday;

  /// No description provided for @planPostponeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get planPostponeTomorrow;

  /// No description provided for @planPostponeIn2.
  ///
  /// In en, this message translates to:
  /// **'In 2 days'**
  String get planPostponeIn2;

  /// No description provided for @planPostponeWeek.
  ///
  /// In en, this message translates to:
  /// **'In a week'**
  String get planPostponeWeek;

  /// No description provided for @planPostponed.
  ///
  /// In en, this message translates to:
  /// **'Plan postponed'**
  String get planPostponed;

  /// No description provided for @trackStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get trackStart;

  /// No description provided for @trackPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get trackPause;

  /// No description provided for @trackResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get trackResume;

  /// No description provided for @trackEnded.
  ///
  /// In en, this message translates to:
  /// **'Plan ended'**
  String get trackEnded;

  /// No description provided for @trackEffective.
  ///
  /// In en, this message translates to:
  /// **'Effective'**
  String get trackEffective;

  /// No description provided for @trackBreaks.
  ///
  /// In en, this message translates to:
  /// **'Breaks'**
  String get trackBreaks;

  /// No description provided for @trackSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get trackSessions;

  /// No description provided for @trackEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get trackEfficiency;

  /// No description provided for @trackOnBreak.
  ///
  /// In en, this message translates to:
  /// **'Break: {time}'**
  String trackOnBreak(String time);

  /// No description provided for @trackFailed.
  ///
  /// In en, this message translates to:
  /// **'The timer could not be updated'**
  String get trackFailed;

  /// No description provided for @taskTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get taskTodo;

  /// No description provided for @taskDoing.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskDoing;

  /// No description provided for @taskDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskDone;

  /// No description provided for @taskCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskCancelled;

  /// No description provided for @planPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planPlanned;

  /// No description provided for @planFreeTime.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFreeTime;

  /// No description provided for @planTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get planTasks;

  /// No description provided for @planHours.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String planHours(int h, int m);

  /// No description provided for @planMinutes.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String planMinutes(int m);

  /// No description provided for @projectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// No description provided for @projectsNew.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectsNew;

  /// No description provided for @projectsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectsEdit;

  /// No description provided for @projectsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get projectsCreate;

  /// No description provided for @projectsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No projects yet. Create your first one.'**
  String get projectsEmpty;

  /// No description provided for @projectsNoDescription.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get projectsNoDescription;

  /// No description provided for @projectsOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get projectsOpen;

  /// No description provided for @projectsDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get projectsDone;

  /// No description provided for @projectsTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get projectsTotal;

  /// No description provided for @projectsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{p}% completed'**
  String projectsCompleted(int p);

  /// No description provided for @projectsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectsName;

  /// No description provided for @projectsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectsDescription;

  /// No description provided for @projectsColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get projectsColor;

  /// No description provided for @projectsCreated.
  ///
  /// In en, this message translates to:
  /// **'Project created'**
  String get projectsCreated;

  /// No description provided for @projectsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Project updated'**
  String get projectsUpdated;

  /// No description provided for @projectsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted'**
  String get projectsDeleted;

  /// No description provided for @projectsConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete the \"{name}\" project with all its tasks and plans?'**
  String projectsConfirmDelete(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @tasksAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tasksAdd;

  /// No description provided for @tasksAddPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a new task…'**
  String get tasksAddPlaceholder;

  /// No description provided for @tasksAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add task'**
  String get tasksAddFailed;

  /// No description provided for @tasksStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change status'**
  String get tasksStatusFailed;

  /// No description provided for @tasksConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String tasksConfirmDelete(String title);

  /// No description provided for @tasksConfirmDeleteSubs.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" and its {n} subtasks?'**
  String tasksConfirmDeleteSubs(String title, int n);

  /// No description provided for @tasksEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No tasks for this filter.'**
  String get tasksEmptyFilter;

  /// No description provided for @tasksFilterOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get tasksFilterOpen;

  /// No description provided for @tasksFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tasksFilterDone;

  /// No description provided for @tasksFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tasksFilterCancelled;

  /// No description provided for @tasksFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tasksFilterAll;

  /// No description provided for @tasksAddSubtask.
  ///
  /// In en, this message translates to:
  /// **'Add subtask'**
  String get tasksAddSubtask;

  /// No description provided for @tasksSubtaskPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Subtask…'**
  String get tasksSubtaskPlaceholder;

  /// No description provided for @tasksParentDone.
  ///
  /// In en, this message translates to:
  /// **'All subtasks are done — \"{title}\" marked as done'**
  String tasksParentDone(String title);

  /// No description provided for @tasksParentReopened.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is back in progress'**
  String tasksParentReopened(String title);

  /// No description provided for @tasksMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get tasksMove;

  /// No description provided for @tasksMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move: {title}'**
  String tasksMoveTitle(String title);

  /// No description provided for @tasksMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Put under task'**
  String get tasksMoveTo;

  /// No description provided for @tasksIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent task'**
  String get tasksIndependent;

  /// No description provided for @tasksCannotNest.
  ///
  /// In en, this message translates to:
  /// **'This task has its own subtasks, so it can only stay independent.'**
  String get tasksCannotNest;

  /// No description provided for @tasksMovedUnder.
  ///
  /// In en, this message translates to:
  /// **'Moved under \"{title}\"'**
  String tasksMovedUnder(String title);

  /// No description provided for @tasksMadeIndependent.
  ///
  /// In en, this message translates to:
  /// **'Task is now independent'**
  String get tasksMadeIndependent;

  /// No description provided for @tasksRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get tasksRename;

  /// No description provided for @tasksMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get tasksMoveUp;

  /// No description provided for @tasksMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get tasksMoveDown;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesTitle;

  /// No description provided for @notesToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notesToday;

  /// No description provided for @notesWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get notesWeek;

  /// No description provided for @notesMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get notesMonth;

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes in this range.'**
  String get notesEmpty;

  /// No description provided for @notesEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No notes match the selected filter.'**
  String get notesEmptyFilter;

  /// No description provided for @notesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get notesSearch;

  /// No description provided for @notesAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notesAll;

  /// No description provided for @notesAllProjects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get notesAllProjects;

  /// No description provided for @notesSummary.
  ///
  /// In en, this message translates to:
  /// **'{n} notes · {tasks} tasks'**
  String notesSummary(int n, int tasks);

  /// No description provided for @notesEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get notesEdited;

  /// No description provided for @notesConfirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get notesConfirmDelete;

  /// No description provided for @notesPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get notesPlan;

  /// No description provided for @notesAdd.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get notesAdd;

  /// No description provided for @notesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'What did you do?'**
  String get notesPlaceholder;

  /// No description provided for @notesSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get notesSaved;

  /// No description provided for @notesTaskEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes for this task yet.'**
  String get notesTaskEmpty;

  /// No description provided for @settingsWorkHours.
  ///
  /// In en, this message translates to:
  /// **'Working hours'**
  String get settingsWorkHours;

  /// No description provided for @settingsWorkHoursHint.
  ///
  /// In en, this message translates to:
  /// **'Daily plans can only be made within this range.'**
  String get settingsWorkHoursHint;

  /// No description provided for @settingsWorkDay.
  ///
  /// In en, this message translates to:
  /// **'Work day: {d}'**
  String settingsWorkDay(String d);

  /// No description provided for @settingsEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'The end must be after the start.'**
  String get settingsEndAfterStart;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotifyBefore.
  ///
  /// In en, this message translates to:
  /// **'How many minutes before a plan starts or ends'**
  String get settingsNotifyBefore;

  /// No description provided for @settingsTracking.
  ///
  /// In en, this message translates to:
  /// **'Time tracking'**
  String get settingsTracking;

  /// No description provided for @settingsEfficiencyHint.
  ///
  /// In en, this message translates to:
  /// **'Efficiency = time actually worked ÷ elapsed plan time.'**
  String get settingsEfficiencyHint;

  /// No description provided for @settingsAutoStop.
  ///
  /// In en, this message translates to:
  /// **'Stop the timer automatically when the plan ends'**
  String get settingsAutoStop;

  /// No description provided for @settingsAutoStopHint.
  ///
  /// In en, this message translates to:
  /// **'A finished plan cannot be started again.'**
  String get settingsAutoStopHint;

  /// No description provided for @settingsTarget.
  ///
  /// In en, this message translates to:
  /// **'Target efficiency'**
  String get settingsTarget;

  /// No description provided for @settingsBreakReminder.
  ///
  /// In en, this message translates to:
  /// **'Remind me when a break lasts longer than'**
  String get settingsBreakReminder;

  /// No description provided for @settingsIdlePause.
  ///
  /// In en, this message translates to:
  /// **'Auto-pause after this much inactivity on the computer'**
  String get settingsIdlePause;

  /// No description provided for @settingsIdleHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-pause runs in the browser, when the timer was started there.'**
  String get settingsIdleHint;

  /// No description provided for @settingsOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsOff;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsSourceTrial.
  ///
  /// In en, this message translates to:
  /// **'Pro trial: {n} days left (until {date})'**
  String settingsSourceTrial(int n, String date);

  /// No description provided for @settingsSourceSubscription.
  ///
  /// In en, this message translates to:
  /// **'Pro subscription ({product})'**
  String settingsSourceSubscription(String product);

  /// No description provided for @settingsRenews.
  ///
  /// In en, this message translates to:
  /// **'Next payment: {date}'**
  String settingsRenews(String date);

  /// No description provided for @settingsEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Subscription ends on {date}'**
  String settingsEndsOn(String date);

  /// No description provided for @settingsSourcePromo.
  ///
  /// In en, this message translates to:
  /// **'Gifted Pro'**
  String get settingsSourcePromo;

  /// No description provided for @settingsPromoUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String settingsPromoUntil(String date);

  /// No description provided for @settingsPromoForever.
  ///
  /// In en, this message translates to:
  /// **'no end date'**
  String get settingsPromoForever;

  /// No description provided for @settingsSourceAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin account — all Pro features are on'**
  String get settingsSourceAdmin;

  /// No description provided for @settingsFreeText.
  ///
  /// In en, this message translates to:
  /// **'Limits: {projects} projects, history of the last {days} days.'**
  String settingsFreeText(int projects, int days);

  /// No description provided for @settingsProductMonthly.
  ///
  /// In en, this message translates to:
  /// **'monthly'**
  String get settingsProductMonthly;

  /// No description provided for @settingsProductYearly.
  ///
  /// In en, this message translates to:
  /// **'yearly'**
  String get settingsProductYearly;

  /// No description provided for @settingsProductGift.
  ///
  /// In en, this message translates to:
  /// **'gift'**
  String get settingsProductGift;

  /// No description provided for @settingsManageWeb.
  ///
  /// In en, this message translates to:
  /// **'This subscription is managed on the website.'**
  String get settingsManageWeb;

  /// No description provided for @settingsManageStore.
  ///
  /// In en, this message translates to:
  /// **'This subscription is managed in the app store.'**
  String get settingsManageStore;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutMission.
  ///
  /// In en, this message translates to:
  /// **'OneLinePlanner helps you plan tasks while working on only one thing at a time: the day is a single line, and at any moment there is just one task on it.'**
  String get aboutMission;

  /// No description provided for @aboutAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get aboutAuthor;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsScheduleView.
  ///
  /// In en, this message translates to:
  /// **'Schedule view'**
  String get settingsScheduleView;

  /// No description provided for @settingsScheduleLocal.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device.'**
  String get settingsScheduleLocal;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get planPro;

  /// No description provided for @planTrial.
  ///
  /// In en, this message translates to:
  /// **'Pro trial · {days} days left'**
  String planTrial(int days);

  /// No description provided for @verifyBanner.
  ///
  /// In en, this message translates to:
  /// **'Confirm your email: we sent a link to {email}. It opens the website.'**
  String verifyBanner(String email);

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Send again'**
  String get resend;

  /// No description provided for @resent.
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get resent;

  /// No description provided for @tasksDrag.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get tasksDrag;

  /// No description provided for @planCopyToWeek.
  ///
  /// In en, this message translates to:
  /// **'Copy to other days'**
  String get planCopyToWeek;

  /// No description provided for @generateTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy this day'**
  String get generateTitle;

  /// No description provided for @generateIntro.
  ///
  /// In en, this message translates to:
  /// **'Source: {date} ({n} blocks). Each new block gets that project\'s open tasks.'**
  String generateIntro(String date, int n);

  /// No description provided for @generateThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get generateThisWeek;

  /// No description provided for @generateNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get generateNextWeek;

  /// No description provided for @generateRestWorkdays.
  ///
  /// In en, this message translates to:
  /// **'Remaining weekdays'**
  String get generateRestWorkdays;

  /// No description provided for @generateRestDays.
  ///
  /// In en, this message translates to:
  /// **'Remaining days this week'**
  String get generateRestDays;

  /// No description provided for @generateClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get generateClear;

  /// No description provided for @generateModeSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip blocks that overlap'**
  String get generateModeSkip;

  /// No description provided for @generateModeReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace existing plans on those days'**
  String get generateModeReplace;

  /// No description provided for @generateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Copy to {n} days'**
  String generateSubmit(int n);

  /// No description provided for @generateCreated.
  ///
  /// In en, this message translates to:
  /// **'{n} blocks created'**
  String generateCreated(int n);

  /// No description provided for @generateSkipped.
  ///
  /// In en, this message translates to:
  /// **'{n} skipped because they overlap'**
  String generateSkipped(int n);

  /// No description provided for @generateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not copy the day'**
  String get generateFailed;

  /// No description provided for @notifyChannel.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get notifyChannel;

  /// No description provided for @notifyStartTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} starts in {m} min'**
  String notifyStartTitle(String name, int m);

  /// No description provided for @notifyEndTitle.
  ///
  /// In en, this message translates to:
  /// **'{name}: {m} min left'**
  String notifyEndTitle(String name, int m);

  /// No description provided for @notifyBody.
  ///
  /// In en, this message translates to:
  /// **'Plan {range}'**
  String notifyBody(String range);

  /// No description provided for @notifyNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {name} ({time})'**
  String notifyNext(String name, String time);

  /// No description provided for @paywallProjectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Project limit reached'**
  String get paywallProjectsTitle;

  /// No description provided for @paywallProjectsText.
  ///
  /// In en, this message translates to:
  /// **'The Free plan allows up to {n} projects. Pro removes the limit. Your data stays.'**
  String paywallProjectsText(int n);

  /// No description provided for @paywallHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Older history is part of Pro'**
  String get paywallHistoryTitle;

  /// No description provided for @paywallHistoryText.
  ///
  /// In en, this message translates to:
  /// **'Free shows the last {n} days. Older plans are still saved.'**
  String paywallHistoryText(int n);

  /// No description provided for @paywallDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'OneLinePlanner Pro'**
  String get paywallDefaultTitle;

  /// No description provided for @paywallDefaultText.
  ///
  /// In en, this message translates to:
  /// **'Unlimited projects, full history, and the Pro features that come next.'**
  String get paywallDefaultText;

  /// No description provided for @paywallMore.
  ///
  /// In en, this message translates to:
  /// **'What Pro includes'**
  String get paywallMore;

  /// No description provided for @paywallClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get paywallClose;

  /// No description provided for @paywallUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get paywallUnlimited;

  /// No description provided for @paywallSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get paywallSoon;

  /// No description provided for @paywallDays.
  ///
  /// In en, this message translates to:
  /// **'{n} days'**
  String paywallDays(int n);

  /// No description provided for @paywallFeatureProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get paywallFeatureProjects;

  /// No description provided for @paywallFeatureHistory.
  ///
  /// In en, this message translates to:
  /// **'Plan history'**
  String get paywallFeatureHistory;

  /// No description provided for @paywallFeatureTimeline.
  ///
  /// In en, this message translates to:
  /// **'Day schedule'**
  String get paywallFeatureTimeline;

  /// No description provided for @paywallFeatureTracking.
  ///
  /// In en, this message translates to:
  /// **'Time tracking'**
  String get paywallFeatureTracking;

  /// No description provided for @paywallFeatureNotes.
  ///
  /// In en, this message translates to:
  /// **'Subtasks and notes'**
  String get paywallFeatureNotes;

  /// No description provided for @paywallFeatureCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar sync'**
  String get paywallFeatureCalendar;

  /// No description provided for @paywallFeatureExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get paywallFeatureExport;

  /// No description provided for @paywallFeatureTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates and repeating plans'**
  String get paywallFeatureTemplates;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericError;

  /// No description provided for @settingsUpgrade.
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get settingsUpgrade;

  /// No description provided for @settingsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestore;

  /// No description provided for @settingsOpenStore.
  ///
  /// In en, this message translates to:
  /// **'Manage in the app store'**
  String get settingsOpenStore;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountText.
  ///
  /// In en, this message translates to:
  /// **'Plans, projects and notes are deleted. An App Store or Google Play subscription is not cancelled here. Cancel it in the store first if you do not want to be charged.'**
  String get settingsDeleteAccountText;

  /// No description provided for @settingsDeletePassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get settingsDeletePassword;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteConfirm;

  /// No description provided for @paywallMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywallMonthly;

  /// No description provided for @paywallYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get paywallYearly;

  /// No description provided for @paywallBuy.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get paywallBuy;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// No description provided for @paywallRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases checked'**
  String get paywallRestored;

  /// No description provided for @paywallPurchased.
  ///
  /// In en, this message translates to:
  /// **'Payment received. Pro turns on after the store confirms it.'**
  String get paywallPurchased;

  /// No description provided for @paywallPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase did not go through. Try again.'**
  String get paywallPurchaseFailed;

  /// No description provided for @paywallPriceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The store did not return a price. Try again in a moment.'**
  String get paywallPriceUnavailable;

  /// No description provided for @paywallStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'In-app purchases are not connected on this build.'**
  String get paywallStoreUnavailable;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['az', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az': return AppLocalizationsAz();
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
