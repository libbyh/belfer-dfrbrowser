options(java.parameters="-Xmx24g") # optional, but more memory for Java helps
library(stringr)
library(readr)
library(dplyr)
library(lubridate)
library(dfrtopics)

#load metadata (table - id, title, author, journal, volume, issue, pubdate, pages)
md <- read_csv("../data/sf_meta.csv",
               # col_names=c("id", "title", "author", "journal", "volume", "issue", "pubdate", "pages"), 
               col_types=str_c(rep("c", 8), 
                               collapse=""))

#load data (tsv files in a directory - word frequency)
fs <- md %>%
  transmute(id,
            filename=file.path("../data/freq", id)) %>%
  mutate(filename=str_c(filename, ".tsv"))

# load data for the files we have
# fs <- as.data.frame(list.files('../data/freqs', pattern = '*.tsv'), stringsAsFactors = FALSE, col.names = "c('filename')")
# fs <- fs %>%
#   rename(filename = 1) %>%
#   mutate(id = str_sub(filename, end=-5)) %>%
#   mutate(filename = paste('../data/freqs/', filename, sep = ''))
# 
# md <- md %>%
#   merge(fs, by='id')
  

# all(file.exists(fs$filename))
# readLines(fs$filename[1], n=3)

read_hathi <- function (f) {
  print(f)
  read_delim(f,
    skip = 1,
    delim="\t", quote="", escape_backslash=F, na="",
    col_names=F, col_types="ci")
}

# read_hathi(fs$filename[1]) %>% head()

counts <- read_wordcounts(fs$filename, fs$id, read_hathi)

stoplist <- readLines(file.path(path.package("dfrtopics"),
                                "stoplist", "stoplist.txt"))

# stoplist <- c("'s", "n't", "said", "says", stoplist)

counts <- counts %>%
  wordcounts_remove_stopwords(stoplist)

# counts <- counts %>%
#   filter(str_detect(word, "\\w"))
# 
# counts <- counts %>%
#   mutate(word=str_replace_all(word, "ﬁ", "fi")) %>%
#   mutate(word=str_replace_all(word, "ﬂ", "fl"))

# wordcounts_word_totals(counts) %>%
#   top_n(10, weight) %>%
#   arrange(desc(weight)) %>%
#   knitr::kable()

ilist <- counts %>%
  wordcounts_texts() %>%
  make_instances(token.regex="\\S+")

write_instances(ilist, "../browser/sf.mallet")

m <- train_model("../browser/sf.mallet", # or, equivalently, ilist
                 n_topics=20,
                 n_iters=200,
                 seed=18951899,
                 metadata=md)

write_mallet_model(m, "../browser/sf_-k20")

m <- load_mallet_model_directory("../browser/sf_-k20",
                                 load_topic_words=T)

metadata(m) <- read_csv("../data/sf_meta.csv",
                        col_names=T, col_types=str_c(rep("c", 8), collapse=""))

# topic_scaled_2d(m, n_words=500) %>%
#   plot_topic_scaled(labels=topic_labels(m, n=3))

export_browser_data(m, "../browser/sf_browser", supporting_files=T, overwrite=T)

metadata(m) <- metadata(m) %>%
  transmute(
    id,
    title,
    author,
    journaltitle=journal,   # no "journal" but let's stick publisher here
    volume="",              # these are expected but we'll leave them blank
    issue="",
    pubdate,
    pagerange="")

export_browser_data(m, "../browser/sf_browser/data", supporting_files=F, overwrite=T)

#change directory to browser
#python2 -m SimpleHTTPServer 8888
#http://localhost:8888/

