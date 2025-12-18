# 🎓 AI Kurikulum Generator v1.1

Azərbaycan təhsil sistemi üçün süni intellekt əsaslı professional kurikulum generatoru

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![Shiny](https://img.shields.io/badge/Shiny-1.7+-green.svg)](https://shiny.rstudio.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Yeniliklər v1.1

### 🆕 Funksiyalar
- 👁️ **View Modal**: Kurikulum məzmununu modal pəncərədə görə bilərsiniz
- 🗑️ **Delete with Confirmation**: Təsdiq ilə kurikulum silinməsi
- 🤖 **Dual AI Separate**: Claude və GPT nəticələri ayrı-ayrı
- 📊 **Statistics Fix**: Chart rendering problemləri həll olundu

### 🐛 Düzəlişlər
- Statistics atomic vector xətası
- Database type conversion
- Template HTML kod görsənməsi
- Chart data structure

## 🚀 Xüsusiyyətlər

### 🤖 Dual AI Engine
- **Claude Sonnet 4.5**: Azərbaycan fokuslu, strukturlaşdırılmış
- **GPT-4o**: Beynəlxalq best practice, innovativ
- Hər iki AI-nin ayrı-ayrı HTML export-u

### 📚 Əhatə
- **17 Fənn**: Riyaziyyat, Fizika, Kimya, Biologiya, İnformatika, dillər və s.
- **11 Sinif**: 1-ci sinifdən 11-ci sinifə qədər
- **10 Referans Ölkə**: Finlandiya, Sinqapur, Estoniya, Kanada və s.

### 📄 Export
- Professional HTML formatı
- Açıq göy rəng sxemi
- Responsive dizayn
- Print-ready
- Ayrı-ayrı Claude və GPT export

### 💾 Database
- SQLite database
- CRUD əməliyyatları
- View modal
- Delete confirmation
- Statistika dashboard

## 🛠️ Quraşdırma

### Tələblər
- R 4.0+
- RStudio (tövsiyə)
- Claude API key
- OpenAI API key (optional)

### Addımlar
```bash
# 1. Clone
git clone https://github.com/Ttariyel-1954/Kurikulum_yarat.git
cd Kurikulum_yarat

# 2. R paketlərini quraşdır
# RStudio-da:
source("requirements.R")

# 3. API keys
# .env faylı yaradın:
ANTHROPIC_API_KEY=your_claude_key
OPENAI_API_KEY=your_openai_key

# 4. İşə sal
shiny::runApp()
```

## 📖 İstifadə

### Yeni Kurikulum
1. Fənn və sinif seç
2. Parametrlər daxil et
3. "Dual AI Kurikulum Yarat"
4. Claude və GPT nəticələrini gör
5. Ayrı-ayrı HTML export

### Kurikulum Kitabxanası
- **Bax**: Kurikulum məzmununu görün
- **Sil**: Təsdiq ilə silin

### Statistika
- Ümumi kurikulum sayı
- Draft sayı
- Fənnlərə görə chart
- Siniflərə görə chart

## 📊 Struktur
```
Kurikulum_yarat/
├── app.R                      # Əsas app (v1.1)
├── global.R                   # Konfiqurasiya
├── modules/
│   └── curriculum_generator.R # Dual AI module
├── R/
│   ├── ai_agents.R           # Claude & GPT API
│   ├── database.R            # SQLite (fixed)
│   └── export.R              # HTML export
├── data/                      # CSV data
├── templates/
│   └── curriculum_template.Rmd # Clean template
├── database/                  # SQLite (ignored)
└── exports/                   # HTML (ignored)
```

## 🔒 Təhlükəsizlik

- API keys `.env` faylında
- `.gitignore` ilə qorunur
- Database və exports ignore olunur

## 💰 Qiymət

~$0.15-0.25 per curriculum (AI token costs)

## 📝 Changelog

### v1.1 (2024-12-18)
- View modal əlavə edildi
- Delete confirmation əlavə edildi
- Statistics bug fix
- Template təmizləndi
- Dual AI separate outputs

### v1.0 (2024-12-17)
- İlk buraxılış
- Dual AI engine
- HTML export
- SQLite database

## 🤝 Töhfə

Pull requests xoş gəlmisiniz!

## 📄 Lisenziya

MIT License © 2024 ARTI

## 👨‍💻 Müəllif

**ARTI** - Azerbaijan Republic Education Institute
- GitHub: [@Ttariyel-1954](https://github.com/Ttariyel-1954)
- Website: [ttariyel.tech](https://ttariyel.tech)

---

⭐ **Star verin əgər bəyəndinizsə!**
