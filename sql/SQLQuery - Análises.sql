-- DATASET:

WITH SalarioAtual AS (
    SELECT 
        BusinessEntityID,
        Rate,
        ROW_NUMBER() OVER (
            PARTITION BY BusinessEntityID 
            ORDER BY RateChangeDate DESC
        ) AS rn
    FROM HumanResources.EmployeePayHistory
)

SELECT 
    e.BusinessEntityID,
    e.JobTitle,
    e.Gender,
    d.Name AS Departamento,
    s.Rate AS SalarioHora
FROM HumanResources.Employee e

JOIN SalarioAtual s
    ON e.BusinessEntityID = s.BusinessEntityID
    AND s.rn = 1

JOIN HumanResources.EmployeeDepartmentHistory ed
    ON e.BusinessEntityID = ed.BusinessEntityID
    AND ed.EndDate IS NULL

JOIN HumanResources.Department d
    ON ed.DepartmentID = d.DepartmentID;

-- VIEW

IF OBJECT_ID('vw_Base_Salarial', 'V') IS NOT NULL
    DROP VIEW vw_Base_Salarial;
GO

CREATE VIEW vw_Base_Salarial
AS
WITH SalarioAtual AS (
    SELECT 
        BusinessEntityID,
        Rate,
        ROW_NUMBER() OVER (
            PARTITION BY BusinessEntityID 
            ORDER BY RateChangeDate DESC
        ) AS rn
    FROM HumanResources.EmployeePayHistory
)

SELECT 
    e.BusinessEntityID,
    e.JobTitle,
    e.Gender,
    d.Name AS Departamento,
    s.Rate AS SalarioHora
FROM HumanResources.Employee e

JOIN SalarioAtual s
    ON e.BusinessEntityID = s.BusinessEntityID
    AND s.rn = 1

JOIN HumanResources.EmployeeDepartmentHistory ed
    ON e.BusinessEntityID = ed.BusinessEntityID
    AND ed.EndDate IS NULL

JOIN HumanResources.Department d
    ON ed.DepartmentID = d.DepartmentID;
GO

-- VISUALIZAR

SELECT *
FROM vw_Base_Salarial
ORDER BY SalarioHora DESC;

-- DESIGUALDADE POR DEPARTAMENTO:

SELECT 
    Departamento,
    AVG(SalarioHora) AS Media,
    MIN(SalarioHora) AS Minimo,
    MAX(SalarioHora) AS Maximo,
    MAX(SalarioHora) / MIN(SalarioHora) AS Razao_Desigualdade,
    COUNT(*) AS Total_Funcionarios
FROM vw_Base_Salarial
GROUP BY Departamento
ORDER BY Media DESC;

/* 

Observa-se uma forte concentração salarial no topo da estrutura organizacional, 
com o departamento Executive apresentando média três vezes superior à maioria dos 
setores operacionais, apesar de contar com apenas dois funcionários. Em contraste, 
o setor Production, responsável pelo maior contingente de trabalhadores, 
apresenta baixa remuneração média e elevada desigualdade interna, indicando forte hierarquização.

*/

-- SUPERSALÁRIOS

SELECT *
FROM vw_Base_Salarial
WHERE SalarioHora > 60
ORDER BY SalarioHora DESC;

/*

Observa-se forte concentração salarial em um grupo restrito de cinco dirigentes, 
responsáveis pelas principais áreas estratégicas da organização. 
Esses indivíduos, que representam menos de 2% do quadro funcional, 
concentram rendimentos até nove vezes superiores à média de seus respectivos departamentos,
evidenciando a centralização do poder econômico e decisório.

*/

-- Quanto esses 5 concentram do total da folha

SELECT 
    SUM(SalarioHora) AS Total_Empresa,
    SUM(CASE 
            WHEN SalarioHora > 60 THEN SalarioHora 
            ELSE 0 
        END) AS Total_Elite
FROM vw_Base_Salarial;

--

SELECT 
    (SUM(CASE WHEN SalarioHora > 60 THEN SalarioHora ELSE 0 END)
     / SUM(SalarioHora)) * 100 AS Percentual_Elite
FROM vw_Base_Salarial;

/* 

Verificou-se que apenas cinco dirigentes, correspondendo a cerca de 1,6% do quadro funcional, 
concentram aproximadamente 7,7% da massa salarial da empresa. 
Tal concentração evidencia um padrão de distribuição altamente desigual, 
no qual funções diretivas se apropriam de parcela desproporcional 
do valor econômico produzido coletivamente.

*/

-- Curva “classe baixa x média x elite”

WITH Faixas AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY SalarioHora) AS Quintil
    FROM vw_Base_Salarial
)

SELECT 
    Quintil,
    COUNT(*) AS Pessoas,
    AVG(SalarioHora) AS Media,
    SUM(SalarioHora) AS Total
FROM Faixas
GROUP BY Quintil
ORDER BY Quintil;

/*

A análise por quintis evidencia forte concentração de renda nos estratos superiores da empresa. 
Enquanto os 20% com menores salários concentram apenas 10,7% da massa salarial, 
os 20% mais bem remunerados apropriam-se de aproximadamente 39,4%, revelando uma estrutura piramidal 
típica de organizações hierarquizadas. Em cada 10 trabalhadores, 2 ficam com quase metade do dinheiro.

*/


