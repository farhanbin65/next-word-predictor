library(shiny)
library(dplyr)
library(tidyr)

# Load n-gram tables
unigrams  <- readRDS("unigrams.rds")
bigrams   <- readRDS("bigrams.rds")
trigrams  <- readRDS("trigrams.rds")
quadgrams <- readRDS("quadgrams.rds")
# ── Prediction function ──────────────────────────────────────────
predict_next <- function(input_text, n = 3) {
  
  # Clean input
  input_text <- tolower(trimws(input_text))
  input_text <- gsub("[^a-z ]", " ", input_text)
  input_text <- gsub("\\s+", " ", input_text)
  words      <- unlist(strsplit(input_text, " "))
  words      <- words[words != ""]
  n_words    <- length(words)
  
  results <- NULL
  
  # Try quadgram first (last 3 words)
  if (n_words >= 3) {
    w1 <- words[n_words - 2]
    w2 <- words[n_words - 1]
    w3 <- words[n_words]
    results <- quadgrams %>%
      filter(word1 == w1, word2 == w2, word3 == w3) %>%
      arrange(desc(n)) %>%
      head(n) %>%
      select(prediction = word4, score = n)
  }
  
  # Backoff to trigram (last 2 words)
  if (is.null(results) || nrow(results) == 0) {
    if (n_words >= 2) {
      w1 <- words[n_words - 1]
      w2 <- words[n_words]
      results <- trigrams %>%
        filter(word1 == w1, word2 == w2) %>%
        arrange(desc(n)) %>%
        head(n) %>%
        select(prediction = word3, score = n)
    }
  }
  
  # Backoff to bigram (last 1 word)
  if (is.null(results) || nrow(results) == 0) {
    if (n_words >= 1) {
      w1 <- words[n_words]
      results <- bigrams %>%
        filter(word1 == w1) %>%
        arrange(desc(n)) %>%
        head(n) %>%
        select(prediction = word2, score = n)
    }
  }
  
  # Final fallback to most common words
  if (is.null(results) || nrow(results) == 0) {
    results <- unigrams %>%
      head(n) %>%
      select(prediction = word, score = n)
  }
  
  return(results)
}

# ── UI ───────────────────────────────────────────────────────────
ui <- fluidPage(
  
  tags$head(
    tags$style(HTML("
      body {
        background-color: #f0f4f8;
        font-family: 'Segoe UI', sans-serif;
      }
      .title-box {
        background: linear-gradient(135deg, #1a1a2e, #16213e);
        color: white;
        padding: 30px;
        border-radius: 12px;
        margin-bottom: 25px;
        text-align: center;
      }
      .title-box h2 { margin: 0; font-size: 28px; }
      .title-box p  { margin: 5px 0 0; opacity: 0.7; font-size: 14px; }
      .card {
        background: white;
        border-radius: 12px;
        padding: 25px;
        box-shadow: 0 2px 12px rgba(0,0,0,0.08);
        margin-bottom: 20px;
      }
      .pred-btn {
        display: inline-block;
        background: linear-gradient(135deg, #667eea, #764ba2);
        color: white !important;
        border: none;
        border-radius: 25px;
        padding: 10px 22px;
        margin: 6px;
        font-size: 16px;
        cursor: pointer;
        transition: transform 0.1s;
      }
      .pred-btn:hover { transform: scale(1.05); }
      .source-badge {
        display: inline-block;
        background: #e8f4fd;
        color: #2166ac;
        border-radius: 20px;
        padding: 4px 14px;
        font-size: 12px;
        font-weight: bold;
        margin-bottom: 15px;
      }
      #result_box {
        min-height: 80px;
        text-align: center;
        padding: 10px;
      }
      .form-control {
        border-radius: 25px !important;
        padding: 12px 20px !important;
        font-size: 16px !important;
        border: 2px solid #667eea !important;
      }
    "))
  ),
  
  div(class = "title-box",
      h2("Next Word Predictor"),
      p("SwiftKey NLP Capstone — Johns Hopkins Data Science")
  ),
  
  fluidRow(
    column(8, offset = 2,
           
           div(class = "card",
               h4("Type a word or phrase:"),
               textInput("user_input", label = NULL,
                         placeholder = "e.g. I want to...",
                         width = "100%"),
               br(),
               div(id = "result_box", uiOutput("predictions")),
           ),
           
           div(class = "card",
               h4("How it works:"),
               div(class = "source-badge", "Stupid Backoff N-gram Model"),
               p("1. You type a phrase"),
               p("2. The model checks 4-word sequences (quadgrams) first"),
               p("3. If no match, falls back to trigrams, then bigrams"),
               p("4. Final fallback: most common English words"),
               br(),
               p(em(paste("Trained on", 
                          format(nrow(bigrams),   big.mark=","), "bigrams |",
                          format(nrow(trigrams),  big.mark=","), "trigrams |",
                          format(nrow(quadgrams), big.mark=","), "quadgrams"
               )))
           )
    )
  )
)

# ── Server ───────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  predictions <- reactive({
    req(input$user_input)
    if (nchar(trimws(input$user_input)) == 0) return(NULL)
    predict_next(input$user_input, n = 5)
  })
  
  output$predictions <- renderUI({
    preds <- predictions()
    if (is.null(preds) || nrow(preds) == 0) {
      return(p("Start typing to see predictions...", 
               style = "color: #999; font-size: 16px;"))
    }
    
    buttons <- lapply(1:nrow(preds), function(i) {
      word <- preds$prediction[i]
      tags$button(
        class = "pred-btn",
        onclick = sprintf(
          "Shiny.setInputValue('chosen_word', '%s', {priority: 'event'})", 
          word),
        word
      )
    })
    
    tagList(
      p("Predicted next words:", 
        style = "color: #666; margin-bottom: 10px;"),
      div(buttons)
    )
  })
  
  # Clicking a prediction appends it to input
  observeEvent(input$chosen_word, {
    current <- trimws(input$user_input)
    updated <- paste(current, input$chosen_word)
    updateTextInput(session, "user_input", value = updated)
  })
}

shinyApp(ui = ui, server = server)