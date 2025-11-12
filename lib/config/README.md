# Configuration Setup

## Google Sheets Configuration

Барои истифодаи барнома, шумо бояд Google Sheets credentials гузоред.

### Қадамҳо:

1. **Copy template файл:**
   ```bash
   copy gsheets_config.dart.example gsheets_config.dart
   ```

2. **Google Cloud Console-ро кушоед:**
   - Ба [Google Cloud Console](https://console.cloud.google.com/) равед
   - Project нав созед ё мавҷударо интихоб кунед

3. **Google Sheets API-ро фаъол кунед:**
   - APIs & Services → Library
   - "Google Sheets API"-ро ҷустуҷӯ кунед ва Enable кунед

4. **Service Account созед:**
   - APIs & Services → Credentials
   - Create Credentials → Service Account
   - Маълумотро пур кунед ва Create кунед
   - Keys → Add Key → Create New Key → JSON
   - Файли JSON-ро зеркашӣ кунед

5. **Credentials-ро copy кунед:**
   - Мазмуни файли JSON-ро кушоед
   - Онро ба `gsheets_config.dart` дар variable `credentials` гузоред

6. **Spreadsheet ID-ро гузоред:**
   - Google Sheets-и худро кушоед
   - URL аз ин шакл: `https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit`
   - `SPREADSHEET_ID`-ро copy кунед ва дар `spreadsheetId` гузоред

7. **Иҷозат додан ба Service Account:**
   - Google Sheets-ро кушоед
   - Share → Client email аз JSON файл (мисол: `xxx@xxx.iam.gserviceaccount.com`)
   - Editor иҷозат додан

## ⚠️ МУҲИМ!

- **ҲЕҶ ВАҚТ** `gsheets_config.dart`-ро ба Git commit накунед!
- Ин файл аллакай дар `.gitignore` илова шудааст
- Танҳо `gsheets_config.dart.example` дар Git нигоҳ дошта мешавад

## Troubleshooting

Агар хатогӣ "Permission denied" ё "404" дидед:
- Service Account email-ро ба Google Sheets share кардаед?
- Google Sheets API дар Google Cloud Console фаъол аст?
- Spreadsheet ID дуруст copy шудааст?

