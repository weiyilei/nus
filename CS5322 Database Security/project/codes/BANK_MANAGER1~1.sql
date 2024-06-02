select * from DB_ADMIN.BANK_RECORDS;
update DB_ADMIN.BANK_RECORDS set DEPOSIT = 400 where HANDLING = 'BP';
commit;