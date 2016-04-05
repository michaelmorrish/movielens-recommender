/* 1. CREATE MOVIELENS RECOMMENDER DATABASE & POPULATE TABLES */

CREATE mlr;

/* Set mlr to the active database. */

use mlr;

/* Create tables for mlr database and load data from .csv files. */
/* Note: due to dependencies, code should be executed in the order presented below. */

/* Create movies table. */

CREATE TABLE movies (
	movieId integer NOT NULL,
	title varchar(200) NOT NULL,
	genres varchar(100) NOT NULL,
	PRIMARY KEY (movieId)
);

/* Load data from movies.csv file into movies table. */
/* Note: Path to .csv file may need to change if files are located in a different location. */

LOAD DATA INFILE '/var/lib/mysql-files/ml-20m/movies.csv' INTO TABLE movies
FIELDS TEMRINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(movieId, title, genres);

/* Create ratings table. */

CREATE TABLE ratings (
	userId integer NOT NULL,
	movieId integer NOT NULL,
	rating numeric(2,1) NOT NULL,
	timestmp integer NOT NULL,
	PRIMARY KEY (userId,movieId)
);

/* Load data from ratings.csv file into ratings table. */
/* Note: Path to .csv file may need to change if files are located in a different location. */

LOAD DATA INFILE '/var/lib/mysql-files/ml-20m/ratings.csv' INTO TABLE ratings
FIELDS TEMRINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(userId, movieId, rating, timestmp);

/* Create users table. */
/* Populate users table from data in ratings table. */

CREATE TABLE users (
	userId integer NOT NULL,
	PRIMARY KEY (userId))
	SELECT DISTINCT userId FROM ratings;

/* users table is reverse engineered from ratings table and last constraint on ratings table could not be created earlier. */
/* Add constraints now. */

ALTER TABLE ratings ADD CONSTRAINT fk_movie FOREIGN KEY (movieId) REFERENCES movies (movieId) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE ratings ADD CONSTRAINT fk_user FOREIGN KEY (userId) REFERENCES users (userId) ON DELETE NO ACTION ON UPDATE NO ACTION;

/* Alter ratings table to create a column for testing version of rating values. Some rating values will be randomly removed and predicted. */
/* Add a column for each testing set required for development. Copy all rating values over with an update query. Remove those not wanted (w Python). */

ALTER TABLE ratings ADD testrate01 numeric(2,1); /* Experiment 01 and 02 use this set. */

/* Update query to copy rating column to testrate01 column. */

UPDATE ratings SET testrate01 = rating; /* Python code randomly selects some users and ratings to erase for prediction testing. */


/* 2. CREATE ADDITIONAL TABLES TO HOLD EXPERIMENT RESULTS */

/* Each experiment conducted with testing data (testrate## tables) will have results stored in an exp## table. */
/* Python will be used to select users and movies for experiments and add them here. Ratings will be imported into rating column */
/* from ratings table with an update query after python adds the userId and movieId values. The predicted rating will be added later by Python code. */

CREATE TABLE exp01 (
	userId integer NOT NULL,
	movieId integer NOT NULL,
	rating numeric(2,1), 
	predict numeric(2,1),
	PRIMARY KEY (userId,movieId)
);

/* Add constraints to first experiment table. */

ALTER TABLE exp01 ADD CONSTRAINT fk_exp01movie FOREIGN KEY (movieId) REFERENCES movies (movieId) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE exp01 ADD CONSTRAINT fk_exp01user FOREIGN KEY (userId) REFERENCES users (userId) ON DELETE NO ACTION ON UPDATE NO ACTION;


/* Run Python script "MLRSetupExperiment01.pynb" up to and including section titled "Complete Test Data Set and Experiment Setup" */
/* Then run the update statement below */

/* Update query to copy rating column from the ratings table to the exp## tables. */

UPDATE exp01, ratings SET exp01.rating = ratings.rating WHERE exp01.userId=ratings.userId AND exp01.movieId=ratings.movieId;

/* Run the last block of Python code in "MLRSetupExperiment01.pynb" to verify the dataset.


/* Run Step 3 below before running "MLRExperiment01.pynb. */
/* Run Step 4 below before running "MLRExperiment02.pynb. */
/* Create additional MLRExperiment##.pynb and exp## tables as needed and similar to existing examples. */


/* 3. MODIFICATION TO EXPERIMENT TABLE */

/* Not able to generate test results for whole table - takes too long. Need a field to capture whether a prediction was made or not. */
/* gotpred holds a 1 if a prediction is made, 0 if a prediction was attempted but failed, and NULL if record not selected for a prediction. */

ALTER TABLE exp01 ADD gotpred integer;


/* 4. ADD TABLE FOR SECOND EXPERIMENT */

/* Create a table for a second experiment */

CREATE TABLE exp02 (
	userId integer NOT NULL,
	movieId integer NOT NULL,
	rating numeric(2,1), 
	predict numeric(2,1),
	gotpred integer,
	PRIMARY KEY (userId,movieId)
);

/* Add constraints to second experiment table. */

ALTER TABLE exp02 ADD CONSTRAINT fk_exp02movie FOREIGN KEY (movieId) REFERENCES movies (movieId) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE exp02 ADD CONSTRAINT fk_exp02user FOREIGN KEY (userId) REFERENCES users (userId) ON DELETE NO ACTION ON UPDATE NO ACTION;

/* Copy userId, movieId, and rating from exp01 to exp02. These have already been generated by Python script "MLRSetupExperiment01.pynb" and this approach will keep it the same.*/

INSERT INTO exp02 SELECT * FROM exp01; /* If done before experiment 1, if done after; set predict and gotpred to NULL with a second statement */