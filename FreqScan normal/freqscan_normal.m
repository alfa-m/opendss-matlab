% Limpa as tela de comando e o workspace
clc
clear
tic;

% Inicializa o objeto DSS
DSSObj = actxserver('OpenDSSEngine.DSS');

% Testa a inicializacao do OpenDSS
if ~DSSObj.Start(0)
    disp('Não foi possível iniciar a OpenDSS Engine')
return
end

% Cria as variaveis da interface
DSSText = DSSObj.Text;
DSSCircuit = DSSObj.ActiveCircuit;
DSSSolution = DSSCircuit.Solution;

% Adiciona o path e compila o arquivo .dss
Projpath    = [pwd,'\ieee34Mod1.dss'];
DSSText.Command=['Clear'];
DSSText.Command=['Compile "',Projpath,'"']; 

% Cria variaveis contendo o nome das linhas e barras 
Linhas = DSSCircuit.Lines;
NomesLinhas = string(Linhas.AllNames);
NomesBarras = string(DSSCircuit.AllBusNames);

% Realiza a solucao do fluxo de potencia para obter os valores de magnitude
% e fase das tensoes e correntes
DSSSolution.Solve;

% Adiciona dados de coordenadas das barras
DSSText.Command = ['Buscoords Buscoords.dat'];

% Remove demais fontes harmonicas
DSSText.Command = ['Spectrum.DefaultLoad.NumHarm=1'];

% Adiciona um monitor em cada linha
for i = 1:length(NomesLinhas)
    linha = NomesLinhas(i);
    comando = string(strcat('New Monitor.MonitorLine',linha,' Line.',linha,' 1 mode=0'));
    DSSText.Command = comando;
end;

% Salva nomes dos monitores
Monitores = DSSCircuit.Monitors;
NomesMonitores = string(Monitores.AllNames);

% Define o espectro de frequencias a serem analisadas
harmonicos = 1:2:25;
harmonicos = harmonicos';
mag_harmonicos = 100 * ones(length(harmonicos),1);
fase_harmonicos = zeros(length(harmonicos),1);
espectro_harmonico = [harmonicos mag_harmonicos fase_harmonicos];
writematrix(espectro_harmonico,'espectro_harmonico.csv');
comando = string(strcat('New spectrum.espectroharmonico numharm=',string(length(harmonicos)),' csvfile=espectro_harmonico.csv'));
DSSText.Command = comando;

% Adiciona a fonte de corrente harmonica de sequencia positiva 
barra = NomesBarras(25);
comando = string(strcat('New Isource.scansource bus1=',barra,' amps=1 spectrum=espectroharmonico'));
DSSText.Command = comando;
    
% Realiza fluxo de potencia considerando a fonte de corrente
DSSSolution.Solve;

% Cria matriz Y
Y = [];

% Seleciona o modo harmonico
DSSText.Command = ['Set mode=harmonic'];

% Executa a analise no modo harmonico
DSSSolution.Solve;

% Salva matriz Y
mySysY = DSSCircuit.SystemY;
NomesNos = DSSCircuit.AllNodeNames;
TamanhoY = size(NomesNos);
myYMat = [];
myIdx = 1;
for a = 1:TamanhoY(1)
    myRow = [];
    for b = 1:TamanhoY(1)
        myRow = [myRow,(mySysY(myIdx) + i*mySysY(myIdx + 1))];
        myIdx = myIdx + 2;
    end;
    myYMat = [myYMat;myRow];
end;
Y = [Y; myYMat];
writematrix(Y,'Y.csv');

% Exporta valores de Y
DSSText.Command = ['Export Y'];
DSSText.Command = ['Export YNodeList'];
DSSText.Command = ['Export Yvoltages'];
DSSText.Command = ['Export YCurrents'];

% Exporta todos os valores dos monitores
DSSText.Command = ['Export monitors all'];

% Plota todos os monitores
for k = 1:length(NomesMonitores)
    monitor = NomesMonitores(k);
    comando = string(strcat('Plot monitor object=',monitor,' channels=(1 3 5 )'));
    DSSText.Command = comando;
end;

disp("Análise harmônica finalizada");
toc;