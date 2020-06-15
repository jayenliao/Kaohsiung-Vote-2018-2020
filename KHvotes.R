# ================================

# Data Management - Final Project
# Jay Liao (jay.chiehen[at]gmail.com)
# Created on 8 June 2020
# Revised on 10 - 15 June 2020

# ================================

library(readxl)
library(dplyr)
library(ggplot2)

## Load in the data sets

## Mayor 2018

mayor <- read_xls('./data/Mayor_2018_KH.xls', range = 'A6:O1866', col_names = FALSE)
head(mayor)

colnames(mayor) <- c('TOWNNAME', 'village', 'vote_venue',
                     'Han', 'candidate2', 'candidate3', 'candidate4',
                     'valid', 'invalid', 'vote_counts',
                     'voteD', 'voteE', 'voteF', 'voter_counts', 'vote_rate')

mayor$TOWNNAME <- substr(mayor$TOWNNAME, 2, 4)
                     
mayor_use <- mayor %>% dplyr::filter(is.na(village)) %>% 
  dplyr::select(TOWNNAME, Han, valid, vote_counts, voter_counts, vote_rate) %>%
  mutate(vote_rate2 = vote_counts / voter_counts, Han_rate = Han / valid)
mayor_use

qplot(Han_rate, data = mayor_use, geom = 'density')
qplot(Han_rate, data = mayor_use, geom = 'density', xlim = c(0, 1))


## President 2020

president <- read_xls('./data/President_2020_KH.xls', range = 'A7:L44', col_names = FALSE)
president

colnames(president) <- c('TOWNNAME', 'candidate1', 'Han', 'candidate3',
                         'valid', 'invalid', 'vote_counts',
                         'voteD', 'voteE', 'voteF', 'voter_counts', 'vote_rate')

president$TOWNNAME <- substr(president$TOWNNAME, 2, 4)

president_use <- president %>%
  dplyr::select(TOWNNAME, Han, valid, vote_counts, voter_counts, vote_rate) %>%
  mutate(vote_rate2 = vote_counts / voter_counts, Han_rate = Han / valid)

qplot(Han_rate, data = president_use, geom = 'density', xlim = c(0, 1))


## Mayor recall 2020

recalll <- read_xlsx('./data/Mayor_recall_2020_KH.xlsx', range = 'A7:K44', col_names = FALSE)
recalll

colnames(recalll) <- c('TOWNNAME', 'agree', 'disagree', 'valid', 'invalid', 'vote_counts',
                       'voteF', 'voteG', 'voteH', 'voter_counts', 'vote_rate')

recalll$TOWNNAME[recalll$TOWNNAME == '那瑪夏區'] <- '那瑪夏'

recalll_use <- recalll %>%
  dplyr::select(TOWNNAME, agree, disagree, valid, vote_counts, voter_counts, vote_rate) %>%
  mutate(vote_rate2 = vote_counts / voter_counts,
         Han_rate1 = 1 - agree / valid,
         Han_rate2 = 1 - agree / voter_counts)

recalll_use


### Merge three voting data sets 

dta <- mayor_use %>%
  inner_join(y = president_use, by = 'TOWNNAME', suffix = c('.mayor', '.president')) %>%
  inner_join(x = ., y = recalll_use, by = 'TOWNNAME', suffix = c('', '.recall')) %>% 
  mutate(Han_rate.recall = 1 - agree / ((vote_counts.mayor + vote_counts.president)/2))

hist(dta$Han_rate.recall)

### Map data

library(sf)
library(leaflet)
library(mapview)

twn_map2 <- st_read('./data/mapdata202003270418/TOWN_MOI_1090324.shp')
kh_map2 <- twn_map2[twn_map2$COUNTYNAME == "高雄市",]
kh_map2

dta_voter_long <- dta %>%
  dplyr::select(TOWNNAME, voter_counts.mayor, voter_counts.president, voter_counts) %>%
  reshape2::melt(id = TOWNNAME)
dta$TOWNNAME[dta$TOWNNAME == '那瑪夏'] <- '那瑪夏區'

df <- kh_map2 %>% dplyr::select(TOWNNAME, geometry) %>% left_join(dta)

#lopt = labelOptions(noHide = TRUE, direction = 'top', textOnly = TRUE)

### Draw the map

# Mayor
m <- mapView(df['Han_rate.mayor'], map.type = 'CartoDB.Positron',
             layer.name = '韓得票率',
             col.regions = c('springgreen1', 'white', blues9)) %>%
  leafem::addStaticLabels(label = df$TOWNNAME)
m %>% setView(mean(c(120.3593, 121.049)), mean(c(22.37135, 23.47171)), zoom = 9)

# President
m <- mapview(df['Han_rate.president'], map.type = 'CartoDB.Positron',
             layer.name = '韓得票率',
             col.regions = c('aquamarine4', paste0('springgreen', 4:1), 'white', blues9[2:8])) %>%
  leafem::addStaticLabels(label = df$TOWNNAME)
m %>% setView(mean(c(120.3593, 121.049)), mean(c(22.37135, 23.47171)), zoom = 9)

# Mayor Recall
m <- mapview(df['Han_rate.recall'], map.type = 'CartoDB.Positron',
             layer.name = '韓支持度（反對罷免）',
             col.regions = c(paste0('deeppink', 3:1), 'white', blues9)) %>%
  leafem::addStaticLabels(label = df$TOWNNAME)
m %>% setView(mean(c(120.3593, 121.049)), mean(c(22.37135, 23.47171)), zoom = 9)


### Examine the differences among three votes

t.test(mayor_use$voter_counts, president_use$voter_counts, paired = TRUE)
t.test(mayor_use$voter_counts, recalll_use$voter_counts, paired = TRUE)
t.test(president_use$voter_counts, recalll_use$voter_counts, paired = TRUE)


model_voter <- aov(value ~ variable + Error(TOWNNAME / variable), data = dta_voter_long)
summary(model_voter)

model_voter <- aov(value ~ variable + TOWNNAME, data = dta_voter_long)
summary(model_voter)
TukeyHSD(model_voter)$variable

summary(recalll)

qplot(disagree, data = recalll, geom = 'density', xlim = c(0, 1))


### Cluster Analysis (1): Hierarchical Clustering

## Cluster Analysis for the counties
df_cluster <- dta %>%
  dplyr::select(Han_rate.mayor, Han_rate.president, Han_rate.recall) %>%
  as.data.frame()
rownames(df_cluster) <- dta$TOWNNAME
E.dist <- dist(df_cluster, method = "euclidean") # 歐式距離 the distance measure to be used. This must be one of "euclidean", "maximum", "manhattan", "canberra", "binary" or "minkowski". Any unambiguous substring can be given.
h.cluster <- hclust(E.dist, method = "ward.D") # 華德法 the agglomeration method to be used. This should be (an unambiguous abbreviation of) one of "ward.D", "ward.D2", "single", "complete", "average" (= UPGMA), "mcquitty" (= WPGMA), "median" (= WPGMC) or "centroid" (= UPGMC).
plot(h.cluster, family = '蘋方-繁 標準體')

out_df_cluster <- data.frame(TOWNNAME = h.cluster$labels, h.cluster$order,
                             group = c(rep(1, 3), rep(2, 7), rep(3, 5),
                                       rep(4, 8), rep(5, 5), rep(6, 10)))

df <- kh_map2 %>% dplyr::select(TOWNNAME, geometry) %>%
  left_join(out_df_cluster)
rownames(df) <- df$TOWNNAME

m <- mapView(x = list(df['group'], df['h.cluster.order'])) %>%
  leafem::addStaticLabels(label = df$TOWNNAME)
m %>% setView(mean(c(120.3593, 121.049)), mean(c(22.37135, 23.47171)), zoom = 9)


### PART 3: Ridge and Lasso regression

# Load in the data sets

library(readxl)

fls <- list.files(path = "./data/demography")
fL <- paste0("./data/demography/", fls)

demo_lst <- lapply(fL, read_xlsx)
names(demo_lst) <- gsub(fls, pattern = '.xlsx', replacement = '')
sapply(demo_lst, colnames)
sapply(demo_lst, dim)

pop_long <- demo_lst$pop_density %>% reshape2::melt() %>%
  mutate(Year = as.numeric(substr(variable, 6, 8)), variable = substr(variable, 1, 4))
pop_final <- inner_join(pop_long[pop_long$variable == '人口密度',] %>% dplyr::select(-variable),
                        pop_long[pop_long$variable == '家戶密度',] %>% dplyr::select(-variable),
                        by = c("TOWNNAME", "Year"))
pop_final$Year[pop_final$Year == 107] <- '107/10'
pop_final$Year[pop_final$Year == 108] <- '108/12'
pop_final$Year[pop_final$Year == 109] <- '109/05'
colnames(pop_final)[2:4] <- c('人口密度', 'Month', '家戶密度')

edu <- demo_lst$edu %>% dplyr::filter(TOWNNAME != '總計' & TOWNNAME != '總  計' & `年　齡　別` == '總計' & `性　別` == '計') %>%
  dplyr::select(-c(`年　齡　別`, `性　別`))
edu_sub1 <- edu %>% dplyr::filter(substr(TOWNNAME, 1, 2) == '鳳山') %>%
  group_by(Month) %>% summarise_if(is.numeric, sum) %>% mutate(TOWNNAME = '鳳山')
edu_sub2 <- edu %>% dplyr::filter(substr(TOWNNAME, 1, 2) == '三民') %>%
  group_by(Month) %>% summarise_if(is.numeric, sum) %>% mutate(TOWNNAME = '三民')
edu <- rbind(edu %>% dplyr::filter(!(substr(TOWNNAME, 3, 3) %in% c('一', '二'))), edu_sub1, edu_sub2)  

dta_demo <- demo_lst$age %>% dplyr::filter(TOWNNAME != '高雄市' & 性別 == '總計') %>% dplyr::select(-性別) %>%
  inner_join(., demo_lst$data_management_population %>% dplyr::filter(TOWNNAME != '高雄市'), by = c('TOWNNAME', 'Month')) %>%
  inner_join(., demo_lst$natural_social_rate_of_increase %>% dplyr::filter(TOWNNAME != '高雄市'), by = c('TOWNNAME', 'Month')) %>%
  inner_join(., pop_final %>% dplyr::filter(TOWNNAME != '高雄市'), by = c('TOWNNAME', 'Month')) %>%
  inner_join(., edu, by = c('TOWNNAME', 'Month'))

dta_demo <- dta_demo %>% dplyr::select(-c('總計', '總　計', '人口數', 'POP', '里數', '鄰數', '戶數', '人口密度', '家戶密度')) %>%
  mutate_if(is.numeric, function(v) {v / dta_demo$POP * 100}) %>%
  inner_join(., dta_demo %>% dplyr::select(TOWNNAME, Month, 里數, 鄰數, 戶數, 人口密度, 家戶密度), by = c('TOWNNAME', 'Month')) %>%
  mutate(性別比 = 男 / 女 * 100)

colnames(dta_demo)[2:22] <- paste0('年齡', colnames(dta_demo)[2:22], '人口比例')
colnames(dta_demo)[33:55] <- paste0(c('識字者', '博士畢業', '博士肄業', '碩士畢業', '碩士肄業', '大學畢業', '大學肄業',
                                      '二三年制專科畢業', '二三年制專科肄業', '五專後二年畢業', '五專後二年肄業',
                                      '高中畢業', '高中肄業', '高職畢業', '高職肄業', '五專前三年肄業',
                                      '國中畢業', '國中肄業', '初職畢業', '初職肄業', '國小畢業', '國小肄業', '自修'), '比例')
colnames(dta_demo)[26:32] <- c('出生率', '死亡率', '自然增加率', '移入率', '移出率', '社會增加率', '人口增加率')
colnames(dta_demo)
