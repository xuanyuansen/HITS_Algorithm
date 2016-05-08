-- ******************************************************
-- ******************************************************
-- * End of Initialization:
-- ******************************************************
-- * Below is re-iteration, copy and paste as many times
-- * as desired
-- ******************************************************
-- ******************************************************

-- * iteration 1

NEW_AUTH = JOIN HUB BY page_id, PAGELINKS BY from_page;
NEW_AUTH = GROUP NEW_AUTH BY to_page;
NEW_AUTH = FOREACH NEW_AUTH GENERATE group AS page_id, NEW_AUTH.HUB::new_hub AS hub;
NEW_AUTH = FOREACH NEW_AUTH GENERATE page_id, SUM(hub) AS new_auth;
NEW_AUTH = JOIN NEW_AUTH BY page_id, AUTH BY page_id;
AUTH = FOREACH NEW_AUTH GENERATE NEW_AUTH::page_id AS page_id, NEW_AUTH::new_auth AS new_auth, AUTH::new_auth AS old_auth;
-- * 
NEW_HUB = JOIN AUTH BY page_id, PAGELINKS BY to_page; 
NEW_HUB = GROUP NEW_HUB BY from_page; 
NEW_HUB = FOREACH NEW_HUB GENERATE group AS page_id, NEW_HUB.AUTH::new_auth AS auth;
NEW_HUB = FOREACH NEW_HUB GENERATE page_id, SUM(auth) AS new_hub;
NEW_HUB = JOIN NEW_HUB BY page_id, HUB BY page_id;
HUB = FOREACH NEW_HUB GENERATE NEW_HUB::page_id AS page_id, NEW_HUB::new_hub AS new_hub, HUB::new_hub AS old_hub;
-- * 
NORM_HUB = FOREACH HUB GENERATE new_hub * new_hub AS sq_hub;
NORM_HUB = GROUP NORM_HUB ALL;
NORM_HUB = FOREACH NORM_HUB GENERATE SUM(NORM_HUB.sq_hub) AS sq_sum;
NORM_HUB = FOREACH NORM_HUB GENERATE SQRT(sq_sum) AS norm;
HUB = JOIN HUB BY 1, NORM_HUB BY 1 USING 'replicated';
HUB = FOREACH HUB GENERATE HUB::page_id AS page_id, HUB::new_hub / NORM_HUB::norm AS new_hub, HUB::old_hub AS old_hub;
-- * 
NORM_AUTH = FOREACH AUTH GENERATE new_auth * new_auth AS sq_auth;
NORM_AUTH = GROUP NORM_AUTH ALL;
NORM_AUTH = FOREACH NORM_AUTH GENERATE SUM(NORM_AUTH.sq_auth) AS sq_sum;
NORM_AUTH = FOREACH NORM_AUTH GENERATE SQRT(sq_sum) AS norm;
AUTH = JOIN AUTH BY 1, NORM_AUTH BY 1 USING 'replicated';
AUTH = FOREACH AUTH GENERATE AUTH::page_id AS page_id, AUTH::new_auth / NORM_AUTH::norm AS new_auth, AUTH::old_auth AS old_auth;
-- * 
PERF_AUTH = FOREACH AUTH GENERATE ABS(new_auth - old_auth) AS diff;
PERF_AUTH = GROUP PERF_AUTH ALL;
PERF_AUTH = FOREACH PERF_AUTH GENERATE SUM(PERF_AUTH) AS auth_dif;
PERF_HUB = FOREACH HUB GENERATE ABS(new_hub - old_hub) AS diff;
PERF_HUB = GROUP PERF_HUB ALL;
PERF_HUB = FOREACH PERF_HUB GENERATE SUM(PERF_HUB) AS hub_dif;
TEMP_PERF = JOIN PERF_AUTH BY 1, PERF_HUB BY 1 USING 'replicated';
TEMP_PERF = FOREACH TEMP_PERF GENERATE CurrentTime() AS time, PERF_AUTH::auth_dif AS auth_dif, PERF_HUB::hub_dif AS hub_dif;
PERF = UNION PERF, TEMP_PERF;



