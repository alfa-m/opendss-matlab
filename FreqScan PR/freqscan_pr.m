% Limpa as tela de comando e o workspace
clc
clear

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
DSSText.Command=['Set DefaultBaseFrequency=60'];

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
    comando = string(strcat('New Monitor.MonitorLine',linha,' Line.',linha,' 1'));
    DSSText.Command = comando;
end;

% Salva nomes dos monitores
Monitores = DSSCircuit.Monitors;
NomesMonitores = string(Monitores.AllNames);
  
% Realiza fluxo de potencia considerando a fonte de corrente
DSSText.Command = ['Set number=1'];
DSSSolution.Solve;

% Cria matriz Y
Y = [];

% Cria matrix tensoes
V_nodais = [];

% Seleciona o modo harmonico
DSSText.Command = ['Set mode=harmonics'];

DSSSolution.Solve;

for j = 1:2:25
    disp(j);
    comando = strcat('Set harmonics=(',string(j),')');
    disp(comando);
    DSSText.Command = comando;
    DSSSolution.Solve;
    DSSIsources.Frequency = j;
    
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
    V_nodais = [V_nodais; DSSCircuit.AllBusVmag];

%     % pega amostra dos valores nos monitores
%     Monitores.SampleAll();
%     
%     % salva os valores nos monitores
%     Monitores.SaveAll();
end;

%DSSText.Command = ['Export monitors all'];

%%%%%%%%%%%%%%%  revisar aqui %%%%%%%%%%%%%%%%%%%
monitor = NomesMonitores(22);
comando = string(strcat('Plot monitor object=',monitor,' channels=(1 3 5 )'));
disp(comando);
DSSText.Command = comando;
% comando = string('Export monitors all');
% disp(comando);
% DSSText.Command = comando;

% for k = 1:length(NomesMonitores)
%     monitor = NomesMonitores(k);
%     comando = string(strcat('Plot monitor object=',monitor,' channels=(1 3 5 )'));
%     disp(comando);
%     DSSText.Command = comando;
% end;
