CREATE TABLE Species (
    Code TEXT PRIMARY KEY,
    Common_name TEXT UNIQUE NOT NULL,
    Scientific_name TEXT, -- can't make NOT NULL, missing data in some rows
    Relevance TEXT
) STRICT;

-------------------------------------------------------------------------------

CREATE TABLE Site (
    Code TEXT PRIMARY KEY,
    Site_name TEXT UNIQUE NOT NULL,
    Location TEXT NOT NULL,
    Latitude REAL NOT NULL CHECK (Latitude BETWEEN -90 AND 90),
    Longitude REAL NOT NULL CHECK (Longitude BETWEEN -180 AND 180),
    Area REAL NOT NULL CHECK (Area > 0),
    UNIQUE (Latitude, Longitude)
) STRICT;

-------------------------------------------------------------------------------

CREATE TABLE Personnel (
    Abbreviation TEXT PRIMARY KEY,
    Name TEXT NOT NULL UNIQUE
) STRICT;

-------------------------------------------------------------------------------

CREATE TABLE Camp_assignment (
    Year INTEGER NOT NULL CHECK (Year BETWEEN 1950 AND 2015),
    Site TEXT NOT NULL,
    Observer TEXT NOT NULL,
    Start TEXT, -- sadly, SQLite lacks a true date data type
    End TEXT,
    FOREIGN KEY (Site) REFERENCES Site (Code),
    FOREIGN KEY (Observer) REFERENCES Personnel (Abbreviation),
    CHECK (Start <= End),
    CHECK (Start BETWEEN Year||'-01-01' AND Year||'-12-31'),
    CHECK (End BETWEEN Year||'-01-01' AND Year||'-12-31')
) STRICT;

-------------------------------------------------------------------------------

CREATE TABLE Bird_nests (
    Book_page TEXT,
    Year INTEGER NOT NULL CHECK (Year BETWEEN 1950 AND 2015),
    Site TEXT NOT NULL,
    Nest_ID TEXT PRIMARY KEY,
    Species TEXT NOT NULL,
    Observer TEXT,
    Date_found TEXT NOT NULL
        CHECK (Date_found BETWEEN Year||'-01-01' AND Year||'-12-31'),
    how_found TEXT CHECK (how_found IN ('searcher', 'rope', 'bander')),
    Clutch_max INTEGER CHECK (Clutch_max BETWEEN 0 AND 20),
    floatAge REAL CHECK (floatAge BETWEEN 0 AND 30),
    ageMethod TEXT CHECK (ageMethod IN ('float', 'lay', 'hatch')),
    FOREIGN KEY (Site) REFERENCES Site (Code),
    FOREIGN KEY (Species) REFERENCES Species (Code),
    FOREIGN KEY (Observer) REFERENCES Personnel (Abbreviation)
) STRICT;

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
) STRICT;
