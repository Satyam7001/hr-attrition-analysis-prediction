# HR Attrition Analysis & Flight Risk Prediction

## Business Problem
The Bangalore office showed a significantly higher employee attrition rate than the company's other five locations, driving up hiring costs and disrupting ongoing projects. Leadership needed to understand what was driving this and whether at-risk employees could be identified before they resigned.

## Data
204,000 employee records (cleaned to 201,000 after deduplication), covering location, department, tenure, compensation, performance, satisfaction, and attrition status. The raw data reflected a real production export and required substantial cleaning:
- Location recorded under 5+ inconsistent spellings (Bangalore/bangalore/Banglore/Bengaluru, etc.)
- Mixed date formats (ISO, DD-MM-YYYY, MM/DD/YYYY) in join and exit dates
- Biologically impossible age values (17, 99)
- Casing and spacing inconsistencies across department and gender fields

## Approach
1. **Cleaned the data in PostgreSQL** — removed 3,000 exact duplicates, standardized location into 6 clean city names, resolved mixed-format dates using per-row pattern detection, and set impossible age values to null rather than guessing (resulting in ~75% of age data being excluded as unusable — stated explicitly as a limitation).
2. **Tested 5 hypotheses** about attrition drivers using rate comparisons (not raw counts) within Bangalore specifically: overtime, job satisfaction, commute distance, salary hike percentage, and tenure. All five were confirmed as real, ranked by effect size.
3. **Built a predictive model** in Python (scikit-learn) to flag individual flight risk. An initial logistic regression model achieved 67% accuracy but only 13% recall on actual leavers — a naive, misleading result driven by class imbalance. Applying `class_weight='balanced'` and comparing against a Random Forest improved recall to 58%, a trade-off against precision (~43%) that was judged acceptable given the low cost of a manager check-in versus the high cost of an unanticipated resignation.
4. Caught and corrected a target leakage bug during model preparation (a duplicate attrition column had been accidentally included as a feature).

## Key Findings

| Driver | Effect Size | Comparison |
|---|---|---|
| Job satisfaction | ~13 pp | Low: ~52% attrition vs High: ~39-40% |
| Overtime | ~9 pp | Yes: 50.9% vs No: 41.9% |
| Salary hike % | ~8 pp | Low (<6%): 51.4% vs Normal/High: 43.4% |
| Commute distance | ~7.4 pp | Long (>25km): 51.3% vs Short: 43.9% |
| Tenure | ~5.3 pp | Under 1yr: 49.3% vs 1+yr: 44.0% |

**Job satisfaction is the strongest single driver** — confirmed independently by both direct rate comparison and the predictive model's feature importance ranking, where it carried more than double the weight of any other factor.

**A residual, unexplained Bangalore-specific effect remains** even after controlling for all five factors together, suggesting a location-specific issue (e.g. management practices, local job market) not captured by current data.

## Recommendations
- Prioritize employee satisfaction initiatives in Bangalore first — the highest-leverage intervention identified.
- Review mandatory overtime in Bangalore, which accounts for a disproportionate share of company-wide overtime hours.
- Reassess the salary hike floor for employees receiving below 6%.
- Deploy the predictive model as an early screening tool for proactive manager check-ins, not as a certainty about any individual.
- Investigate the unexplained Bangalore-specific effect through direct employee feedback (exit interviews, surveys).

## Tools
- **PostgreSQL** — data cleaning, hypothesis testing
- **Python (pandas, scikit-learn)** — predictive modeling
- **Matplotlib** — visualizations

## Files
- `project3_hr_raw.csv` — raw source data
- `hr_clean.csv` — cleaned dataset
- `hr_clean.sql` — SQL cleaning and hypothesis-testing scripts
- `hr_prediction_model.ipynb` — model building notebook
- `attrition_by_location.png`, `drivers_ranked.png`, `feature_importance.png` — supporting charts
- `Project3_Key_Insights.pdf` — polished summary of findings
- `Project3_HR_Attrition_Complete.pdf` — full technical documentation
