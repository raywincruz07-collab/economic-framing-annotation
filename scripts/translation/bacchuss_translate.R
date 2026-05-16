.pick_ctx_bracket <- function(est, brackets = c(4096,5120,6144,7168,8192,10240,15360,20480,40960), default_ctx) {
  if (is.null(est) || is.na(est) || length(est)==0) return(default_ctx)
  chosen <- brackets[which(brackets >= est)[1]]
  if (is.na(chosen)) max(brackets) else chosen
}


#' Translate a single text according to instructions
#'
#' @description
#' `bacchuss_translate_satyr()` translates a single text. It is used within
#' `bacchuss_translate()`. It uses the instructions you hand over and detects
#' whether you added example cases. Please write instructions that tell the LLM
#' to output the translation after `Text:`. The returned translation may be
#' multiparagraph.
#'
#' @param instructions A char with your translation instructions
#' @param examples,translations Two vectors with translation examples: the
#' source text and the correct translated text for each case
#' @param reminder_s Short reminders to send after each example. Can be left
#' empty.
#' @param reminder Short reminder sent after all examples.
#' @param input_text The text to translate
#' @param expected_response_format Do you use plaintext or json format? Default plain.
#' @param est_ctx_len The estimated context length for instructions, examples,
#' translations and the text to translate.
#' @param model Which LLM model to use. No default.
#' @param host Address of the host you use. Default: local ollama
#' installation (uses default from ollamar package)
#' @param api_key Which API key to use (if your host handles users with
#' API keys). Default: NULL for unrestricted APIs.
#' @param backend Are you using a local Ollama instance or a LiteLLM host?
#' @param temperature Which temperature to use for the LLM. Higher =
#' more creative, lower = more consistent. Anything above 1 is not advised.
#' Default set to 0.2.
#' @param seed Seed to use for deterministic translation. In unsuccessful
#' tries, will try again with seed + 1. Default: NULL
#' @param retry_loop Small LLMs sometimes get into a long loop producing irrelevant
#' text. If set TRUE, the results of this run will be discarded and the LLM will
#' rerun with seed + 1. If set FALSE, keep result from loop.
#' @param retry_sleep How long to wait before retrying. Default: 30 seconds.
#' @param max_retries Max number of retries per call. Default: 3.
#' @param default_ctx Default context length if no context length is handed over.
#' Default: 5120.
#'
#' @returns
#' A list with:
#' \describe{
#'   \item{text}{Translated text.}
#'   \item{raw_output}{Full LLM output.}
#'   \item{max_context_used}{Context sent to the model.}
#'   \item{tokens_prompt}{Prompt token count.}
#'   \item{tokens_response}{Response token count.}
#' }
#' @export
bacchuss_translate_satyr <- function(instructions, examples = NULL, translations = NULL,
                                     reminder_s = "", reminder, input_text,
                                     est_ctx_len = NA,
                                     expected_response_format = c("plain","json"),
                                     model, host = NULL, api_key = NULL,
                                     backend = c("ollama",API_BACKEND),
                                     temperature = 0.2, seed = NULL,
                                     retry_sleep = 30, max_retries = 3,
                                     default_ctx = 5120,
                                     retry_loop = TRUE) {
  expected_response_format <- match.arg(expected_response_format)
  backend <- match.arg(backend)
  max_ctx <- .pick_ctx_bracket(est_ctx_len, default_ctx = default_ctx)
  
  ## Errors that explain user mistakes
  if (is.null(examples)) {
    if (!is.null(translations)) {
      stop("`translations` must be NULL when `examples` is NULL (zero-shot mode).", call. = FALSE)
    }
  } else {
    if (is.null(translations)) {
      stop("`translations` must be provided when `examples` are used (few-shot mode).", call. = FALSE)
    }
    if (length(translations) != length(examples)) {
      stop("`translations` and `examples` must have the same length.", call. = FALSE)
    }
  }
  
  if (backend == API_BACKEND && (is.null(host) || !nzchar(host))) {
    stop("`host` must be set for backend = 'litellm'.", call. = FALSE)
  }
  
  # normalize examples and translations
  if (!is.null(examples)) {
    if (length(examples) == 1 && is.na(examples)) examples <- NULL else examples[is.na(examples)] <- ""
  }
  if (!is.null(translations)) {
    if (length(translations) == 1 && is.na(translations)) translations <- NULL else translations[is.na(translations)] <- ""
  }
  
  # generate messages
  system_message <- list(role = "system", content = instructions)
  
  example_messages <- if (is.null(examples)) {
    list()
  } else {
    purrr::map2(seq_along(examples), examples, function(i, ex_text) {
      user_msg <- list(
        role = "user",
        content = paste0("Text: '", ex_text, "'\nReminder: ", reminder_s)
      )
      
      if (expected_response_format == "json") {
        example_content <- jsonlite::toJSON(
          list(text = translations[i]),
          auto_unbox = TRUE
        )
      } else {
        example_content <- paste0("Text: ", translations[i])
      }
      
      assistant_msg <- list(role = "assistant", content = example_content)
      list(user_msg, assistant_msg)
    }) |> purrr::list_flatten()
  }
  
  input_message <- list(
    role = "user",
    content = paste0("Text: '", input_text, "'\nReminder: ", reminder)
  )
  
  messages <- c(list(system_message), example_messages, list(input_message))
  seed_s <- seed
  
  response_text <- NULL
  tokens_prompt <- NA
  tokens_response <- NA
  resp <- NULL
  
  for (i in seq_len(max_retries)) {
    if (backend == "ollama") {
      req <- ollamar::chat(
        model = model,
        messages = messages,
        keep_alive = "10m",
        output = "req",
        temperature = temperature,
        num_ctx = max_ctx,
        host = host,
        seed = seed_s
      )
      
      req <- httr2::req_timeout(req, seconds = 300)
      
      if (!is.null(api_key) && nzchar(api_key)) {
        req <- httr2::req_headers(req, "Authorization" = paste0("Bearer ", api_key))
      }
      
      res <- tryCatch({
        resp <- httr2::req_perform(req)
        ollamar::resp_process(resp, output = "text")
      }, error = function(e) NULL)
      
      ok_tokens <- tryCatch(
        !is.null(resp$cache[[ls(resp$cache)[1]]]$prompt_eval_count),
        error = function(e) FALSE
      )
      
      if (!is.null(res) && (ok_tokens || !retry_loop)) {
        response_text <- res
        if (ok_tokens) {
          tokens_prompt <- httr2::resp_body_json(resp)$prompt_eval_count
          tokens_response <- httr2::resp_body_json(resp)$eval_count
        }
        break
      }
    } else {
      url <- paste0(host, "/chat/completions")
      body <- list(
        model = model,
        messages = messages,
        temperature = temperature,
        num_ctx = max_ctx
      )
      if (!is.null(seed_s)) body$seed <- seed_s
      
      req <- httr2::request(url) |>
        httr2::req_body_json(body)
      
      if (!is.null(api_key) && nzchar(api_key)) {
        req <- req |> httr2::req_headers(Authorization = paste0("Bearer ", api_key))
      }
      
      j <- tryCatch({
        resp <- httr2::req_perform(req)
        httr2::resp_body_json(resp)
      }, error = function(e) NULL)
      
      if (!is.null(j)) {
        response_text <- j$choices[[1]]$message$content
        tokens_prompt <- j$usage$prompt_tokens
        tokens_response <- j$usage$completion_tokens
        break
      }
    }
    
    if (i < max_retries) {
      message(sprintf("Attempt %d failed, retrying.", i))
      Sys.sleep(retry_sleep)
      seed_s <- if (is.null(seed_s)) NULL else seed_s + 1
    } else {
      stop(sprintf("All %d attempts failed.", max_retries))
    }
  }
  
  if (expected_response_format == "json") {
    txt_clean <- stringr::str_remove(
      response_text,
      stringr::regex("^```[jJ]?[sS]?[oO]?[nN]?\\s*", dotall = TRUE)
    )
    txt_clean <- stringr::str_remove(
      txt_clean,
      stringr::regex("```\\s*$", dotall = TRUE)
    )
    
    json_str <- stringr::str_extract(
      txt_clean,
      stringr::regex("\\{.*\\}", dotall = TRUE)
    )
    
    if (!is.na(json_str)) {
      j <- tryCatch(jsonlite::fromJSON(json_str), error = function(e) NULL)
      text_out <- if (!is.null(j$text)) as.character(j$text) else NA_character_
    } else {
      text_out <- NA_character_
    }
  } else {
    # Capture everything after the first "Text:" including line breaks
    text_out <- stringr::str_match(
      response_text,
      stringr::regex("Text:\\s*([\\s\\S]*)$", dotall = TRUE)
    )[, 2]
  }
  
  list(
    text = stringr::str_trim(text_out),
    raw_output = response_text,
    max_context_used = max_ctx,
    tokens_prompt = tokens_prompt,
    tokens_response = tokens_response
  )
}


#' Translate texts according to instructions
#'
#' @description
#' `bacchuss_translate()` translates the text in the dataframe you hand over.
#' It uses the instructions you hand over and detects whether you added
#' example cases. Please write instructions that tell the LLM to output the
#' translation after `Text:`. The returned translation may be multiparagraph.
#' Sometimes, small LLMs will be stuck in short loops. Default behavior is to
#' message "Attempt failed" and then retry.
#'
#' @param df A data frame containing the texts you want to translate
#' @param input_column A char indicating the column the texts to translate
#' are stored. Default: "text"
#' @param ctx_column A char indicating where the context length for the call
#' is stored. Leave at default if there is none.
#' @param instructions A char with your translation instructions
#' @param examples,translations Two vectors with example source texts and
#' their correct translations
#' @param reminder_s Short reminders to send after each example
#' @param reminder Short reminder sent after all examples
#' @param expected_response_format Do you use plaintext or json format? Default plain.
#' @param model Which LLM model to use. No default.
#' @param host Address of the host you use.
#' @param api_key Which API key to use. Default: NULL.
#' @param backend Are you using a local Ollama instance or a LiteLLM host?
#' @param temperature Which temperature to use for the LLM.
#' @param seed Seed to use for deterministic translation.
#' @param retry_loop Retry likely looped outputs.
#' @param retry_sleep How long to wait before retrying. Default: 30 seconds.
#' @param max_retries Max number of retries per call. Default: 3.
#' @param default_ctx Default context length if no context length is handed over.
#' @param warmup Number of warmup calls. Default: 0.
#'
#' @returns
#' A data frame with added columns:
#' \describe{
#'   \item{translated_texts}{Translated texts.}
#'   \item{raw_output}{Full LLM output per row.}
#'   \item{max_context_used}{Context used.}
#'   \item{tokens_prompt}{Prompt tokens.}
#'   \item{tokens_response}{Response tokens.}
#' }
#' @export
bacchuss_translate <- function(df, input_column = "text",
                               ctx_column = "estimated_context_length",
                               instructions, examples = NULL, translations = NULL,
                               reminder_s = "", reminder,
                               expected_response_format = c("plain","json"),
                               model, host = NULL, api_key = NULL,
                               backend = c("ollama",API_BACKEND),
                               temperature = 0.2, seed = NULL,
                               retry_loop = TRUE,
                               retry_sleep = 30, max_retries = 3,
                               default_ctx = 5120, warmup = 0) {
  
  expected_response_format <- match.arg(expected_response_format)
  backend <- match.arg(backend)
  
  if (!(input_column %in% names(df))) {
    stop(sprintf("Input column '%s' not found in dataframe.", input_column), call. = FALSE)
  }
  
  if (!(ctx_column %in% names(df))) {
    message(sprintf("Estimated context length column not found. Using default_ctx = %d.", default_ctx))
  }
  
  if (nrow(df) == 0) {
    stop("Input dataframe has 0 rows.", call. = FALSE)
  }
  
  df$translated_texts <- NA_character_
  df$raw_output <- NA_character_
  df$max_context_used <- NA_integer_
  df$tokens_prompt <- NA_integer_
  df$tokens_response <- NA_integer_
  
  has_est <- ctx_column %in% names(df)
  
  if (warmup > 0) {
    df_warmup <- df[rep(seq_len(nrow(df)), length.out = warmup), ]
    message(sprintf("Running warmup: %d calls.", nrow(df_warmup)))
    
    pb_warmup <- progress::progress_bar$new(
      format = "  warmup [:bar] :current/:total (:percent) in :elapsed ETA: :eta",
      total = nrow(df_warmup),
      clear = FALSE,
      width = 60
    )
    
    for (i in seq_len(nrow(df_warmup))) {
      est_ctx_len <- if (has_est) df_warmup[[ctx_column]][i] else NA
      bacchuss_translate_satyr(
        instructions = instructions,
        examples = examples,
        translations = translations,
        reminder_s = reminder_s,
        reminder = reminder,
        input_text = df_warmup[[input_column]][i],
        est_ctx_len = est_ctx_len,
        model = model,
        temperature = temperature,
        host = host,
        api_key = api_key,
        retry_loop = retry_loop,
        retry_sleep = retry_sleep,
        max_retries = max_retries,
        default_ctx = default_ctx,
        seed = seed,
        backend = backend,
        expected_response_format = expected_response_format
      )
      pb_warmup$tick()
    }
  }
  
  pb <- progress::progress_bar$new(
    format = "  [:bar] :current/:total (:percent) in :elapsed ETA: :eta",
    total = nrow(df),
    clear = FALSE,
    width = 60
  )
  
  for (i in seq_len(nrow(df))) {
    est_ctx_len <- if (has_est) df[[ctx_column]][i] else NA
    
    result <- bacchuss_translate_satyr(
      instructions = instructions,
      examples = examples,
      translations = translations,
      reminder_s = reminder_s,
      reminder = reminder,
      input_text = df[[input_column]][i],
      est_ctx_len = est_ctx_len,
      model = model,
      temperature = temperature,
      host = host,
      api_key = api_key,
      retry_loop = retry_loop,
      retry_sleep = retry_sleep,
      max_retries = max_retries,
      default_ctx = default_ctx,
      seed = seed,
      backend = backend,
      expected_response_format = expected_response_format
    )
    
    df$translated_texts[i] <- result$text
    df$raw_output[i] <- result$raw_output
    df$max_context_used[i] <- result$max_context_used
    df$tokens_prompt[i] <- result$tokens_prompt
    df$tokens_response[i] <- result$tokens_response
    pb$tick()
  }
  
  df
}
