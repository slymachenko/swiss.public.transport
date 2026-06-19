# Hackathon 2026: Data Science in R

## Obiettivo del progetto
[cite_start]Sviluppare un pacchetto R per scaricare, analizzare e visualizzare l'accessibilità del trasporto pubblico in Svizzera utilizzando l'API degli orari di `search.ch`[cite: 6]. 

[cite_start]L'obiettivo principale è la creazione di una **mappa dei tempi di attesa** che mostri quanto tempo un utente debba attendere, a partire da determinati orari di query, prima della successiva connessione disponibile verso ogni destinazione[cite: 8].

---

## Funzionalità richieste del pacchetto
[cite_start]Il pacchetto deve implementare le seguenti funzionalità core[cite: 10]:

1.  [cite_start]**Lettura dati**: Leggere i dati regionali da `SwissCities.csv`[cite: 11].
2.  [cite_start]**API Integration**: Scaricare i dati dei percorsi dall'API di `search.ch`[cite: 12].
3.  [cite_start]**Caching**: Utilizzare il caching locale per evitare chiamate API ripetute[cite: 13].
4.  [cite_start]**Parsing**: Analizzare e formattare le risposte JSON in dataframe *tidy*[cite: 14].
5.  [cite_start]**Calcolo indicatori**: Calcolare i tempi di attesa dalla query alla partenza successiva[cite: 15].
6.  [cite_start]**Summarisation**: Riassumere i tempi di attesa per destinazione[cite: 16].
7.  [cite_start]**Visualizzazione**: Generare mappe di alta qualità sui tempi di attesa[cite: 17].

---

## Task Obbligatori (Workflow)

### 3.1 Lettura dei dati
[cite_start]Il file `SwissCities.csv` fornisce le informazioni necessarie[cite: 44].
* [cite_start]Utilizzare `station_id` per le chiamate API[cite: 56].
* [cite_start]Utilizzare `city`, `region`, `latitude`, `longitude` e `population` per le analisi e le mappe[cite: 57].

### 3.2 Tabella delle query
[cite_start]Creare una tabella *tidy* contenente le combinazioni origine-destinazione-data-ora[cite: 60].
* [cite_start]**Nota**: Limitarsi a un solo giorno feriale e un massimo di 5 orari di query per evitare superamento dei limiti API[cite: 71].

### 3.3 Download e Caching
* [cite_start]Implementare una funzione `get_route(from, to, date, time, num=5)`[cite: 75].
* [cite_start]Il caching è obbligatorio: salvare ogni risposta API localmente (es. file `.rds`) e controllare l'esistenza del file prima di ogni chiamata[cite: 85, 86, 87].

### 3.4 Analisi e Mappe
* [cite_start]Calcolare il tempo di attesa minimo non negativo per ogni query[cite: 95, 96].
* [cite_start]**Mappa**: Utilizzare il pacchetto `sf` per leggere i dati geografici (`2026_GEOM_TK`) e `ggplot2` per la visualizzazione[cite: 109, 113].
* [cite_start]La mappa deve evidenziare la stazione di origine (es. una stella) e colorare le destinazioni in base al tempo di attesa mediano[cite: 106, 107].

---

## Task Opzionale
* [cite_start]Estrarre e mappare i "leg" (tratte) del percorso[cite: 119, 120].
* [cite_start]Disegnare percorsi semplificati collegando le fermate intermedie[cite: 124].

---

## Valutazione
[cite_start]Per superare l'hackathon è necessario che[cite: 140]:
1.  [cite_start]Il pacchetto superi `devtools::check()` senza errori[cite: 141].
2.  [cite_start]Il pacchetto sia installabile correttamente[cite: 142].
3.  [cite_start]Siano presenti le funzioni minime richieste (lettura, query, API, cache, parsing, calcolo, mappa) e uno script di esempio[cite: 143, 144, 151].