library(dplyr)
library(ggplot2)
library(scales)

con_dply <- src_mysql(dbname="rstudio",user="root",password="lxhnt0906",host="localhost")

myData <- con_dply %>%
  tbl("mratings") %>%
  collect()

myData <- myData %>%
  group_by(MovieID) %>%
  summarise(popularity =-n()) %>%
  mutate(inventory = min_rank(popularity)) %>%
  select(inventory,MovieID) %>%
  inner_join(myData)

myData <- myData %>%
  group_by(UserID) %>%
  summarise(total_rated = n()) %>%
  inner_join(myData)

min(myData$total_rated) < 10  #no one rated less than 10 movie


#since we know that total_rated <= inventory for each user, to count the user at each inventory level,
#we need to pick the maximum inventory level for each user.


satisfy_100<- myData %>%
  group_by(UserID) %>%
  summarise(max_inv_level = max(inventory)) %>%
  arrange(max_inv_level) %>%
  mutate(cum= cume_dist(max_inv_level)) %>%
  distinct(max_inv_level) %>%
  select(max_inv_level,cum)


qplot(x=max_inv_level, y=cum,data=satisfy_100,xlab="Movie Inventory",ylab="Percent of 100% Satisfied Users")

prepare_90 <- myData %>%
  group_by(UserID) %>%
  summarise(max_inv_level_90 = 0.9 * max(inventory)) %>%
  inner_join(myData)

satisfy_90 <- prepare_90 %>%
  mutate(fil = inventory-max_inv_level_90) %>%
  filter(fil >= 0) %>%
  group_by(UserID) %>%
  summarise(min_inv = min(inventory)) %>%
  arrange(min_inv) %>%
  mutate(cum = cume_dist(min_inv)) %>%
  select(min_inv,cum)

qplot(x=min_inv, y=cum,data=satisfy_90,xlab="Movie Inventory",ylab="Percent of 90% Satisfied Users")
