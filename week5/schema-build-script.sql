PRAGMA foreign_keys = ON;
.mode box

-------------------------------------------------------------------------------

CREATE TABLE Species (
    Code TEXT PRIMARY KEY,
    Common_name TEXT UNIQUE NOT NULL,
    Scientific_name TEXT, -- can't make NOT NULL, missing data in some rows
    Relevance TEXT
);

.import --csv --skip 1 species.csv Species

-- Here and in multiple places below: there is absolutely no way to
-- get SQLite to interpret an empty field in a CSV file as NULL.
-- Hence these post-import updates.

UPDATE Species SET Scientific_name = NULL WHERE Scientific_name = '';

-------------------------------------------------------------------------------

CREATE TABLE Site (
    Code TEXT PRIMARY KEY,
    Site_name TEXT UNIQUE NOT NULL,
    Location TEXT NOT NULL,
    Latitude REAL NOT NULL CHECK (Latitude BETWEEN -90 AND 90),
    Longitude REAL NOT NULL CHECK (Longitude BETWEEN -180 AND 180),
    Area REAL NOT NULL CHECK (Area > 0),
    UNIQUE (Latitude, Longitude)
);

.import --csv --skip 1 site.csv Site

-------------------------------------------------------------------------------

CREATE TABLE Personnel (
    Abbreviation TEXT PRIMARY KEY,
    Name TEXT NOT NULL UNIQUE
);

.import --csv --skip 1 personnel.csv Personnel

-------------------------------------------------------------------------------

CREATE TABLE Camp_assignment (
    Year INTEGER NOT NULL CHECK (Year BETWEEN 1950 AND 2015),
    Site TEXT NOT NULL,
    Observer TEXT NOT NULL,
    Start TEXT, -- sadly, SQLite lacks a true date data type
    End TEXT,
    FOREIGN KEY (Site) REFERENCES Site (Code),
    FOREIGN KEY (Observer) REFERENCES Personnel (Abbreviation),
    CHECK (End = '' OR Start <= End),
    CHECK (Start = '' OR Start BETWEEN Year||'-01-01' AND Year||'-12-31'),
    CHECK (End = '' OR End BETWEEN Year||'-01-01' AND Year||'-12-31')
);

.import --csv --skip 1 ASDN_Camp_assignment.csv Camp_assignment

UPDATE Camp_assignment SET Start = NULL WHERE Start = '';
UPDATE Camp_assignment SET End = NULL WHERE End = '';

-------------------------------------------------------------------------------

-- The only way to deal with NULL foreign keys in SQLite (Observer may
-- be NULL below) is to temporarily turn checking off, so lame.

PRAGMA foreign_keys = OFF;

CREATE TABLE Bird_nests (
    Book_page TEXT,
    Year INTEGER NOT NULL CHECK (Year BETWEEN 1950 AND 2015),
    Site TEXT NOT NULL,
    Nest_ID TEXT PRIMARY KEY,
    Species TEXT NOT NULL,
    Observer TEXT,
    Date_found TEXT NOT NULL
        CHECK (Date_found BETWEEN Year||'-01-01' AND Year||'-12-31'),
    how_found_temp TEXT,
    Clutch_max_temp TEXT,
    floatAge_temp TEXT,
    ageMethod_temp TEXT,
    FOREIGN KEY (Site) REFERENCES Site (Code),
    FOREIGN KEY (Species) REFERENCES Species (Code),
    FOREIGN KEY (Observer) REFERENCES Personnel (Abbreviation)
);

.import --csv --skip 1 ASDN_Bird_nests.csv Bird_nests

UPDATE Bird_nests SET Observer = NULL WHERE Observer = '';

-- Sadly, the following will not go back and check that foreign key
-- references are valid.

PRAGMA foreign_keys = ON;

UPDATE Bird_nests SET Book_page = NULL WHERE Book_page = '';

-- To add proper constraints on columns that come in with empty values
-- that only later get replaced with NULLs, must do the rigamarole
-- below.

UPDATE Bird_nests SET how_found_temp = NULL WHERE how_found_temp = '';
ALTER TABLE Bird_nests ADD COLUMN how_found TEXT DEFAULT NULL
    CHECK (how_found IN ('searcher', 'rope', 'bander'));
UPDATE Bird_nests SET how_found = how_found_temp;
ALTER TABLE Bird_nests DROP COLUMN how_found_temp;

UPDATE Bird_nests SET Clutch_max_temp = NULL WHERE Clutch_max_temp = '';
ALTER TABLE Bird_nests ADD COLUMN Clutch_max INTEGER DEFAULT NULL
    CHECK (Clutch_max BETWEEN 0 AND 20);
UPDATE Bird_nests SET Clutch_max = CAST(Clutch_max_temp AS INTEGER);
ALTER TABLE Bird_nests DROP COLUMN Clutch_max_temp;

UPDATE Bird_nests SET floatAge_temp = NULL WHERE floatAge_temp = '';
ALTER TABLE Bird_nests ADD COLUMN floatAge REAL DEFAULT NULL
    CHECK (floatAge BETWEEN 0 AND 30);
UPDATE Bird_nests SET floatAge = CAST(floatAge_temp AS REAL);
ALTER TABLE Bird_nests DROP COLUMN floatAge_temp;

UPDATE Bird_nests SET ageMethod_temp = NULL
    WHERE ageMethod_temp = '' OR ageMethod_temp = 'none';
ALTER TABLE Bird_nests ADD COLUMN ageMethod TEXT DEFAULT NULL
    CHECK (ageMethod IN ('float', 'lay', 'hatch'));
UPDATE Bird_nests SET ageMethod = ageMethod_temp;
ALTER TABLE Bird_nests DROP COLUMN ageMethod_temp;

-------------------------------------------------------------------------------

CREATE TABLE Bird_eggs (
    Book_page TEXT DEFAULT NULL,
    Year INTEGER DEFAULT NULL CHECK (Year BETWEEN 1950 AND 2015),
    Site TEXT DEFAULT NULL,
    Nest_ID TEXT NOT NULL,
    Egg_num INTEGER DEFAULT NULL CHECK (Egg_num BETWEEN 1 AND 20),
    Length REAL NOT NULL CHECK (Length > 0 AND Length < 100),
    Width REAL NOT NULL CHECK (Width > 0 AND Width < 100),
    PRIMARY KEY (Nest_ID, Egg_num),
    FOREIGN KEY (Site) REFERENCES Site (Code),
    FOREIGN KEY (Nest_ID) REFERENCES Bird_nests (Nest_ID)
);

-- Example of a trigger approach to checking that the duplicated
-- columns in Bird_eggs match those in Bird_nests.

CREATE TRIGGER egg_nest_consistency
    BEFORE INSERT ON Bird_eggs
    FOR EACH ROW
    WHEN
        new.Book_Page NOT IN (
            SELECT Book_Page FROM Bird_nests WHERE Nest_ID = new.Nest_ID
        )
        OR
        new.Year NOT IN (
            SELECT Year FROM Bird_nests WHERE Nest_ID = new.Nest_ID
        )
        OR
        new.Site NOT IN (
            SELECT Site FROM Bird_nests WHERE Nest_ID = new.Nest_ID
        )
    BEGIN
        SELECT RAISE(FAIL, 'egg-nest data inconsistency');
    END;

.import --csv --skip 1 ASDN_Bird_eggs.csv Bird_eggs

DROP TRIGGER egg_nest_consistency;

UPDATE Bird_eggs SET Book_page = NULL WHERE Book_page = '';
