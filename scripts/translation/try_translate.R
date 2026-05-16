require(bacchuss)


all_multi_paragraphs_2022 <- readRDS("all_multi_paragraphs_2022_2026.RDS")


test_paragraphs <- all_multi_paragraphs_2022[sample(1:nrow(all_multi_paragraphs_2022), 300),]

library(readr)

system_prompt <- read_file("translate_prompt.txt")


source("../../config.R")
source("../utils_api.R")
check_api_config()

source("bacchuss_translate.R")

translated <- bacchuss_translate(test_paragraphs, input_column = "text_block", 
                       instructions = system_prompt,
                       reminder = "Preserve names, numbers, and quotes exactly. Return only the translation. Do not comment on the translation.",
                       default_ctx = 7680,
                       model = API_MODEL,
                       host = API_HOST,
                       api_key = API_KEY,
                       backend = API_BACKEND,
                       expected_response_format = "plain")


# translated <- bacchuss_translate(test_paragraphs[1:10,], input_column = "text_block", 
#                                  instructions = system_prompt,
#                                  reminder = "Preserve names, numbers, and quotes exactly. Return only the translation. Do not comment on the translation.",
#                                  default_ctx = 7680,
#                                  model = "magistral:24b_6k",
#                                  host = "http://a-colon:11434",
#                                  expected_response_format = "plain")


