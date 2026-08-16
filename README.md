 _  _ ____ _  _ ___    _ _ _  ____ ____ ____    ___  ____ ____ ___  _ ____ ___ ____ ____ 
 |\ | |___  \/   |     | | |  |  | |__/ |  \    |__] |__/ |___ |  \ | |     |  |  | |__/ 
 |  \| |___ _\/_ |     |_|_|  |__| |  \ |__/    |    |  \ |___ |__/ | |___  |  |__| |  \


A SwiftKey style next word prediction app built with R, trained on 150,000 lines of real English text from blogs, news and Twitter.

## Live Links
- **Shiny App:** https://jjvqgo-farhan-bin.shinyapps.io/next-word-predictor/
- **EDA Report:** https://rpubs.com/keo/word_prediction
- **Slide Deck:** https://rpubs.com/keo/1452578


## Screenshot

![Next Word Predictor App](./shinny%20app/Screenshot%202026-08-16%20at%203.58.50 pm.png)

## System Architecture

```mermaid
flowchart LR
    subgraph DATA ["Data Sources"]
        A1[Blogs\n899k lines]
        A2[News\n1M lines]
        A3[Twitter\n2.3M lines]
    end

    subgraph TRAIN ["Training Pipeline"]
        B1[Sample 50k each]
        B2[Clean & Tokenise]
        B3[Build Unigrams\n100k words]
        B4[Build Bigrams\n1.3M pairs]
        B5[Build Trigrams\n2.9M sequences]
        B6[Build Quadgrams\n3.7M sequences]
        B7[(Save as RDS)]
    end

    subgraph PREDICT ["Prediction Engine"]
        C1[User Input]
        C2[Clean Input]
        C3{Quadgram\nLookup}
        C4{Trigram\nLookup}
        C5{Bigram\nLookup}
        C6{Unigram\nFallback}
        C7([Top 5 Predictions])
    end

    subgraph APP ["Shiny App"]
        D1[Text Input Box]
        D2[Clickable Predictions]
        D3[Live on shinyapps.io]
    end

    A1 & A2 & A3 --> B1
    B1 --> B2
    B2 --> B3 & B4 & B5 & B6
    B3 & B4 & B5 & B6 --> B7

    B7 --> C3 & C4 & C5 & C6
    D1 --> C1 --> C2
    C2 --> C3
    C3 -->|No Match| C4
    C4 -->|No Match| C5
    C5 -->|No Match| C6
    C3 & C4 & C5 & C6 -->|Match| C7
    C7 --> D2
    D1 & D2 --> D3

    style DATA fill:#1a1a2e,color:#fff
    style TRAIN fill:#2d6a4f,color:#fff
    style PREDICT fill:#3d405b,color:#fff
    style APP fill:#667eea,color:#fff
    style C7 fill:#f72585,color:#fff
    style B7 fill:#4cc9f0,color:#000
```

## How It Works
Uses a Stupid Backoff N-gram model with 4 layers:
1. Quadgrams (3,707,806 sequences)
2. Trigrams (2,997,658 sequences)
3. Bigrams (1,361,416 pairs)
4. Unigram fallback (100,501 words)

## Training Data (SwiftKey Dataset)
| Source  | Lines     | Avg Words/Line |
|---------|-----------|----------------|
| Blogs   | 899,288   | 42 words       |
| News    | 1,010,242 | 35 words       |
| Twitter | 2,360,148 | 12 words       |

## Tech Stack
- R, Shiny, tidytext, dplyr, ggplot2
- Deployed on shinyapps.io
- Report published on RPubs



## Course
Johns Hopkins Data Science Capstone — Coursera