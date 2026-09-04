/// Bundled Privacy Policy and Support copy, rendered as Flutter widgets.
///
/// These documents describe what the binary actually does: local storage,
/// motion for steps, camera/photos for an optional avatar, local reminders,
/// and AppsFlyer for install / usage measurement.
class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.effective,
    required this.intro,
    required this.sections,
    this.webUrl,
    this.email,
  });

  final String title;
  final String effective;
  final String intro;
  final List<LegalSection> sections;
  final String? webUrl;
  final String? email;
}

class LegalSection {
  const LegalSection({
    required this.heading,
    this.paragraphs = const <String>[],
    this.bullets = const <String>[],
  });

  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;
}

class EmbeddedDocs {
  const EmbeddedDocs._();

  static const LegalDocument privacy = LegalDocument(
    title: 'Privacy Policy',
    effective: 'September 2026',
    intro:
        'Crazy Hen Run ("the app") is a habit tracker and running companion. '
        'This policy explains what stays on your phone and what is sent to AppsFlyer.',
    webUrl: 'https://crazyhennrun.com/privacy-policy.html',
    email: 'support@crazyhennrun.com',
    sections: <LegalSection>[
      LegalSection(
        heading: 'What the app stores',
        paragraphs: <String>[
          'All of the following is saved only in the app\'s local storage on this device:',
        ],
        bullets: <String>[
          'Habits, streaks, completions and archive status',
          'Journal entries and the weekly sprint target',
          'Run history, interval plans, step totals and challenges',
          'Your display name and an optional profile photo you choose',
          'Theme, reminder times and other settings',
        ],
      ),
      LegalSection(
        heading: 'What we do not collect',
        paragraphs: <String>[
          'Crazy Hen Run has no account and no product backend. We do not upload '
          'your habit titles, journal text, profile photo, or run notes. Those stay '
          'in the app\'s local storage on this device.',
        ],
      ),
      LegalSection(
        heading: 'AppsFlyer',
        paragraphs: <String>[
          'The app uses AppsFlyer to measure installs, opens and a few anonymous '
          'product events (onboarding finished, a habit closed, a run saved). '
          'AppsFlyer may receive device type, OS version, IP address, a vendor '
          'or install identifier, and diagnostic information. Advertising identifiers '
          '(IDFA) are disabled and the app does not show an App Tracking prompt. '
          'This is the same measurement described on crazyhennrun.com.',
        ],
      ),
      LegalSection(
        heading: 'Device permissions',
        paragraphs: <String>[
          'The app only asks for access when you use the matching feature:',
        ],
        bullets: <String>[
          'Motion & Fitness — optional step counting via the on-device sensor. No GPS and no location.',
          'Camera — optional, only if you snap a new profile picture.',
          'Photo Library — optional, only if you pick or save a profile picture.',
          'Notifications — optional local reminders for habits and a daily run nudge. There are no remote push messages.',
        ],
      ),
      LegalSection(
        heading: 'Sharing',
        paragraphs: <String>[
          'If you tap Share after a run, the system share sheet sends a picture '
          'you generated. That hand-off is initiated by you and is not a background upload.',
        ],
      ),
      LegalSection(
        heading: 'Third parties',
        paragraphs: <String>[
          'The only third-party SDK in the app is AppsFlyer, for install and usage '
          'measurement. There are no ads and no social SDKs. Opening Support or this '
          'policy in Safari uses the system browser.',
        ],
      ),
      LegalSection(
        heading: 'Data retention and deletion',
        paragraphs: <String>[
          'Because data lives only on the device, uninstalling Crazy Hen Run '
          'permanently deletes habits, runs, journal entries and your profile photo. '
          'You can also wipe storage from Settings → Data & storage.',
          'If you contact us about deletion, we can ask AppsFlyer to delete the '
          'measurement record tied to this install. We have no server-side copy of '
          'your habits or journal.',
        ],
      ),
      LegalSection(
        heading: 'Children',
        paragraphs: <String>[
          'The app is not directed at children under 13, and it does not collect personal information from anyone.',
        ],
      ),
      LegalSection(
        heading: 'Your rights',
        paragraphs: <String>[
          'Depending on where you live, you may have rights to access, correct or '
          'delete personal data. For this app those rights are exercised on the device: '
          'edit or delete habits, journal entries and your profile, or uninstall the app.',
        ],
      ),
      LegalSection(
        heading: 'Changes',
        paragraphs: <String>[
          'If this policy changes, the updated text ships inside the next app version. '
          'The copy you are reading is the one packed with this install.',
        ],
      ),
      LegalSection(
        heading: 'Contact',
        paragraphs: <String>[
          'Questions about this policy: support@crazyhennrun.com',
        ],
      ),
    ],
  );

  static const LegalDocument support = LegalDocument(
    title: 'Support',
    effective: 'Crazy Hen Run',
    intro:
        'Questions, bug reports and feature requests are welcome. Write from any mail app — '
        'there is no in-app form and no account to look up.',
    webUrl: 'https://crazyhennrun.com/support.html',
    email: 'support@crazyhennrun.com',
    sections: <LegalSection>[
      LegalSection(
        heading: 'How to reach us',
        paragraphs: <String>[
          'Email support@crazyhennrun.com. Include enough detail that we can reproduce the issue.',
        ],
        bullets: <String>[
          'What you were doing when the problem appeared',
          'Your device model and iOS or Android version',
          'App version from Settings → About',
          'A screenshot, if the issue is visual',
        ],
      ),
      LegalSection(
        heading: 'Your data',
        paragraphs: <String>[
          'Crazy Hen Run stores habits, streaks, journal entries, run history and your '
          'profile photo on this device only. Uninstalling the app removes all of it. '
          'We cannot reset a streak or restore a journal from our side.',
        ],
      ),
      LegalSection(
        heading: 'Permissions',
        paragraphs: <String>[
          'Step counting needs Motion & Fitness. Profile photos need Camera or Photos. '
          'Reminders need Notifications. Each of these is optional — the rest of the app works without them.',
        ],
      ),
    ],
  );
}
