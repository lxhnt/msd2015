library(dplyr)
library(ggplot2)
library(scales)


# I use mysql to read data, please ignore this piece of code.....

#con_dply <- src_mysql(dbname="rstudio",user="root",password="****",host="localhost")
#myData <- con_dply %>%
#  tbl("mratings") %>%
#  collect()user_ranking


#standard reading data procedure 
myData <- read.csv(file.choose(),header=F)


#calculate the popularity for each movie and attach to the original data set
myData <- myData %>%
  group_by(MovieID) %>%
  summarise(popularity =-n()) %>%
  mutate(inventory = min_rank(popularity)) %>%
  select(inventory,MovieID) %>%
  inner_join(myData)
  
#calculate the movie rated by each user and attach to the original data set
myData <- myData %>%
  group_by(UserID) %>%
  summarise(total_rated = n()) %>%
  inner_join(myData)

#no one rated less than 10 movie, no need to filter the data
min(myData$total_rated) < 10  


#since we know that total_rated <= inventory for each user, to count the user at each inventory level,
#we need to pick the maximum inventory level for each user.

#calculate 100% satisfaction level for each inventory size
satisfy_100<- myData %>%
  group_by(UserID) %>%
  summarise(max_inv_level = max(inventory)) %>%
  arrange(max_inv_level) %>%
  mutate(cum= cume_dist(max_inv_level)) %>%
  distinct(max_inv_level) %>%
  select(max_inv_level,cum)

#calculate 90% satisfaction level for each user
prepare_90 <- myData %>%
  group_by(UserID) %>%
  arrange(inventory) %>%
  summarise(total=n(),invent_size = inventory[round(total*0.9)])

#calculate 90% satisfaction level for each inventory size
satisfy_90 <- prepare_90 %>%
  arrange(invent_size) %>%
  mutate(cum = cume_dist(invent_size)) %>%
  select(invent_size,cum)

#draw the picture
satisfy_color=c("90% level"="#000000","100% level"="#009E73")
ggplot()+geom_line(aes(x=invent_size,y=cum,color="90% level"),data=satisfy_90)+geom_line(aes(x=max_inv_level,y=cum,color="100% level"),data=satisfy_100)+
  scale_color_manual(name="Satisfaction Level",values=satisfy_color)+xlab("Movie Inventory")+ylab("Percent of Satisfied Users")+ggtitle("User satisfaction curves for movies as a function of inventory size")
