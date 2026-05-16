# ============================================================
# 00_config.R  —  Shared configuration for all steps
# Project: Economic Framing Annotation — 10,000 Rows
# Routine: Freudenthaler bacchuss routine (routine.md)
# ============================================================

# ── API (University GPU) ─────────────────────────────────────
API_MODEL   <- Sys.getenv("MAKI_API_MODEL", unset = "ministral-3-14b")
API_HOST    <- Sys.getenv("MAKI_API_HOST", unset = "https://maki.uni-mannheim.de/v1")
API_KEY     <- Sys.getenv("MAKI_API_KEY", unset = "")
API_BACKEND <- Sys.getenv("MAKI_API_BACKEND", unset = "compute_proxy")

if (API_KEY == "") {
  stop("MAKI_API_KEY is not set. Please configure it in your .Renviron file or environment variables.")
}

# ── Files ────────────────────────────────────────────────────
INPUT_FILE      <- "data/raw/dataset_10k_translated.csv"
SAMPLE_200_FILE <- "data/samples/sample_200.csv"
FEWSHOT_FILE    <- "data/fewshot/fewshot_training_blocks.csv"
GOLD_FILE       <- "data/validation/human_gold_validation.csv"
NOTES_FILE      <- "reports/project_notes.md"

# ── bacchuss source (parent folder) ──────────────────────────
BACCHUSS_PKG <- TRUE  # set FALSE to source manually

# ============================================================
# ANNOTATION INSTRUCTIONS — Step 1 Draft
# ============================================================

# ── THREAT instructions ──────────────────────────────────────

instructions_threat <- paste(
  "Role: You are a trained content analyst. You detect economic threat framing",
  "in German news paragraphs translated to English.",
  "",
  "Context: Each input is one paragraph from a German news article.",
  "Be literal — search only for expressions explicitly present in the text.",
  "Do not use background knowledge or infer from context.",
  "",
  "OCCURRENCE RULE — MANDATORY:",
  "Code YES whenever an economic threat frame linked to immigration is EXPLICITLY MENTIONED",
  "in the paragraph — even if the author denies it, quotes it, uses sarcasm, or refutes it.",
  "You code whether the frame APPEARS. Not whether it is true or endorsed.",
  "EXAMPLE: 'It is false that migrants burden public finances' → Label: YES",
  "         (the threat frame is present even though denied)",
  "EXAMPLE: 'Critics claim immigration costs taxpayers billions' → Label: YES",
  "         (frame is present even though it is a quotation)",
  "",
  "WIRTSCHAFT THREAT — Code YES if ANY of T1–T5 is explicitly mentioned:",
  "",
  "T1: Does the text mention that immigration threatens the economic well-being or",
  "    economic prospects of the receiving society or country?",
  "",
  "T2: Does the text mention a specific threat to the economic prospects of Germany",
  "    or the European Union caused by immigration?",
  "",
  "T3: Does the text mention labour market harm caused by immigration: rising",
  "    unemployment, displacement of native workers, taking of jobs, unwillingness",
  "    or inability to work, lack of work incentive, or wage depression?",
  "",
  "T4: Does the text mention strain on welfare or public finances caused by immigration:",
  "    social benefits as a migration pull factor, Hartz-IV recipients from the group,",
  "    taxpayer burden, loss of financial control over social systems?",
  "",
  "T5: Does the text explicitly mention COSTS, BURDEN, OVERLOAD, CAPACITY LIMITS,",
  "    or NEED FOR MORE RESOURCES caused by immigration:",
  "    housing shortages, school costs, healthcare costs, administrative backlog,",
  "    communes at financial limits, billions in expenditure, border or deportation costs?",
  "    Includes rhetorical questions that imply cost ('How much more will it cost us?').",
  "",
  "Code NO if none of T1–T5 applies.",
  "Always code NO for these even if present in the text:",
  "  - Logistics reporting: text only states that accommodation WAS set up or",
  "    exists, with NO mention of cost, burden, strain, overload, or shortage = NO",
  "    Example: 'Volunteers set up emergency accommodation at a former elderly home' = NO",
  "  - Statistics reporting: text reports numbers of beds, residents, or arrivals",
  "    without any cost, shortage, or overload language = NO",
  "    Example: '103 beds available, 257 people living there' = NO",
  "  - Logistical failures: a housing plan fails for building/safety reasons with",
  "    no explicit financial cost or capacity burden stated = NO",
  "  - Factual entitlement announcements: stating that a benefit or entitlement EXISTS",
  "    (e.g. free transport, free housing) WITHOUT framing it as a burden, pull",
  "    factor, or taxpayer cost = NO",
  "  - Donations (Spenden) to refugee organisations",
  "  - Weapons deliveries (Waffenlieferungen)",
  "  - General economic hardship (inflation, recession) NOT linked to immigration",
  "  - War or disaster without explicit mention of costs",
  "  - International politics & foreign aid: Policies, financial sanctions, or agreements",
  "    between foreign countries (e.g. UK-Rwanda, EU-Hungary rule-of-law) or disaster",
  "    relief funds (e.g. Red Cross) are NOT German economic threats = NO",
  "  - Non-immigration capacity limits: Limited university spots, sports subsidies cut,",
  "    or domestic labor market funding NOT caused by refugees are NO.",
  "  - Criminal activity: Embezzlement, fraud, or fines by individuals are NO.",
  "  - Mere occupancy reporting: stating that a shelter has 300 residents or is full",
  "    is NO. HOWEVER, explicitly stating 'housing shortage', 'communes at capacity limits',",
  "    or 'overloaded' DO count as T5.",
  "  - Humanitarian descriptions: language describing difficult CONDITIONS for",
  "    refugees (sleeping outdoors, cramped spaces) without naming a financial",
  "    burden on the RECEIVING society = NO. The hardship of the refugee is NOT T5.",
  "  - Municipal 'challenges' without cost: if a mayor or official describes",
  "    'enormous challenges' or 'difficult situation' without naming euros, staff",
  "    shortages, budget overruns, or specific resource scarcity = NO",
  "  - German domestic economic issues: mentions of German energy costs, inflation,",
  "    housing prices for Germans, or labour market data NOT linked to immigration",
  "    as a cause = NO",
  "",
  "OUTPUT FORMAT — use exactly this, every row, no exceptions:",
  "Explanation: [One sentence: identify the sub-criterion T1–T5 and quote the exact",
  "phrase from the text that triggered YES — OR explain why none of T1–T5 applies]",
  "Label: YES",
  "",
  "OR:",
  "Explanation: [One sentence: explain why none of T1–T5 applies to this text]",
  "Label: NO",
  sep = "\n"
)

reminder_threat <- paste(
  "Code YES if ANY of T1–T5 is explicitly mentioned.",
  "T5 triggers on: cost, expense, financial pressure, budget strain,",
  "renting at cost, shortage, overload, capacity limits, or need for more resources.",
  "An explicit euro amount is NOT required — 'considerable cost' or",
  "'financial pressure' are sufficient for T5.",
  "CRITICAL: Do NOT code YES just because refugees are present.",
  "A facility being established or accommodation being set up (no cost language) = NO.",
  "Statistics reporting only (numbers of beds/residents, no burden language) = NO.",
  "When in doubt, code NO.",
  sep = " "
)

# ── BENEFIT instructions ──────────────────────────────────────

instructions_benefit <- paste(
  "Role: You are a trained content analyst. You detect economic benefit framing",
  "in German news paragraphs translated to English.",
  "",
  "Context: Each input is one paragraph from a German news article.",
  "Be literal — search only for expressions explicitly present in the text.",
  "Do not use background knowledge or infer from context.",
  "",
  "OCCURRENCE RULE — MANDATORY:",
  "Code YES whenever an economic benefit frame linked to immigration is EXPLICITLY MENTIONED",
  "in the paragraph — even if the author denies it, quotes it, uses sarcasm, or refutes it.",
  "You code whether the frame APPEARS. Not whether it is true or endorsed.",
  "EXAMPLE: 'The myth that migrants would deliver a second economic miracle was a lie'",
  "         → Label: YES (the benefit frame is present even though denied)",
  "",
  "WIRTSCHAFT BENEFIT — Code YES if ANY of B1–B5 is explicitly mentioned:",
  "",
  "B1: Does the text mention that immigration generates or could generate positive",
  "    economic effects: tax revenue, economic growth, GDP benefit, attracting workers?",
  "",
  "B2: Does the text mention positive economic effects of immigration for Germany",
  "    or the European Union as a whole?",
  "",
  "B3: Does the text mention that immigration is needed or beneficial because of",
  "    aging populations, a shrinking workforce, or strain on pension/social security?",
  "",
  "B4: Does the text mention skilled labour shortages (Fachkräftemangel) AND immigration",
  "    together? Or cheap labour provision by the immigrant group?",
  "    CRITICAL: Fachkräftemangel mentioned WITHOUT any link to immigration = NO.",
  "",
  "B5: Does the text explicitly state:",
  "    (a) That more prosperity or labour WILL result IF integration measures, work",
  "        permits, or training are provided — the benefit must be named explicitly, OR",
  "    (b) That economic benefits are being LOST because of restrictive policy, lack of",
  "        degree recognition, work permit denial, or language barriers?",
  "        (e.g. 'we lose skilled workers', 'language barriers prevent labour market entry')",
  "",
  "Code NO if none of B1–B5 applies.",
  "Always code NO for these even if present in the text:",
  "  - Staffing vs. Labor: a 'lack of staff' or 'lack of carers' to manage or",
  "    house refugees is a RESOURCE SHORTAGE (THREAT T5), not an economic benefit.",
  "    Only code B1-B5 if refugees are FILLING a vacancy, not causing a staffing",
  "    crisis = NO",
  "  - Seasonal/Weather effects: news about 'seasonal effects', 'weather', or",
  "    'spring upturns' in the labor market is NOT an economic benefit = NO",
  "  - Deportation/Status: news about deportation deals (e.g., Rwanda), distance,",
  "    illegal entry, or 'status' changes is NOT an economic benefit = NO",
  "  - Threat != Benefit: if a text describes a THREAT (e.g., social system",
  "    collapse, burden, strain, workers' protections collapsing), do NOT code YES",
  "    for Benefit even if money or labour is mentioned, unless a positive economic",
  "    outcome is explicitly and independently named = NO",
  "  - Budgetary Flow: allocated money flowing back to the treasury because it was",
  "    unused, or the mere existence of a budget for refugees, is a logistical fact",
  "    and NOT an economic benefit = NO",
  "  - Vague Optimism: general 'optimism' or a 'fundamentally different situation'",
  "    is NOT an economic benefit unless a specific variable (tax revenue, labour",
  "    shortage filled, GDP) is the explicit reason for the optimism = NO",
  "  - Macroeconomic news: news about global trade, currencies (Dollar/Euro),",
  "    central banks, or inflation WITHOUT a direct link to the immigrant group = NO",
  "  - International news: news about Russia, Ukraine, or Turkey that does not",
  "    explicitly name an economic benefit for Germany linked to refugees = NO",
  "  - Employment agency logistics: text describes the PROCESS of helping refugees",
  "    find work (counselling, placement, hotlines, 'holding discussions') WITHOUT",
  "    explicitly stating that this provides economic benefit to Germany = NO",
  "    Example: 'The agency will support refugees with job placement services' = NO",
  "  IMPORTANT DISTINCTION for B4:",
  "  - 'Agency helps refugees find work' (process description) = NO",
  "  - 'Refugees filling 3,000 vacant nursing positions' (vacancy filled) = YES",
  "  - 'Ministry proposes simplified visa for engineers to fill shortages' = YES",
  "  The key test: is a SPECIFIC LABOUR SHORTAGE being FILLED by immigration? YES.",
  "  Is a general support process being described? NO.",
  "  - Positive/solidarity framing: a warm tone, volunteer support, or successful",
  "    accommodation story does NOT count as B1-B5 unless an economic outcome is",
  "    explicitly named (tax revenue, GDP, labour shortage filled) = NO",
  "  - Cultural integration success (language learning, citizenship) WITHOUT an explicit",
  "    economic outcome — that is Kultur Benefit, not Wirtschaft Benefit",
  "  - Vague 'migrants contribute to society' without naming an economic mechanism",
  "  - Fachkräftemangel without any link to immigration as a solution",
  "  - General positive economic news not linked to immigration",
  "  - Donations, weapons deliveries",
  "  - Historical or international political/legal news (e.g., British India, China, UK Supreme Court) WITHOUT a direct economic benefit to Germany linked to immigration",
  "",
  "OUTPUT FORMAT — use exactly this, every row, no exceptions:",
  "Explanation: [One sentence: identify the sub-criterion B1–B5 and quote the exact",
  "phrase from the text that triggered YES — OR explain why none of B1–B5 applies]",
  "Label: YES",
  "",
  "OR:",
  "Explanation: [One sentence: explain why none of B1–B5 applies to this text]",
  "Label: NO",
  sep = "\n"
)

reminder_benefit <- paste(
  "Code YES if ANY of B1–B5 is explicitly mentioned.",
  "B4 triggers on: skills gap, labor shortage, vacancy filled, or immigration needed for labor.",
  "B5 triggers on: degree recognition, language courses, work permits, or LOST benefits due to these barriers.",
  "An explicit 'billions' or 'tax' figure is NOT required — 'finding work' or 'filling a gap' is enough.",
  "When in doubt, code NO.",
  sep = " "
)

# ── Reasoning versions (with 'Always provide explanation' added) ───

instructions_threat_cot <- paste(
  instructions_threat,
  "",
  "REASONING: Before writing your label, first identify which sub-criterion",
  "(T1, T2, T3, T4, or T5) applies and quote the specific phrase from the text.",
  "Write this as your Explanation. Then write your Label on the next line.",
  sep = "\n"
)

reminder_threat_cot <- paste(
  reminder_threat,
  "Write Explanation: first (name the sub-criterion and quote the phrase), then Label: on the next line."
)

instructions_benefit_cot <- paste(
  instructions_benefit,
  "",
  "REASONING: Before writing your label, first identify which sub-criterion",
  "(B1, B2, B3, B4, or B5) applies and quote the specific phrase from the text.",
  "Write this as your Explanation. Then write your Label on the next line.",
  sep = "\n"
)

reminder_benefit_cot <- paste(
  reminder_benefit,
  "Write Explanation: first (name the sub-criterion and quote the phrase), then Label: on the next line."
)

# Note: clean_label and clean_text_api moved to scripts/utils.R

cat("Config loaded (v1 Draft — SENIOR GUIDE). Method:", API_MODEL, "| Host:", API_HOST, "\n")

# ============================================================
# LOAD TRAINING BLOCKS (From WHERE_TO_ADD_TRAINING_BLOCKS.md)
# ============================================================
library(readr); library(dplyr)

# Check if training blocks file exists before loading
TRAINING_BLOCKS_FILE <- "data/fewshot/fewshot_training_blocks.csv"

if (file.exists(TRAINING_BLOCKS_FILE)) {
  training <- read_csv(TRAINING_BLOCKS_FILE, show_col_types = FALSE)
  
  # ── THREAT few-shot set ──────────────────────────────────────
  fewshot_threat <- training %>%
    filter(dimension %in% c("threat", "both")) %>%
    select(input, label, explanation)
  
  # ── BENEFIT few-shot set ─────────────────────────────────────
  fewshot_benefit <- training %>%
    filter(dimension %in% c("benefit", "both")) %>%
    select(input, label, explanation)
  
  # ── STARTER SET (6 blocks — Step 4 recommendation) ───────────
  fewshot_threat_starter <- training %>%
    filter(dimension %in% c("threat","both"),
           sub_criterion %in% c(
             "T4",                    # welfare YES — Hartz-IV example
             "T5",                    # capacity cost YES — billions in expenditure
             "EXCL-donation",         # Red Cross / aid / relief = NO
             "EXCL-weapons",          # military / weapons deliveries = NO
             "EXCL-war",              # war/conflict without cost = NO
             "EXCL-general-economy"   # sanctions / inflation without immigration = NO
           )) %>%
    group_by(sub_criterion) %>%
    slice(1) %>%
    ungroup() %>%
    select(input, label, explanation) %>%
    mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))
  
  fewshot_benefit_starter <- training %>%
    filter(dimension %in% c("benefit","both"),
           sub_criterion %in% c(
             "B4",                              # Fachkräftemangel + immigration YES
             "B5",                              # lost benefits YES
             "B3",                              # demographic necessity YES
             "EXCL-cultural",                   # cultural integration without economic = NO
             "EXCL-fachkraefte-no-migration"    # Fachkräftemangel without immigration = NO
           )) %>%
    group_by(sub_criterion) %>%
    slice(1) %>%
    ungroup() %>%
    select(input, label, explanation) %>%
    mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))
    
  # ── ADD TARGETED EXAMPLES (Iteration 6) ─────────────────────
  
  threat_extra <- tibble::tibble(
    input = paste(
      "The district administrator reported that all available spaces for",
      "[Group 1] are full. The municipality is renting additional private",
      "apartments at considerable cost and is under significant financial",
      "pressure to find more solutions before winter."
    ),
    label = "YES",
    explanation = paste(
      "T5: 'renting additional private apartments at considerable cost' and",
      "'significant financial pressure' are explicit financial burden language",
      "caused by immigration — no euro amount required for T5 to apply."
    )
  ) %>% mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))
  
  fewshot_threat_starter <- bind_rows(fewshot_threat_starter, threat_extra)
  
  benefit_extra <- tibble::tibble(
    input = c(
      # B5 — degree recognition 
      paste(
        "To help refugees integrate into the labour market, we must accelerate",
        "the recognition of their foreign qualifications. Many skilled workers",
        "remain unemployed because they are still waiting for their degrees",
        "to be approved by the authorities."
      ),
      # B4 — labor shortage 
      paste(
        "Local companies are desperately looking for staff. Immigration from",
        "[Group 1] is a major opportunity to fill these vacancies and ensure",
        "that our regional economy remains competitive."
      ),
      # NO — logistical status (work permit)
      paste(
        "Unlike other groups, refugees from [Other Group] receive a residence",
        "title immediately upon arrival. This means they are automatically",
        "entitled to social benefits and receive a work permit right away."
      )
    ),
    label = c("YES", "YES", "NO"),
    explanation = c(
      paste(
        "B5: 'recognition of their foreign qualifications' and 'remain unemployed",
        "because they are still waiting' indicates lost economic benefit due to",
        "missing integration measures."
      ),
      paste(
        "B4: 'fill these vacancies' and 'ensure economy remains competitive'",
        "explicitly links immigration to solving a labour shortage."
      ),
      paste(
        "NO: stating that a 'work permit' or 'entitlement' exists as a matter",
        "of legal status is a logistical fact and NOT an economic benefit frame."
      )
    )
  ) %>% mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))
  
  fewshot_benefit_starter <- bind_rows(fewshot_benefit_starter, benefit_extra)
  
  # ── ADD TARGETED NO EXAMPLE (Iteration 8) ────────────────────
  
  benefit_no_extra <- tibble::tibble(
    input = paste(
      "[Group 1] who arrive in Germany under the temporary protection",
      "directive do not have to go through the asylum process.",
      "They can start working immediately and are free to move around",
      "Germany without restrictions."
    ),
    label = "NO",
    explanation = paste(
      "NO — 'can start working immediately' and 'free to move' describe",
      "legal STATUS rights, not an explicit economic benefit.",
      "B4/B5 requires the text to name a specific economic outcome:",
      "a labour shortage filled, tax revenue generated, or economic value",
      "explicitly stated. Describing a legal right to work is NOT sufficient."
    )
  ) %>% mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))
  
  fewshot_benefit_starter <- bind_rows(fewshot_benefit_starter, benefit_no_extra)
  
  benefit_no_students <- tibble::tibble(
    input = paste(
      "The University has announced ten scholarships for [Group 1] students",
      "to join the economics department. This was made possible by the",
      "dedicated support of researchers who moved here years ago."
    ),
    label = "NO",
    explanation = paste(
      "NO — scholarship offers or university positions for students are",
      "academic/humanitarian support, not an explicit economic benefit frame",
      "like labor market entry or GDP growth."
    )
  ) %>% mutate(input = clean_text_api(input), explanation = clean_text_api(explanation))
  
  fewshot_benefit_starter <- bind_rows(fewshot_benefit_starter, benefit_no_students)
  
  cat("Training blocks loaded:", nrow(training), "blocks.\n")
  cat("Threat starter rows:", nrow(fewshot_threat_starter), "\n")
  cat("Benefit starter rows:", nrow(fewshot_benefit_starter), "\n")
} else {
  cat("WARNING: fewshot_training_blocks.csv not found. Falling back to data/fewshot/fewshot_examples.csv.\n")
  fallback <- read_csv("data/fewshot/fewshot_examples.csv", show_col_types = FALSE)
  fewshot_threat <- fallback %>% filter(dimension == "threat") %>% select(input, label, explanation)
  fewshot_benefit <- fallback %>% filter(dimension == "benefit") %>% select(input, label, explanation)
}
