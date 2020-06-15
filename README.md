# Data Analysis of Three Voting in Kaohsiung in 2018-2020 (Focus on the Approval Rate of Han Kuo-Yu)
## A final project for Data Management

### Author:
  - <u> 廖傑恩 Jay Liao </u> | jay.chiehen[at]gmail.com | Department of Psychology | National Cheng Kung University
  - <u> 李唐榮 TJ Lee </u> | u38081046[at]gs.ncku.edu.tw | Institute of Education | National Cheng Kung University

### Description:

This is a final project presentation for _Data Management_, a course in National Cheng Kung University, Taiwan. In brief, we analyzed three votes in Kaohsiung in 2018-2020. We used map plotting and `shiny` app do demonstrate some finding and visualize data.

### Contents

#### Documents (Please do not move the path of any document or image.)

- `README.md`: This file.
- `KHvotes_presentation_forMac.Rmd`: The code file of ioslides with shiny web app, markdown, and mathjax (for Mac)
- `KHvotes_presentation_forWin.Rmd`: The code file of ioslides with shiny web app, markdown, and mathjax (for Windows)
- `KHvotes.R`: This is the pure R code file writing in the process of analysis. This is not well-organized, thus using above .Rmd files is recommended.

#### Images (Please do not move the path of any document or image.)

#### Font style file

- `PingFang.ttc`: This is a build-in font style of MacOS. Install it if you want to use it.

### Usage

#### Directly use

Directly open https://jay-chiehen.shinyapps.io/KHvotes_2018-2020_presentation/ through the browser.

#### Reconstruct the web app slides

1. Install the latest version of R and RStudio.

2. Install all required packages:

```
install.packages('shiny')
install.packages('dplyr')
install.packages('ggplot2')
install.packages('sf')       
install.packages('leaflet')  
install.packages('leafem')  
install.packages('mapview')
install.packages('readxl')
install.packages('robustHD')
install.packages('glmnet')

```

3. Open either `KHvotes_presentation_forMac.Rmd` or `KHvotes_presentation_forWin.Rmd` on RStudio and edit it if you want. For example, you can change the presentation format into the document format. It is recommended to save the edited file as the other file with different name.

4. Click `Run Presentation` to construct the web app.
