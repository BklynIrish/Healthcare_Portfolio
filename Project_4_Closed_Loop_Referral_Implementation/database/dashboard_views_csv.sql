SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = ON;	
SHOW GLOBAL VARIABLES LIKE 'local_infile';


/* Referral Lifecycle to be exported as a .csv file for dashboard */
SELECT *
FROM v_referral_lifecycle
ORDER BY referral_id;
    
/* Operational Work Queue to be exported as a .csv file for dashboard */
SELECT *
FROM v_operational_work_queue
ORDER BY
    CASE
        WHEN work_priority = 'Critical—Urgent Overdue' THEN 1
        WHEN work_priority LIKE '%Overdue%' THEN 2
        ELSE 3
    END,
    service_level_due_at,
    referral_id;
     
/* Referral Funnel to be exported as a .csv file for dashboard */
SELECT *
FROM v_referral_funnel
ORDER BY stage_order;

/* site_specialty_performance to be exported as a .csv file for dashboard */
SELECT *
FROM v_site_specialty_performance;

/* COUNT rows in site_specialty_performance --> 60 */
SELECT COUNT(*) FROM v_site_specialty_performance;

/* data_exception_queue to be exported as a .csv file for dashboard */
SELECT *
FROM v_data_exception_queue;

/* COUNT rows in v_data_exception_queue--> 93 */
SELECT COUNT(*) FROM v_data_exception_queue;