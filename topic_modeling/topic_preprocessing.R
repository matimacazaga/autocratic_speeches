# ----------------------------------------------------------------------------------------------
# ---------------------------------------- Preparation -----------------------------------------
# ----------------------------------------------------------------------------------------------

# Install and load required packages
os <- Sys.info()[["sysname"]] # Get operating system information
itype <- ifelse(os == "Linux", "source", "binary") # Set corresponding installation type
packages_required <- c(
  "quanteda", "stringi", "tidyverse"
)
not_installed <- packages_required[!packages_required %in%
                                     installed.packages()[, "Package"]]
if (length(not_installed) > 0) {
  lapply(
    not_installed,
    install.packages,
    repos = "http://cran.us.r-project.org",
    dependencies = TRUE,
    type = itype
  )
}
lapply(packages_required, library, character.only = TRUE)

# set working directory (to folder where this code file is saved)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load data
df <- read_delim('../data/df_unidecode.csv', delim = ',')
# inspect parsing problems
problems(df)

# plot histogram of tweets per year
hist(df %>% pull(Year))

# drop index columns / keep only relevant columns
df <- df %>% dplyr::select(c(Year, Name, doc_id, Text))

# generate time index t
## first year
first_year <- df$Year %>% unique() %>% min()
## time index t
df["t"] <- df$Year%%(first_year - 1)

# ----------------------------------------------------------------------------------------------
# ------------------ Preprocessing data with the quanteda package ------------------------------
# ----------------------------------------------------------------------------------------------

# build corpus, which by default organizes documents into types, tokens, and sentences
corp <- quanteda::corpus(x = df, text_field = "Text")

# build document-feature matrix, where in our case a feature corresponds to a word
# stopwords, numbers, and punctuation are removed and word stemming is performed
# each word is indexed and frequency per document assigned

# start with defining stopwords
stopwords_es <- read_lines(
  "https://raw.githubusercontent.com/stopwords-iso/stopwords-es/master/stopwords-es.txt"
)
length(stopwords_es) # 620 stopwords
length(stopwords("es")) # 231 stopwords contained in quanteda package
# combine all stopwords (amp from '&' and innen from -innen)
stopwords_es_customized <- Reduce(union, list(stopwords_es, stopwords("es")))

# convert special characters for stopwords (for text data: done in Python already)
stopwords_es_customized <- stringi::stri_replace_all_fixed(
  stopwords_es_customized, 
  c("ñ", "ü", "á", "é", "í", "ó", "ú"), 
  c("n", "u", "a", "e", "i", "o", "u"), 
  vectorize_all = FALSE
)

# build document-feature matrix
dfmatrix <- quanteda::dfm(
  corp,
  remove = stopwords_es_customized,
  remove_symbols = TRUE,
  remove_numbers = TRUE,
  remove_punct = TRUE,
  remove_url = TRUE,
  tolower = TRUE,
  verbose = FALSE
)

# check most frequent words
quanteda::topfeatures(dfmatrix, 20)

# manually remove specific tokens
dfmatrix <- dfmatrix %>% 
  quanteda::dfm_remove(pattern = "#", valuetype = "regex") %>%  # hashtags
  quanteda::dfm_remove(pattern = "@", valuetype = "regex")  %>%   # @username
  quanteda::dfm_remove(pattern = "(^[0-9]+[,.]?[0-9]+)\\w{1,3}$",  # 10er, 14.00uhr etc.
                       valuetype = "regex") %>%
  quanteda::dfm_remove(pattern = "^[^a-zA-Z0-9]*$",  # non-alphanumerical 
                       valuetype = "regex") %>%  
  quanteda::dfm_remove(pattern = "^.*(aaa|aeae|fff|hhh|uuu|www).*$",  # interjections (aaaawww etc.)
                       valuetype = "regex") %>%
  quanteda::dfm_remove(pattern = "^(polit|bundesregier|bundestag|deutsch|land|jaehrig|http)", # specific words
                       valuetype = "regex")

# perform word stemming and remove infrequent words
dfmatrix <- dfmatrix %>% 
  quanteda::dfm_wordstem(language = "spanish") %>% # word stemming
  quanteda::dfm_remove(min_nchar = 4) %>% # removing words with <4 characters
  quanteda::dfm_trim(min_termfreq = 5, min_docfreq = 3) # removing words occuring in <3 documents or <5 times overall

# check most frequent words again
quanteda::topfeatures(dfmatrix, 20)

# convert to stm object (this reduces memory use when fitting stm; see ?stm)
df_preprocessed <- quanteda::convert(dfmatrix, to = "stm")

# save
saveRDS(df_preprocessed, "../data/df_preprocessed.rds")

