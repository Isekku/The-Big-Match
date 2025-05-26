--Jsp si vrmt necessaire c'est pour avoir la distance 
CREATE EXTENSION IF NOT EXISTS cube;
CREATE EXTENSION IF NOT EXISTS earthdistance;

-- 1. Vue de matching “full” intégrant tags, mots dominants, proximité, événements et orientations
CREATE OR REPLACE VIEW view_match_full AS
WITH 
  -- 1.1 Extrait les mots dominants (avis ≥ 5) par utilisateur
  mots AS (
    SELECT 
      re.idu,
      LOWER(regexp_replace(word, '[^\w]+', '', 'g')) AS mot
    FROM public.avis            a
    JOIN public.appavis        aa ON aa.idaav = a.idaav
    JOIN public.reseauexterne  re ON re.idre  = aa.idre
    CROSS JOIN LATERAL regexp_split_to_table(trim(a.explication), '\s+') AS word
    WHERE a.note >= 5
  ),
  frequences AS (
    SELECT idu, mot, COUNT(*) AS freq
    FROM mots
    GROUP BY idu, mot
  ),
  mots_max_freq AS (
    SELECT idu, mot,
           RANK() OVER (PARTITION BY idu ORDER BY freq DESC) AS rk
    FROM frequences
  ),
  mots_top1 AS (
    SELECT idu, mot
    FROM mots_max_freq
    WHERE rk = 1
  )

SELECT
  u1.idu AS user_id,
  u2.idu AS candidate_id,

  -- 25% : nombre brut de tags communs
  (
    SELECT COUNT(DISTINCT t2.idt)
    FROM public.tagutilisateur t1
    JOIN public.tagutilisateur t2
      ON t2.idt = t1.idt
     AND t2.idu = u2.idu
    WHERE t1.idu = u1.idu
  ) * 0.25

  -- 30% : partage du mot dominant d’avis
  + (
      EXISTS (
        SELECT 1
        FROM mots_top1 m1
        JOIN mots_top1 m2
          ON m2.mot = m1.mot
         AND m2.idu = u2.idu
        WHERE m1.idu = u1.idu
      )::int
    ) * 0.30

  -- 20% : proximité géographique (0 → 1 km → 1 ; ≥ 50 km → 0)
  + GREATEST(
      0,
      1
      - earth_distance(
          ll_to_earth(u1.last_localisation_latitude,  u1.last_localisation_longitude),
          ll_to_earth(u2.last_localisation_latitude,  u2.last_localisation_longitude)
        ) / 50000.0
    ) * 0.20

  -- 15% : événements passés communs
  + (
      SELECT COUNT(DISTINCT p2.ide)
      FROM public.participation p1
      JOIN public.participation p2
        ON p2.ide = p1.ide
       AND p2.idu = u2.idu
      JOIN public.evenement e
        ON e.ide = p1.ide
      WHERE p1.idu = u1.idu
        AND e.date_event < NOW()
    ) * 0.15

  -- 10% : compatibilité d’orientation
  + (
      (
        -- Hétérosexuel : attirance envers l’autre genre
        (u1.nom_orientation = 'Hétérosexuel' AND u1.nom_genre <> u2.nom_genre)
        -- Homosexuel : même genre
     OR (u1.nom_orientation = 'Homosexuel' AND u1.nom_genre = u2.nom_genre)
        -- Bisexuel ou Pansexuel : attirance multi-genre
     OR u1.nom_orientation IN ('Bisexuel','Pansexuel')
      )::int
    ) * 0.10

  AS score

FROM public.utilisateur u1
JOIN public.utilisateur u2
  ON u2.idu <> u1.idu
;

-- 2. Requête finale : top 10 recommandations avec classement RANK (ex-æquo gérés)
WITH ranked AS (
  SELECT
    user_id,
    candidate_id,
    ROUND(score::numeric, 4)                                    AS final_score,
    RANK() OVER (PARTITION BY user_id ORDER BY score DESC)       AS recommendation_rank
  FROM view_match_full
  WHERE user_id = :target_user_id
    AND score   >   0
)
SELECT
  user_id,
  candidate_id,
  final_score,
  recommendation_rank
FROM ranked
WHERE recommendation_rank <= 10
ORDER BY recommendation_rank, final_score DESC
LIMIT 10;
