--
-- PostgreSQL database dump
--

\restrict j2Pjrs5i1snABrHFyCCl90RijFYgU3o2jpQJITrUSZKuE62cCEOxJheHDOmTVAf

-- Dumped from database version 16.14
-- Dumped by pg_dump version 16.14

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, email, name, password_hash, created_at) FROM stdin;
2	admin@crm.local	Rufat Asadov	$2a$10$SC9evyQd110Z57LWEr6OtOqHTXKsiu5vQyEdAbOjRxIn382QBj12.	2026-10-07 05:23:12.444114+00
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.projects (id, user_id, name, description, color, created_at) FROM stdin;
3	2	AI -CallCenter		#6366f1	2026-10-07 05:25:05.732697+00
4	2	CRM		#14b8a6	2026-10-07 05:26:48.129385+00
5	2	BOB		#ec4899	2026-10-07 05:31:15.426928+00
6	2	PIPRO		#ef4444	2026-10-07 05:31:33.760583+00
7	2	Touristgram		#f97316	2026-10-07 05:31:54.566827+00
8	2	MedistockBonusServer		#f59e0b	2026-10-07 05:32:37.232441+00
9	2	Planner		#22c55e	2026-10-07 05:46:47.956389+00
10	2	Nahar fasilesi		#14b8a6	2026-10-07 05:54:25.754431+00
\.


--
-- Data for Name: plans; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plans (id, user_id, project_id, plan_date, start_min, end_min, note, created_at) FROM stdin;
10	2	9	2026-10-07	555	615		2026-10-07 05:47:07.040274+00
11	2	5	2026-10-07	615	675		2026-10-07 05:53:55.236084+00
12	2	3	2026-10-07	690	750		2026-10-07 05:54:06.802583+00
13	2	10	2026-10-07	780	870		2026-10-07 05:54:40.473275+00
14	2	4	2026-10-07	900	930		2026-10-07 05:54:57.537447+00
15	2	5	2026-10-07	960	1020		2026-10-07 05:55:07.680843+00
16	2	7	2026-10-07	1035	1080		2026-10-07 05:55:33.598576+00
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.tasks (id, user_id, project_id, title, description, status, created_at, updated_at) FROM stdin;
3	2	3	Asterisk default qurmaq		todo	2026-10-07 05:34:27.648584+00	2026-10-07 05:34:27.648584+00
4	2	3	Asterisk elaveler etmek ve readme yazmaq		todo	2026-10-07 05:34:41.814222+00	2026-10-07 05:34:41.814222+00
5	2	3	TTS qurmaq		todo	2026-10-07 05:34:48.642179+00	2026-10-07 05:34:48.642179+00
7	2	3	AVA docker qaldirmaq		todo	2026-10-07 05:35:04.246996+00	2026-10-07 05:35:04.246996+00
8	2	3	Web app docker qaldir		todo	2026-10-07 05:39:42.429633+00	2026-10-07 05:39:42.429633+00
6	2	3	STT qurmaq		done	2026-10-07 05:34:53.909334+00	2026-10-07 05:39:49.683915+00
9	2	4	Inteqrasiyalar		todo	2026-10-07 05:40:25.10562+00	2026-10-07 05:40:25.10562+00
10	2	4	UI animasiyalar		todo	2026-10-07 05:40:38.083362+00	2026-10-07 05:40:38.083362+00
11	2	4	asterisk veya ringostat integrasiya		todo	2026-10-07 05:40:50.334354+00	2026-10-07 05:40:50.334354+00
12	2	4	data import		todo	2026-10-07 05:41:01.74469+00	2026-10-07 05:41:01.74469+00
13	2	4	google docs integrasiya		todo	2026-10-07 05:41:13.656325+00	2026-10-07 05:41:13.656325+00
14	2	7	yeni serverde docker qaldir		todo	2026-10-07 05:41:26.418842+00	2026-10-07 05:41:26.418842+00
15	2	7	mobile-da ip deyish		todo	2026-10-07 05:41:32.280633+00	2026-10-07 05:41:32.280633+00
16	2	7	qalan tasklari tamamla, ishlek veziyete getir		todo	2026-10-07 05:41:46.747951+00	2026-10-07 05:41:46.747951+00
17	2	7	store-a yerleshdir		todo	2026-10-07 05:41:56.491758+00	2026-10-07 05:41:56.491758+00
18	2	6	donma problemini hell et		todo	2026-10-07 05:42:06.838131+00	2026-10-07 05:42:06.838131+00
19	2	6	yeni versiya ver Firdovsiye		todo	2026-10-07 05:42:12.859167+00	2026-10-07 05:42:12.859167+00
20	2	8	bonus serveri ucun docker hazirla		todo	2026-10-07 05:42:35.673687+00	2026-10-07 05:42:35.673687+00
21	2	8	rehimden bonus apileri al		todo	2026-10-07 05:42:45.32466+00	2026-10-07 05:42:45.32466+00
\.


--
-- Data for Name: plan_tasks; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.plan_tasks (plan_id, task_id) FROM stdin;
12	3
12	4
12	5
12	7
12	8
14	9
14	10
14	11
14	12
14	13
16	14
16	15
16	16
16	17
\.


--
-- Data for Name: user_settings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_settings (user_id, work_start_min, work_end_min, notify_before_min) FROM stdin;
2	540	1440	10
\.


--
-- Name: plans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.plans_id_seq', 16, true);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.projects_id_seq', 10, true);


--
-- Name: tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tasks_id_seq', 21, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

\unrestrict j2Pjrs5i1snABrHFyCCl90RijFYgU3o2jpQJITrUSZKuE62cCEOxJheHDOmTVAf

