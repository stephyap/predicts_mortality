# Predicting Mortality for Subarachnoid Hemorrhage Patients

### Authors: Brian Bacik, Chiu-Feng Yap, Joy Yoo, Yi Yao, Yun Qing

### -- Project Status: [Completed]

### -- Project Ranking: 3/15

# Introducction

Subarachnoid Hemorrhage (SAH) is a type of stroke that commonly affects individuals who had head traumas. Among individuals without head trauma, SAH is most commonly caused by a brain ruptured aneurysm. SAH is life-threatening and can reduce the quality of years of individuals who survive. The main treatment for patients with SAH is not limited to IV fluid, but vasopressors, such as dopamine, phenylephrine, and norepinephrine that help patients with SAH to elevate their blood pressures. Patients who have three of these vasopressors as their treatment are considered more severe cases and that makes up to almost 10% of patients with SAH. Unfortunately, there are no standardized guidelines for distinguishing these patients.

The objective of this project is to predict the risk of the adverse outcome for SAH patients defined as in-hospital death or discharge to hospice care, a binary classification problem, on day 3 since admission using baseline demographics, medications administered, and procedures conducted information extracted from the Cerner Health Facts EMR database. 

# Methods Used:
* Categorical variable encoding
* Feature engineering
* Hyperparameter tuning
* Dimension reduction (forward stepwise selection method) 

# Models Used:
* Logistic Regression Classifier
* Lasso Regression 
* Elastic Net
* Support Vector Machine
* Random Forest
* XGBoost Classifier

# Performance Results on Validation Set
| Model  | AUC | Accuracy | Sensitivity (TPR)  |  Specificity (TNR) |
| ------ | --- | -------- | ------------------ |  ----------------- |
| GBM |	0.871 |	0.823 |	0.377  | 0.972|
| Random Forest | 0.861	 | 0.824	 | 0.438  | 	0.962  | 
|GBM (SMOTE)| 0.868	| 0.836	| 0.460	| 0.962| 
|GBM (Reduced)| 	0.868| 	0.822| 	0.374| 	0.972| 
|RF (Reduced)	| 0.861| 	0.831| 	0.472 | 	0.957| 
|Logistic Regression (Full)	| 0.861 | 0.828 | 0.684 | 	0.866| 
|Logistic Regression (Reduced)	| 0.856| 	0.826| 	0.710 | 	0.851| 
|Lasso (Lambda.min)	| 0.867| 	0.836| 	0.748| 	0.855| 
|Lasso (Lambda.1se)	| 0.865| 	0.830| 	0.751| 	0.845| 
|Elastic Net |	0.846	| 0.825| 	0.533| 	0.924| 
|SVM (radial kernel)	| 0.865| 	0.842| 	0.569| 	0.933| 
|Super Learner	| 0.850	| 0.823	0.500| 	0.932| 

