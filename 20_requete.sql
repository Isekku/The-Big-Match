--Les pairs d'utilisateur ayant eu un match 
SELECT U1.idU, U2.idU
FROM Utilisateur U1, Utilisateur U2, Aime A1, Aime A2
WHERE U1.idU < U2.idU 
AND A1.idU1 = U1.idU AND A1.idU2 = U2.idU
AND A2.idU1 = U2.idU AND A2.idU2 = U1.idU;

--Les événements organisés par des utilisateurs dont les centres d’intérêt sont liés au lieu ou au type d’événement.
SELECT E.idE, E.nom, E.date_event
FROM Evenement E

JOIN Lieu L ON E.idL = L.idL
JOIN Organisateur O ON O.idE = E.idE
JOIN Utilisateur U ON U.idU = O.idU

JOIN TagUtilisateur Tu ON Tu.idU = U.idU
JOIN TagLieu Tl ON Tl.idL = L.idL
JOIN TagEvenement Te ON Te.idE = E.idE

WHERE Tu.idT = Tl.idT OR Tl.idT = Te.idT;

--Les utilisateurs n'ayant pas participé à un événement ayant le tag 'Hit Me Hard And Soft'
SELECT U.idU
FROM Utilisateur U
WHERE U.idU NOT IN (
	SELECT Ut.idU
	FROM Utilisateur Ut, Participation P, Evenement E, TagEvenement Te, Tag T
	WHERE Ut.idU = P.idU AND E.idE = P.idE AND P.type_participation = 'participe'
	AND Te.idE = E.idE AND Te.idT = T.idT
	AND T.nom = 'Hit Me Hard And Soft'
);

--La moyenne du prix des événements organisé par un utilisateur externe
SELECT AVG(E.prix) AS moyenne_prix
FROM Evenement E
WHERE 
E.idE NOT IN (SELECT idE FROM Organisateur)
AND E.idE IN (SELECT idE FROM OrganisateurExterne);


--Les lieux ayant le même nombre d'événement produit et le même nombre de tags
SELECT L.idL
FROM Lieu L
GROUP BY L.idL
HAVING (
	SELECT COUNT(*)
	FROM TagLieu TL
	WHERE TL.idL = L.idL
) = (
	SELECT COUNT(*)
	FROM Evenement E
	WHERE E.idL = L.idL
);

--Tous les utilisateurs qui ont dépenser plus de 100 euros dans des objets de catégorie 'Running'
SELECT idU
FROM (
	SELECT RE.idU AS idU, SUM(OA.prix) AS somme_total
	FROM ReseauExterne RE
	JOIN AppAchat AAc ON AAc.idRE = RE.idU
	JOIN ObjetAchete OA ON OA.idAAC = AAc.idAAc
	WHERE OA.genre = 'Running'
	GROUP BY RE.idU
) AS somme_achat_running
WHERE somme_achat_running.somme_total > 100;

--Tous les événements les plus chères d'un lieu
SELECT E1.idE, E1.idL, E1.prix
FROM Evenement E1
WHERE E1.prix = (
	SELECT MAX(COALESCE(E2.prix, 0))
	FROM Evenement E2
	WHERE E1.idL = E2.idL
);

--Tous les pairs d'utilisateur et le mots dominant dans les contenus où ils ont déposé un avis positif (donc plus de 5)
WITH mots AS (
  SELECT 
    re.idU,
    LOWER(regexp_replace(word, '[^\w]+', '', 'g')) AS mot
  FROM Avis a
  JOIN AppAvis aa ON a.idAAv = aa.idAAv
  JOIN ReseauExterne re ON aa.idRE = re.idRE
  CROSS JOIN LATERAL regexp_split_to_table(trim(a.explication), '\s+') AS word
  WHERE a.note >= 5
),
frequences AS (
  SELECT 
    idU,
    mot,
    COUNT(*) AS freq
  FROM mots
  GROUP BY idU, mot
),
mots_max_freq AS (
  SELECT 
    idU,
    mot,
    freq,
    RANK() OVER (PARTITION BY idU ORDER BY freq DESC) AS rk
  FROM frequences
),
mots_top1 AS (
  SELECT idU, mot
  FROM mots_max_freq
  WHERE rk = 1
)
SELECT DISTINCT d1.idU AS idU1, d2.idU AS idU2, d1.mot
FROM mots_top1 d1
JOIN mots_top1 d2 ON d1.mot = d2.mot AND d1.idU < d2.idU;


--La taille maximale et la moyenne d'âge des utilisateurs ayant au moins un tag de la catégorie 'Heureux'
SELECT MAX(U.taille) AS taille_max, AVG(U.age) AS age_moyen
FROM Utilisateur U
JOIN TagUtilisateur TU ON U.idU = TU.idU
JOIN Tag T ON T.idT = TU.idT
WHERE T.nom = 'Heureux';

--Les utilisateurs qui sont à 3 niveaux de like d'un utilisateur donné ?
WITH RECURSIVE LikeChain(id_source, id_cible, niveau) AS (
    SELECT A.idU1, A.idU2, 1
    FROM Aime A
    WHERE A.idU1 = :idU_source

    UNION ALL

    SELECT LC.id_source, A.idU2, LC.niveau + 1
    FROM LikeChain LC
    JOIN Aime A ON LC.id_cible = A.idU1
    WHERE LC.niveau < 3
)

SELECT DISTINCT id_cible
FROM LikeChain
WHERE niveau = 3;

--La prochaine date disponible dans le lieux avec le plus d'événement organisé dans l'application :
WITH RECURSIVE dates_futures AS (
    -- CTE d’ancrage sans ORDER BY/LIMIT directement
    SELECT date_test, idL
    FROM (
        SELECT MAX(E.date_event) + INTERVAL '1 day' AS date_test, E.idL
        FROM Evenement E
        GROUP BY E.idL
        ORDER BY COUNT(*) DESC
        LIMIT 1
    ) AS sub

    UNION ALL

    SELECT df.date_test + INTERVAL '1 day', df.idL
    FROM dates_futures df
    WHERE df.date_test < CURRENT_DATE + INTERVAL '1 year'
)
SELECT df.date_test
FROM dates_futures df
LEFT JOIN Evenement E ON E.date_event = df.date_test AND E.idL = df.idL
WHERE E.date_event IS NULL
LIMIT 1;


--Les utilisateurs qui, pour au moins un réseau externe, ont un pseudo qui commence par leur prénom :
SELECT U.idU
FROM Utilisateur U
NATURAL JOIN ReseauExterne RE
WHERE LOWER(nom_reseau) LIKE '%' || LOWER(LEFT(U.prenom, 3)) || '%'
   OR LOWER(nom_reseau) LIKE '%' || LOWER(LEFT(U.nom, 3)) || '%';

--Pour chaque utilisateur, son réseau externe où il a le plus d'abonnés (app social), ou NULL s'il n'a pas d'app Social :
SELECT u.idU, u.prenom, u.nom, r.nom_reseau, a.nb_abonne
FROM Utilisateur u
LEFT JOIN ReseauExterne r ON u.idU = r.idU
LEFT JOIN AppSocial a ON r.idRe = a.idRe
WHERE (r.idRe, a.nb_abonne) IN (
    SELECT re.idRe, MAX(ap.nb_abonne)
    FROM ReseauExterne re
    JOIN AppSocial ap ON re.idRe = ap.idRe
    WHERE re.idU = u.idU
    GROUP BY re.idRe
)
OR a.nb_abonne IS NULL;

--Les utilisateurs qui ont un compte sur au moins 20% les réseaux externes disponibles :
----Avec sous-requête corrélés :
SELECT u.idU, u.prenom, u.nom
FROM Utilisateur u
JOIN (
    SELECT r.idU, COUNT(DISTINCT r.nom_reseau) AS nb_reseaux_user
    FROM ReseauExterne r
    GROUP BY r.idU
) AS reseaux_user ON u.idU = reseaux_user.idU
WHERE reseaux_user.nb_reseaux_user >= (
    SELECT COUNT(DISTINCT nom_reseau) * 0.2
    FROM ReseauExterne
);



----Avec agrégation :
SELECT u.idU, u.prenom, u.nom
FROM Utilisateur u
JOIN ReseauExterne r ON u.idU = r.idU
GROUP BY u.idU, u.prenom, u.nom
HAVING COUNT(DISTINCT r.nom_reseau) >= (
    SELECT COUNT(DISTINCT nom_reseau) * 0.2
    FROM ReseauExterne
);

--Les utilisateurs ayant participé à des événements payant (sachnat que le prix peut être NULL) :
----Sans COALESCE :
SELECT DISTINCT u.idU, u.prenom, u.nom
FROM Utilisateur u
JOIN Participation p ON u.idU = p.idU
JOIN Evenement e ON p.idE = e.idE
WHERE e.prix > 0
ORDER BY u.idU;


----Avec COALESCE :
SELECT DISTINCT u.idU, u.prenom, u.nom
FROM Utilisateur u
JOIN Participation p ON u.idU = p.idU
JOIN Evenement e ON p.idE = e.idE
WHERE e.prix > 0 OR e.prix IS NULL
ORDER BY u.idU;

--Tous les utilisateurs qui ont donné au moins deux avis positifs successifs (dans l'ordre des titres) avec une note qui augmente d'un avis à l'autre :
SELECT DISTINCT re.idU
FROM Avis a1
JOIN AppAvis aa1 ON a1.idAAv = aa1.idAAv
JOIN ReseauExterne re ON aa1.idRE = re.idRE

JOIN Avis a2 ON re.idU = (
    SELECT re2.idU
    FROM ReseauExterne re2
    JOIN AppAvis aa2 ON re2.idRE = aa2.idRE
    WHERE aa2.idAAv = a2.idAAv
    LIMIT 1
)
AND a2.idAAv <> a1.idAAv -- éviter même avis

WHERE a1.note > 5
  AND a2.note > 5
  AND a1.titre > a2.titre -- ordre arbitraire sur titre
  AND a1.note > a2.note;


--Paires d'utilisateurs qui aiment des personnes ayant au moins un même tag utilisateur :
SELECT DISTINCT (a1.idU1, a2.idU1)
FROM Aime a1
JOIN Aime a2 ON a1.idU2 = a2.idU2
JOIN TagUtilisateur tu1 ON a1.idU2 = tu1.idU
JOIN TagUtilisateur tu2 ON a2.idU2 = tu2.idU AND tu1.idT = tu2.idT
WHERE a1.idU1 < a2.idU1;

--Trouver deux utilisateurs distincts qui suivent au moins un même type_contenu :
SELECT DISTINCT re1.idU, re2.idU, cs1.type_contenu
FROM CompteSuivi cs1
JOIN AppSocial as1 ON cs1.idAs = as1.idAs
JOIN ReseauExterne re1 ON as1.idRe = re1.idRe

JOIN CompteSuivi cs2 ON cs1.type_contenu = cs2.type_contenu
JOIN AppSocial as2 ON cs2.idAs = as2.idAs
JOIN ReseauExterne re2 ON as2.idRe = re2.idRe

WHERE re1.idU < re2.idU;

--Trouver les paires d'utilisateurs liés par un tag commun, qui ont participé ensemble à un événement, et à afficher les tags associés (éventuellement) au lieu de l’événement.
SELECT DISTINCT tu1.idU, tu2.idU, tu1.idT, e.idL, tl.idT AS tag_lieu
FROM TagUtilisateur tu1
JOIN TagUtilisateur tu2 ON tu1.idT = tu2.idT AND tu1.idU < tu2.idU
JOIN Participation p1 ON tu1.idU = p1.idU
JOIN Participation p2 ON tu2.idU = p2.idU AND p1.idE = p2.idE
JOIN Evenement e ON p1.idE = e.idE
LEFT JOIN TagLieu tl ON e.idL = tl.idL;

--Les paires d'utilisateur qui ont organisé des événements dans le même lieu, où les dates des événements sont séparées de 10 jours ou moins.
SELECT DISTINCT o1.idU AS organisateur1, o2.idU AS organisateur2, e1.idL AS lieu_commun
FROM Organisateur o1
JOIN Evenement e1 ON o1.idE = e1.idE
JOIN Organisateur o2 ON o1.idU < o2.idU
JOIN Evenement e2 ON o2.idE = e2.idE
WHERE e1.idL = e2.idL
  AND ABS(EXTRACT(DAY FROM e1.date_event - e2.date_event)) <= 10
ORDER BY organisateur1, organisateur2, lieu_commun;