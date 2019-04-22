
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(dplyr)
library(tidyr)
library(ggplot2)
library(purrr)
library(ggmap)

shinyServer(function(input, output) {
  
#### Creating data sets ========================================================
  crime_data_raw <- readRDS("Data\\crime_data_raw.rds")
  
  crime_data <- reactive({
    crime_data_raw %>% 
      extract(col = OCCURRED_ON_DATE, into = c("Date", "Time"),
              regex = "^(.*) (.*):\\d\\d$", remove = T) %>% 
      mutate(Date = as.Date(Date),
             Shooting = SHOOTING == "Y") %>% 
      filter(Date >= min(input$daterange), Date <= max(input$daterange),
             OFFENSE_CODE_GROUP == input$targcrime | input$targcrime == "ALL")
  })
  
  crime_loc <- reactive({
    select(crime_data(), Long, Lat) %>% 
      filter(!is.na(Long), Lat != -1)
  })
  
  ## Loading presaved ggmap (See renderplot notes)
  load("Data/boston_img.rda")
  
  
  ## Distributions tab =========================================================
  
  output$title <- renderText({
    paste0("Crimes committed in Boston from ", min(crime_data()$Date),
           " to ", max(crime_data()$Date))
  })
  output$crimeselect <- renderUI({
    selectInput("targcrime", label = "Crimes filter to:", multiple = FALSE,
                choices = c("ALL", levels(crime_data_raw$OFFENSE_CODE_GROUP)),
                selected = "ALL")
  })
    
  
  output$shootingpct <- renderText({
    paste0(round(mean(crime_data()$Shooting)*100, digits = 2),
          "% of crimes involved shootings")
  })
  output$crimeplot <- renderPlot({
    crime_data() %>% 
      ggplot(aes(x = MONTH, fill = factor(YEAR))) + 
      geom_bar() + ggtitle("Total Crimes Committed") +
      scale_fill_brewer()
  })
  
  output$timecrime <- renderPlot({
    crime_data() %>% 
      ggplot(aes(x = HOUR, fill = factor(YEAR))) + 
      geom_density() + ggtitle("Time of Day") +
      scale_fill_brewer()
  })
  
  
  
  ## Heatmap tab ===============================================================
  
  output$count_text <- renderText({
    paste0("Total Crimes Displayed: ", format(nrow(crime_loc()),
                                              big.mark = ","))
  })
  
  output$crimemap <- renderPlot({
    ## Due to google api restrictions these calls can only be made once a day
    # key <- "AIzaSyDm2VwNgikxRvzLlBFngp7Ja6mRSBAwpfE"
    # boston <- get_map(location = c(mean(crime_loc()$Long),
    #                                mean(crime_loc()$Lat)),
    #                   source = "google", zoom = 12, api_key = key)
    
    ggmap(boston) + 
      stat_density2d(data = crime_loc(),
                     aes(x = Long, y = Lat,
                         fill = ..level..,
                         alpha = ..level..),
                     geom = "polygon") +
      scale_alpha_continuous(range = c(0.1, .4))
  })
  
  

})
