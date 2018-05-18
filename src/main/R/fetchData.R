
library(rvest)
library(data.table)

## fetch group data stuff

dataRaw <- read_html("http://www.fifa.com/worldcup/groups/") %>%
  html_nodes(xpath = "//table[@class='fi-table fi-standings']") 


teams <- dataRaw %>% html_nodes(xpath = "//span[@class='fi-t__nText ']") %>% html_text() %>% unique()
codes <- dataRaw %>% html_nodes(xpath = "//span[@class='fi-t__nTri']") %>% html_text() %>% unique()


result <- NULL
for (ii in seq_along(dataRaw)) {
  group <- dataRaw[ii] %>% html_nodes(xpath = "//p[@class='fi-table__caption__title']") %>% .[ii] %>% html_text()

  result <- rbind(result, data.table(
    group=rep(substring(group, nchar(group), nchar(group)), 4),
    team=teams[(ii*4-3):(ii*4)],
    code=codes[(ii*4-3):(ii*4)])
    )
}


## fetch betting odds

dataRaw <- read_html("https://www.oddschecker.com/football/world-cup/winner") %>%
  html_nodes(xpath = "//*[(@id = 'oddsTableContainer')]") 

dataRawOdds <- dataRaw %>%
  html_nodes(xpath = "table") %>%
  html_table() %>%
  as.data.table() 

dataProvider <- dataRaw %>% 
  html_nodes(xpath = "//*[contains(concat( ' ', @class, ' ' ), concat( ' ', 'bk-logo-click', ' ' ))]") %>%
  html_attr("title") %>%
  unique()

indEmpty <- which(dataRawOdds$X1 == "")
dataRawOdds <- dataRawOdds[(indEmpty[1]+1):(indEmpty[2]-1)]

indEmpty <- which(colSums(is.na(dataRawOdds)) > 0) - 1
dataRawOdds <- dataRawOdds[1:32, 1:indEmpty[1]]

colnames(dataRawOdds) <- c("team", dataProvider[1:(indEmpty[1]-1)])
providerNames <- colnames(dataRawOdds)[-1]

dataRawOdds[, (providerNames) := lapply(.SD, function(x) {
  lapply(x, function(y) {
    eval(parse(text = y))
  }) %>% unlist()
}), .SDcols = providerNames]

result[team=="IR Iran"]$team <- "Iran"
result[team=="Korea Republic"]$team <- "South Korea"


setkey(result, "team")
setkey(dataRawOdds, "team")

result <- result[dataRawOdds]
result <- result[order(group, team)]

fwrite(result, file = paste0("bettingOdds", format(Sys.Date(), "%Y%m%d"), ".csv"), sep = ";")
write.table(as.data.frame(result), paste0("bettingOdds", format(Sys.Date(), "%Y%m%d"), ".csv"), quote = FALSE, row.names = FALSE, sep = ";")
