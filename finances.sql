CREATE SCHEMA finances;

--------------------
-- account_origin --
--------------------

CREATE TYPE finances.account_origin AS ENUM (
    'ASSET',
    'LIABILITY',
    'INCOME',
    'EXPENSE'
);

--------------------
-- account_preset --
--------------------

CREATE TABLE finances.account_preset (
    preset text PRIMARY KEY,
    origin finances.account_origin NOT NULL
);

INSERT INTO finances.account_preset (preset, origin) VALUES
    ('BANK', 'ASSET'),
    ('ACCOUNTS RECEIVABLE', 'ASSET'),
    ('OTHER CURRENT ASSETS', 'ASSET'),
    ('FIXED ASSETS', 'ASSET'),
    ('OTHER ASSETS', 'ASSET'),
    ('ACCOUNTS PAYABLE', 'LIABILITY'),
    ('CREDIT CARD', 'LIABILITY'),
    ('OTHER CURRENT LIABILITIES', 'LIABILITY'),
    ('LONG TERM LIABILITIES', 'LIABILITY'),
    ('EQUITY', 'LIABILITY'),
    ('INCOME', 'INCOME'),
    ('COST OF GOODS SOLD', 'EXPENSE'),
    ('EXPENSES', 'EXPENSE'),
    ('OTHER INCOME', 'INCOME'),
    ('OTHER EXPENSE', 'EXPENSE');

-------------
-- account --
-------------

CREATE TABLE finances.account (
    id int PRIMARY KEY,
    title text NOT NULL,
    preset text REFERENCES finances.account_preset (preset),
    contra boolean NOT NULL DEFAULT FALSE,
    parent_id int
);

-----------
-- batch --
-----------

CREATE TABLE finances.batch (
    id serial PRIMARY KEY,
    summary text NOT NULL,
    posted_on timestamp with time zone
);

-------------
-- journal --
-------------

CREATE TABLE finances.journal (
    id serial PRIMARY KEY,
    batch_id int NOT NULL REFERENCES finances.batch (id),
    account_debit_id int NOT NULL REFERENCES finances.account (id),
    account_credit_id int NOT NULL REFERENCES finances.account (id),
    amount numeric(12, 2) NOT NULL CHECK (amount > 0),
    summary TEXT
    CHECK (account_debit_id <> account_credit_id)
);

------------
-- period --
------------

CREATE TABLE finances.period (
    period int PRIMARY KEY,
    abbrev text NOT NULL UNIQUE,
    started_on timestamp with time zone NOT NULL,
    finished_on timestamp with time zone NOT NULL
);

-------------
-- posting --
-------------

CREATE VIEW finances.posting AS
SELECT
    J.batch_id,
    J.id AS journal_id,
    (
	CASE WHEN F.nature = 'DEBIT' THEN
	    J.account_debit_id
	ELSE
	    J.account_credit_id
	END
    ) AS account_id,
    (
	CASE WHEN F.nature = 'DEBIT' THEN
	    P1.origin
	ELSE
	    P2.origin
	END
    ) AS origin,
    (
	CASE WHEN F.nature = 'DEBIT' THEN
	    J.amount
	ELSE
	    0
	END
    ) AS amount_debit,
    (
	CASE WHEN F.nature = 'DEBIT' THEN
	    0
	ELSE
	    J.amount
	END
    ) AS amount_credit,
    B.posted_on,
    F.nature
FROM
    finances.journal J
    JOIN finances.batch B ON J.batch_id = B.id
    JOIN finances.account A1 ON J.account_debit_id = A1.id
    JOIN finances.account A2 ON J.account_credit_id = A2.id
    JOIN finances.account_preset P1 ON A1.preset = P1.preset
    JOIN finances.account_preset P2 ON A2.preset = P2.preset
    CROSS JOIN (
	VALUES
	    ('CREDIT'),
	    ('DEBIT')
    ) F (nature)
WHERE
    B.posted_on IS NOT NULL;

-------------------------
-- posting_over_period --
-------------------------

CREATE VIEW finances.posting_over_period AS
SELECT
    T.period,
    P.batch_id,
    P.journal_id,
    P.account_id,
    P.origin,
    P.amount_debit,
    P.amount_credit,
    P.posted_on,
    P.nature
FROM
    finances.posting P
    JOIN finances.period T ON P.posted_on < T.finished_on;

-- CREATE VIEW finances.posting_over_period AS
-- SELECT
--     T.period,
--     P.batch_id,
--     P.journal_id,
--     P.account_id,
--     P.origin,
--     P.amount_debit,
--     P.amount_credit,
--     P.posted_on,
--     P.nature
-- FROM
--     finances.posting P
--     JOIN finances.period T ON P.posted_on < T.finished_on;
-- WHERE
--     P.origin IN ('ASSET', 'LIABILITY')
-- UNION
-- SELECT
--     T.period,
--     P.batch_id,
--     P.journal_id,
--     P.account_id,
--     P.origin,
--     P.amount_debit,
--     P.amount_credit,
--     P.posted_on,
--     P.nature
-- FROM
--     finances.posting P
--     JOIN finances.period T ON P.posted_on >= T.started_on AND P.posted_on < T.finished_on
-- WHERE
--     P.origin IN ('INCOME', 'EXPENSE');

-------------
-- balance --
-------------

CREATE VIEW finances.balance AS
SELECT
    P.period,
    P.account_id,
    P.origin,
    greatest(sum(P.amount_debit) - sum(P.amount_credit), 0) AS balance_debit,
    greatest(sum(P.amount_credit) - sum(P.amount_debit), 0) AS balance_credit
FROM
    finances.posting_over_period P
GROUP BY
    P.period,
    P.account_id,
    P.origin;

-------------
-- summary --
-------------

CREATE VIEW finances.summary AS
SELECT
    B.period,
    SUM(B.balance_debit) FILTER (WHERE B.origin = 'ASSET') asset_debit,
    SUM(B.balance_credit) FILTER (WHERE B.origin = 'ASSET') asset_credit,
    SUM(B.balance_debit) FILTER (WHERE B.origin = 'LIABILITY') liability_debit,
    SUM(B.balance_credit) FILTER (WHERE B.origin = 'LIABILITY') liability_credit,
    SUM(B.balance_debit) FILTER (WHERE B.origin = 'INCOME') income_debit,
    SUM(B.balance_credit) FILTER (WHERE B.origin = 'INCOME') income_credit,
    SUM(B.balance_debit) FILTER (WHERE B.origin = 'EXPENSE') expense_debit,
    SUM(B.balance_credit) FILTER (WHERE B.origin = 'EXPENSE') expense_credit
FROM
    finances.balance B
GROUP BY
    B.period;
