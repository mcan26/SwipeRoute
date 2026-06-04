# SwipeRoute: Akıllı Şehir Seyahat Rehberi

**Hazırlayan:** Murat Can Işık  
**Öğrenci Numarası:** 232923043  

## 1. Problem Tanımı
Modern şehirlerde yaşayanlar veya şehri ziyaret eden turistler için en büyük zorluklardan biri, devasa bir mekan havuzu içinde kendi kişisel zevklerine ve kısıtlı zamanlarına en uygun seyahat rotasını oluşturabilmektir. Mevcut harita ve keşif uygulamaları kullanıcılara çok fazla mekan sunmakta, ancak bu mekanları kullanıcı profiline göre süzüp ardışık ve coğrafi olarak mantıklı bir rota oluşturma konusunda eksik kalmaktadır. 

SwipeRoute, popüler çöpçatanlık uygulamalarındaki (Tinder vb.) sağa-sola kaydırma (swipe) mekaniğini kullanarak mekan seçim sürecini eğlenceli ve sezgisel bir hale getirmeyi, ardından bu interaktif seçimleri yapay zeka ve matematiksel algoritmalar ile optimize edilmiş günlük rotalara dönüştürmeyi amaçlayan bir mobil seyahat asistanıdır.

## 2. Literatür ve Benzer Çalışmalar
Turizm ve seyahat planlaması alanında "Karar Yorgunluğu" (Decision Fatigue), literatürde sıkça incelenen bir problemdir. Kullanıcılar Tripadvisor, Foursquare veya Google Travel gibi geleneksel uygulamalarda çok sayıda seçenek, uzun listeler ve karmaşık filtrelerle baş başa kalmaktadır. Bu bilgi yoğunluğu (information overload), kullanıcı deneyimini zorlaştırmaktadır.

Son yıllarda literatürde ve yenilikçi mobil uygulamalarda (örneğin Roameo, SwiGo ve Travel Swipe App gibi konseptler) bu problemi çözmek için "Oyunlaştırma" (Gamification) teknikleri kullanılmaya başlanmıştır. "Tinder-like" olarak bilinen kaydırma (swipe) arayüzü, Point of Interest (POI - İlgi Çekici Noktalar) tavsiye sistemlerinde büyük bir başarı yakalamıştır. Bu etkileşim modeli:
- Her defasında ekrana tek bir seçenek sunarak bilişsel yükü (cognitive load) azaltır.
- Kullanıcıdan gelen "sağa/sola kaydırma" (ikili - binary feedback) verilerini toplayarak yapay zeka algoritmalarının çok daha isabetli öğrenmesini sağlar.
- Seyahat planlama sürecini sıkıcı bir araştırma görevinden çıkarıp eğlenceli bir aktiviteye dönüştürür.

SwipeRoute, literatürdeki bu modern "kaydırmalı POI tavsiye" yaklaşımını benimser. Ancak mevcut örneklerin aksine, sadece mekan eşleştirmesi yapmakla kalmaz; bu tercihleri **Google Gemini Yapay Zeka** modeli ve **Greedy (Açgözlü) Mesafe Optimizasyon Algoritmaları** ile birleştirerek mantıklı, ardışık ve tamamen kişiselleştirilmiş "Günlük Seyahat Rotalarına" dönüştürür.

### Öne Çıkan Akademik Makaleler (Referanslar)
Projeye ve konseptimize (Karar Yorgunluğu, Akıllı Öneri Sistemleri, Kullanıcı Arayüzü) temel oluşturan güncel akademik çalışmalardan bazıları şunlardır:
1. *"A Thematic Travel Recommendation System Using an Augmented Big Data Analytical Model"* (2023) - **Alan:** Turizmde Büyük Veri, Veri Madenciliği ve Karar Yorgunluğu (Decision Fatigue) Çözümleri.
2. *"A Recommendation System for Tourists Using Decision Tree Methodologies"* (2021) - **Alan:** Makine Öğrenmesi ile Turizm Öneri Sistemleri ve Bilişsel Yükün (Cognitive Load) Azaltılması.
3. *"Enhancing Hotel Recommendations with AI: LLM-Based Review Summarization and Query-Driven Insights"* (2025) - **Alan:** Büyük Dil Modelleri (LLM) tabanlı akıllı seyahat asistanları ve kişiselleştirme.
4. *"Wanderer: An Integrated Application for Seamless Travel and Tourism"* (2025) - **Alan:** Uygulama Arayüz Tasarımı (UX), Seyahat Planlamasında Bilişsel Yük Yönetimi ve Akıllı Rota Entegrasyonu.
5. *"Personalized Tourism Recommendations: Leveraging User Preferences and Trust Network"* (2024) - **Alan:** Bilgi Yükü (Information Overload) Yönetimi ve Turizm Öneri Sistemlerinde Güven Ağları. (Interdisciplinary Journal of Information, Knowledge, and Management)
6. *"Promoting Sustainable Travel Experiences: A Weighted Parallel Hybrid Approach for Personalized Tourism Recommendations"* (2023) - **Alan:** Mobil Turizm Uygulamalarında Karar Yorgunluğunu Azaltan Hibrit Filtreleme Sistemleri. (MDPI)
7. *"Intelligent recommendation model of tourist places based on collaborative filtering and user preferences"* (2023) - **Alan:** Büyük Veri Çağında Turistik Mekan Önerileri ve Kullanıcı Tercihi Analizi. (Taylor & Francis)

## 3. Dataset (Veriseti)
Uygulamada kullanılan veri seti, Google Places API üzerinden çekilmiş ve veri ön işleme (data preprocessing) aşamasından geçirilerek tarafımızca zenginleştirilmiş 182 adet yüksek değerlendirmeli (300+ yorum, 4+ yıldız) İstanbul mekanından oluşmaktadır. Bu veriler çevrimdışı çalışma gereksinimlerini karşılamak üzere sisteme entegre edilmiştir.
Veriseti özellikleri:
- **Konum ve Kimlik:** Mekan adı, koordinatları (enlem ve boylam) ve Google Place ID.
- **Kategorizasyon:** Yemek, Manzara, Tarih, Gece Hayatı ve Sanat gibi anlamsal etiketler.
- **Medya ve Metin:** Yüksek çözünürlüklü API fotoğrafları. Her bir mekana özel araştırılarak yazılmış detaylı açıklamalar ve "💡 Tüyo: İmza tatlısını denemeden kalkma!" formatında yapay zeka destekli ipuçları.
- **Gerçekçi Ücretlendirme Sınıflandırması:** Lüks restoranlar için "💸💸💸 Luxe", müzeler için "💸💸 Premium", parklar ve sokak lezzetleri için "💸 Uygun" şeklinde statik ve gerçeği yansıtan fiyat seviyeleri.

## 4. Problem Çözümü
SwipeRoute uygulamasının çözüm mimarisi şu 4 temel adımdan oluşmaktadır:
1. **Swipe Mekaniği ile Seçim:** Kullanıcılar dinamik kart yapısı (Card Swiper) üzerinde mekanları sağa (beğen) veya sola (geç) kaydırarak kendi zevklerine uygun bir portföy oluştururlar.
2. **Coğrafi Optimizasyon (Greedy TSP):** Seçilen mekanlar, başlangıç noktasından itibaren birbirine en yakın olacak şekilde mesafe hesaplama (Distance Sorting) algoritması ile sıralanır. Bu sayede harita üzerinde zikzak çizmeyen, lojistik açıdan en verimli güzergah elde edilir.
3. **Yapay Zeka Destekli Planlama:** Sıralanmış mekanlar Google Gemini API'ye gönderilerek kullanıcının seçtiği seyahat süresine (örn. 3 gün) bölünür. Yapay zeka, metro, vapur gibi ulaşım şekillerini ve ziyaret sıralarını detaylandıran kişiselleştirilmiş bir metin üretir.
4. **Veri Kalıcılığı ve Harita Entegrasyonu:** Elde edilen rota, modern Backend-as-a-Service olan Supabase veritabanına ve cihazın yerel depolamasına (offline mode) kaydedilir. Kullanıcı "Kayıtlı Rotalarım" ekranından rotasını görüntüleyebilir veya Google Haritalar'a aktararak adım adım yönlendirme (navigation) başlatabilir.

## 5. GitHub Linki
**Geliştirici:** Murat Can Işık  
**Proje Repository Linki:** [https://github.com/mcan26/SwipeRoute](https://github.com/mcan26/SwipeRoute)

## 6. Ekler (Uygulama Ekran Görüntüleri)

- **Görsel 1: Ana Ekran ve Kaydırma (Swipe) Arayüzü**
  *(Buraya mekanların olduğu, sağa-sola kaydırılabilen ana ekran fotoğrafını yapıştırınız)*

- **Görsel 2: Yapay Zeka veya Bypass Destekli Günlük Rota**
  *(Buraya uygulamanın 1. Gün, 2. Gün şeklinde oluşturduğu planın fotoğrafını yapıştırınız)*

- **Görsel 3: Kayıtlı Rotalarım ve Harita Entegrasyonu**
  *(Buraya "Kayıtlı Rotalarım" sekmesinin veya rota detaylarının fotoğrafını yapıştırınız)*
