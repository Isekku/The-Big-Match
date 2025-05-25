#!/bin/bash

# Variables de connexion (modifie-les si besoin)
DB_NAME="the_big_match"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"

# Exécution des commandes COPY
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -f insert_donnee_fixe.sql

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy utilisateur (nom_genre,type_genre,nom_orientation,nom,prenom,email,numero_tel,mdp_hash,age,taille,couleur_peau,couleur_yeux,corpulence,photo_profil_url,derniere_connexion,bio,isPremium,last_localisation_latitude,last_localisation_longitude) FROM 'CSV/utilisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy genreUtilisateur (idU, nom_genre, type_genre, genre_assigne_naiss, pronom_preferes, transition_sociale, transition_medicale) FROM 'CSV/genre_utilisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy aime (idU1, idU2) FROM 'CSV/aime.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy lieu (nom, adresse, description_lieu) FROM 'CSV/lieu.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy evenement (idL, nom, prix, description_event, date_event) FROM 'CSV/evenement.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT -c "\copy organisateur (idU, idE) FROM 'CSV/organisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');"

# Import participation.csv en gérant les conflits (doublons)
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_participation (
    idU INT,
    idE INT,
    type_participation VARCHAR(200)
);

\copy temp_participation FROM 'CSV/participation.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO participation (idU, idE, type_participation)
SELECT idU, idE, type_participation FROM temp_participation
ON CONFLICT DO NOTHING;

DROP TABLE temp_participation;
EOF

# Import tagUtilisateur.csv en gérant les conflits (doublons)
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_tagUtilisateur (
    idT INT,
    idU INT
);

\copy temp_tagUtilisateur FROM 'CSV/tagUtilisateur.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO tagUtilisateur (idT, idU)
SELECT idT, idU FROM temp_tagUtilisateur
ON CONFLICT DO NOTHING;

DROP TABLE temp_tagUtilisateur;
EOF

# Import tagLieu.csv en gérant les conflits (doublons)
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_tagLieu (
    idT INT,
    idL INT
);

\copy temp_tagLieu FROM 'CSV/tagLieu.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO tagLieu (idT, idL)
SELECT idT, idL FROM temp_tagLieu
ON CONFLICT DO NOTHING;

DROP TABLE temp_tagLieu;
EOF

# Import tagEvenement.csv en gérant les conflits (doublons)
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_tagEvenement (
    idT INT,
    idE INT
);

\copy temp_tagEvenement FROM 'CSV/tagEvenement.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

INSERT INTO tagEvenement (idT, idE)
SELECT idT, idE FROM temp_tagEvenement
ON CONFLICT DO NOTHING;

DROP TABLE temp_tagEvenement;
EOF

# Import reseauExterne.csv en gérant les conflits (doublons)
psql -U $DB_USER -h $DB_HOST -d $DB_NAME -p $DB_PORT << EOF
CREATE TEMP TABLE temp_reseauExterne (
    idU INT,
    nom_reseau VARCHAR(200),
    pseudo VARCHAR(200)
);

\copy temp_reseauExterne FROM 'CSV/reseauExterne.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');

DELETE FROM temp_reseauExterne WHERE nom_reseau = '';

INSERT INTO reseauExterne (idU, nom_reseau, pseudo)
SELECT idU, nom_reseau, pseudo FROM temp_reseauExterne
ON CONFLICT DO NOTHING;

DROP TABLE temp_reseauExterne;
EOF