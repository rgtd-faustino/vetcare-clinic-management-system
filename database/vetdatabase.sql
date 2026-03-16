DROP DATABASE IF EXISTS VetCare;
CREATE DATABASE VetCare;
USE VetCare;


CREATE TABLE Cadeia (
	designacaoCad VARCHAR(70) PRIMARY KEY,
    localidadeCad VARCHAR(50) NOT NULL
);
    

CREATE TABLE Clinica (
	localidade VARCHAR(50) PRIMARY KEY UNIQUE,
	designacaoCad VARCHAR(70) NOT NULL, -- referência à cadeia
    FOREIGN KEY (designacaoCad) REFERENCES Cadeia(designacaoCad) ON DELETE CASCADE,
    -- a designação das clínicas vão ter sempre o nome da cadeia por detrás, é virtual porque não precisamos de pesquisar por ela ou ordenar e não tem um uso útil então não vamos ocupar espaço
    designacaoCompleta VARCHAR(70) GENERATED ALWAYS AS (concat(designacaoCad, ' - ', localidade)) VIRTUAL, -- não é preciso meter aqui unique porque a localidade já é a primary key então isto é automaticamente unique
    arteria VARCHAR(255) NOT NULL,
    numero INT NOT NULL,
    andar INT DEFAULT NULL,
    codPostal1 DECIMAL(4, 0) NOT NULL, -- 4 digitos e 0 decimais
	codPostal2 DECIMAL(3, 0) NOT NULL,
    -- não ordenamos por código postal nem morada então também podemos usar virtual aqui porque não tem uso real no código para além de ser decorativo
	codPostalTotal VARCHAR(8) GENERATED ALWAYS AS (concat(lpad(codPostal1, 4, '0'),'-', lpad(codPostal2, 3, '0'))) VIRTUAL, -- se o número não tiver 4/3 digitos metemos um 0 à esquerda com o lpad porque tem que ser 4/3 dígitos
	morada VARCHAR(255) GENERATED ALWAYS AS (concat_ws(', ', arteria, numero, andar, localidade, codPostalTotal)) VIRTUAL,
    latitude DECIMAL(8,6) NOT NULL,
    longitude DECIMAL(9,6) NOT NULL,
    altitude DECIMAL(6,2) NOT NULL,
    coordenadas VARCHAR(255) GENERATED ALWAYS AS (concat_ws(', ', latitude, longitude, altitude)) VIRTUAL,
    contacto INT NOT NULL,
	CONSTRAINT contacto CHECK (LENGTH(CAST(contacto AS CHAR)) = 9) -- meter os numeros de telemovel a 9 digitos
);


CREATE TABLE Cliente (
    nifCliente INT PRIMARY KEY,
    concelho VARCHAR(50),
    freguesia VARCHAR(50),
    distrito VARCHAR(50),
    CONSTRAINT nifCliente CHECK (LENGTH(CAST(nifCliente AS CHAR)) = 9),
    nome VARCHAR(100) NOT NULL,
    contactos VARCHAR(255) NOT NULL,

    -- 🔐 password (hash)
    passwordHash CHAR(64) NOT NULL,

    codPostal1 DECIMAL(4, 0) NOT NULL,
    codPostal2 DECIMAL(3, 0) NOT NULL,
    codPostalTotal VARCHAR(8) GENERATED ALWAYS AS (
        concat(lpad(codPostal1, 4, '0'),'-', lpad(codPostal2, 3, '0'))
    ) VIRTUAL,
    arteria VARCHAR(255) NOT NULL,
    numero INT NOT NULL,
    andar INT DEFAULT NULL,
    morada VARCHAR(255) GENERATED ALWAYS AS (
        concat_ws(', ', arteria, numero, andar, distrito, concelho, freguesia, codPostalTotal)
    ) VIRTUAL,
    capitalSocial INT DEFAULT NULL,
    prefLinguistica VARCHAR(100)
);



CREATE TABLE Rececionista (
	nifRececionista INT PRIMARY KEY,
    localidade VARCHAR(50) NOT NULL,
	FOREIGN KEY (localidade) REFERENCES Clinica(localidade),
    nome VARCHAR(100) NOT NULL
);

CREATE TABLE Especie (
    idEspecie INT AUTO_INCREMENT PRIMARY KEY,
    nomeComum VARCHAR(100) NOT NULL,
    nomeCientifico VARCHAR(100) NOT NULL,
    regimeAlimentar VARCHAR(100) NOT NULL,
    padraoAtividade VARCHAR(100) NOT NULL,
    vocalizacao VARCHAR(100) NOT NULL
);

CREATE TABLE Raca (
    idRaca INT AUTO_INCREMENT PRIMARY KEY,
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie) ON DELETE CASCADE,
    nomeRaca VARCHAR(100) NOT NULL,
    expectativaVida INT NOT NULL,
    pesoAdulto DECIMAL(5, 2) NOT NULL,
    comprimentoAdulto DECIMAL(3, 2) NOT NULL,
    porte VARCHAR(50) NOT NULL
);

CREATE TABLE PredGenetica (
    idPredisposicao INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(255) NOT NULL
);



CREATE TABLE CuidadosEspecificos (
    idCuidado INT AUTO_INCREMENT PRIMARY KEY,
    descricao VARCHAR(255) NOT NULL
);

CREATE TABLE RacaPredGenetica (
    idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca) ON DELETE CASCADE,
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie) ON DELETE CASCADE,
    idPredisposicao INT NOT NULL,
    FOREIGN KEY (idPredisposicao) REFERENCES PredGenetica(idPredisposicao) ON DELETE CASCADE,
    PRIMARY KEY (idRaca, idEspecie, idPredisposicao)
);

CREATE TABLE RacaCuidadosEspecificos (
    idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca) ON DELETE CASCADE,
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie) ON DELETE CASCADE,
    idCuidado INT NOT NULL,
    FOREIGN KEY (idCuidado) REFERENCES CuidadosEspecificos(idCuidado) ON DELETE CASCADE,
    PRIMARY KEY (idRaca, idEspecie, idCuidado)
);

CREATE TABLE ServicoMedico (
    designacao VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Veterinario (
	nLicenca INT PRIMARY KEY,
    localidade VARCHAR(50) NOT NULL,
	FOREIGN KEY (localidade) REFERENCES Clinica(localidade) ON DELETE CASCADE,
    nome VARCHAR(100) NOT NULL,
    horaEntrada TIME NOT NULL,
    horaSaida TIME NOT NULL,
    CONSTRAINT horario_veterinario_valido CHECK (horaSaida > horaEntrada)
);

-- o horário serve para ver quando as clinicas estão abertas e quando é que os veterinários estão a trabalhar
CREATE TABLE Horario (
	idHorario INT AUTO_INCREMENT PRIMARY KEY,
	localidadeClinica VARCHAR(50) NOT NULL, -- a localidade para quem vai o horário
    FOREIGN KEY (localidadeClinica) REFERENCES Clinica(localidade) ON DELETE CASCADE, -- sem localidade não existe horário então quando ela é apagada o horário também
    nLicenca INT NOT NULL, -- a disponibilidade do veterinário
    FOREIGN KEY (nLicenca) REFERENCES Veterinario(nLicenca) ON DELETE CASCADE,
    diaUtil DATE NOT NULL,
	horaAbertura TIME NOT NULL,
	horaFecho TIME NOT NULL,
    CONSTRAINT horario_valido CHECK (horaFecho > horaAbertura)
);

CREATE TABLE FeriadoBase (
    idFeriado INT AUTO_INCREMENT PRIMARY KEY,
    tipo ENUM('FIXO', 'MOVEL') NOT NULL,
    dia INT DEFAULT NULL,
    mes INT DEFAULT NULL,
    descricao VARCHAR(100) NOT NULL
);


CREATE TABLE ServicoMedicoHorario (
    idHorario INT NOT NULL,
    FOREIGN KEY (idHorario) REFERENCES Horario(idHorario) ON DELETE CASCADE,
    designacao VARCHAR(50) NOT NULL,
    FOREIGN KEY (designacao) REFERENCES ServicoMedico(designacao) ON DELETE CASCADE,
    PRIMARY KEY (idHorario, designacao)
);

CREATE TABLE ExcecaoHorario (
    idExcecao INT AUTO_INCREMENT PRIMARY KEY,
    localidadeClinica VARCHAR(50) DEFAULT NULL, -- porque podem ser nacionais
    FOREIGN KEY (localidadeClinica) REFERENCES Clinica(localidade),
    dataExcecao DATE NOT NULL,
    tipoExcecao ENUM('Feriado Nacional', 'Feriado Municipal', 'Férias', 'Luto', 'Outro') NOT NULL,
    descricao VARCHAR(255) NOT NULL,
    UNIQUE (localidadeClinica, dataExcecao) -- para não haver repetições de feriados no mesmo dia para a mesma localidade
);

-- liga os veterinários aos serviços médicos que podem fazer
CREATE TABLE VeterinarioServicoMedico (
	nLicenca INT NOT NULL,
    FOREIGN KEY (nLicenca) REFERENCES Veterinario(nLicenca) ON DELETE CASCADE,
	designacao VARCHAR(50) NOT NULL,
    FOREIGN KEY (designacao) REFERENCES ServicoMedico(designacao) ON DELETE CASCADE,
    PRIMARY KEY (nLicenca, designacao)
);


CREATE TABLE ServicoDetalhe (
	idDetalhe INT AUTO_INCREMENT PRIMARY KEY,
    designacao VARCHAR(50) NOT NULL,
    FOREIGN KEY (designacao) REFERENCES ServicoMedico(designacao) ON DELETE CASCADE,
    nomeDetalhe VARCHAR(255) NOT NULL
);
    
CREATE TABLE FichaClinicaAnimal (
    idFicha INT AUTO_INCREMENT PRIMARY KEY,
    
    idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    
    nifCliente INT NOT NULL,
    FOREIGN KEY (nifCliente) REFERENCES Cliente(nifCliente),
    
    nifRececionista INT NOT NULL,
    FOREIGN KEY (nifRececionista) REFERENCES Rececionista(nifRececionista),
    
    nome VARCHAR(100) NOT NULL,
    sexo CHAR NOT NULL,
    CONSTRAINT chk_sexo CHECK (sexo = 'F' OR sexo = 'M'),
    
    dataNascimento DATE NOT NULL,
    
    idPai INT DEFAULT NULL,
    idMae INT DEFAULT NULL,
    FOREIGN KEY (idPai) REFERENCES FichaClinicaAnimal(idFicha),
    FOREIGN KEY (idMae) REFERENCES FichaClinicaAnimal(idFicha),
    
    filiacao VARCHAR(255) GENERATED ALWAYS AS (CONCAT_WS(', ', idPai, idMae)) VIRTUAL,
    
    estadoReprodutivo VARCHAR(100) NOT NULL,
    
    -- Correção do numTransponder
    numTransponder VARCHAR(15) DEFAULT NULL UNIQUE,
    CONSTRAINT chk_numTransponder CHECK (numTransponder IS NULL OR numTransponder REGEXP '^[0-9]{15}$'),
    
    numTransponderFormatado VARCHAR(20) GENERATED ALWAYS AS (
        CASE
            WHEN numTransponder IS NULL THEN NULL
            ELSE CONCAT('ISO ', LEFT(numTransponder, 5), '/', RIGHT(numTransponder, 10))
        END
    ) STORED,
    
    caracteristicasEspecificas VARCHAR(255) DEFAULT NULL,
    foto LONGBLOB NOT NULL,
    peso DECIMAL(3,1) NOT NULL,
    cor VARCHAR(50) NOT NULL,
    dataCriacao DATE NOT NULL
);


CREATE TABLE Alergia (
	alergia VARCHAR(50) PRIMARY KEY
);

-- esta tabela foi criada porque uma ficha clinica pode conter várias alergias e se quisermos organizar por alergias podemos fazer isso facilmente ao contrário de se tivessemos usado alergias VARCHAR(255)
CREATE TABLE FichaClinicaAnimalAlergia (
    idFicha INT NOT NULL,
    alergia VARCHAR(50) NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha) ON DELETE CASCADE,
    FOREIGN KEY (alergia) REFERENCES Alergia(alergia) ON DELETE CASCADE,
    PRIMARY KEY (idFicha, alergia)
);

-- o veterinário será atribuído automaticamente com base no serviço e disponibilidade
CREATE TABLE Agendamento (
	idAgendamento INT AUTO_INCREMENT PRIMARY KEY,
    designacaoServico VARCHAR(100) NOT NULL,
	FOREIGN KEY (designacaoServico) REFERENCES ServicoMedico(designacao),
    localidade VARCHAR(50) NOT NULL,
    FOREIGN KEY (localidade) REFERENCES Clinica(localidade),
    nifCliente INT NOT NULL,
    FOREIGN KEY (nifCliente) REFERENCES Cliente(nifCliente),
    idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
    dataHora DATETIME NOT NULL,
    nLicencaAtribuida INT, -- veterinário atribuído ao serviço desejado no trigger ent tem que começar por null
    FOREIGN KEY (nLicencaAtribuida) REFERENCES Veterinario(nLicenca),
    estado ENUM('Válido', 'Inválido', 'Concluído', 'Cancelado') NOT NULL,
    motivoEstado VARCHAR(255) NOT NULL, -- explicação do estado
	custo DECIMAL(10,2) DEFAULT NULL,
    UNIQUE(idFicha, dataHora) -- um animal só pode ter 1 agendamento num momento específico
);

CREATE TABLE HistoricoClinico (
    idHistorico INT AUTO_INCREMENT PRIMARY KEY,
    idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
    nLicenca INT NOT NULL,
    FOREIGN KEY (nLicenca) REFERENCES Veterinario(nLicenca)
);

CREATE TABLE VeterinarioHistoricoClinico (
    idHistorico INT NOT NULL,
	FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico) ON DELETE CASCADE,
    nLicenca INT NOT NULL,
    FOREIGN KEY (nLicenca) REFERENCES Veterinario(nLicenca) ON DELETE CASCADE,
    PRIMARY KEY (idHistorico, nLicenca)
);

CREATE TABLE Sintoma (
    sintoma VARCHAR(50) PRIMARY KEY
);

CREATE TABLE Consulta (
	idConsulta INT AUTO_INCREMENT PRIMARY KEY,
    idHistorico INT NOT NULL,
    FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico),
	idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
	idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    motivo VARCHAR(255) NOT NULL,
    diagnostico VARCHAR(100) NOT NULL,
    medicacao VARCHAR(100) NOT NULL,
    dataHora DATETIME NOT NULL,
    veterinario VARCHAR(100) NOT NULL
);



-- esta tabela foi criada porque uma consulta pode ter vários sintomas e se quisermos organizar por sintomas podemos facilmente ao contrário de se tivessemos usado sintomas VARCHAR(255)
CREATE TABLE ConsultaSintoma (
	idConsulta INT NOT NULL,
    sintoma VARCHAR(50) NOT NULL,
    FOREIGN KEY (idConsulta) REFERENCES Consulta(idConsulta) ON DELETE CASCADE,
    FOREIGN KEY (sintoma) REFERENCES Sintoma(sintoma) ON DELETE CASCADE,
    PRIMARY KEY (idConsulta, sintoma)
);


CREATE TABLE ExameFisico (
	idExame INT AUTO_INCREMENT PRIMARY KEY,
    idHistorico INT NOT NULL,
    FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico),
	idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
	idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    dataHora DATETIME NOT NULL,
    freqRespiratoria INT NOT NULL,
    temperatura DECIMAL (3, 1) NOT NULL,
    peso DECIMAL (3, 1) NOT NULL,
    freqCardiaca INT NOT NULL
);


CREATE TABLE ResultadoExame (
	idResultado INT AUTO_INCREMENT PRIMARY KEY,
	idHistorico INT NOT NULL,
    FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico),
	idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
	idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    dataHora DATETIME NOT NULL,
    tipoExame VARCHAR(50) NOT NULL,
    descricao VARCHAR(100) NOT NULL
);

CREATE TABLE Vacinacao (
	idVacinacao INT AUTO_INCREMENT PRIMARY KEY,
    idHistorico INT NOT NULL,
    FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico),
	idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
	idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    dataHora DATETIME NOT NULL,
    tipoVacina VARCHAR(100) NOT NULL,
    fabricante VARCHAR(50) NOT NULL
);

CREATE TABLE TratamentoTerapeutico (
	idTratamento INT AUTO_INCREMENT PRIMARY KEY,
    idHistorico INT NOT NULL,
    FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico),
	idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
	idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    dataHora DATETIME NOT NULL,
    descricao VARCHAR(255) NOT NULL
);

CREATE TABLE Cirurgia (
	idCirurgia INT AUTO_INCREMENT PRIMARY KEY,
    idHistorico INT NOT NULL,
    FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico),
	idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
	idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    dataHora DATETIME NOT NULL,
    tipoCirurgia VARCHAR(100) NOT NULL,
    notas VARCHAR(255) NOT NULL
);

CREATE TABLE Desparasitacao (
	idDesparasitacao INT AUTO_INCREMENT PRIMARY KEY,
    idHistorico INT NOT NULL,
    FOREIGN KEY (idHistorico) REFERENCES HistoricoClinico(idHistorico),
	idFicha INT NOT NULL,
    FOREIGN KEY (idFicha) REFERENCES FichaClinicaAnimal(idFicha),
	idRaca INT NOT NULL,
    FOREIGN KEY (idRaca) REFERENCES Raca(idRaca),
    idEspecie INT NOT NULL,
    FOREIGN KEY (idEspecie) REFERENCES Especie(idEspecie),
    dataHora DATETIME NOT NULL,
    tipo VARCHAR(100) NOT NULL,
    produtosUtil VARCHAR(255) NOT NULL
);

CREATE TABLE Avaliacao (
	idAvaliacao INT AUTO_INCREMENT PRIMARY KEY,
    nifCliente INT NOT NULL,
    FOREIGN KEY (nifCliente) REFERENCES Cliente(nifCliente),
    designacao VARCHAR(50) NOT NULL,
    FOREIGN KEY (designacao) REFERENCES ServicoMedico(designacao),
    dataHora DATETIME NOT NULL,
    classificacao ENUM('Adorei', 'Gostei', 'Não vou voltar') NOT NULL,
    comentario VARCHAR(255) NOT NULL
);


CREATE TABLE RececionistaAgendamento (
	nifRececionista INT NOT NULL,
    FOREIGN KEY (nifRececionista) REFERENCES Rececionista(nifRececionista) ON DELETE CASCADE,
    idAgendamento INT NOT NULL,
    FOREIGN KEY (idAgendamento) REFERENCES Agendamento(idAgendamento) ON DELETE CASCADE,
    PRIMARY KEY (nifRececionista, idAgendamento)
);


DELIMITER $$

CREATE PROCEDURE PreencherHorariosAno(IN p_ano INT, IN p_localidade VARCHAR(50), IN p_nLicenca INT, IN p_horaAbertura TIME, IN p_horaFecho TIME)
BEGIN
    DECLARE veterinarioData DATE;
    DECLARE veterinarioDataFim DATE;
    DECLARE veterinariodiaSemana INT;
    
    SET veterinarioData = CONCAT(p_ano, '-01-01');
    SET veterinarioDataFim = CONCAT(p_ano, '-12-31');
    
    WHILE veterinarioData <= veterinarioDataFim DO
        SET veterinariodiaSemana = DAYOFWEEK(veterinarioData); -- apanhamos o dia da semana sendo que 1 = domingo e 7 = sábado
        
        IF veterinariodiaSemana BETWEEN 2 AND 6 THEN -- só queremos dias úteis
        -- se não existir uma exceção então metemos inserimos o horário
        -- temos de apanhar a exceção no mesmo dia que o veterinário trabalha e comparar com as datas nos horários
        -- também temos de ver se a localidade do veterinário tem feriados regionais e ver no geral para os nacionais
        -- (para os nacionais vai ser sempre verdadeiro porque são todos null, para os regionais se for uma localidade diferente da do vet então não conta)
            IF NOT EXISTS (SELECT 'x' FROM ExcecaoHorario WHERE dataExcecao = veterinarioData AND (localidadeClinica = p_localidade OR localidadeClinica IS NULL)) THEN -- o 'x' é irrelevante, só queremos ver se há uma linha que corresponda
                INSERT INTO Horario (localidadeClinica, nLicenca, diaUtil, horaAbertura, horaFecho)
                VALUES (p_localidade, p_nLicenca, veterinarioData, p_horaAbertura, p_horaFecho);
            END IF;
        END IF;
        
        SET veterinarioData = DATE_ADD(veterinarioData, INTERVAL 1 DAY); -- adicionamos um dia e vamos para o próximo
    END WHILE;
END$$

CREATE PROCEDURE PreencherTodosHorarios(IN p_ano INT)
BEGIN
    DECLARE veterinarioDone INT DEFAULT FALSE;
    DECLARE veterinarionLicenca INT;
    DECLARE veterinarioLocalidade VARCHAR(50);
    
    -- um cursor é tipo um loop que percorre cada linha neste caso de todos os veterinários apanhando a sua licença e a localidade onde trabalham
    DECLARE cur CURSOR FOR 
        SELECT nLicenca, localidade FROM Veterinario;
    
    -- quando há não houver mais linhas metemos a variável a true e saímos do loop
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET veterinarioDone = TRUE;
    
    -- abrimos o cursor e criamos um horário para cada veterinário, ou seja, metemos um veterinário a trabalhar numa localidade, porque depois ao criar um veterinário é que decidimos as suas horas de trabalho
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO veterinarionLicenca, veterinarioLocalidade;
        IF veterinarioDone THEN
            LEAVE read_loop;
        END IF;
        
        CALL PreencherHorariosAno(p_ano, veterinarioLocalidade, veterinarionLicenca, '09:00:00', '17:00:00'); -- horas de abertura e fecho das clínicas
    END LOOP;
    CLOSE cur;
END$$


CREATE PROCEDURE GerarFeriadosAno(IN p_ano INT)
BEGIN
    INSERT INTO ExcecaoHorario (localidadeClinica, dataExcecao, tipoExcecao, descricao)
    SELECT
        NULL,
        STR_TO_DATE(
            CONCAT(p_ano, '-', LPAD(mes,2,'0'), '-', LPAD(dia,2,'0')),
            '%Y-%m-%d'
        ),
        'Feriado Nacional',
        descricao
    FROM FeriadoBase
    WHERE tipo = 'FIXO'
      AND NOT EXISTS (
          SELECT 1
          FROM ExcecaoHorario e
          WHERE e.dataExcecao = STR_TO_DATE(
              CONCAT(p_ano, '-', LPAD(mes,2,'0'), '-', LPAD(dia,2,'0')),
              '%Y-%m-%d'
          )
      );
END$$



-- ao criar um veterinário temos de ver se as suas horas de trabalho são entre as horas de trabalho da clínica (horas que esteja aberta)
CREATE TRIGGER ValidarHorarioVeterinario
BEFORE INSERT ON Veterinario
FOR EACH ROW
BEGIN
    DECLARE clinicaAbre TIME;
    DECLARE clinicaFecha TIME;
    
    -- apanhamos as horas da clínica onde o veterinário trabalha (com base no NEW do valor que está atualmente a ser inserido na criação do veterinário)
    SELECT h.horaAbertura, h.horaFecho
	INTO clinicaAbre, clinicaFecha -- criamos variáveis para continuarmos a usar os valores
    FROM Horario h
    WHERE h.localidadeClinica = NEW.localidade
    LIMIT 1;
    
	-- checka as horas de entrada e saída a serem inseridas
    IF NEW.horaEntrada < clinicaAbre OR NEW.horaSaida > clinicaFecha THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Horário do veterinário incompatível com horário da clínica';
    END IF;
END$$
    
-- temos de associar os rececionistas aos agendamentos feitos
DELIMITER $$
CREATE TRIGGER AssociarRececionistaAgendamento
AFTER INSERT ON Agendamento
FOR EACH ROW
BEGIN
    DECLARE v_nifRececionista INT;
    
    -- procuramos por um rececionista da mesma localidade que a do agendamento
    SELECT nifRececionista INTO v_nifRececionista
    FROM Rececionista
    WHERE localidade = NEW.localidade
    LIMIT 1;
    
    IF v_nifRececionista IS NOT NULL THEN
        INSERT INTO RececionistaAgendamento (nifRececionista, idAgendamento)
        VALUES (v_nifRececionista, NEW.idAgendamento);
    END IF;
END$$

-- pequeno detalhe, não podemos deixar que a data de nascimento seja no futuro nem que a ficha tenha existido antes do animal ter nascido
CREATE TRIGGER ValidarDataNascimento
BEFORE INSERT ON FichaClinicaAnimal
FOR EACH ROW
BEGIN
    IF NEW.dataNascimento > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '❌ Data de nascimento não pode ser no futuro';
    END IF;
    
    IF NEW.dataCriacao < NEW.dataNascimento THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '❌ Data de criação da ficha não pode ser anterior ao nascimento do animal';
    END IF;
END$$

-- outro pequeno detalhe, não podemos deixar que o custo do agendamento seja negativo
CREATE TRIGGER ValidarCustoAgendamento
BEFORE UPDATE ON Agendamento
FOR EACH ROW
BEGIN
    IF NEW.custo IS NOT NULL AND NEW.custo < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = '❌ Custo não pode ser negativo';
    END IF;
END$$


-- antes de interirmos o agendamento temos de verificar se existe um veterinário para o agendamento feito, então temos o trigger que é chamado automaticamente quando corre um insert no agendamento
CREATE TRIGGER ValidarHorarioAgendamento
BEFORE INSERT ON Agendamento
FOR EACH ROW
BEGIN
    DECLARE agendamentoHora TIME;
    DECLARE agendamentoData DATE;
    DECLARE veterinarioDisponivel INT;
    DECLARE motivo VARCHAR(255);
    DECLARE temConflito INT;
    
    -- o NEW apanha o valor que está atualmente a ser inserido
    SET agendamentoHora = TIME(NEW.dataHora);
    SET agendamentoData = DATE(NEW.dataHora);

		-- procuramos um veterinário que:
		-- trabalhe na localidade do agendamento
		-- ofereça o serviço pretendido
		-- esteja disponível na data/hora do agendamento
		SELECT v.nLicenca INTO veterinarioDisponivel
		FROM Veterinario v
		-- não queremos fazer corss join porque um produto cartesiano entre 6 veterinários, 1000 horários e 20 serviços dariam 120 000 linhas e não faz sentido porque nós queremos um veterinário específico com a relação que quisermos ou seja
		-- um veterinário com o serviço específico no horário específico na localidade específica
		INNER JOIN VeterinarioServicoMedico vsm ON v.nLicenca = vsm.nLicenca
		INNER JOIN Horario h ON h.nLicenca = v.nLicenca
		-- podemos ver diretamente com as horas de trabalho do veterinário porque já sabemos que a clínica também está aberta nessas horas
		WHERE v.localidade = NEW.localidade AND vsm.designacao = NEW.designacaoServico AND h.localidadeClinica = NEW.localidade AND h.diaUtil = agendamentoData AND agendamentoHora BETWEEN v.horaEntrada AND v.horaSaida 
        -- não podemos deixar que haja um agendamento para o mesmo veterinário ao mesmo tempo então temos de ver se o vet tem um agendamento para a mesma hora (ou seja os que forem válidos)
        AND NOT EXISTS (
              SELECT 1 
              FROM Agendamento a2 
              WHERE a2.nLicencaAtribuida = v.nLicenca 
                AND a2.dataHora = NEW.dataHora
                AND a2.estado IN ('Válido')
          )
		LIMIT 1; -- apanha o primeiro veterinário que encontrarmos
		
		-- se encontrarmos um veterinário então o estado valor a ser atribuído no insert é válido e explicado o estado. também adicionamos a licença
		IF veterinarioDisponivel IS NOT NULL THEN
				SET NEW.nLicencaAtribuida = veterinarioDisponivel;
				SET NEW.estado = 'Válido';
				SET NEW.motivoEstado = CONCAT('✅ Veterinário atribuído: ', veterinarioDisponivel);
			ELSE -- se não houver veterinário então é inválido e o motivo é explicado depois
				SET NEW.nLicencaAtribuida = NULL;
				SET NEW.estado = 'Inválido';
				
				-- primeiro verificamos se existe algum veterinário (apanhamos a licença do veterinário e procuramos por ele na tabela do VeterinarioServicoMedico com o inner join) na localidade da clínica específica que ofereça este serviço específico
				IF NOT EXISTS (SELECT 'x' FROM Veterinario v INNER JOIN VeterinarioServicoMedico vsm ON v.nLicenca = vsm.nLicenca WHERE v.localidade = NEW.localidade AND vsm.designacao = NEW.designacaoServico) THEN
					SET NEW.motivoEstado = '❌ Nenhum veterinário oferece este serviço nesta clínica';
					
				-- se existir veterinário na localidade podemos aprofundar mais
				ELSE
					-- fim de semana e feriados, se a localidade estiver fechada é o primeiro que temos de ver, aqui é ver fim de semana
					IF DAYOFWEEK(agendamentoData) IN (1, 7) THEN -- se for especificamente 1 ou 7 (domingo ou sábado)
						SET NEW.motivoEstado = '❌ A clínica não funciona ao fim de semana';
					-- aqui é ver se é exceção
					ELSEIF EXISTS (SELECT 'x' FROM ExcecaoHorario WHERE dataExcecao = agendamentoData AND (localidadeClinica = NEW.localidade OR localidadeClinica IS NULL)) THEN
						SET NEW.motivoEstado = '❌ A clínica está encerrada (feriado/exceção)';
						
					-- e aqui já sabemos que a clínica está aberta e existe veterinário é ver se o próprio veterinário está disponível nas horas que queremos
					ELSEIF NOT EXISTS (SELECT 'x' FROM Horario h INNER JOIN Veterinario v ON h.nLicenca = v.nLicenca WHERE h.localidadeClinica = NEW.localidade AND h.diaUtil = agendamentoData AND agendamentoHora BETWEEN v.horaEntrada AND v.horaSaida) THEN
						SET NEW.motivoEstado = '❌ Nenhum veterinário não trabalha nestas horas.';
					ELSE
						SET NEW.motivoEstado = '❌ Todos os veterinários estão ocupados neste horário';
					END IF;
				END IF;
			END IF;

END$$


CREATE PROCEDURE ConcluirAgendamento(IN p_idAgendamento INT) 
BEGIN
    DECLARE v_idFicha INT;
    DECLARE v_nLicenca INT;
    DECLARE v_estadoAtual VARCHAR(20);
    DECLARE p_idHistorico INT;
        
    -- apanhamos os dados do agendamento
    SELECT idFicha, nLicencaAtribuida, estado
    INTO v_idFicha, v_nLicenca, v_estadoAtual
    FROM Agendamento
    WHERE idAgendamento = p_idAgendamento;
    
    -- depois criamos um histórico clínico
    INSERT INTO HistoricoClinico (idFicha, nLicenca)
    VALUES (v_idFicha, v_nLicenca);
    
    SET p_idHistorico = LAST_INSERT_ID(); -- isto apanha o id do histórico que acabámos de criar
    
    -- associamos o veterinário ao histórico
    INSERT INTO VeterinarioHistoricoClinico (idHistorico, nLicenca)
    VALUES (p_idHistorico, v_nLicenca);
    
    -- e atualizamos o estado do agendamento para concluído
    UPDATE Agendamento
    SET estado = 'Concluído',
        motivoEstado = CONCAT('✔️ Consulta realizada. Histórico ID: ', p_idHistorico)
    WHERE idAgendamento = p_idAgendamento;
    
    SELECT CONCAT('✅ Agendamento concluído! Histórico criado: ', p_idHistorico) AS Resultado;
END$$

CREATE PROCEDURE CancelarAgendamento(IN p_idAgendamento INT, IN p_motivoCancelamento VARCHAR(255)) BEGIN
    DECLARE v_estadoAtual VARCHAR(20);
    
    -- apanhamos o estado atual e guardamo-lo para o podermos atualizar para cancelado depois com o motivo no parametro
    SELECT estado INTO v_estadoAtual
    FROM Agendamento
    WHERE idAgendamento = p_idAgendamento; -- temos de usar o agendamento com o ID específico no parametro
    
    UPDATE Agendamento -- isto apanha o agendamento criado e atualiza
    SET estado = 'Cancelado',
		-- o COALESCE retorna o primeiro valor não nulo, ou seja se a variável é nula então retorna o texto porque é um texto então não é nulo
        motivoEstado = CONCAT('⛔ Cancelado: ', COALESCE(p_motivoCancelamento, 'Sem motivo especificado'))
    WHERE idAgendamento = p_idAgendamento;
    
    SELECT '✅ Agendamento cancelado com sucesso' AS Resultado;
END$$



DELIMITER ;


CREATE VIEW Vista_AnimaisCompletos AS
SELECT 
    f.idFicha,
    f.nome AS nomeAnimal,
    e.nomeComum AS especie,
    r.nomeRaca AS raca,
    f.sexo,
    TIMESTAMPDIFF(YEAR, f.dataNascimento, CURDATE()) AS idade,
    f.peso,
    c.nome AS nomeDono,
    c.contactos,
    cli.localidade AS clinicaRegistro
FROM FichaClinicaAnimal f
JOIN Especie e ON f.idEspecie = e.idEspecie
JOIN Raca r ON f.idRaca = r.idRaca
JOIN Cliente c ON f.nifCliente = c.nifCliente
JOIN Rececionista rec ON f.nifRececionista = rec.nifRececionista
JOIN Clinica cli ON rec.localidade = cli.localidade;

CREATE VIEW Vista_AgendamentosDetalhados AS
SELECT 
    a.idAgendamento,
    f.nome AS animal,
    c.nome AS dono,
    c.contactos AS contactoDono,
    a.designacaoServico,
    cli.designacaoCompleta AS clinica,
    a.dataHora,
    v.nome AS veterinario,
    a.estado,
    a.motivoEstado,
    a.custo
FROM Agendamento a
JOIN FichaClinicaAnimal f ON a.idFicha = f.idFicha
JOIN Cliente c ON a.nifCliente = c.nifCliente
JOIN Clinica cli ON a.localidade = cli.localidade
LEFT JOIN Veterinario v ON a.nLicencaAtribuida = v.nLicenca;

CREATE VIEW Vista_HistoricoClinico AS
SELECT 
	f.idFicha,
    f.nome AS animal,
    e.nomeComum AS especie,
    c.motivo,
    c.diagnostico,
    c.medicacao,
    c.dataHora,
    v.nLicenca,
    v.nome AS veterinario,
    cli.localidade AS clinica
FROM Consulta c
JOIN FichaClinicaAnimal f ON c.idFicha = f.idFicha
JOIN Especie e ON f.idEspecie = e.idEspecie
JOIN HistoricoClinico h ON c.idHistorico = h.idHistorico
JOIN Veterinario v ON h.nLicenca = v.nLicenca
JOIN Clinica cli ON v.localidade = cli.localidade;USE VetCare;

CREATE OR REPLACE VIEW Vista_HistoricoClinico AS
SELECT
    hc.idHistorico,
    f.idFicha,
    f.nome AS animal,
    f.idEspecie,
    f.idRaca,
    f.nifCliente,
    f.sexo,
    f.dataNascimento,
    f.peso,
    f.cor,
    f.estadoReprodutivo,
    c.motivo,
    c.diagnostico,
    c.medicacao,
    c.dataHora,
    v.nome AS veterinario,
    v.localidade AS clinica,
    v.nLicenca
FROM
    HistoricoClinico hc
    INNER JOIN FichaClinicaAnimal f ON hc.idFicha = f.idFicha
    INNER JOIN Veterinario v ON hc.nLicenca = v.nLicenca
    LEFT JOIN Consulta c ON hc.idHistorico = c.idHistorico
ORDER BY
    c.dataHora DESC;




INSERT INTO Cadeia (designacaoCad, localidadeCad)
VALUES ('VetCare', 'Portugal');

INSERT INTO Clinica (localidade, designacaoCad, arteria, numero, andar, codPostal1, codPostal2, latitude, longitude, altitude, contacto)
VALUES 
('ÉVORA', 'VetCare', 'Rua de Avis', 44, NULL, 7460, 155, 38.5667, -7.9000, 300, 266123456),
('LISBOA', 'VetCare', 'Av. da Liberdade', 120, 1, 1250, 145, 38.7223, -9.1393, 80, 213456789),
('PORTO', 'VetCare', 'Rua de Santa Catarina', 312, 2, 4000, 443, 41.1496, -8.6109, 104, 223456789);

INSERT INTO ServicoMedico (designacao)
VALUES ('Consulta Geral'),
       ('Vacinação'),
       ('Cirurgia'),
       ('Análises');

INSERT INTO Veterinario (nLicenca, localidade, nome, horaEntrada, horaSaida)
VALUES
(1001, 'ÉVORA', 'Dr. Ricardo Martins', '09:00:00', '14:00:00'),
(1002, 'ÉVORA', 'Dra. Inês Almeida', '14:00:00', '17:00:00'),
(2001, 'LISBOA', 'Dr. Tiago Figueiredo', '9:00:00', '14:00:00'),
(2002, 'LISBOA', 'Dra. Ana Santos', '14:00:00', '17:00:00'),
(3001, 'PORTO', 'Dr. Luís Costa', '09:30:00', '14:30:00'),
(3002, 'PORTO', 'Dra. Sofia Oliveira', '14:00:00', '17:00:00');

INSERT INTO FeriadoBase (tipo, dia, mes, descricao) VALUES
-- Feriados nacionais FIXOS
('FIXO', 1, 1, 'Ano Novo'),
('FIXO', 25, 4, 'Dia da Liberdade'),
('FIXO', 1, 5, 'Dia do Trabalhador'),
('FIXO', 10, 6, 'Dia de Portugal'),
('FIXO', 15, 8, 'Assunção de Nossa Senhora'),
('FIXO', 5, 10, 'Implantação da República'),
('FIXO', 1, 11, 'Todos os Santos'),
('FIXO', 1, 12, 'Restauração da Independência'),
('FIXO', 8, 12, 'Imaculada Conceição'),
('FIXO', 25, 12, 'Natal');

INSERT INTO ExcecaoHorario (localidadeClinica, dataExcecao, tipoExcecao, descricao)
VALUES
('LISBOA', '2025-06-13', 'Feriado Municipal', 'Santo António'),
('PORTO', '2025-06-24', 'Feriado Municipal', 'São João'),
('ÉVORA', '2025-06-29', 'Feriado Municipal', 'São Pedro'),
('LISBOA', '2026-06-13', 'Feriado Municipal', 'Santo António'),
('PORTO', '2026-06-24', 'Feriado Municipal', 'São João'),
('ÉVORA', '2026-06-29', 'Feriado Municipal', 'São Pedro'),
('LISBOA', '2027-06-13', 'Feriado Municipal', 'Santo António'),
('PORTO', '2027-06-24', 'Feriado Municipal', 'São João'),
('ÉVORA', '2027-06-29', 'Feriado Municipal', 'São Pedro');

CALL GerarFeriadosAno(2025);
CALL GerarFeriadosAno(2026);
CALL GerarFeriadosAno(2027);
CALL GerarFeriadosAno(2028); 


CALL PreencherTodosHorarios(2025);
CALL PreencherTodosHorarios(2026);
CALL PreencherTodosHorarios(2027);
CALL PreencherTodosHorarios(2028);


INSERT INTO ServicoDetalhe (designacao, nomeDetalhe)
VALUES
('Consulta Geral', 'Consulta de rotina'),
('Consulta Geral', 'Consulta de emergência'),
('Vacinação', 'Vacinação anual antirrábica'),
('Cirurgia', 'Cirurgia de esterilização'),
('Cirurgia', 'Cirurgia de cardiologia'),
('Análises', 'Análise de sangue');

INSERT INTO VeterinarioServicoMedico (nLicenca, designacao)
VALUES
-- Dr. Ricardo Martins (Évora) - Generalista
(1001, 'Consulta Geral'),
(1001, 'Vacinação'),
(1001, 'Análises'),
-- Dra. Inês Almeida (Évora) - Cirurgiã
(1002, 'Consulta Geral'),
(1002, 'Cirurgia'),
(1002, 'Análises'),
-- Dr. Tiago Figueiredo (Lisboa) - Generalista
(2001, 'Consulta Geral'),
(2001, 'Vacinação'),
(2001, 'Análises'),
-- Dra. Ana Santos (Lisboa) - Especialista em cirurgia
(2002, 'Consulta Geral'),
(2002, 'Cirurgia'),
-- Dr. Luís Costa (Porto) - Generalista
(3001, 'Consulta Geral'),
(3001, 'Vacinação'),
(3001, 'Análises'),
-- Dra. Sofia Oliveira (Porto) - Todos os serviços
(3002, 'Consulta Geral'),
(3002, 'Vacinação'),
(3002, 'Cirurgia'),
(3002, 'Análises');

INSERT INTO Sintoma (sintoma)
VALUES ('Febre'), ('Tosse'), ('Cansaço');



INSERT INTO Alergia (alergia)
VALUES 
('Penicilina'),
('Sulfonamidas'),
('Proteína de frango'),
('Proteína de vaca'),
('Pólen'),
('Ácaros'),
('Produtos lácteos'),
('Anestésicos locais');







INSERT INTO Cliente (nifCliente, nome, concelho, freguesia, distrito, contactos,passwordHash, arteria, numero, codPostal1, codPostal2, prefLinguistica)
VALUES 
(123456789, 'João Silva', 'Évora', 'Sé e São Pedro', 'Évora', '912345678', SHA2('MinhaPassword123', 256), 'Rua das Flores', 10, 7000, 100, 'Português'),
(234567890, 'Maria Santos', 'Lisboa', 'Santa Maria Maior', 'Lisboa', '913456789',  SHA2('123', 256) ,'Rua do Ouro', 25, 1100, 200, 'Português'),
(345678901, 'Carlos Oliveira', 'Porto', 'Cedofeita', 'Porto', '914567890',SHA2('321', 256), 'Rua de Santa Catarina', 150, 4000, 300, 'Português');

INSERT INTO Rececionista (nifRececionista, localidade, nome)
VALUES 
(111111111, 'ÉVORA', 'Ana Rececionista'),
(222222222, 'LISBOA', 'Pedro Rececionista'),
(333333333, 'PORTO', 'Sofia Rececionista');

INSERT INTO Especie (nomeComum, nomeCientifico, regimeAlimentar, padraoAtividade, vocalizacao)
VALUES 
('Cão', 'Canis familiaris', 'Omnívoro', 'Diurno', 'Latido'),
('Gato', 'Felis catus', 'Carnívoro', 'Crepuscular', 'Miar'),
('Coelho', 'Oryctolagus cuniculus', 'Herbívoro', 'Crepuscular', 'Grunhido');

INSERT INTO Raca (idEspecie, nomeRaca, expectativaVida, pesoAdulto, comprimentoAdulto, porte)
VALUES 
(1, 'Labrador', 12, 30.00, 0.60, 'Grande'),
(1, 'Chihuahua', 15, 2.50, 0.20, 'Pequeno'),
(2, 'Persa', 15, 4.50, 0.45, 'Médio'),
(2, 'Siamês', 15, 3.80, 0.40, 'Médio'),
(1, 'Golden Retriever', 12, 32.00, 0.62, 'Grande'),
(3, 'Anão Holandês', 10, 1.20, 0.25, 'Pequeno');

INSERT INTO FichaClinicaAnimal
(idRaca, idEspecie, nifCliente, nifRececionista, nome, sexo,
 dataNascimento, estadoReprodutivo, peso, cor, dataCriacao, foto)
VALUES

-- Tutor 123456789 (2 animais)
-- Labrador (expectativa 12 anos) → ULTRAPASSOU + excesso de peso
(1, 1, 123456789, 111111111,
 'Rex', 'M', '2010-05-15', 'Não castrado',
 36.0, 'Dourado', '2024-01-10', 0x00),

-- Chihuahua (expectativa 15 anos) → ainda não ultrapassou, MAS excesso de peso
(2, 1, 123456789, 111111111,
 'Pipoca', 'F', '2014-03-20', 'Castrada',
 3.2, 'Creme', '2024-02-15', 0x00),


-- Tutor 234567890 (2 animais)
-- Persa → ainda não ultrapassou, excesso de peso
(3, 2, 234567890, 222222222,
 'Mimi', 'F', '2012-07-10', 'Não castrada',
 5.3, 'Cinzenta', '2024-01-20', 0x00),

-- Siamês → dentro da idade, peso normal
(4, 2, 234567890, 222222222,
 'Felix', 'M', '2016-11-05', 'Castrado',
 3.6, 'Preto e branco', '2024-03-01', 0x00),


-- Tutor 345678901 (2 animais)
-- Golden Retriever → ULTRAPASSOU expectativa + excesso de peso
(5, 1, 345678901, 333333333,
 'Luna', 'F', '2009-08-25', 'Castrada',
 39.0, 'Creme claro', '2024-01-05', 0x00),

-- Coelho Anão → dentro da idade, excesso de peso
(6, 3, 345678901, 333333333,
 'Tambor', 'M', '2018-01-15', 'Não castrado',
 1.8, 'Branco', '2024-02-20', 0x00);


INSERT INTO FichaClinicaAnimal (
    idRaca,
    idEspecie,
    nifCliente,
    nifRececionista,
    nome,
    sexo,
    dataNascimento,
    idPai,
    idMae,
    estadoReprodutivo,
    caracteristicasEspecificas,
    foto,
    peso,
    cor,
    dataCriacao
) VALUES (
    1,
    1,
    123456789,
    111111111,
    'Luna',
    'F',
    '2024-03-12',
    1,
    5,
    'Não reprodutivo',
    'Muito dócil',
    0x00,
    4.2,
    'Preto',
    CURDATE()
);


INSERT INTO FichaClinicaAnimalAlergia (idFicha, alergia)
VALUES
(1, 'Pólen'),
(2, 'Penicilina'),
(2, 'Ácaros'),
(3, 'Proteína de frango'),
(4, 'Sulfonamidas'),
(5, 'Anestésicos locais'),
(6, 'Produtos lácteos');

INSERT INTO Agendamento
(localidade, idFicha, designacaoServico, nifCliente, dataHora, custo)
-- o estado é introduzido automaticamente
VALUES
-- Usar 123456789 (João Silva)
('ÉVORA', 1, 'Consulta Geral', 123456789, '2025-02-10 10:00:00', 10.00),
('ÉVORA', 1, 'Consulta Geral', 123456789, '2025-02-10 20:00:00', 10.00),
('ÉVORA', 1, 'Consulta Geral', 123456789, '2025-02-11 10:00:00', 10.00),

-- Usar 234567890 (Maria Santos)
('LISBOA', 3, 'Análises', 234567890, '2025-02-15 14:00:00', 15.00),
('LISBOA', 3, 'Análises', 234567890, '2025-04-25 14:00:00', 15.00),
('LISBOA', 2, 'Vacinação', 234567890, '2025-02-12 12:00:00', 10.00),

-- Usar 345678901 (Carlos Oliveira)
('PORTO', 5, 'Cirurgia', 345678901, '2025-02-20 14:00:00', 30.00),
('PORTO', 5, 'Consulta Geral', 345678901, '2025-02-15 08:00:00', 10.00),
('PORTO', 6, 'Vacinação', 345678901, '2025-02-10 10:00:00', 10.00);


INSERT INTO HistoricoClinico (idFicha, nLicenca)
VALUES 
(1, 1001), -- Rex com Dr. Ricardo
(2, 1002), -- Pipoca com Dra. Inês
(3, 2001), -- Mimi com Dr. Tiago
(4, 2002), -- Felix com Dra. Ana
(5, 3001), -- Luna com Dr. Luís
(6, 3002); -- Tambor com Dra. Sofia


INSERT INTO VeterinarioHistoricoClinico (idHistorico, nLicenca)
VALUES
(1, 1001),
(2, 1002),
(3, 2001),
(4, 2002),
(5, 3001),
(6, 3002);


INSERT INTO Consulta 
(idHistorico, idFicha, idRaca, idEspecie, motivo, diagnostico, medicacao, dataHora, veterinario)
VALUES
(1, 1, 1, 1, 'Check-up de rotina', 'Animal saudável', 'Nenhuma', '2025-01-15 10:00:00', 'Dr. Ricardo Martins'),
(2, 2, 2, 1, 'Vacinação antirrábica', 'Vacinação preventiva', 'Vacina antirrábica', '2025-01-15 14:30:00', 'Dra. Inês Almeida'),
(3, 3, 3, 2, 'Febre alta', 'Infeção respiratória', 'Antibiótico', '2025-01-16 09:15:00', 'Dr. Tiago Figueiredo'),
(4, 4, 4, 2, 'Análises pré-cirúrgicas', 'Preparação para cirurgia', 'Nenhuma', '2025-01-16 11:00:00', 'Dra. Ana Santos'),
(5, 5, 5, 1, 'Pós-operatório', 'Recuperação normal', 'Anti-inflamatório', '2025-01-17 15:00:00', 'Dr. Luís Costa'),
(6, 6, 6, 3, 'Vacinação anual', 'Vacinação preventiva', 'Vacina polivalente', '2025-01-17 16:30:00', 'Dra. Sofia Oliveira');



INSERT INTO ConsultaSintoma (idConsulta, sintoma)
VALUES
(3, 'Febre'),
(3, 'Tosse'),
(5, 'Cansaço'),
(5, 'Tosse');

INSERT INTO ExameFisico (idHistorico, idFicha, idRaca, idEspecie, dataHora, freqRespiratoria, temperatura, peso, freqCardiaca)
VALUES
(1, 1, 1, 1, '2025-01-15 10:15:00', 25, 38.5, 12.3, 90),
(2, 2, 2, 1, '2025-01-15 14:45:00', 28, 38.7, 8.5, 95),
(3, 3, 3, 2, '2025-01-16 09:30:00', 22, 39.2, 5.2, 110),
(4, 4, 4, 2, '2025-01-16 11:15:00', 20, 38.3, 4.8, 100),
(5, 5, 5, 1, '2025-01-17 15:20:00', 26, 38.1, 15.7, 85),
(6, 6, 6, 3, '2025-01-17 16:45:00', 18, 38.9, 2.1, 120);

INSERT INTO ResultadoExame (idHistorico, idFicha, idRaca, idEspecie, dataHora, tipoExame, descricao)
VALUES
(1, 1, 1, 1, '2025-01-15 10:30:00', 'Hemograma completo', 'Valores dentro da normalidade'),
(3, 3, 3, 2, '2025-01-16 09:45:00', 'Análise de sangue', 'Leucócitos elevados - infeção presente'),
(4, 4, 4, 2, '2025-01-16 11:30:00', 'Hemograma pré-cirúrgico', 'Animal apto para cirurgia'),
(4, 4, 4, 2, '2025-01-16 11:45:00', 'Bioquímica renal', 'Função renal normal'),
(5, 5, 5, 1, '2025-01-17 15:35:00', 'Radiografia torácica', 'Pós-operatório sem complicações'),
(6, 6, 6, 3, '2025-01-17 17:00:00', 'Teste serológico', 'Anticorpos adequados');

INSERT INTO Vacinacao (idHistorico, idFicha, idRaca, idEspecie, dataHora, tipoVacina, fabricante)
VALUES
(2, 2, 2, 1, '2025-01-15 14:50:00', 'Antirrábica', 'Zoetis'),
(6, 6, 6, 3, '2025-01-17 17:15:00', 'Polivalente (V8)', 'MSD Animal Health'),
(6, 6, 6, 3, '2025-01-17 17:20:00', 'Antirrábica', 'Virbac');

INSERT INTO TratamentoTerapeutico (idHistorico, idFicha, idRaca, idEspecie, dataHora, descricao)
VALUES
(3, 3, 3, 2, '2025-01-16 10:00:00', 'Antibioterapia: Amoxicilina 10mg/kg de 12/12h durante 7 dias'),
(5, 5, 5, 1, '2025-01-17 15:50:00', 'Anti-inflamatório: Meloxicam 0.1mg/kg de 24/24h durante 5 dias'),
(5, 5, 5, 1, '2025-01-17 15:55:00', 'Analgésico: Tramadol 2mg/kg de 8/8h durante 3 dias');

INSERT INTO Cirurgia (idHistorico, idFicha, idRaca, idEspecie, dataHora, tipoCirurgia, notas)
VALUES
(4, 4, 4, 2, '2025-01-16 12:00:00', 'Ovariohisterectomia', 'Cirurgia eletiva. Procedimento sem complicações. Animal acordou bem da anestesia.'),
(5, 5, 5, 1, '2025-01-17 14:00:00', 'Remoção de massa cutânea', 'Massa benigna removida do membro anterior direito. Amostra enviada para histopatologia.');

INSERT INTO Desparasitacao (idHistorico, idFicha, idRaca, idEspecie, dataHora, tipo, produtosUtil)
VALUES
(1, 1, 1, 1, '2025-01-15 10:45:00', 'Interna', 'Milbemax - Comprimido oral'),
(1, 1, 1, 1, '2025-01-15 10:50:00', 'Externa', 'Bravecto - Spot-on'),
(2, 2, 2, 1, '2025-01-15 15:00:00', 'Interna e Externa', 'NexGard Spectra - Comprimido mastigável'),
(6, 6, 6, 3, '2025-01-17 17:30:00', 'Interna', 'Drontal Plus - Comprimido oral');

INSERT INTO PredGenetica (descricao) VALUES 
('Displasia da anca'),
('Problemas cardíacos'),
('Problemas respiratórios'),
('Atrofia progressiva da retina');

INSERT INTO CuidadosEspecificos (descricao) VALUES 
('Escovagem diária'),
('Exercício moderado'),
('Dieta controlada'),
('Limpeza facial regular');

INSERT INTO RacaPredGenetica (idRaca, idEspecie, idPredisposicao) VALUES
(1, 1, 1), -- Labrador -> Displasia da anca
(5, 1, 2), -- Golden -> Problemas cardíacos
(3, 2, 4); -- Persa -> Atrofia progressiva da retina

INSERT INTO RacaCuidadosEspecificos (idRaca, idEspecie, idCuidado) VALUES
(1, 1, 2), -- Labrador -> Exercício moderado
(3, 2, 1), -- Persa -> Escovagem diária
(3, 2, 4); -- Persa -> Limpeza facial regular

-- Avaliações dos clientes
INSERT INTO Avaliacao (nifCliente, designacao, dataHora, classificacao, comentario) VALUES
(123456789, 'Consulta Geral', '2025-01-15 18:00:00', 'Gostei', 'Ótimo atendimento do Dr. Ricardo!'),
(234567890, 'Análises', '2025-01-16 16:00:00', 'Gostei', 'Muito profissionais e atenciosos'),
(345678901, 'Cirurgia', '2025-01-17 20:00:00', 'Não vou voltar', 'Tempo de espera muito longo');

CALL ConcluirAgendamento(1);
CALL CancelarAgendamento(2, 'Cliente doente');
CALL CancelarAgendamento(3, 'Reagendado para outra data');


SELECT '====== REDE DE CLÍNICAS ======' AS '';
SELECT designacaoCompleta, morada, contacto
FROM Clinica
ORDER BY localidade;

SELECT '====== VETERINÁRIOS E SERVIÇOS ======' AS '';
SELECT v.nome, v.localidade, 
       GROUP_CONCAT(vsm.designacao SEPARATOR ', ') AS especializacoes
FROM Veterinario v
LEFT JOIN VeterinarioServicoMedico vsm ON v.nLicenca = vsm.nLicenca
GROUP BY v.nLicenca
ORDER BY v.localidade;

SELECT '====== ANIMAIS REGISTADOS ======' AS '';
SELECT nomeAnimal, especie, raca, nomeDono, idade
FROM Vista_AnimaisCompletos
ORDER BY nomeAnimal;

SELECT '====== AGENDAMENTOS ======' AS '';
SELECT idAgendamento, animal, designacaoServico, dataHora, estado, motivoEstado
FROM Vista_AgendamentosDetalhados
ORDER BY idAgendamento;

SELECT '====== HISTÓRICO CLÍNICO ======' AS '';
SELECT animal, veterinario, diagnostico, dataHora
FROM Vista_HistoricoClinico
ORDER BY dataHora DESC;

SELECT '====== ESTATÍSTICAS ======' AS '';
SELECT 
    (SELECT COUNT(*) FROM FichaClinicaAnimal) AS total_animais,
    (SELECT COUNT(*) FROM Cliente) AS total_clientes,
    (SELECT COUNT(*) FROM Veterinario) AS total_veterinarios,
    (SELECT COUNT(*) FROM Agendamento WHERE estado = 'Válido') AS agendamentos_validos,
    (SELECT COUNT(*) FROM Agendamento WHERE estado = 'Concluído') AS agendamentos_concluidos;