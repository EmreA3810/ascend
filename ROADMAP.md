# ASCEND - Flutter RPG Productivity App TODO Roadmap

Bu doküman Ascend projesinin fikir aşamasından Play Store yayın sürecine kadar tüm geliştirme planını, yapılacakları ve öncelikleri içerir.

## 1. Proje Temeli
- [ ] Uygulama ismini belirle
- [ ] Logo ve renk paleti oluştur
- [ ] Rakip analizi yap (Habitica, Forest, Finch, LifeUp)
- [ ] Ana hedef kitleyi belirle
- [ ] Temel oyun mantığını netleştir

## 2. Teknik Altyapı
- [x] Flutter projesini oluştur
- [x] Firebase entegrasyonu yap
- [x] Riverpod state management kur
- [x] Firestore database yapısını oluştur
- [x] Authentication sistemi ekle (Email + Google)
- [x] Tema sistemi oluştur

## 3. UI / UX Tasarımı
- [x] Onboarding ekranı tasarla
- [x] Ana dashboard ekranı oluştur
- [x] Character profile ekranı oluştur
- [x] Quest ekranı tasarla
- [x] Pomodoro ekranı oluştur
- [x] Stats ekranı oluştur
- [x] Dark mode tasarımı yap

## 4. Core Gameplay Sistemleri
- [x] XP sistemi geliştir
- [x] Level sistemi geliştir
- [ ] Stat sistemi oluştur
- [ ] Daily quest sistemi ekle
- [ ] Achievement sistemi oluştur
- [ ] Reward sistemi geliştir
- [x] Streak sistemi geliştir

## 5. Pomodoro & Focus Sistemi
- [x] 25/5 pomodoro sistemi ekle
- [ ] Custom timer sistemi ekle
- [ ] Session geçmişi oluştur
- [ ] Bildirim sistemi ekle
- [ ] Focus modu oluştur

## 6. Animasyon & Ses
- [ ] XP animation sistemi yap
- [ ] Level up animasyonu ekle
- [ ] Particle effect sistemi oluştur
- [ ] Ses efektleri ekle
- [ ] Premium UI geçişleri tasarla

## 7. Beta Hazırlığı
- [ ] Crash testleri yap
- [ ] Performans optimizasyonu yap
- [ ] 50 kişilik beta test oluştur
- [ ] Kullanıcı feedback topla
- [ ] Hataları düzelt

## 8. Play Store Hazırlığı
- [ ] App icon hazırla
- [ ] Feature graphic oluştur
- [ ] Store screenshotları hazırla
- [ ] Privacy policy oluştur
- [ ] Google Play Console hesabı aç
- [ ] AAB release build oluştur

## 9. Yayın Sonrası
- [ ] Analytics verilerini takip et
- [ ] Retention oranlarını analiz et
- [ ] İlk büyük update planla
- [ ] Guild sistemi ekle
- [ ] Battle sistemi geliştir
- [ ] AI mentor sistemi ekle

## 10. Marketing Planı
- [ ] TikTok içerikleri oluştur
- [ ] Discord topluluğu kur
- [ ] Instagram reels paylaş
- [ ] Beta kullanıcılarından video al
- [ ] Üniversite topluluklarında paylaş

## 11. Tahmini Zaman Çizelgesi
| Süre | Hedef |
|---|---|
| 1. Ay | UI + temel sistemler |
| 2. Ay | XP + görev + pomodoro |
| 3. Ay | Animasyon + polish |
| 4. Ay | Beta test |
| 5. Ay | Bug fix + optimizasyon |
| 6. Ay | Play Store release |

> **Önemli Not:** İlk hedef küçük ama bağımlılık yapan bir MVP çıkarmak olmalı. İlk sürümde fazla özellik eklemek projeyi gereksiz büyütebilir.

---

# Proje Detayları

## Logo ve Renk Paleti

### Marka Kimliği
**Stil Karışımı:**
- Cyberpunk
- Anime RPG
- Modern productivity app

### Ana Renkler
**Primary:** `#7C4DFF` (Neon mor)
- *Sebep:* Premium his, gamer hissi, modern görünüm.

**Secondary:** `#00E5FF` (Cyan / neon blue)

**Background:** `#0F1117` (Koyu arka plan)

**Success / XP:** `#00FF95`

### UI Hissi
**Olmalı:**
- Glow efektleri
- Blur kartlar
- Minimal ama canlı
- Clean typography

**Olmamalı:**
- Aşırı karmaşık fantasy UI
- Ucuz gamer görünümü

### Logo Fikirleri
**En iyi seçenek:** Yukarı çıkan bir rune / ok / kristal.
**Anlam:** Progression, yükseliş, level up.

---

## Rakip Analizi

### Habitica
- **Güçlü Yanları:** RPG sistemi, görev mantığı, sadık topluluk.
- **Zayıf Yanları:** Eski UI, onboarding kötü, modern his vermiyor.
- **Senin Avantajın:** Modern ve premium görünümle ayrışabilirsin.

### Forest
- **Güçlü Yanları:** Aşırı basit, focus hissi çok iyi.
- **Zayıf Yanları:** Progression az, sosyal sistem zayıf.
- **Senin Avantajın:** Daha oyun hissi vereceksin.

### Finch
- **Güçlü Yanları:** Duygusal bağ, maskot sistemi.
- **Zayıf Yanları:** Fazla soft/cute.
- **Senin Avantajın:** Anime/gamer kitlesine hitap edeceksin.

### LifeUp
- **Güçlü Yanları:** Güçlü gamification.
- **Zayıf Yanları:** Karmaşık UX, eski görünüm.
- **Senin Avantajın:** Daha clean experience sunabilirsin.

**Rakiplerden Ayrışma Noktan Sloganı:** "Level up your real life."
**Senin uygulaman:** Daha sosyal, daha premium, daha anime/gamer, daha modern olmalı.

---

## Ana Hedef Kitle

**Primary Audience ⭐ (16-28 yaş)**
Özellikle:
- Üniversite öğrencileri
- Sınav öğrencileri
- Gamer/anime kitlesi
- Gym/self-improvement kitlesi

**Secondary Audience**
- Yazılımcılar
- Remote çalışanlar
- Productivity bağımlıları

**Kullanıcı Psikolojisi:** Bu insanlar disiplinli olmak istiyor ama klasik productivity app sıkıcı geliyor.
**Sen:** "Disiplini oyun gibi hissettireceksin."

---

## Temel Oyun Mantığı

### Ana Gameplay Loop
Döngü:
1. Görev yap
2. XP kazan
3. Level atla
4. Reward kazan
5. Daha zor hedef koy
6. Tekrar et
*Bu loop bağımlılık yaratır.*

### Günlük Kullanım Akışı
**Kullanıcı uygulamayı açar:**
- Daily quest görür
- Pomodoro başlatır
- Görev tamamlar
- XP kazanır
- Streak korur

**Sonra:**
- Arkadaşlarıyla yarışır
- Leaderboard görür
- Karakter geliştirir

### İlk Sürümde Kesin Olması Gerekenler (Core Features)
- [ ] Görev sistemi
- [ ] XP sistemi
- [ ] Level sistemi
- [ ] Streak sistemi
- [ ] Pomodoro
- [ ] Basit karakter sistemi
- [ ] Achievement sistemi

### İlk Sürümde OLMAMASI Gerekenler
- ❌ Açık dünya mantığı
- ❌ Karmaşık inventory
- ❌ Gerçek multiplayer
- ❌ Çok fazla AI
- ❌ Market sistemi
