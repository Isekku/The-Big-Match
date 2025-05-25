/* Suppression des tables si elles existent déjà et leur séquence */
DROP TABLE IF EXISTS 
    tag,
    tagutilisateur,
    taglieu,
    tagevenement,
    souhait,
    reseauexterne,
    participation,
    orientation,
    organisateurexterne,
    organisateur,
    objetachete,
    messageappsocial,
    listesouhait,
    lieu,
    genreutilisateur,
    genre,
    evenementsuivi,
    evenementpasse,
    evenement,
    contenu,
    comptesuivi,
    avis,
    appsocial,
    appaviscontenu,
    appavis,
    appachat,
    aime,
    utilisateur
CASCADE;

-- Ensuite, supprimer toutes les séquences

DROP SEQUENCE IF EXISTS 
    utilisateur_idu_seq,
    tag_idt_seq,
    reseauexterne_idre_seq,
    lieu_idl_seq,
    evenement_ide_seq,
    appsocial_idas_seq,
    appavis_idaav_seq,
    appachat_idaac_seq
CASCADE;

/* Creation des tables */

-- Partie Utilisateur :
CREATE TABLE genre (
    nom_genre VARCHAR(200) NOT NULL,
    type_genre VARCHAR(200) NOT NULL,
    PRIMARY KEY (nom_genre, type_genre)
);

CREATE TABLE orientation (
    nom_orientation VARCHAR(200) NOT NULL,
    description_orientation VARCHAR(1000),
    PRIMARY KEY (nom_orientation)
);

CREATE TABLE utilisateur (
    idU SERIAL NOT NULL,
    nom_genre VARCHAR(200) NOT NULL,
    type_genre VARCHAR(200) NOT NULL,
    nom_orientation VARCHAR(200) NOT NULL,
    nom VARCHAR(200) NOT NULL,
    prenom VARCHAR(200) NOT NULL,
    email VARCHAR(200) NOT NULL,
    numero_tel CHAR(10),
    mdp_hash VARCHAR(200) NOT NULL,
    age INT NOT NULL,
    taille INT,
    couleur_peau VARCHAR(200),
    couleur_yeux VARCHAR(200),
    corpulence VARCHAR(200),
    photo_profil_url VARCHAR(200),
    derniere_connexion TIMESTAMP,
    bio VARCHAR(200),
    isPremium BOOLEAN NOT NULL,
    last_localisation_latitude DECIMAL(9,6),
    last_localisation_longitude DECIMAL(9,6),

    PRIMARY KEY (idU),
    CONSTRAINT fk_genre FOREIGN KEY (nom_genre, type_genre) REFERENCES genre(nom_genre, type_genre) ON DELETE CASCADE,
    CONSTRAINT fk_orientation FOREIGN KEY (nom_orientation) REFERENCES orientation(nom_orientation) ON DELETE CASCADE,
    CONSTRAINT chk_age CHECK (age >= 18)
);

CREATE TABLE genreUtilisateur (
    idU INT NOT NULL,
    nom_genre VARCHAR(200) NOT NULL,
    type_genre VARCHAR(200) NOT NULL,
    genre_assigne_naiss VARCHAR(200),
    pronom_preferes VARCHAR(200),
    transition_sociale BOOLEAN,
    transition_medicale BOOLEAN,

    PRIMARY KEY (idU, nom_genre, type_genre),
    CONSTRAINT fk_utilisateur FOREIGN KEY (idU) REFERENCES utilisateur(idU) ON DELETE CASCADE,
    CONSTRAINT fk_genre FOREIGN KEY (nom_genre, type_genre) REFERENCES genre(nom_genre, type_genre) ON DELETE CASCADE
);

CREATE TABLE aime (
    idU1 INT NOT NULL,
    idU2 INT NOT NULL,

    PRIMARY KEY (idU1, idU2),
    CONSTRAINT fk_utilisateur_1 FOREIGN KEY (idU1) REFERENCES utilisateur(idU) ON DELETE CASCADE,
    CONSTRAINT fk_utilisateur_2 FOREIGN KEY (idU2) REFERENCES utilisateur(idU) ON DELETE CASCADE
);

-- Partie Événement :
CREATE TABLE lieu (
    idL SERIAL NOT NULL,
    nom VARCHAR(200) NOT NULL,
    adresse VARCHAR(200) NOT NULL,
    description_lieu VARCHAR(1000),

    PRIMARY KEY (idL)
);

CREATE TABLE evenement (
    idE SERIAL NOT NULL,
    idL INT NOT NULL,
    nom VARCHAR(200) NOT NULL,
    prix INT,
    description_event VARCHAR(1000),
    date_event TIMESTAMP NOT NULL,

    PRIMARY KEY (idE),
    CONSTRAINT fk_lieu FOREIGN KEY (idL) REFERENCES lieu(idL) ON DELETE CASCADE
);

CREATE TABLE organisateur (
    idU INT NOT NULL,
    idE INT NOT NULL,

    PRIMARY KEY (idU, idE),
    CONSTRAINT fk_utilisateur FOREIGN KEY (idU) REFERENCES utilisateur(idU) ON DELETE CASCADE,
    CONSTRAINT fk_evenement FOREIGN KEY (idE) REFERENCES evenement(idE) ON DELETE CASCADE
);

CREATE TABLE participation (
    idU INT NOT NULL,
    idE INT NOT NULL,
    type_participation VARCHAR(200),

    PRIMARY KEY (idU, idE),
    CONSTRAINT fk_utilisateur FOREIGN KEY (idU) REFERENCES utilisateur(idU) ON DELETE CASCADE,
    CONSTRAINT fk_evenement FOREIGN KEY (idE) REFERENCES evenement(idE) ON DELETE CASCADE
);

-- Partie Tag :
CREATE TABLE tag (
    idT SERIAL NOT NULL,
    nom VARCHAR(200) NOT NULL,
    categorie_tag VARCHAR(200) NOT NULL,

    PRIMARY KEY (idT)
);

CREATE TABLE tagUtilisateur (
    idT INT NOT NULL,
    idU INT NOT NULL,

    PRIMARY KEY (idT, idU),
    CONSTRAINT fk_tag FOREIGN KEY (idT) REFERENCES tag(idT) ON DELETE CASCADE,
    CONSTRAINT fk_utilisateur FOREIGN KEY (idU) REFERENCES utilisateur(idU) ON DELETE CASCADE
);

CREATE TABLE tagLieu (
    idT INT NOT NULL,
    idL INT NOT NULL,

    PRIMARY KEY (idT, idL),
    CONSTRAINT fk_tag FOREIGN KEY (idT) REFERENCES tag(idT) ON DELETE CASCADE,
    CONSTRAINT fk_lieu FOREIGN KEY (idL) REFERENCES lieu(idL) ON DELETE CASCADE
);

CREATE TABLE tagEvenement (
    idT INT NOT NULL,
    idE INT NOT NULL,

    PRIMARY KEY (idT, idE),
    CONSTRAINT fk_tag FOREIGN KEY (idT) REFERENCES tag(idT) ON DELETE CASCADE,
    CONSTRAINT fk_evenement FOREIGN KEY (idE) REFERENCES evenement(idE) ON DELETE CASCADE
);

-- Partie Réseau :
CREATE TABLE reseauExterne (
    idRE SERIAL NOT NULL,
    idU INT NOT NULL,
    nom_reseau VARCHAR(200) NOT NULL,
    pseudo VARCHAR(200) NOT NULL,

    PRIMARY KEY (idRE),
    CONSTRAINT fk_utilisateur FOREIGN KEY (idU) REFERENCES utilisateur(idU) ON DELETE CASCADE
);

---- Partie App Social :
CREATE TABLE appSocial (
    idAS SERIAL NOT NULL,
    idRE INT NOT NULL,
    nb_abonne INT NOT NULL,

    PRIMARY KEY (idAS),
    CONSTRAINT fk_reseau_externe FOREIGN KEY (idRE) REFERENCES reseauExterne(idRE) ON DELETE CASCADE
);

CREATE TABLE messageAppSocial (
    idAS INT NOT NULL,
    contenu VARCHAR(1000) NOT NULL,
    date_envoi DATE,

    PRIMARY KEY (idAS, contenu),
    CONSTRAINT fk_app_social FOREIGN KEY (idAS) REFERENCES appSocial(idAS) ON DELETE CASCADE
);

CREATE TABLE compteSuivi (
    idAS INT NOT NULL,
    pseudo VARCHAR(200),
    nb_abonne INT,
    type_contenu VARCHAR(200),

    CONSTRAINT fk_app_social FOREIGN KEY (idAS) REFERENCES appSocial(idAS) ON DELETE CASCADE
);

CREATE TABLE evenementSuivi (
    idAS INT NOT NULL,
    nom_orga VARCHAR(200) NOT NULL,
    nom_event VARCHAR(200) NOT NULL,
    genre VARCHAR(200) NOT NULL,
    nb_abonne INT,

    PRIMARY KEY (idAS, nom_orga, nom_event),
    CONSTRAINT fk_app_social FOREIGN KEY (idAS) REFERENCES appSocial(idAS) ON DELETE CASCADE,
    CONSTRAINT unique_nomorga_nomevent UNIQUE (nom_orga, nom_event)
);

CREATE TABLE evenementPasse (
    idAS INT NOT NULL,
    nom_event VARCHAR(200) NOT NULL,
    date_event DATE NOT NULL,
    organisateur VARCHAR(200) NOT NULL,
    genre VARCHAR(200) NOT NULL,

    PRIMARY KEY (idAS, nom_event, date_event, organisateur),
    CONSTRAINT fk_app_social FOREIGN KEY (idAS) REFERENCES appSocial(idAS) ON DELETE CASCADE
);

CREATE TABLE organisateurExterne (
    nom_orga VARCHAR(200) NOT NULL,
    nom_event VARCHAR(200) NOT NULL,
    idE INT NOT NULL,
    date_event DATE NOT NULL,
    lien_externe VARCHAR(1000) NOT NULL,

    PRIMARY KEY (nom_orga, nom_event, idE),
    CONSTRAINT fk_evenement_suivi FOREIGN KEY (nom_orga, nom_event) REFERENCES evenementSuivi(nom_orga, nom_event) ON DELETE CASCADE,
    CONSTRAINT fk_evenement FOREIGN KEY (idE) REFERENCES evenement(idE) ON DELETE CASCADE
);

---- Partie App Achat :
CREATE TABLE appAchat (
    idAAc SERIAL NOT NULL,
    idRE INT NOT NULL,
    isPremium BOOLEAN,

    PRIMARY KEY (idAAc),
    CONSTRAINT fk_reseau_externe FOREIGN KEY (idRE) REFERENCES reseauExterne(idRE) ON DELETE CASCADE
);

CREATE TABLE objetAchete (
    idAAc INT NOT NULL,
    genre VARCHAR(200) NOT NULL,
    prix VARCHAR(200) NOT NULL,
    date_achat DATE,

    CONSTRAINT fk_app_achat FOREIGN KEY (idAAc) REFERENCES appAchat(idAAc) ON DELETE CASCADE
);

CREATE TABLE listeSouhait (
    idAAc INT NOT NULL,
    nom_objet VARCHAR(200),
    genre_objet VARCHAR(200),

    CONSTRAINT fk_app_achat FOREIGN KEY (idAAc) REFERENCES appAchat(idAAc) ON DELETE CASCADE
);

---- Partie App Avis :
CREATE TABLE appAvis (
    idAAv SERIAL NOT NULL,
    idRE INT NOT NULL,
    genre_pref VARCHAR(200),
    prefere VARCHAR(200),

    PRIMARY KEY (idAAv),
    CONSTRAINT fk_reseau_externe FOREIGN KEY (idRE) REFERENCES reseauExterne(idRE) ON DELETE CASCADE
);

CREATE TABLE contenu (
    titre VARCHAR(200) NOT NULL,
    createur VARCHAR(200) NOT NULL,
    donnee VARCHAR(8000),

    PRIMARY KEY (titre, createur)
);

CREATE TABLE appAvisContenu (
    idAAv INT NOT NULL,
    titre VARCHAR(200) NOT NULL,
    createur VARCHAR(200) NOT NULL,

    PRIMARY KEY (idAAv, titre, createur),
    CONSTRAINT fk_contenu FOREIGN KEY (titre, createur) REFERENCES contenu(titre, createur) ON DELETE CASCADE
);

CREATE TABLE avis (
    idRE INT NOT NULL,
    idAAv INT NOT NULL,
    titre VARCHAR(200) NOT NULL,
    createur VARCHAR(200) NOT NULL,
    note INT,
    explication VARCHAR(200),

    PRIMARY KEY (idRE, idAAv, titre, createur),
    CONSTRAINT fk_reseau_externe FOREIGN KEY (idRE) REFERENCES reseauExterne(idRE) ON DELETE CASCADE,
    CONSTRAINT fk_app_avis FOREIGN KEY (idAAv) REFERENCES appAvis(idAAv) ON DELETE CASCADE,
    CONSTRAINT fk_contenu FOREIGN KEY (titre, createur) REFERENCES contenu(titre, createur) ON DELETE CASCADE
);

CREATE TABLE souhait (
    idAAv INT NOT NULL,
    nom VARCHAR(200),
    genre VARCHAR(200),

    CONSTRAINT fk_app_avis FOREIGN KEY (idAAv) REFERENCES appAvis(idAAv) ON DELETE CASCADE
);