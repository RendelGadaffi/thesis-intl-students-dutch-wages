# QUESTIONS & ANSWERS
## Presenter Reference — All Q: Interactive Questions from the Deck

This document collects every Q: interactive question from the slide deck, paired with target/sample answers and presenter tips for handling classroom dynamics. Use this to prepare delivery, anticipate silence, and deepen discussion.

---

## Slide: [Tidy] [Group] [Predict] Overview (Three Skills)

**Q:** You're handed a CSV. Column names have spaces and dollar signs. Some cells are blank. Three rows look identical. One salary says **$856,580** when the max should be ~$150K. What do you do **first**?

**Target Answer:**  
Don't panic — start by **loading the file and inspecting it**. Use `df.info()` to see column types, null counts, and shape. Then systematically: (1) rename columns to lowercase with underscores, (2) drop missing salaries, (3) drop duplicate rows, (4) investigate the outlier with a boxplot, (5) split the mangled department column. The *first* concrete action: `df = pd.read_csv("file.csv")` then `df.info()`.

**Presenter Tip:**  
If nobody volunteers, prompt with: *"What's the first line of code you'd type after opening your laptop?"* Guide toward `pd.read_csv()` + `df.info()`. Then say: *"Let's see what happens when we run it* — transitions naturally into Part 1 (Tidying).

---

## Slide: [Quick] Quick Setup

**Q:** Q: Raise your hand when you see a version number. Don't move on until everyone has it.

**Target Answer:**  
No verbal answer needed — this is a **visual check-in**. Students should have a terminal/window showing `pandas.__version__` printed (e.g., `2.0.3`). The goal is to confirm every environment is working before the practical begins.

**Presenter Tip:**  
Scan the room. If ~80% have hands up, say *"I see most of you — shout out 'got it' if yours is working"* to flush out the last few. For stragglers: *"Pair up with your neighbour who has it working."* Don't proceed until everyone is green-lit — you'll lose people immediately in Part 1 otherwise.

---

## Slide: [Folder] Load the Mess (Part 1 — Tidying)

**Q:** 504 rows when there should be 500. What's going on?

**Target Answer:**  
The dataset has **4 extra rows** introduced by data quality issues: 3 duplicate rows (same data repeated) and 1 outlier row (the $856,580 salary — which is also an extra row if the original DGP aimed for 500 clean records). In practice, extra rows come from: re-imports, bad joins, accidental copy-paste in spreadsheets, or data entry forms saving twice. The count itself (504 vs 500) is the **first signal that something is wrong** — it forces you to `dropna()` and `drop_duplicates()`.

**Presenter Tip:**  
Let the audience guess freely — *"Data entry glitch?"*, *"Merged two files?"*. Validate each guess briefly, then reveal: *"Let's run the code and find out."* This is a low-stakes warm-up question; keep it < 30 seconds. Follow-up: *"504 to 475 — that's a 6% data loss. Is that okay?"* (Answer: losing 6% due to actual defects is fine; losing 6% randomly is not.)

---

## Slide: [Fix] Fix 2 & 3 — Missing + Duplicates

**Q:** Q: How do duplicates happen? *(Export errors, merge bugs, human copy-paste.)*

**Target Answer:**  
Common causes:  
- **Export errors:** A database query runs twice and appends to the same CSV.  
- **Merge bugs:** An `inner` join used where a `left` join was intended, inflating rows.  
- **Human copy-paste:** Someone manually appends data in Excel and accidentally includes a header row or duplicated selection.  
- **API pagination:** A script fetches page 1 and page 2 but doesn't track already-seen rows.  
- **Cron overlaps:** Two scheduled jobs write to the same file simultaneously.

**Presenter Tip:**  
The answer is in parentheses on the slide — read it dramatically: *"I'll give you three — export errors, merge bugs, human copy-paste. Can anyone add a fourth?"* Wait 5 seconds. If no one adds one, move on. This question is a quick comprehension check, not a deep discussion. Keep it snappy.

---

## Slide: [Tidy] Tidying — Why It Matters

**Q:** Q: What if you skip tidying?

**Target Answer:**  
Three concrete consequences (from the slide):  
1. **Outlier ($857K)** → Regression experience coefficient inflates by ~$300/year, making experience look more valuable than it is.  
2. **Duplicates** → p-values look more significant than they really are (artificially inflated sample size).  
3. **Bad column names** → 5-minute debugging sessions hunting for `KeyError: 'annual_salary'` when the column is actually `'Annual Salary ($)'`.

Broader takeaway: **Tidying is not busywork.** It is the difference between a finding and a mistake. Published retractions often trace back to data that was never properly inspected.

**Presenter Tip:**  
This is a **rhetorical question** with answers already on the slide. Read it aloud and point to each bullet. Then ask: *"Has anyone here ever skipped cleaning, got a 'significant' result, then realized it was a bug?"* Sharing a personal war story from your own experience works well here (5–10 seconds). This slide closes Part 1 — let it land with a pause.

---

## Slide: [Group] `groupby()` — When You Have Labels (Part 2 — Grouping)

**Q:** Q: Discuss with your neighbour (30 sec): If you had **ONE billboard ad**, which segment do you target and **why**? Defend your answer with a number from this table.

**Target Answer:**  
Two defensible answers:

| Segment | Argument | Number |
|:--|:--|:--|
| **Whales** | Highest spend per customer — one whale is worth ~7.6 budget shoppers | $9,377/yr vs $1,239/yr |
| **Premium Loyalists** | Highest loyalty (7.3 yr) — best LTV over time; also medium spend × high retention | 7.3 yr loyalty × $4,454/yr = ~$32,500 lifetime |

The *best* answer depends on the business goal: short-term revenue (Whales) vs long-term retention (Premium Loyalists). Budget Shoppers are the weakest choice (lowest spend, low loyalty).

**Presenter Tip:**  
Set a timer! *"30 seconds — go!"* Walk around. After time, call on 2–3 pairs. Expect the Whale answer first. Follow-up: *"What if the billboard costs $50,000? Does that change your answer?"* (Yes — you'd need ~6 whales or ~12 premium loyalists to break even.) If nobody answers, pick a random pair and say *"You two — what did you discuss?"*

---

## Slide: Q: What If You DON'T Have Labels?

**Q:** Q: Before we run it — guess how many groups exist in this data.

**Target Answer:**  
**Three.** The dataset has 3 known segments (Whale, Premium Loyalist, Budget Shopper). Students who look at the scatter plot snippet (spend vs visits) should see three visual clusters. If someone says "2" or "4", that's fine — the elbow method later will confirm K=3.

**Presenter Tip:**  
Take a **quick show of hands**: *"How many say 2? 3? 4?"* Usually >50% say 3. If they're split, tease: *"We're about to find out who's right."* This builds anticipation for running K-Means. If the room is silent, guess yourself: *"I think 3 — let's see."*

---

## Slide: [Group] Grouping — Your Toolkit

**Q:** Q: FINAL GROUPING QUESTION: You're the marketing director. Budget covers **ONE email campaign**. Which segment — and defend with a number from the groupby table.

**Target Answer:**  
This is a **reprise** of the billboard question (slide ~15) but with a different channel (email vs billboard). The numbers change the analysis:

| Segment | Spend/yr | Basket | Loyalty | Best for email? |
|:---|---:|---:|---:|:--|
| **Whales** | $9,377 | $117.10 | 5.1 yr | [OK] Best ROI — highest per-email revenue |
| **Premium Loyalist** | $4,454 | $53.50 | 7.3 yr | [OK] Best for long-term nurturing |
| **Budget Shopper** | $1,239 | $21.90 | 2.7 yr | [No] Low-value per message |

**Best answer:** **Whales** — $9,377/yr annual spend is **7.6×** a Budget Shopper. Email is cheap per message, so you maximize return by targeting highest-value customers. *Runner-up: Premium Loyalists if the goal is retention/upsell.*

**Presenter Tip:**  
Compare this to the billboard question. *"Notice I changed the channel — email is cheap, billboard is expensive. Does your answer change?"* The shift (Whales for billboard vs Whales for email) is the same, but the *reasoning* differs: billboard is about reach, email is about precision. If a student changes their answer, praise them — *"That's the right instinct — the medium changes the math."*

---

## Slide: [Data] Explore — Experience vs Salary (Part 3 — Prediction)

**Q:** Q: Correlation is 0.888. Is that "good"? What does it actually **MEAN**?

**Target Answer:**  
**"Good" depends on context** — but in social science data, r = 0.888 is **very strong**. It means:  
- There is a strong **positive linear relationship** between experience and salary.  
- As experience increases, salary tends to increase.  
- R² = 0.888² ≈ **0.789** — meaning experience alone explains ~79% of the variation in salary.  
- 0.888 is the **Pearson correlation coefficient**; it measures linear association, not causation.

**Presenter Tip:**  
If someone says *"Yeah, that's good!"*, push back: *"What's the threshold for 'good' in your field?"* (Psychology: r > 0.5 is large; Physics: r = 0.999 is expected; Economics: r = 0.3 is notable.) The point is that **r = 0.888 in salary data is suspiciously high** — in the real world, individual salaries are noisy and experience rarely explains this much. Tease: *"This is synthetic data — that's why the correlation is so clean."*

---

## Slide: [Stats] Your First Regression

**Q:** Q: `salary ~ experience` — what does the `~` mean in plain English?

**Target Answer:**  
**"Is modelled as a function of"** or **"is predicted by"**. In R/statsmodels formula syntax, the `~` separates the dependent variable (left) from the independent variables (right). Plain English: *"Salary is predicted by experience"* or *"We model salary as a function of experience."*

**Presenter Tip:**  
This is a **pop quiz** for students new to formula syntax. If they look confused, say *"Think of it as an arrow"* and draw on the board/air: `salary ← experience`. If someone says *"equals"* or *"depends on"*, validate: *"Close enough — 'depends on' is the right intuition."* Keep this under 20 seconds; it's a terminology check.

---

## Slide: [Add] Add More Variables

**Q:** Q: The experience coef was **$2,228** in Model 1. Now it's **$2,183**. Why did it change?

**Target Answer:**  
**Omitted variable bias.** In Model 1 (just `experience`), the coefficient absorbed the effect of omitted variables that correlate with both experience and salary — particularly `education`, `is_manager`, and `hours`. More experienced workers are also more likely to be managers and have higher education. When you add those controls to Model 2, the experience coefficient **shrinks toward its true partial effect** — the effect of experience *holding education, management status, and hours constant*. The drop ($2,228 → $2,183 = −$45/year) is modest because the controls are relatively balanced across experience levels, but the direction (down) is expected.

**Presenter Tip:**  
This is the **most important conceptual question in the deck**. Spend time here. Draw on the board or air: two parallel lines — Model 1 (total effect = $2,228) vs Model 2 (partial effect = $2,183). Ask: *"Which one is the 'true' effect of experience?"* (Answer: Model 2 is closer to the truth because it holds other factors constant.) If nobody answers, walk through it: *"Are managers more experienced on average? Yes. So Model 1 gave experience 'credit' for the manager effect. Model 2 separates them."*

---

## Slide: [Advanced] The Bleeding Edge — Beyond OLS

**Q:** Q: If XGBoost predicts better, why ever use OLS?

**Target Answer:**  
Three reasons:

1. **Interpretability** — OLS gives you a clear, defensible statement: *"Each year of experience adds $2,167 to salary, and we're 99.999% confident."* You can say this to a boss, a journal reviewer, a regulator, or a court. With XGBoost, you get feature importance — useful, but not a causal or precise statement.

2. **Inference vs Prediction** — OLS is for **understanding** (What drives salary? Is the effect statistically significant?). XGBoost is for **predicting** (What will this person's salary be?). Different tools for different jobs.

3. **Transparency + Assumptions** — OLS assumptions (linearity, normality, homoscedasticity) can be checked and violated assumptions can be addressed. A black-box model's failure modes are harder to diagnose.

**Presenter Tip:**  
Quote the slide directly — it's the strongest line in the deck: *"'Salary goes up by $2,167/year and we're 99.999% confident' — you can defend that to a boss, a journal, or a court. 'The black box says so' — you can't."* Ask: *"Has anyone ever had to defend a model to a non-technical stakeholder?"* If yes, let them share. This is the closing philosophical question of the workshop — end on the quote, then transition to the toolkit slide.

---

## Summary: Quick Reference

| # | Slide | Type | Question Summary |
|:-:|:--|:--:|:--|
| 1 | [Tidy] [Group] [Predict] Overview | Warm-up | What do you do first with a messy CSV? |
| 2 | [Quick] Quick Setup | Check-in | Raise your hand when you see a version number |
| 3 | [Folder] Load the Mess | Comprehension | 504 rows vs 500 — what's happening? |
| 4 | [Fix] Fix 2 & 3 | Comprehension | How do duplicates happen? |
| 5 | [Tidy] Why It Matters | Rhetorical | What if you skip tidying? |
| 6 | [Group] groupby() | Discussion | Which segment for ONE billboard ad? |
| 7 | Q: No Labels | Prediction | Guess how many groups exist |
| 8 | [Group] Grouping Toolkit | Discussion | Which segment for ONE email campaign? |
| 9 | [Data] Explore | Comprehension | r = 0.888 — is that good? What does it mean? |
| 10 | [Stats] First Regression | Terminology | What does `~` mean in plain English? |
| 11 | [Add] Add More Variables | **Core concept** | Why did the coefficient change? (Omitted variable bias) |
| 12 | [Advanced] Beyond OLS | Philosophical | Why use OLS if XGBoost predicts better? |

---

*Total: 12 interactive questions/prompts across ~29 slides. Estimated discussion time: 8–12 minutes total if each question runs 30–60 seconds. Budget extra time (~3–5 min) for question #11 (omitted variable bias) — it is the single most important conceptual moment in the workshop.*
