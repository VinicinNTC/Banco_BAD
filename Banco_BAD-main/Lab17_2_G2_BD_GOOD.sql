-- Banco PJ (Brasileirao Serie A e B) - SQL Server 
-- Script unico: cria o banco do zero, as tabelas com chaves estrangeiras dentro do CREATE TABLE, e insere dados de exemplo.
-- Executar no SQL Server Management Studio (to usando a 2022 mas acho q a 2019 funciona tambem) selecionar tudo e executar (F5).
--

-- Faz Recomecar do zero (deixa tu rodar o script varias vezes no f5 sem ter q ficar dando drop pra rodar dnv)
USE master;
GO
IF DB_ID('PJ') IS NOT NULL
BEGIN
    ALTER DATABASE PJ SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PJ;
END
GO

-- 1) Criar e selecionar o banco
CREATE DATABASE PJ;
GO
USE PJ;
GO

-- 2) Tabelas, na ordem: quem e referenciado vem antes de quem referencia

CREATE TABLE Campeonato
(
    IdCampeonato     INT PRIMARY KEY IDENTITY(1,1),
    Nome             VARCHAR(20),
    NumeroTimes      INT,
    NumeroRebaixados INT,
    NumeroPromovidos INT,
    Rodadas          INT,
    IdSuperior       INT,   -- divisao acima
    IdInferior       INT,   -- divisao abaixo
    CONSTRAINT FK_Campeonato_Superior FOREIGN KEY (IdSuperior) REFERENCES Campeonato(IdCampeonato),
    CONSTRAINT FK_Campeonato_Inferior FOREIGN KEY (IdInferior) REFERENCES Campeonato(IdCampeonato)
);

CREATE TABLE Estadio
(
    IdEstadio           INT PRIMARY KEY IDENTITY(1,1),
    Nome                VARCHAR(60),
    Fundacao            INT,   -- ano da fundaçao
    Cidade              VARCHAR(40),
    CapacidadeCasa      INT,
    CapacidadeVisitante INT,
    PartidasJogadas     INT,
    VitoriasCasa        INT
);

CREATE TABLE Clube
(
    IdClube      INT PRIMARY KEY IDENTITY(1,1),
    Nome         VARCHAR(30),
    Fundacao     INT NULL,
    Abreviacao   VARCHAR(3),
    Nacao        VARCHAR(30),
    IdCampeonato INT,
    IdEstadio    INT,
    IdAfiliado   INT,   -- clube parceiro (afiliado): outro clube ligado a este
    CONSTRAINT FK_Clube_Campeonato FOREIGN KEY (IdCampeonato) REFERENCES Campeonato(IdCampeonato),
    CONSTRAINT FK_Clube_Estadio    FOREIGN KEY (IdEstadio)    REFERENCES Estadio(IdEstadio),
    CONSTRAINT FK_Clube_Afiliado   FOREIGN KEY (IdAfiliado)   REFERENCES Clube(IdClube)
);

CREATE TABLE Jogador
(
    IdJogador     INT PRIMARY KEY IDENTITY(1,1),
    Nome          VARCHAR(30),
    Idade         INT,
    Altura        INT,   -- em centimetros
    IdClube       INT,
    Nacionalidade VARCHAR(20),
    Camisa        INT,
    PePreferido   VARCHAR(10),
    CONSTRAINT FK_Jogador_Clube FOREIGN KEY (IdClube) REFERENCES Clube(IdClube)
);

CREATE TABLE Partida
(
    IdPartida        INT PRIMARY KEY IDENTITY(1,1),
    DataEHora        DATETIME,
    IdClubeCasa      INT,
    IdClubeVisitante INT,
    NomeArbitro      VARCHAR(30),
    IdCampeonato     INT,
    GolsCasa         INT,
    GolsFora         INT,
    CONSTRAINT FK_Partida_ClubeCasa      FOREIGN KEY (IdClubeCasa)      REFERENCES Clube(IdClube),
    CONSTRAINT FK_Partida_ClubeVisitante FOREIGN KEY (IdClubeVisitante) REFERENCES Clube(IdClube),
    CONSTRAINT FK_Partida_Campeonato     FOREIGN KEY (IdCampeonato)     REFERENCES Campeonato(IdCampeonato)
);
GO

-- 3) Inserts pra teste
-- Ordem: tem que ser na mesma ordem da criação das tabelas (Campeonato > Estadio > Clube > Jogador > partida)
--    (a chave estrangeira so aceita Ids que ja existem)

-- Campeonato (Id 1, 2, 3). Superior/Inferior entram no UPDATE logo abaixo,
-- porque um campeonato nao pode apontar para outro que ainda nao existe.

INSERT INTO Campeonato (Nome, NumeroTimes, NumeroRebaixados, NumeroPromovidos, Rodadas, IdSuperior, IdInferior)
VALUES
('Serie A', 20, 4, 0, 38,   NULL, NULL),
('Serie B', 20, 4, 4, 38,   NULL, NULL),
('Serie C', 20, 4, 4, NULL, NULL, NULL);

UPDATE Campeonato SET IdInferior = 2                 WHERE IdCampeonato = 1; -- abaixo da A: B
UPDATE Campeonato SET IdSuperior = 1, IdInferior = 3 WHERE IdCampeonato = 2; -- acima: A / abaixo: C
UPDATE Campeonato SET IdSuperior = 2                 WHERE IdCampeonato = 3; -- acima da C: B

-- Estadio (Id 1 a 8). Capacidade total em CapacidadeCasa; o resto NULL (nao informado).
INSERT INTO Estadio (Nome, Fundacao, Cidade, CapacidadeCasa, CapacidadeVisitante, PartidasJogadas, VitoriasCasa)
VALUES
('Neo Quimica Arena', 2014, 'Sao Paulo',      48905, NULL, NULL, NULL),
('Arena MRV',         2023, 'Belo Horizonte', 46000, NULL, NULL, NULL),
('Arena Fonte Nova',  2013, 'Salvador',       50025, NULL, NULL, NULL),
('Arena da Baixada',  1914, 'Curitiba',       42372, NULL, NULL, NULL),
('Ressacada',         1983, 'Florianopolis',  17800, NULL, NULL, NULL),
('Rei Pele',          1970, 'Maceio',         17126, NULL, NULL, NULL),
('Heriberto Hulse',   1955, 'Criciuma',       19225, NULL, NULL, NULL),
('Alfredo Jaconi',    1975, 'Caxias do Sul',  19924, NULL, NULL, NULL);

-- Clube (Id 1 a 8): 1-4 na Serie A (IdCampeonato = 1), 5-8 na Serie B (IdCampeonato = 2)
INSERT INTO Clube (Nome, Fundacao, Abreviacao, Nacao, IdCampeonato, IdEstadio, IdAfiliado)
VALUES
('Corinthians',          1910, 'COR', 'Brasil', 1, 1, NULL),
('Atletico Mineiro',     1908, 'CAM', 'Brasil', 1, 2, NULL),
('Bahia',                1931, 'BAH', 'Brasil', 1, 3, NULL),
('Athletico Paranaense', 1924, 'CAP', 'Brasil', 1, 4, NULL),
('Avai',                 1923, 'AVA', 'Brasil', 2, 5, NULL),
('CRB',                  1912, 'CRB', 'Brasil', 2, 6, NULL),
('Criciuma',             1947, 'CRI', 'Brasil', 2, 7, NULL),
('Juventude',            1913, 'JUV', 'Brasil', 2, 8, NULL);

-- Exemplo de IdAfiliado (nao eh parceria real): Bahia (3) com Avai (5) como parceiros
UPDATE Clube SET IdAfiliado = 5 WHERE IdClube = 3;

-- Jogador (FICTICIOS, 1 por clube)
INSERT INTO Jogador (Nome, Idade, Altura, IdClube, Nacionalidade, Camisa, PePreferido)
VALUES
('Carlos Silva',    27, 180, 1, 'Brasileira', 9,  'Direito'),
('Mateus Rocha',    22, 175, 2, 'Brasileira', 10, 'Esquerdo'),
('Lucas Pereira',   30, 188, 3, 'Brasileira', 1,  'Direito'),
('Diego Fernandez', 25, 178, 4, 'Argentina',  7,  'Ambos'),
('Rafael Costa',    29, 183, 5, 'Brasileira', 5,  'Direito'),
('Bruno Lima',      24, 172, 6, 'Brasileira', 11, 'Esquerdo'),
('Tiago Santos',    33, 185, 7, 'Brasileira', 4,  'Direito'),
('Pedro Alves',     21, 176, 8, 'Brasileira', 8,  'Esquerdo');

-- Partida (FICTICIAS: placares e arbitros inventados)
INSERT INTO Partida (DataEHora, IdClubeCasa, IdClubeVisitante, NomeArbitro, IdCampeonato, GolsCasa, GolsFora)
VALUES
('20260906 16:00', 1, 2, 'Marcos Oliveira', 1, 2, 1),
('20260906 18:30', 3, 4, 'Paulo Mendes',    1, 0, 0),
('20260906 16:00', 5, 6, 'Marcos Oliveira', 2, 1, 1),
('20260906 18:30', 7, 8, 'Paulo Mendes',    2, 3, 2);
GO

-- 4) Consultas tabelas
 -- Campeonato > Estadio > Clube > Jogador > partida)

SELECT * From Campeonato
SELECT * From Estadio
SELECT * From Clube
SELECT * From Jogador
SELECT * From Partida

-- inner join só pega os valores que dão match em ambas tabelas meio q uma intersecção

-- Clube com estadio
SELECT Clube.Nome, Estadio.Nome
FROM Clube
JOIN Estadio ON Estadio.IdEstadio = Clube.IdEstadio;

-- Partidas dos times
SELECT Clubecasa.Nome AS Casa, Partida.GolsCasa, Partida.GolsFora, Clubefora.Nome AS Visitante
FROM Partida
JOIN Clube Clubecasa ON Clubecasa.IdClube = Partida.IdClubeCasa
Join Clube Clubefora ON Clubefora.IdClube = Partida.IdClubeVisitante;