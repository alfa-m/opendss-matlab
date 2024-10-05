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

% Adiciona o path e compila o arquivo .dss
Projpath    = [pwd,'\34Barras\ieee34Mod1.dss'];
DSSText.Command=['Clear'];
DSSText.Command=['Redirect "',Projpath,'"']; 

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

% Define o espectro de frequencias a serem analisadas
harmonicos = 1:2:25;
harmonicos = harmonicos';
% mag_harmonicos = 100 * ones(length(harmonicos),1);
% fase_harmonicos = zeros(length(harmonicos),1);
% espectro_harmonico = [harmonicos mag_harmonicos fase_harmonicos];
% writematrix(espectro_harmonico,'espectro_harmonico.csv');
% comando = string(strcat('New spectrum.espectroharmonico numharm=',string(length(harmonicos)),' csvfile=espectro_harmonico.csv'));
% disp(comando);
% DSSText.Command = comando;

% Adiciona a fonte de corrente harmonica de sequencia positiva 
barra = NomesBarras(25);
comando = string(strcat('New Isource.scansource bus1=',barra,' amps=1'));
disp(comando);
DSSText.Command = comando;

% Realiza fluxo de potencia considerando a fonte de corrente
DSSSolution.Solve;

% Cria matriz Y
Y = [];

% Cria matrix tensoes
V_nodais = [];

% Cria matriz correntes
I_nodais =[];

% % Seleciona o modo harmonico
% DSSText.Command = ['Set mode=harmonic'];

DSSSolution.Solve;

for j = 1:2:25
    frequencia = 60 * j;
    disp(j);
    disp(frequencia);
    comando = strcat('Set DefaultBaseFrequency=',string(frequencia));
    disp(comando);
    DSSText.Command = comando;
    DSSSolution.Solve;
    
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
        myYMat = [myYMat; myRow];
    end;
    
    Y = [Y; myYMat];
    
    myYV = DSSCircuit.YNodeVarray;
    mySize = size(myYV);
    % Formats the voltages vector as a complex and polar vectors
    myVCmplx = [];
    myVPolar = [];
    for a = 1:2:mySize(2)
        cmplxNum = myYV(a)+ i*myYV(a + 1);
        myVCmplx = [myVCmplx;cmplxNum];
        myVPolar = [myVPolar;[abs(cmplxNum),angle(cmplxNum)*180/pi]];
    end;
    
    V_nodais = [V_nodais; myYV];

    myYCurr = DSSCircuit.YCurrents;
    mySize = size(myYCurr);
    % Formats the injection currents vector as a complex and polar vectors
    myInjCurrCmplx = [];
    myInjCurrPolar = [];
    for a = 1:2:mySize(2)
        cmplxNum = myYCurr(a)+ i*myYCurr(a + 1);
        myInjCurrCmplx = [myInjCurrCmplx;cmplxNum];
        myInjCurrPolar = [myInjCurrPolar;[abs(cmplxNum),angle(cmplxNum)*180/pi]];
    end;
    
    I_nodais = [I_nodais; myYCurr];
    
%     % pega amostra dos valores nos monitores
%     Monitores.SampleAll();
%     
%     % salva os valores nos monitores
%     Monitores.SaveAll();

end;

% DSSText.Command = ['Export monitors all'];
harmonicos = 1:2:25;
harmonicos = harmonicos';
V1 = V_nodais(:,61);
V2 = V_nodais(:,62);
V3 = V_nodais(:,63);
plot(harmonicos,V1,harmonicos,V2,':',harmonicos,V3,'--');

% monitor = NomesMonitores(1);
% comando = string(strcat('Plot monitor object=',monitor,' channels=(1 3 5 )'));
% disp(comando);
% DSSText.Command = comando;
% comando = string('Export monitors all');
% disp(comando);
% DSSText.Command = comando;

% for k = 1:length(NomesMonitores)
%     monitor = NomesMonitores(k);
%     comando = string(strcat('Plot monitor object=',monitor,' channels=(1 3 5 )'));
%     disp(comando);
%     DSSText.Command = comando;
% end;


