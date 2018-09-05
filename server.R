
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(dplyr)
library(tidyr)
library(ggplot2)

shinyServer(function(input, output) {
  
  
  crime_data_raw <- readRDS("C:\\Users\\Sean Murphy\\Documents\\BostonCrime\\Data\\crime_data_raw.rds")
  
  
  
  crime_data <- reactive({
    crime_data_raw %>% 
      extract(col = OCCURRED_ON_DATE, into = c("Date", "Time"),
              regex = "^(.*) (.*):\\d\\d$", remove = T) %>% 
      mutate(Date = as.Date(Date),
             Shooting = SHOOTING == "Y") %>% 
      filter(Date >= min(input$daterange), Date <= max(input$daterange),
             OFFENSE_CODE_GROUP == input$targcrime | input$targcrime == "ALL")
  })
  
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
    paste(round(mean(crime_data()$Shooting)*100, digits = 2), "% of crimes involved shootings")
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

})
