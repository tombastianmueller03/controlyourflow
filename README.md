# Control your Flow

**Kurz vor Instagram, YouTube & Co. eine kleine Mathe-Pause.** Kostenlos, ohne Konto, ohne Internet. Alle Daten bleiben auf dem iPhone.

Du öffnest eine ausgewählte App. Eine Automation in der Kurzbefehle-App startet dann „Flow“, und Flow zeigt ein paar Kopfrechenaufgaben (Multiple Choice A–D). Erst wenn **alle Aufgaben richtig gelöst sind und die Mindestzeit vorbei ist**, öffnet Flow die App. Danach hast du eine Schonfrist (Standard 5 Minuten), in der die App ohne neue Pause aufgeht.

Das Prinzip kommt von [one sec](https://one-sec.app). Die Unterschiede: beliebig viele Apps, alles pro App einstellbar, komplett kostenlos, kein Server.

> Status: **MVP, noch nicht auf einem echten iPhone getestet.** Alles, was nur auf dem Gerät prüfbar ist, steht unten unter [Unbestätigte Annahmen](#unbestätigte-annahmen-unverified).

---

## Inhalt
1. [So funktioniert es](#so-funktioniert-es)
2. [App aufs iPhone bringen](#app-aufs-iphone-bringen)
3. [Automation einrichten (pro App)](#automation-einrichten-pro-app)
4. [Einstellungen](#einstellungen)
5. [Test-Checkliste für das iPhone](#test-checkliste-für-das-iphone)
6. [Bekannte Grenzen](#bekannte-grenzen)
7. [Unbestätigte Annahmen (unverified)](#unbestätigte-annahmen-unverified)
8. [Für Entwickler](#für-entwickler)

---

## So funktioniert es

```
Du öffnest Instagram
   └─▶ Automation „Wenn Instagram geöffnet wird“ → Aktion „Flow starten“ (Ziel-App: Instagram)
         ├─ Gültige Freigabe (Schonfrist läuft)?  → nichts passiert, Instagram bleibt offen
         └─ Keine Freigabe → Flow kommt nach vorne und zeigt die Mathe-Pause
               ├─ Bestanden → Freigabe für die Schonfrist speichern → Flow öffnet Instagram
               │     └─ Die Automation feuert erneut, sieht die Freigabe und lässt durch (keine Endlosschleife)
               └─ „Nicht jetzt“ → ruhiger Bildschirm, keine Freigabe
```

Die Freigabe wird beim Prüfen **nicht verbraucht**, sie läuft nur zeitlich ab. Wechselst du innerhalb der Schonfrist zwischen Apps, gibt es deshalb keine neue Pause.

---

## App aufs iPhone bringen

Du brauchst nur eine **kostenlose Apple-ID**, keinen bezahlten Entwickler-Account. Es gibt zwei Wege:

| | **Weg A: Xcode (empfohlen, sobald möglich)** | **Weg B: SideStore mit .ipa** |
|---|---|---|
| Voraussetzung | Mac mit macOS 26.6+ bzw. 27 und Xcode | Mac nur einmal zum Einrichten |
| Aufwand | einmal einrichten, dann 1 Klick | fummeligere Einrichtung |
| Nach 7 Tagen | in Xcode erneut ▶ drücken | SideStore erneuert selbst (im Hintergrund) |
| Plätze (max. 3 Apps) | Flow belegt 1 | SideStore + Flow belegen 2 |

Bei beiden Wegen gilt für kostenlose Konten: **Die Signatur läuft nach 7 Tagen ab**, **höchstens 3 selbst installierte Apps gleichzeitig** und **höchstens 10 neue App-IDs pro Woche**.

### Entwicklermodus am iPhone einschalten (für beide Wege nötig)
1. Der Schalter erscheint erst, nachdem das iPhone einmal mit Xcode verbunden war oder du versucht hast, eine App selbst zu installieren. Tipp: Zuerst Weg A oder B bis zur Installation durchgehen.
2. **Einstellungen → Datenschutz & Sicherheit → Entwicklermodus** (ganz unten) → einschalten.
3. Das iPhone startet neu. Danach „Einschalten“ bestätigen und den Code eingeben.

### Weg A: mit Xcode

**Schritt 1: Platz schaffen und macOS aktualisieren** (einmalig, dauert etwa 1–2 Stunden)
1. Mache zuerst ein **Backup** (Time Machine).
2. Prüfe den freien Speicher unter **Apple-Menü  → Systemeinstellungen → Allgemein → Speicher**. Du brauchst **mindestens ~70 GB frei** (macOS-Update plus Xcode plus iOS-Komponenten). Große Dateien findest du dort unter „Empfehlungen“ oder „Dokumente“.
3. **Systemeinstellungen → Allgemein → Softwareupdate** → **macOS 27** installieren.

**Schritt 2: Xcode installieren**
1. **App Store** öffnen, nach **Xcode** suchen und laden (sehr groß).
2. Xcode einmal starten. Wenn es nach Komponenten fragt, **iOS** mit auswählen.
3. **Xcode → Settings… → Accounts → „+“ → Apple Account** und mit deiner Apple-ID anmelden. Dadurch entsteht automatisch ein kostenloses „Personal Team“.

**Schritt 3: Projekt öffnen**
Im Programm **Terminal**:
```bash
cd ~/Desktop/ControllYourFlow
```
```bash
xcodegen generate && open ControlYourFlow.xcodeproj
```

**Schritt 4: Signieren**
1. Klicke in Xcode links auf das blaue Projekt **ControlYourFlow**, dann auf das Ziel **Flow** und den Tab **Signing & Capabilities**.
2. Wähle bei **Team** deinen Namen („Personal Team“).
3. *Optional, damit du das nicht nach jedem Projekt-Update wiederholen musst:* Unter **Build Settings** nach „Development Team“ suchen und die 10-stellige ID kopieren. Dann die Datei `Config/Local.xcconfig` anlegen mit dem Inhalt `DEVELOPMENT_TEAM = DEINEID`. Diese Datei wird nicht hochgeladen.
4. Meldet Xcode, die Bundle-ID sei vergeben: In `project.yml` `com.tbmueller.controlyourflow` durch etwas Eigenes ersetzen und `xcodegen generate` erneut ausführen.

**Schritt 5: Aufs iPhone**
1. iPhone per Kabel anschließen, entsperren und „Diesem Computer vertrauen“ bestätigen.
2. In Xcode oben in der Mitte dein iPhone als Ziel wählen und **▶ (Run)** drücken.
3. Beim ersten Mal auf dem iPhone: **Einstellungen → Allgemein → VPN & Geräteverwaltung →** deine Apple-ID **→ Vertrauen**. Den Entwicklermodus einschalten, falls noch nicht geschehen (siehe oben).
4. **Alle 7 Tage:** Startet Flow nicht mehr, iPhone anschließen und in Xcode erneut ▶ drücken. Einstellungen und Automationen bleiben dabei erhalten (unverified).

### Weg B: SideStore mit der fertigen .ipa
1. Jede Version erscheint unter **[Releases](../../releases)** als `Flow.ipa`. Das ist eine unsignierte Datei, SideStore signiert sie mit deiner Apple-ID.
2. SideStore nach der offiziellen Anleitung einrichten: <https://docs.sidestore.io/docs/installation/prerequisites>. Kurz gesagt: Am Mac einmal **iloader** ausführen (erstellt die „Pairing-Datei“), am iPhone **LocalDevVPN** installieren, dann SideStore installieren.
3. `Flow.ipa` in Safari am iPhone laden, in SideStore auf **„+“** tippen und die Datei wählen.
4. SideStore erneuert die Signatur alle 7 Tage selbst, solange es ab und zu laufen darf.

> **Hinweis:** Beim Neusignieren hängt SideStore eventuell deine Team-ID an die Bundle-ID an. Wechselst du später von Weg B zu Weg A (oder umgekehrt), ist das für iOS eine *andere* App. Dann musst du die Automationen neu einrichten (unverified).

Das Repository ist **öffentlich**, weil GitHub nur für öffentliche Repos unbegrenzt kostenlose macOS-Build-Minuten bietet.

---

## Automation einrichten (pro App)

In Flow findest du dieselbe Anleitung unter **Automation einrichten**, mit Test-Knopf.

1. In **Flow** die App hinzufügen (z. B. Instagram).
2. Die **Kurzbefehle**-App öffnen und unten auf **Automation** tippen.
3. **„+“** bzw. **Neue Automation** → **App**.
4. Bei **App** auf **Auswählen** tippen, **Instagram** wählen, nur **„Wird geöffnet“** markieren.
5. **„Sofort ausführen“** wählen und **„Bei Ausführung mitteilen“ ausschalten** → **Weiter**.
6. **Neuer leerer Kurzbefehl** → **Aktion hinzufügen** → nach **„Flow starten“** suchen.
7. In der Aktion auf **Ziel-App** tippen und **Instagram** wählen. **Wichtig:** Ohne diese Auswahl läuft die Automation nicht.
8. **Fertig**.
9. In Flow unter **Automation einrichten → Automation testen** prüfen: Flow öffnet Instagram, und kurz danach sollte die Pause erscheinen.

Die Bezeichnungen können je nach iOS-Version leicht abweichen. Automationen werden **nicht** zwischen Geräten übertragen (Apple synchronisiert sie deaktiviert).

---

## Einstellungen

Pro App (und als Standardwerte für neue Apps):

| Einstellung | Standard | Bereich | Bedeutung |
|---|---|---|---|
| Aufgaben | 10 | 1–50 | so viele richtige Antworten sind nötig |
| Mindestdauer | 60 s | 0–10 Min | so lange dauert die Pause mindestens |
| Schwierigkeit | 1 | 1–4 | siehe unten |
| Strafzeit bei Fehler | 5 s | 0–60 s | Sperre nach falscher Antwort, danach kommt eine neue Aufgabe |
| Schonfrist | 5 Min | 1–240 Min | so lange geht die App nach bestandener Pause ohne neue Pause auf |

**Schwierigkeitsstufen**
1. Zweistellig plus/minus (47 + 38)
2. Zweistellig × einstellig (64 × 7), dreistellig plus/minus
3. Zweistellig × zweistellig (43 × 27), Prozentrechnen (25 % von 360)
4. Dreistellig × zweistellig (512 × 34), Quadratzahlen 11²–30², Division mit ganzzahligem Ergebnis

Die falschen Antworten sind typische Rechenfehler: ±10, ±1, vertauschte Ziffern, vergessener Übertrag, eine Reihe zu viel oder zu wenig.

**Vorlagen (URL-Schemes zum Öffnen, alle *unverified*):** Instagram `instagram://`, YouTube `youtube://`, TikTok `snssdk1233://`, X `twitter://`, Facebook `fb://`, Reddit `reddit://` (am unsichersten), Snapchat `snapchat://`, WhatsApp `whatsapp://`. Funktioniert eine Adresse nicht, zeigt Flow einen Hinweis. Die Adresse lässt sich pro App ändern.

**App-Icon:** Das Icon ist noch ein leerer Platzhalter. Ein 1024 × 1024 px großes PNG **ohne Transparenz** kommt als `AppIcon.png` in `Flow/Resources/Assets.xcassets/AppIcon.appiconset/`. In der dortigen `Contents.json` muss beim einzigen Bild zusätzlich `"filename" : "AppIcon.png"` stehen.

---

## Test-Checkliste für das iPhone

Kurzbefehle-Automationen laufen **nicht im Simulator**, deshalb bitte einmal am echten Gerät prüfen:

- [ ] Flow installiert, Instagram in Flow angelegt (10 Aufgaben, 60 s, 5 Min Schonfrist)
- [ ] Automation für Instagram angelegt, in Kurzbefehle ist „Flow starten“ auffindbar
- [ ] **Erstöffnung:** Instagram öffnen → Flow erscheint mit der Pause
- [ ] **Bestehen:** 10 richtige Antworten und mindestens 60 s → Instagram öffnet sich **ohne erneute Pause**
- [ ] **Schonfrist:** Instagram schließen, innerhalb von 5 Min wieder öffnen → keine Pause
- [ ] **Nach Ablauf:** nach über 5 Min öffnen → wieder eine Pause
- [ ] **Abbruch:** „Nicht jetzt“ → ruhiger Screen, erneutes Öffnen von Instagram → wieder eine Pause
- [ ] **Falsche Antwort:** rote Markierung, Vibration, 5 s Sperre, danach neue Aufgabe
- [ ] **Doppelauslösung:** während der Pause Instagram erneut antippen → dieselbe Pause läuft weiter (kein Neustart)
- [ ] **Drei Apps** mit unterschiedlichen Einstellungen (z. B. Instagram Stufe 1, YouTube Stufe 3, TikTok 20 Aufgaben)
- [ ] **Fallback:** eine Vorlage mit absichtlich falscher Adresse → verständlicher Hinweis statt Absturz
- [ ] **Statistik** zeigt gestartete, bestandene und abgebrochene Pausen
- [ ] **Bedienungshilfen:** Dunkelmodus, große Schrift, VoiceOver liest „Antwort A: 42“, „Bewegung reduzieren“ stoppt das Atmen
- [ ] **Nach 7 Tagen / Neusignieren:** Laufen die Automationen weiter?

Bitte trag die Ergebnisse in die Tabelle unten ein (oder sag sie mir).

---

## Bekannte Grenzen
- **Kein echtes Sperren.** Wer die Automation löscht oder abschaltet, umgeht Flow. Das ist Absicht: Flow ist ein Stolperstein, kein Schloss. Echtes Sperren braucht die Screen-Time-API, und die gibt es nur mit bezahltem Entwickler-Account.
- **Kostenloses Apple-Konto:** 7 Tage Laufzeit, max. 3 Apps, 10 App-IDs pro Woche.
- **Automationen muss man von Hand anlegen.** Unter iOS 26 gibt es keine Schnittstelle, mit der eine App eine Automation selbst anlegen kann. Mit iOS 27 lassen sich Automationen als Kurzbefehl teilen und importieren (so macht es one sec). Eine dokumentierte API dafür haben wir nicht gefunden. Das ist eine Idee für später.
- **Kurzes Aufblitzen:** Die Ziel-App ist schon kurz sichtbar, bevor Flow nach vorne kommt. Das liegt an der Automation.
- **Websites** (z. B. instagram.com in Safari) werden nicht abgefangen.

---

## Unbestätigte Annahmen (unverified)

Diese Punkte sind aus Apple-Dokumentation und Recherche abgeleitet, aber **noch nicht auf einem echten iPhone bestätigt**. Im Code sind sie mit `UNVERIFIED` markiert.

| # | Annahme | Status |
|---|---|---|
| 1 | Der App Intent läuft im Prozess der App, deshalb reicht `UserDefaults.standard` und es braucht **keine App Group** | offen |
| 2 | `App.init` läuft auch, wenn iOS die App nur für den Intent im Hintergrund startet (Registrierung per `AppDependencyManager`) | offen |
| 3 | `continueInForeground(alwaysConfirm: false)` darf Flow nach vorne holen, während die Ziel-App per Automation öffnet (ohne Rückfrage) | offen |
| 4 | Wird die Ziel-App aus Flow per URL-Scheme geöffnet, feuert die Automation erneut und wird durch die Freigabe durchgelassen | offen |
| 5 | Die URL-Schemes der Vorlagen öffnen die jeweilige App | offen |
| 6 | Die Automations-Schritte heißen unter iOS 26 so wie beschrieben | offen |
| 7 | Automationen überleben das Neusignieren nach 7 Tagen | offen |

---

## Für Entwickler

**Aufbau:** ein App-Target (`Flow`) ohne Extensions, dazu Unit-Tests (`FlowTests`, Swift Testing). SwiftUI, Swift 6, iOS 26.0. Das Projekt entsteht mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) aus `project.yml`. Die `.xcodeproj` wird nicht eingecheckt.

```
Flow/App        FlowApp (Einstieg, Registrierung des Routers), FlowRouter (Ablauf-Logik), RootView
Flow/Intent     StartFlowIntent („Flow starten“), RuleEntity + Query (Parameter „Ziel-App“)
Flow/Model      AppRule, ChallengeSettings (Phase-2-Hook: effectiveSettings(at:)), AppTemplates
Flow/Storage    RuleStore, LaunchPassStore, StatsStore (JSON in UserDefaults)
Flow/Math       MathProblemGenerator, MathProblem, SplitMix64 (seedbarer Zufall)
Flow/Challenge  ChallengeSession (reine Logik), ChallengeView, BreathingRing, NoticeView
Flow/Settings   HomeView, RuleEditView, AddRuleView, DefaultsView, StatsView
Flow/Setup      SetupGuideView
```

**CI** (`.github/workflows/ci.yml`, Runner `macos-26` mit Xcode 26.6):
- `xcodegen generate` → Unit-Tests im iPhone-17-Simulator → unsigniertes Archiv
- Prüft, dass `Metadata.appintents` in der App steckt (sonst fehlt die Aktion in Kurzbefehle)
- `Flow.ipa` als Artefakt; ein Git-Tag `v*` erzeugt ein GitHub-Release

**Lokal:**
```bash
brew install xcodegen && xcodegen generate
```
```bash
xcodebuild test -project ControlYourFlow.xcodeproj -scheme Flow -destination "platform=iOS Simulator,name=iPhone 17"
```

**Sprachen:** Die Entwicklungssprache ist Deutsch (`developmentLanguage: de`). Deutsche Texte sind die Schlüssel im String Catalog `Flow/Resources/Localizable.xcstrings`. Für weitere Sprachen dort Übersetzungen ergänzen.

**Phase 2 (vorbereitet, nicht gebaut):** Abstufung nach Wochentag und Uhrzeit. `AppRule.effectiveSettings(at:)` ist der Einstiegspunkt. Neue Felder werden tolerant dekodiert (`decodeIfPresent`), deshalb ist keine Migration nötig.

### Technische Notizen und Quellen
- `AppIntent.supportedModes`, `IntentModes.ForegroundMode.dynamic` (iOS 26): <https://developer.apple.com/documentation/appintents/appintent/supportedmodes>, <https://developer.apple.com/documentation/appintents/intentmodes/foregroundmode>
- `continueInForeground(_:alwaysConfirm:)`: <https://developer.apple.com/documentation/appintents/appintent/continueinforeground(_:alwaysconfirm:)>
- `systemContext.currentMode` / `canContinueInForeground`: <https://developer.apple.com/documentation/appintents/intentmodes/current>
- `openAppWhenRun` ist in iOS 26 veraltet: <https://developer.apple.com/documentation/appintents/appintent/openappwhenrun>
- WWDC25 „Explore new advances in App Intents“ (Muster mit `.foreground(.dynamic)`): <https://developer.apple.com/videos/play/wwdc2025/275/>
- Zeitbudget im Hintergrund (~30 s): <https://developer.apple.com/documentation/appintents/longrunningintent>
- Automations-Trigger „App wird geöffnet“ („when you open or switch to the selected app“): <https://support.apple.com/guide/shortcuts/setting-triggers-apde31e9638b/ios>
- `canOpenURL` / `LSApplicationQueriesSchemes` (max. 50, ab iOS-27-SDK 25 Einträge; `open` braucht keinen Eintrag): <https://developer.apple.com/documentation/uikit/uiapplication/canopenurl(_:)>
- Xcode-Systemvoraussetzungen: <https://developer.apple.com/support/xcode/>
- SideStore FAQ (Limits kostenloser Konten): <https://docs.sidestore.io/docs/faq>
