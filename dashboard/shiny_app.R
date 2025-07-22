# dashboard/shiny_app.R

# Load libraries
library(shiny)
library(ggplot2)
library(plotly)
library(DT)
library(readr)
library(reticulate)       # For Python integration (optional)
library(shinydashboard)
library(here)
library(httr)

# Optional: Link to your Python virtualenv if needed
# reticulate::use_virtualenv("path_to_your_virtualenv")

# Load R model outputs using here()
# surrogate_data <- read_csv(here("r_models", "output", "surrogate_train_data.csv"))
# brms_summary <- read_csv(here("r_models", "output", "brms_summary.csv"))   # optional
# causal_impact <- read_csv(here("r_models", "output", "causal_impact_results.csv"))   # optional

# Define UI
ui <- dashboardPage(
    dashboardHeader(title = "Marketing Causal Dashboard"),
    dashboardSidebar(
        sliderInput("spend_input", "Past Spend (Before Campaign):", min = 0, max = 500, value = 100),
        actionButton("predict_btn", "Predict Uplift"),
        br(),
        fileInput("csv_input", "Upload New User Data (Optional)", accept = ".csv")
    ),
    dashboardBody(
        fluidRow(
            box(title = "Uplift Prediction", width = 6, status = "primary", solidHeader = TRUE,
                plotOutput("uplift_plot"),
                verbatimTextOutput("pred_values")
            ),
            # box(title = "Bayesian Model Summary", width = 6, status = "warning", solidHeader = TRUE,
            #     DTOutput("brms_table")
            # )
        ),
        fluidRow(
            box(title = "Causal Impact Summary", width = 6, status = "warning", solidHeader = TRUE,
                verbatimTextOutput("impact_summary")
            ),
            box(title = "User Churn Survival", width = 6, status = "success", solidHeader = TRUE,
                 tags$img(src = "http://54.242.206.194:8000/survival_plot", width = "600px", height = "400px")
            )
        ),

        # fluidRow(
        #     # box(title = "Causal Impact Results", width = 12, status = "success", solidHeader = TRUE,
        #     #     plotlyOutput("impact_plot")
        #     # )
        # )
    )
)

# Define server logic
server <- function(input, output, session) { 

    # Predict uplift using a Python API call (FastAPI)
    observeEvent(input$predict_btn, {
        req(input$spend_input)

        # Prepare API request
        url <- "http://54.242.206.194:8000/predict_uplift"
        payload <- list(
            user_id = 1,
            spend = input$spend_input
        )

        res <- httr::POST(url, body = payload, encode = "json")

        # Parse response
        if (res$status_code == 200) {
            content <- httr::content(res)

            output$pred_values <- renderPrint({
                print(content)
            })

            output$uplift_plot <- renderPlot({
                df <- data.frame(
                    Scenario = c("Treated", "Control"),
                    Spend = c(content$predicted_spend_treated, content$predicted_spend_control)
                )
                ggplot(df, aes(x = Scenario, y = Spend, fill = Scenario)) +
                    geom_bar(stat = "identity") +
                    labs(title = "Predicted Spend with/without Campaign", y = "Spend ($)") +
                    theme_minimal()
            })

        } else {
            output$pred_values <- renderPrint({
                print("API Error: Unable to fetch predictions.")
            })
        }
    })

            output$impact_summary <- renderPrint({
            res <- httr::GET("http://54.242.206.194:8000/causal_impact_summary")
            if (res$status_code == 200) {
                content <- httr::content(res, as = "text")
                cat(content)
            } else {
                cat("Error fetching causal impact summary.")
            }
        })

            output$survival_plot <- renderImage({
                list(src = "http://54.242.206.194:8000/survival_plot", contentType = "image/png", width = 600, height = 400)
            }, deleteFile = FALSE)


            # output$survival_plot <- renderImage({
            #     list(src = "survival_plot.png", contentType = "image/png", width = 600, height = 400)
            # }, deleteFile = FALSE)

    # # Show Bayesian model results
    # output$brms_table <- renderDT({
    #     datatable(brms_summary)
    # })

    # # Plot causal impact results (optional)
    # output$impact_plot <- renderPlotly({
    #     p <- ggplot(causal_impact, aes(x = date)) +
    #         geom_line(aes(y = actual), color = "black") +
    #         geom_line(aes(y = predicted), color = "blue", linetype = "dashed") +
    #         labs(title = "CausalImpact: Actual vs Predicted", y = "Spend") +
    #         theme_minimal()
    #     ggplotly(p)
    # })
}

# Run the app
shinyApp(ui, server)

#Summary shiny_app.R:
# This Shiny app provides a dashboard for marketing causal analysis. 
# A slide and dashboard feature allows for spend to be predicted from any given input data.
# "/predict_uplifts": This frontend app sends a HTTP POST request to the FASTAPI server which returns treated, control, and uplift predictions
# "/casual_impact_summary": The app sends a HTTP GET request to casual impact summary which runs  "r_models/causal_inference.R" and returns the ""causal_impact_summary.txt" to the Shiny_app which is displayed here "verbatimTextOutput("impact_summary")"
#"/survival_plot": The app sends a HTTP GET request to "/survival_plot end point" whichruns "r_models/survival_model.R", generating a survival plot which is copied to "dashboard/www//survival_plot.png" and rettrienved by FastAPI server and finally displayed by shniy app UI here "tags$img(src = "http://127.0.0.1:8000/survival_plot", width = "600px", height = "400px")"
# The app uses ggplot2 for plotting, DT for displaying tables, and plotly for interactive plots.