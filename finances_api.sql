CREATE SCHEMA finances_api;

-------------
-- account --
-------------

CREATE VIEW finances_api.account AS
SELECT
    A.id,
    A.title,
    A.preset,
    A.contra,
    A.parent_id
FROM
    finances.account A
ORDER BY
    A.id;

-----------
-- batch --
-----------

CREATE VIEW finances_api.batch AS
SELECT
    B.id,
    B.summary,
    B.posted_on
FROM
    finances.batch B
ORDER BY
    B.posted_on;

-------------
-- journal --
-------------

CREATE VIEW finances_api.journal AS
SELECT
    J.id,
    J.batch_id,
    J.account_debit_id,
    J.account_credit_id,
    J.amount,
    J.summary
FROM
    finances.journal J
ORDER BY
    J.id DESC;

------------
-- period --
------------

CREATE VIEW finances_api.period AS
SELECT
    T.period,
    T.abbrev,
    T.started_on,
    T.finished_on
FROM
    finances.period T
ORDER BY
    T.started_on;

-------------
-- posting --
-------------

CREATE VIEW finances_api.posting AS
SELECT
    P.batch_id,
    P.account_id,
    P.origin,
    P.amount_debit,
    P.amount_credit,
    P.posted_on,
    P.nature
FROM
    finances.posting P
ORDER BY
    P.posted_on;

-------------
-- balance --
-------------

CREATE VIEW finances_api.balance AS
SELECT
    B.period,
    B.account_id,
    B.origin,
    B.balance_debit,
    B.balance_credit
FROM
    finances.balance B
ORDER BY
    B.period, B.account_id;

-------------
-- summary --
-------------

CREATE VIEW finances_api.summary AS
SELECT
    S.period,
    S.asset_debit,
    S.asset_credit,
    S.liability_debit,
    S.liability_credit,
    S.income_debit,
    S.income_credit,
    S.expense_debit,
    S.expense_credit
FROM
    finances.summary S
ORDER BY
    S.period;

--------------
-- web_anon --
--------------

CREATE ROLE web_anon NOLOGIN;

GRANT USAGE ON SCHEMA finances_api TO web_anon;

GRANT SELECT ON finances_api.account TO web_anon;

GRANT SELECT ON finances_api.batch TO web_anon;

GRANT SELECT ON finances_api.journal TO web_anon;

GRANT SELECT ON finances_api.period TO web_anon;

GRANT SELECT ON finances_api.posting TO web_anon;

GRANT SELECT ON finances_api.balance TO web_anon;

GRANT SELECT ON finances_api.summary TO web_anon;

-------------------
-- authenticator --
-------------------

CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'mysecretpassword';

GRANT web_anon TO authenticator;
