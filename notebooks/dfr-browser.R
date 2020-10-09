options(java.parameters="-Xmx4g") # optional, but more memory for Java helps
library(stringr)
library(readr)
library(dplyr)
library(lubridate)
library(dfrtopics)

#load metadata (table - id, title, author, journal, volume, issue, pubdate, pages)
md <- read_csv("Documents/belfer/data/processed/dfr-sample/sf_rd_sample_with_ids_meta_sample.csv",
               col_names=T, col_types=str_c(rep("c", 19), collapse=""))

#load data (tsv files in a directory - word frequency)
fs <- md %>%
  transmute(id,
            filename=file.path("Documents/belfer/data/processed/dfr-sample/sf_rd_frequencies/", id)) %>%
  mutate(filename=str_c(filename, ".tsv"))

# all(file.exists(fs$filename))
# readLines(fs$filename[1], n=3)

read_hathi <- function (f) read_delim(f,
                                      delim="\t", quote="", escape_backslash=F, na="",
                                      col_names=F, col_types="ci")

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

write_instances(ilist, "Documents/belfer/data/processed/dfr-sample/sf_rd_sample.mallet")

m <- train_model("Documents/belfer/data/processed/dfr-sample/sf_rd_sample.mallet", # or, equivalently, ilist
                 n_topics=50,
                 n_iters=200,
                 seed=18951899,
                 metadata=md)

write_mallet_model(m, "Documents/belfer/data/processed/dfr-sample/sf_rd_sample-k50")

m <- load_mallet_model_directory("Documents/belfer/data/processed/dfr-sample/sf_rd_sample-k50",
                                 load_topic_words=T)

metadata(m) <- read_csv("Documents/belfer/data/processed/dfr-sample/sf_rd_sample_with_ids_meta_sample.csv",
                        col_names=T, col_types=str_c(rep("c", 19), collapse=""))

# topic_scaled_2d(m, n_words=500) %>%
#   plot_topic_scaled(labels=topic_labels(m, n=3))

export_browser_data(m, "Documents/belfer/data/processed/dfr-sample/sf_rd_sample_browser", supporting_files=T, overwrite=T)

metadata(m) <- metadata(m) %>%
  transmute(
    id,
    title,
    author="",
    journaltitle=journal,   # no "journal" but let's stick publisher here
    volume="",              # these are expected but we'll leave them blank
    issue="",
    pubdate,
    pagerange="")

export_browser_data(m, "Documents/belfer/data/processed/dfr-sample/sf_rd_sample_browser/data", supporting_files=F, overwrite=T)

#change directory to browser
#python2 -m SimpleHTTPServer 8888
#http://localhost:8888/

