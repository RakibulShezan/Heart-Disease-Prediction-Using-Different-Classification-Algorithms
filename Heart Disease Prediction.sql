%sql
select * 
from heartdisease_data;


Total Patients Based on Chest Pain Type
%sql
select cp,count(*) as Total
from HEARTDISEASE_DATA
group by cp

Number of heart disease patient based on their age
%sql

select age, count(target) AS TARGET
from heartdisease_data
where target = 1
group by age;

Total Heart Disease Based on Cholesterol

%sql
SELECT COUNT(TARGET)
FROM HEARTDISEASE_DATA
WHERE TARGET = 1 and CHOL>=200;  

Total Heart  Disease Patients based on Sex

%sql
SELECT SEX,COUNT(TARGET)
FROM HEARTDISEASE_DATA
WHERE TARGET = 1
GROUP BY SEX;


Create a Sequence 
%sql
CREATE SEQUENCE "PERSON_SEQUENCE" START WITH 1 INCREMENT BY 1;

%sql
ALTER TABLE heartdisease_data ADD (PERSON_ID NUMBER);

%sql
UPDATE heartdisease_data SET PERSON_ID = person_sequence.NEXTVAL;

%sql
select * 
from heartdisease_data;

Create Views
%script

CREATE OR REPLACE VIEW HEARTDISEASE_VIEW
  AS SELECT PERSON_ID,AGE,SEX,CP,TRESTBPS,CHOL,FBS,RESTECG,THALACH,EXANG,OLDPEAK,SLOPE,CA,THAL,TARGET
  FROM heartdisease_data;
Settings Table Creation
%sql
CREATE TABLE nn_settings (
  setting_name VARCHAR2(30),
  setting_value VARCHAR2(4000));

Train Test Split
%script

CREATE OR REPLACE VIEW TRAIN_DATA_CLAS AS SELECT * FROM heartdisease_view SAMPLE (70) SEED (1);
CREATE OR REPLACE VIEW TEST_DATA_CLAS AS SELECT * FROM heartdisease_view MINUS SELECT * FROM TRAIN_DATA_CLAS;


Decision Tree
%script

BEGIN DBMS_DATA_MINING.DROP_MODEL('CLASS_MODEL');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
    
BEGIN
    v_setlst('PREP_AUTO') := 'ON';
    v_setlst('ALGO_NAME') := 'ALGO_DECISION_TREE';
    
    DBMS_DATA_MINING.CREATE_MODEL2(
        'CLASS_MODEL',  --model_name
        'CLASSIFICATION', --The mining function,
        'SELECT * FROM TRAIN_DATA_CLAS',  --Train Data set,
        v_setlst,  --Settings Table
        'PERSON_ID', --case identifier
        'TARGET');
END;

Naive Bayes

%script

BEGIN DBMS_DATA_MINING.DROP_MODEL('NAIVE_BAYES');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
    
BEGIN
    v_setlst('PREP_AUTO') := 'ON';
    v_setlst('ALGO_NAME') := 'ALGO_NAIVE_BAYES';
    
    DBMS_DATA_MINING.CREATE_MODEL2(
        'NAIVE_BAYES',  --model_name
        'CLASSIFICATION', --The mining function,
        'SELECT * FROM TRAIN_DATA_CLAS',  --Train Data set,
        v_setlst,  --Settings Table
        'PERSON_ID', --case identifier
        'TARGET');
END;

Random Forest
%script

BEGIN DBMS_DATA_MINING.DROP_MODEL('RANDOM_FOREST');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
    
BEGIN
    v_setlst('PREP_AUTO') := 'ON';
    v_setlst('ALGO_NAME') := 'ALGO_RANDOM_FOREST';
    
    DBMS_DATA_MINING.CREATE_MODEL2(
        'RANDOM_FOREST',  --model_name
        'CLASSIFICATION', --The mining function,
        'SELECT * FROM TRAIN_DATA_CLAS',  --Train Data set,
        v_setlst,  --Settings Table
        'PERSON_ID', --case identifier
        'TARGET');
END;

Support Vector Machine
%script

BEGIN DBMS_DATA_MINING.DROP_MODEL('SVM');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
DECLARE
    v_setlst DBMS_DATA_MINING.SETTING_LIST;
    
BEGIN
    v_setlst('PREP_AUTO') := 'ON';
    v_setlst('ALGO_NAME') := 'ALGO_SUPPORT_VECTOR_MACHINES';
    
    DBMS_DATA_MINING.CREATE_MODEL2(
        'SVM',  --model_name
        'CLASSIFICATION', --The mining function,
        'SELECT * FROM TRAIN_DATA_CLAS',  --Train Data set,
        v_setlst,  --Settings Table
        'PERSON_ID', --case identifier
        'TARGET');
END;

Neural Network%script
BEGIN EXECUTE IMMEDIATE 'DELETE FROM nn_settings PURGE';
    
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN 
    INSERT INTO nn_settings (setting_name, setting_value) VALUES
                   ('NNET_NODES_PER_LAYER', '128,1');
    INSERT INTO nn_settings (setting_name, setting_value) VALUES
                   ('NNET_ACTIVATIONS', '''NNET_ACTIVATIONS_TANH'', ''NNET_ACTIVATIONS_LOG_SIG''');
    INSERT INTO nn_settings (setting_name, setting_value) VALUES
     ('ALGO_NAME', 'ALGO_NEURAL_NETWORK');
  COMMIT;
END;
/
BEGIN DBMS_DATA_MINING.DROP_MODEL('neural_network');
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
DBMS_DATA_MINING.CREATE_MODEL(
model_name          => 'neural_network',
mining_function     => dbms_data_mining.classification,
data_table_name     => 'TRAIN_DATA_CLAS',
case_id_column_name => 'PERSON_ID',
target_column_name  => 'TARGET',
settings_table_name => 'nn_settings');
END;
/

Evaluate Model: DECISION TREE

%script
BEGIN EXECUTE IMMEDIATE 'DROP TABLE APPLY_RESULT_DT PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE LIFT_TABLE_DT PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_DATA_MINING.APPLY('CLASS_MODEL','TEST_DATA_CLAS','PERSON_ID','APPLY_RESULT_DT');
  DBMS_DATA_MINING.COMPUTE_LIFT('APPLY_RESULT_DT','TEST_DATA_CLAS','PERSON_ID','TARGET',
                                'LIFT_TABLE_DT','1','PREDICTION','PROBABILITY',100);
END;
/


Evaluate Model: NAIVE BAYES

%script
BEGIN EXECUTE IMMEDIATE 'DROP TABLE APPLY_RESULT_NB PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE LIFT_TABLE_NB PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_DATA_MINING.APPLY('NAIVE_BAYES','TEST_DATA_CLAS','PERSON_ID','APPLY_RESULT_NB');
  DBMS_DATA_MINING.COMPUTE_LIFT('APPLY_RESULT_NB','TEST_DATA_CLAS','PERSON_ID','TARGET',
                                'LIFT_TABLE_NB','1','PREDICTION','PROBABILITY',100);
END;
/
Evaluate Model: RANDOM FOREST

%script

BEGIN EXECUTE IMMEDIATE 'DROP TABLE APPLY_RESULT_RF PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE LIFT_TABLE_RF PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_DATA_MINING.APPLY('RANDOM_FOREST','TEST_DATA_CLAS','PERSON_ID','APPLY_RESULT_RF');
  DBMS_DATA_MINING.COMPUTE_LIFT('APPLY_RESULT_RF','TEST_DATA_CLAS','PERSON_ID','TARGET',
                                'LIFT_TABLE_RF','1','PREDICTION','PROBABILITY',100);
END;
/

Evaluate Model: SVM

%script
BEGIN EXECUTE IMMEDIATE 'DROP TABLE APPLY_RESULT_SVM PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE LIFT_TABLE_SVM PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_DATA_MINING.APPLY('SVM','TEST_DATA_CLAS','PERSON_ID','APPLY_RESULT_SVM');
  DBMS_DATA_MINING.COMPUTE_LIFT('APPLY_RESULT_SVM','TEST_DATA_CLAS','PERSON_ID','TARGET',
                                'LIFT_TABLE_SVM','1','PREDICTION','PROBABILITY',100);
END;
/

Evaluate Model: NEURAL NETWORKS

%script

BEGIN EXECUTE IMMEDIATE 'DROP TABLE APPLY_RESULT_NN PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE LIFT_TABLE_NN PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
  DBMS_DATA_MINING.APPLY('neural_network','TEST_DATA_CLAS','PERSON_ID','APPLY_RESULT_NN');
  DBMS_DATA_MINING.COMPUTE_LIFT('APPLY_RESULT_NN','TEST_DATA_CLAS','PERSON_ID','TARGET',
                                'LIFT_TABLE_NN','1','PREDICTION','PROBABILITY',100);
END;

Accuracy Measure on Test Data

%script
SET FEEDBACK OFF;
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dt_confusion_matrix PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DELETE FROM MODEL_ACCURACY PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
   v_accuracy    NUMBER;
   BEGIN
        DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
                   accuracy                     => v_accuracy,
                   apply_result_table_name      => 'APPLY_RESULT_DT',
                   target_table_name            => 'TEST_DATA_CLAS',
                   case_id_column_name          => 'PERSON_ID',
                   target_column_name           => 'TARGET',
                   confusion_matrix_table_name  => 'dt_confusion_matrix',
                   score_column_name            => 'PREDICTION',
                   score_criterion_column_name  => 'PROBABILITY',
                  score_criterion_type         => 'PROBABILITY');
        DBMS_OUTPUT.PUT_LINE('****Decision Tree MODEL ACCURACY ****: ' || (ROUND(v_accuracy,4))*100 ||'%');
        INSERT INTO MODEL_ACCURACY VALUES('Decision Tree', (ROUND(v_accuracy,4))*100);
      END;
      /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE nb_confusion_matrix PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
   v_accuracy    NUMBER;
   BEGIN
        DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
                   accuracy                     => v_accuracy,
                   apply_result_table_name      => 'APPLY_RESULT_NB',
                   target_table_name            => 'TEST_DATA_CLAS',
                   case_id_column_name          => 'PERSON_ID',
                   target_column_name           => 'TARGET',
                   confusion_matrix_table_name  => 'nb_confusion_matrix',
                   score_column_name            => 'PREDICTION',
                   score_criterion_column_name  => 'PROBABILITY',
                  score_criterion_type         => 'PROBABILITY');
        DBMS_OUTPUT.PUT_LINE('****NAIVE BAYES MODEL ACCURACY ****: ' || (ROUND(v_accuracy,4))*100 ||'%');
        INSERT INTO MODEL_ACCURACY VALUES('NAIVE BAYES', (ROUND(v_accuracy,4))*100);
      END;
      /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE rf_confusion_matrix PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
   v_accuracy    NUMBER;
   BEGIN
        DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
                   accuracy                     => v_accuracy,
                   apply_result_table_name      => 'APPLY_RESULT_RF',
                   target_table_name            => 'TEST_DATA_CLAS',
                   case_id_column_name          => 'PERSON_ID',
                   target_column_name           => 'TARGET',
                   confusion_matrix_table_name  => 'rf_confusion_matrix',
                   score_column_name            => 'PREDICTION',
                   score_criterion_column_name  => 'PROBABILITY',
                  score_criterion_type         => 'PROBABILITY');
        DBMS_OUTPUT.PUT_LINE('****RANDOM FOREST MODEL ACCURACY ****: ' || (ROUND(v_accuracy,4))*100 ||'%');
        INSERT INTO MODEL_ACCURACY VALUES('RANDOM FOREST', (ROUND(v_accuracy,4))*100);
      END;
      /
BEGIN EXECUTE IMMEDIATE 'DROP TABLE svm_confusion_matrix PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
   v_accuracy    NUMBER;
   BEGIN
        DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
                   accuracy                     => v_accuracy,
                   apply_result_table_name      => 'APPLY_RESULT_SVM',
                   target_table_name            => 'TEST_DATA_CLAS',
                   case_id_column_name          => 'PERSON_ID',
                   target_column_name           => 'TARGET',
                   confusion_matrix_table_name  => 'svm_confusion_matrix',
                   score_column_name            => 'PREDICTION',
                   score_criterion_column_name  => 'PROBABILITY',
                  score_criterion_type         => 'PROBABILITY');
        DBMS_OUTPUT.PUT_LINE('****SVM MODEL ACCURACY ****: ' || (ROUND(v_accuracy,4))*100 ||'%');
        INSERT INTO MODEL_ACCURACY VALUES('SVM', (ROUND(v_accuracy,4))*100);
      END;
      /

BEGIN EXECUTE IMMEDIATE 'DROP TABLE nn_confusion_matrix PURGE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

DECLARE
   v_accuracy    NUMBER;
   BEGIN
        DBMS_DATA_MINING.COMPUTE_CONFUSION_MATRIX (
                   accuracy                     => v_accuracy,
                   apply_result_table_name      => 'APPLY_RESULT_NN',
                   target_table_name            => 'TEST_DATA_CLAS',
                   case_id_column_name          => 'PERSON_ID',
                   target_column_name           => 'TARGET',
                   confusion_matrix_table_name  => 'nn_confusion_matrix',
                   score_column_name            => 'PREDICTION',
                   score_criterion_column_name  => 'PROBABILITY',
                  score_criterion_type         => 'PROBABILITY');
        DBMS_OUTPUT.PUT_LINE('****NEURAL NETWORK MODEL ACCURACY ****: ' || (ROUND(v_accuracy,4))*100 ||'%');
        INSERT INTO MODEL_ACCURACY VALUES('NEURAL NETWORK', (ROUND(v_accuracy,4))*100);
      END;
      /
      SET FEEDBACK ON;


ACCURACY TABLE
%sql
CREATE TABLE MODEL_ACCURACY(
    MODEL VARCHAR2(20),
    ACCURACY NUMBER
);


SELECT * 
FROM MODEL_ACCURACY
ORDER BY ACCURACY DESC;


Confusion Matrix

%sql
SELECT * from nn_confusion_matrix;

F1-SCORE

%script

DECLARE
    TP NUMBER;
    FP NUMBER;
    FN NUMBER;
    PREC Number;
    RECALL NUMBER;
    
    F1_SCORE NUMBER;
BEGIN
    SELECT VALUE INTO TP
    FROM dt_confusion_matrix
    WHERE ACTUAL_TARGET_VALUE = 1 AND PREDICTED_TARGET_VALUE = 1;
    
    SELECT VALUE INTO FP
    FROM dt_confusion_matrix
    WHERE ACTUAL_TARGET_VALUE = 0 AND PREDICTED_TARGET_VALUE=1;
    
    SELECT VALUE INTO FN
    FROM dt_confusion_matrix
    WHERE ACTUAL_TARGET_VALUE = 1 AND PREDICTED_TARGET_VALUE=0;
    
    PREC:= TP/(TP+FP);
    RECALL:= TP/(TP+FN);
    
    F1_SCORE := TP/(TP+0.5*(FP+FN));
    dbms_output.put_line('F1 Score for Neural Network: ' || ROUND(F1_SCORE,2));
    dbms_output.put_line('Precision Neural Network: ' || ROUND(PREC,2));
    dbms_output.put_line('Recall for Neural Network: ' || ROUND(RECALL,2));
END;
/
    PERSONS WITH >50% PROBABILITY OF HEART DISEASE
%sql

SELECT PERSON_ID, PREDICTION PRED,ROUND(PROBABILITY,3) PROB, ROUND(COST,2) COST 
  FROM APPLY_RESULT WHERE PREDICTION = 1 AND PROBABILITY > 0.5 
  ORDER BY PROBABILITY DESC;

INTERACTIVE PREDICTIONS

%sql 
SELECT A.*, B.TARGET
  FROM APPLY_RESULT_DT A, TEST_DATA_CLAS B 
  WHERE PREDICTION = ${PREDICTION='1','1'|'0'} AND A.PERSON_ID = B.PERSON_ID;


%sql
select * from test_data_clas;

PREDICTION ON A NEW RECORD

%sql
SELECT ROUND(PREDICTION_PROBABILITY(neural_network, '1' USING 
                                    55 AS AGE, 
                                     1 AS SEX, 
                                     2 AS CP,
                                     133 AS TRESTBPS,
                                     250 AS CHOL,
                                     0 AS FBS,
                                     1 AS RESTECG,
                                     125 AS THALACH,
                                     0 AS EXANG,
                                     0.7 AS OLDPEAK,
                                     1 AS SLOPE,
                                     1 AS CA,
                                     2 AS THAL),3) PROBABILITY_HEART_DISEASE
  FROM DUAL;