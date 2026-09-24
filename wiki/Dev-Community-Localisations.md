# Community Localisations

Trouble In Armaville welcomes translation corrections from native speakers. The existing non-English text is a first pass, so natural phrasing, consistent game terminology, and text that fits the interface are all valuable contributions.

All player-facing words live in [`stringtable.xml`](https://github.com/AdamWaldie/TTTARMA3/blob/main/stringtable.xml). Submit changes through a pull request so maintainers can check and test them with the mission.

## Current languages

The mission currently contains:

- English
- German
- French
- Spanish
- Italian
- Polish
- Portuguese
- Russian
- Czech
- Japanese
- Korean
- Simplified Chinese (`Chinesesimp`)
- Turkish

Use these exact XML element names. Arma selects them from the player's game language.

## What to translate

Translate words that a player can see: role names and briefings, HUD labels, notifications, shop text, scoreboard text, diary entries, actions, hints, and round results.

Do not translate internal role IDs, SQF variable names, classnames, stringtable key IDs, or control IDs. The role crest initials `I`, `T`, `D`, and `J` are logos and deliberately remain the same in every language. Translate the full role name shown beside a crest, but not the crest itself.

## Correct an existing translation

Find the relevant `STR_TIA_...` key in `stringtable.xml` and change only your language element. For example:

```xml
<Key ID="STR_TIA_Role_Detective">
	<Original>Detective</Original>
	<English>Detective</English>
	<German>Detektiv</German>
</Key>
```

Keep `<Original>` and `<English>` as the source text unless the pull request corrects the English wording. Key IDs stay in English because scripts use them as stable identifiers.

Translate the meaning and tone. Do not copy English word order. A complete sentence should remain one stringtable entry because translated fragments produce incorrect grammar in many languages.

## Placeholders and XML characters

The mission replaces placeholders such as `%1`, `%2`, and `%3` with names, numbers, roles, or other runtime values. Every translation must contain exactly the same placeholders as the English source. Their order may change if the language requires it.

```xml
<English>%1 found %2 bodies.</English>
<German>%1 hat %2 Leichen gefunden.</German>
```

Do not add, remove, or renumber a placeholder. Check punctuation around it in the rendered UI.

XML reserves some characters. Write `&amp;` for `&`, `&lt;` for `<`, and `&gt;` for `>`. Do not add spaces at the beginning or end of a translation.

## Add a language

Before translating all keys, open an issue or draft pull request to confirm the Arma stringtable language tag. Then:

1. Add that language element to every player-facing key in `stringtable.xml`.
2. Add the exact tag to `languages` in `tools/qa/localisation_gameplay_audit/audit_manifest.json`.
3. Run the static stringtable check and the localisation audit described below.
4. Include screenshots proving that the font renders and the longest text fits.

An incomplete language silently falls back to English in places. Submit every player-facing key when adding a language.

## Terminology and interface fit

Use the same translation for recurring terms such as Traitor, Detective, Jester, Innocent, credits, overtime, body identification, and Karma. Check nearby strings before inventing a new term.

Keep labels concise enough for the interface, but do not shorten them until their meaning becomes unclear. Pay particular attention to:

- role briefing cards and the top timer.
- shop titles, item buttons, descriptions, and the Purchased panel.
- scoreboard headings and player briefing text.
- notification cards.
- the How To Play diary entries.

If a good translation does not fit, include the necessary UI sizing fix in the same pull request and explain it. Do not replace a translation with English merely to make it fit.

## Validate the change

Run the static validator from the repository root:

```powershell
python tools/ci/stringtable_checker.py
```

It checks the XML, duplicate keys, required English source text, leading or trailing whitespace, referenced keys, and placeholder parity. The same check runs in pull-request CI.

The audit launcher can assemble and validate its disposable mission without opening Arma:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File `
  .\tools\qa\localisation_gameplay_audit\launch_audit.ps1 `
  -Languages German
```

Replace `German` with the exact language tag. A maintainer with Arma installed can run the focused in-game audit with `-Run`. The audit captures 24 player-facing UI states and resolves every localisation key in the selected language. It also tests the round state machine and checks the RPT for script errors.

Automated checks cannot judge whether a sentence sounds natural. Read every changed line yourself and inspect the screenshots at normal playing size.

## Pull request checklist

- Name the language and state your level of fluency.
- Describe the terminology choices that may not be obvious to reviewers.
- Keep unrelated code and formatting changes out of the pull request.
- Preserve all `%1`, `%2`, and other placeholders.
- Confirm `tools/ci/stringtable_checker.py` passes.
- List any in-game screens tested and attach screenshots when possible.
- Confirm the translation leaves the `I`, `T`, `D`, and `J` crest logos unchanged.

Small correction pull requests are welcome. You do not need to retranslate the whole language to fix a typo, awkward sentence, or inconsistent term.
