function res=OPERA(varargin)

Version='2.6';
SubVersion='2.6-beta1';
%%
%
%        _______________________________________________________________________
%       |                                                                       |
%       |   OPERA models for physchem, environmental fate and tox properties.   |
%       |                 Version 2.6 (January 2020)                            |
%       |_______________________________________________________________________|
%
%
%OPERA is a command line application developed in Matlab providing QSAR models predictions as well as
%applicability domain and accuracy assessment. All models are built on curated data from public domain.
%Molecular descriptors are calculated using PaDEL and CDK software.
%
%
%Input:
%  -s, --SDF, --MOL, --SMI  Structure file containing the molecule(s) to be
%                           predicted. IDs will be assigned if the file does not contain molecule names.
%                           Molecular descriptors will be calculated using
%                           PaDEL software. Use V2000 SDF.
%  -d, --Descriptors        pre-calculated PaDEL descriptors in a comma delimited csv file. If the first column is not
%                           "Name" as the standard PaDEL output, molecule IDs will be assinged.
%  -fp, --fingerprints      pre-calculated descriptors using CDK2.0 in a tab delimited text file.
%  -cdk, --cdk              pre-calculated fingerprints using PaDEL in a comma delimited csv file.
%  -m, --Mat, --ascii       Matlab matrix or ascii file containing PaDEL descriptors.
%  -i, --MolID              Molecule names in csv file.
%  -t, --SaltInfo           Salt IDs to improve melting point predictions. List provided in Salts.xls
%  -l, --Labels             Descriptor labels. Necessary if the descriptor file does not contain labels
%                           or contains more than the 1444 PaDEL 2D descriptors.
%  -st, --Standardize		Generate QSAR-ready structures from input structures.
%
%Output:
%  -o, --Output             Output file containing the predictions, applicability domain and accuracy
%                           information. File extension could be csv or txt. The output will contain by default:
%                           Molecule ID, predicted value (pred), Applicability domain (AD), Applicability domain index
%                           (AD_index) and accuracy estimate (Conf_index).
%  -n, --Neighbors          Add 5 nearest neighbors from training set (CAS, InCHiKeys, Observed and predicted values)
%  -O, --FullOutput         Output file containing all prediction details including NN and used descriptors in csv format.
%  -gd, -getDesc			Output file containing used descriptors in csv format.
%  -x, --Separate           Separate output file for each endpoint.
%
%Miscellaneous:
%  -v, --Verbose            Verbose level: 0=silent (default), 1=minimum details, %  2=full details.
%  -a, --All                All endpoints to be calculated (default).
%  -c, --Clean              Remove temporary files (generated during descriptor calculation.)
%  -LogP, -BCF...           List endpoints to be calculated (case insensitive). 'BCF'/'LogBCF','BP','LogP','MP',
%                           'VP'/'LogVP','WS', 'AOH', 'BioDeg', 'RB'/'ReadyBiodeg','HL'/'LogHL','KM'/'LogKM',
%                           'KOA','Koc'/'LogKoc', 'RT', 'pKa', 'LogD', 'CERAPP'/'ER', 'CoMPARA'/'AR', 'CATMoS/AcuteTox'.
% 							Groups of Endpoints: StrP (Structural properties), PC/Physchem, EnvFate/EF, Tox (ER, AR, AcuteTox).
%  -e, --Endpoint      		List endpoints to be calculated.
%  -h, --Help               Display this help file and exit.
%  -V, --Version            Version of the application
%
%
%
%
%Developed by:
%Kamel Mansouri
%mansourikamel@gmail.com
%kamel.mansouri@nih.gov
%
%
%For more information about the models and the data:
%[1] Mansouri, K. et al. SAR and QSAR in Env. Res. (2016). https://doi.org/10.1080/1062936X.2016.1253611
%[2] Mansouri K. et al. J Cheminform (2018) https://doi.org/10.1186/s13321-018-0263-1.
%[3] The CompTox Chemistry Dashboard (https://comptox.epa.gov/dashboard)
%[4] Williams A. J. et al. J Cheminform (2017) https://doi.org/10.1186/s13321-017-0247-6
%[5] JRC QSAR Model Database https://qsardb.jrc.ec.europa.eu/qmrf/endpoint
%[6] Mansouri, K. et al. EHP (2016) https://ehp.niehs.nih.gov/doi/full/10.1289/ehp.1510267
%[7] Mansouri, K. et al. J Cheminform (2019) https://link.springer.com/article/10.1186/s13321-019-0384-1


%%
% s = SplashScreen( 'Splashscreen', 'Splash_OPERA.gif', ...
%                         'ProgressBar', 'on', ...
%                         'ProgressPosition', 5, ...
%                         'ProgressRatio', 0.4 );
% delete(s);
%%


if nargin==0
    %
    % % % Read in your GIF file. Don't forget to read in the colour map as it is
    % required for display.
    [I, map]=imread('Splash5_OPERA.gif','Frames','all');
    
    % Create a figure to hold your splashscreen
    hfig=figure;
    set(hfig,'Menubar', 'none');
    set(hfig,'name','Please wait. Loading...','numbertitle','off');
    
    % Set a timer to dynamically update the plot every 0.1 sec
    t=timer('TimerFcn', {@timerCallbackFcn, hfig, I, map},'ExecutionMode','FixedRate','Period',0.1);
    
    % Start the timer
    start(t);
    
    % Check path variable on Windows
    % if isdeployed
    %     [status, result] = system('echo %PATH%');
    %     %contains(result,'OPERA')
    %     if isempty(regexpi(result,'C:\Program Files\OPERA\application'))
    %       %[status, result] = system('IF EXIST "C:\Program Files\OPERA\application" set "PATH=%PATH%;C:\Program Files\OPERA\application"');
    %
    %       setenv('PATH', [getenv('PATH') ';C:\Program Files\OPERA\application']);
    %       system('echo %PATH%')
    %
    %     end
    % end
    
    % Do your stuff here
    for j=1:5
        pause(0.5);
    end
    %train=load ('OPERA_models.mat', '-mat');
    
    % Clean-up
    stop(t);
    delete(t);
    delete(hfig);
    %
    if ispc
        type('intro_w.txt')
    else
        type('intro.txt')
    end
    help=1;
    
else
    timerAll=tic;
    FileOut=['OPERA',Version,'_Pred.csv'];
    verbose=0;
    InputMatrix=0;
    importedNames=0;
    importedLabels=0;
    input=0;
    InputDescPadel=0;
    inputFP=0;
    inputCDK=0;
    structure=0;
    clean=0;
    printtDesc=0;
    sep=0;
    all=1;
    prop={};
    salt=0;
    help=0;
    e=0;
    i=1;
    neighbors=0;
    fp=0;
    cdk=0;
    InputDesc={};
    InputDescFP={};
    InputDescCDK={};
    StructureFile={};
    FileSalt={};
    tox=0;
    pc=0;
    ef=0;
    adme=0;
    exp=0;
    nf=0;
    f=0;
    standardize=0;
    
    
    
    %if nargin>0
    while i<=length(varargin)
        if  strcmpi('--descriptors',varargin{i})|| strcmpi('-d',varargin{i})|| strcmpi('--desc',varargin{i})
            InputDesc=varargin{i+1};
            InputDescPadel=1;
            input=1;
            i=i+2;
            continue
        elseif strcmpi('--fingerprints',varargin{i})|| strcmpi('-fp',varargin{i})
            InputDescFP=varargin{i+1};
            inputFP=1;
            i=i+2;
        elseif strcmpi('--cdk',varargin{i})|| strcmpi('-cdk',varargin{i})
            InputDescCDK=varargin{i+1};
            inputCDK=1;
            i=i+2;
        elseif strcmpi('--mat',varargin{i}) || strcmpi('--ascii',varargin{i})|| strcmp('-m',varargin{i})
            InputDesc=varargin{i+1};
            InputMatrix=1;
            input=1;
            i=i+2;
            continue
        elseif strcmpi('--MolID',varargin{i})|| strcmp('-i',varargin{i})
            MolID=varargin{i+1};
            MoleculeNames=importfile(MolID);
            importedNames=1;
            i=i+2;
            continue
        elseif  strcmpi('--labels',varargin{i}) || strcmp('-l',varargin{i})
            labels=varargin{i+1};
            Xlabels=importfile(labels);
            importedLabels=1;
            i=i+2;
            continue
        elseif strcmpi('--structure',varargin{i}) || strcmpi('--sdf',varargin{i})|| strcmpi('--smiles',varargin{i})|| strcmpi('--smi',varargin{i})|| strcmpi('-s',varargin{i})|| strcmpi('--mol',varargin{i})
            StructureFile=varargin{i+1};
            %InputDesc='PadelDesc.csv';
            structure =1;
            input=1;
            %clean=1;
            i=i+2;
            continue
        elseif strcmpi('--out',varargin{i}) || strcmpi('--fullOutput',varargin{i})|| strcmpi('-o',varargin{i})
            FileOut=varargin{i+1};
            if strcmpi('--fullOutput',varargin{i})|| strcmp('-O',varargin{i})
                printtDesc=1;
                neighbors=1;
            end
            i=i+2;
            continue
        elseif strcmp('-v',varargin{i}) || strcmpi('--verbose',varargin{i})
            verbose=varargin{i+1};
            if ischar(verbose)
                verbose=str2double(verbose);
            end
            i=i+2;
            continue
        elseif strcmpi('--Clean',varargin{i})|| strcmp('-c',varargin{i})
            clean=1;
            i=i+1;
            continue
        elseif strcmpi('--Neighbors',varargin{i})|| strcmp('-n',varargin{i})
            neighbors=1;
            i=i+1;
            continue
        elseif strcmpi('--salt',varargin{i}) || strcmpi('--saltInfo',varargin{i})|| strcmp('-t',varargin{i})
            salt=1;
            FileSalt=varargin{i+1};
            i=i+2;
            continue
        elseif strcmpi('--sep',varargin{i}) || strcmpi('--separate',varargin{i})|| strcmp('-x',varargin{i})
            sep=1;
            i=i+1;
            continue
        elseif strcmpi('-All',varargin{i})|| strcmp('-a',varargin{i})
            all=1;
            fp=1;
            %InputDescFP='PadelFP.csv';
            cdk=1;
            %InputDescCDK='CDKDesc.csv';
            i=i+1;
            continue
        elseif strcmp('-e',varargin{i})|| strcmpi('--endpoint',varargin{i})
            all=0;
            e=1;
            i=i+1;
            continue
        elseif strcmpi('StrP',varargin{i}) || strcmpi('BCF',varargin{i}) || strcmpi('BP',varargin{i})|| strcmpi('LogP',varargin{i})|| strcmpi('MP',varargin{i})|| strcmpi('VP',varargin{i})|| strcmpi('WS',varargin{i})...
                || strcmpi('LogWS',varargin{i})|| strcmpi('LogVP',varargin{i})|| strcmpi('LogBCF',varargin{i})|| strcmpi('AOH',varargin{i})|| strcmpi('BioHC',varargin{i})...
                || strcmpi('Biowin',varargin{i})|| strcmpi('RB',varargin{i})|| strcmpi('HL',varargin{i})|| strcmpi('KM',varargin{i})|| strcmpi('KOA',varargin{i})...
                || strcmpi('KOC',varargin{i})|| strcmpi('LogKOC',varargin{i})|| strcmpi('LogKM',varargin{i})|| strcmpi('LogHL',varargin{i})|| strcmpi('BioDeg',varargin{i})|| strcmpi('AOH',varargin{i})...
                || strcmpi('ReadyBiodeg',varargin{i})|| strcmpi('RT',varargin{i})|| strcmpi('Rbiodeg',varargin{i})||strcmpi('BioHL',varargin{i})||strcmpi('BioDegHL',varargin{i})||strcmpi('pka',varargin{i})||strcmpi('LogD',varargin{i})||strcmpi('EnvFate',varargin{i})||strcmpi('EF',varargin{i})...
                ||strcmpi('ER',varargin{i})||strcmpi('CERAPP',varargin{i})||strcmpi('AR',varargin{i})||strcmpi('CoMPARA',varargin{i})||strcmpi('AcuteTox',varargin{i})||strcmpi('CATMoS',varargin{i})||strcmpi('Tox',varargin{i})||strcmpi('PhysChem',varargin{i})||strcmpi('PC',varargin{i})...
                ||strcmpi('FuB',varargin{i})||strcmpi('FU',varargin{i})||strcmpi('ADME',varargin{i})||strcmpi('Clint',varargin{i})||strcmpi('Cl',varargin{i})
            if strcmpi('pka',varargin{i})||strcmpi('LogD',varargin{i})||strcmpi('PhysChem',varargin{i})||strcmpi('PC',varargin{i})
                fp=1;
                
            elseif strcmpi('ER',varargin{i})||strcmpi('CERAPP',varargin{i})||strcmpi('AR',varargin{i})||strcmpi('CoMPARA',varargin{i})||strcmpi('AcuteTox',varargin{i})||strcmpi('CATMoS',varargin{i})||strcmpi('Tox',varargin{i})...
                    ||strcmpi('FuB',varargin{i})||strcmpi('FU',varargin{i})||strcmpi('ADME',varargin{i})||strcmpi('Clint',varargin{i})||strcmpi('Cl',varargin{i})
                cdk=1;
                
            end
            
            if e==1
                if strcmpi('Tox',varargin{i})
                    prop=[prop, 'CERAPP','CoMPARA', 'CATMoS'];
                    all=0;
                    tox=1;
                elseif strcmpi('PhysChem',varargin{i})||strcmpi('PC',varargin{i})
                    prop=[prop, 'BP','LogP','MP','VP','WS', 'HL', 'KOA', 'RT','pKa', 'LogD'];
                    all=0;
                    pc=1;
                elseif strcmpi('EnvFate',varargin{i})||strcmpi('EF',varargin{i})
                    prop=[prop, 'BCF', 'AOH', 'BioDeg', 'RBioDeg','KM','KOC'];
                    all=0;
                    ef=1;
                elseif strcmpi('ADME',varargin{i})
                    prop=[prop, 'FuB', 'Clint'];
                    all=0;
                    adme=1;
                else
                    prop=[prop varargin{i}];
                    all=0;
                end
            else
                error('Check input arguments or type -h, --help for more info.')
            end
            i=i+1;
            continue
            
        elseif strcmpi('-StrP',varargin{i}) ||strcmpi('-BCF',varargin{i}) || strcmpi('-BP',varargin{i})|| strcmpi('-LogP',varargin{i})|| strcmpi('-MP',varargin{i})|| strcmpi('-VP',varargin{i})|| strcmpi('-WS',varargin{i})...
                || strcmpi('-LogWS',varargin{i})|| strcmpi('-LogVP',varargin{i})|| strcmpi('-LogBCF',varargin{i})|| strcmpi('-AOH',varargin{i})|| strcmpi('-BioHC',varargin{i})...
                || strcmpi('-Biowin',varargin{i})|| strcmpi('-RB',varargin{i})|| strcmpi('-HL',varargin{i})|| strcmpi('-KM',varargin{i})|| strcmpi('-KOA',varargin{i})...
                || strcmpi('-KOC',varargin{i})|| strcmpi('-LogKOC',varargin{i})|| strcmpi('-LogKM',varargin{i})|| strcmpi('-LogHL',varargin{i})|| strcmpi('-BioDeg',varargin{i})|| strcmpi('-AOH',varargin{i})...
                || strcmpi('-ReadyBiodeg',varargin{i})|| strcmpi('-RT',varargin{i})|| strcmpi('-Rbiodeg',varargin{i})||strcmpi('-BioHL',varargin{i})||strcmpi('-BioDegHL',varargin{i})||strcmpi('-pka',varargin{i})||strcmpi('-LogD',varargin{i})||strcmpi('-EnvFate',varargin{i})||strcmpi('-EF',varargin{i})...
                ||strcmpi('-ER',varargin{i})||strcmpi('-CERAPP',varargin{i})||strcmpi('-AR',varargin{i})||strcmpi('-CoMPARA',varargin{i})||strcmpi('-AcuteTox',varargin{i})||strcmpi('-CATMoS',varargin{i})||strcmpi('-Tox',varargin{i})||strcmpi('-PhysChem',varargin{i})||strcmpi('-PC',varargin{i})...
                ||strcmpi('-FuB',varargin{i})||strcmpi('-FU',varargin{i})||strcmpi('-ADME',varargin{i})||strcmpi('-Clint',varargin{i})||strcmpi('-Cl',varargin{i})
            if  strcmpi('-pka',varargin{i})||strcmpi('-LogD',varargin{i})||strcmpi('-PhysChem',varargin{i})||strcmpi('-PC',varargin{i})
                fp=1;
                
            elseif strcmpi('-ER',varargin{i})||strcmpi('-CERAPP',varargin{i})||strcmpi('-AR',varargin{i})||strcmpi('-CoMPARA',varargin{i})||strcmpi('-AcuteTox',varargin{i})||strcmpi('-CATMoS',varargin{i})||strcmpi('-Tox',varargin{i})...
                    ||strcmpi('-FuB',varargin{i})||strcmpi('-FU',varargin{i})||strcmpi('-ADME',varargin{i})||strcmpi('-Clint',varargin{i})||strcmpi('-Cl',varargin{i})
                cdk=1;
                
            end
            if strcmpi('-Tox',varargin{i})
                prop=[prop, 'CERAPP', 'CoMPARA','CATMoS'];
                all=0;
                tox=1;
            elseif strcmpi('-PhysChem',varargin{i})||strcmpi('-PC',varargin{i})
                prop=[prop, 'BP','LogP','MP','VP','WS', 'HL','KOA','RT','pKa', 'LogD'];
                all=0;
                pc=1;
            elseif strcmpi('-EnvFate',varargin{i})||strcmpi('-EF',varargin{i})
                prop=[prop, 'BCF', 'AOH', 'BioDeg', 'RBioDeg','KM','KOC'];
                all=0;
                ef=1;
            elseif strcmpi('-ADME',varargin{i})
                prop=[prop, 'FuB', 'Clint'];
                all=0;
                adme=1;
            else
                all=0;
                prop=[prop strrep(varargin{i},'-','')];
            end
            i=i+1;
            continue
        elseif strcmpi('--help',varargin{i})|| strcmp('-h',varargin{i})
            if ispc
                type('help_w.txt')
            else
                type('help.txt')
            end
            help=1;
            i=i+1;
            continue
        elseif strcmp('-V',varargin{i})|| strcmpi('--version',varargin{i})
            fprintf(1,'Version %s.\n',SubVersion);
            help=1;
            i=i+1;
            continue
        elseif strcmpi('-exp',varargin{i})
            exp=1;
            i=i+1;
            continue
        elseif strcmpi('-getDesc',varargin{i})||strcmpi('-gd',varargin{i})||strcmpi('--getDescriptors',varargin{i})
            printtDesc=1;
            i=i+1;
            continue
        elseif strcmpi('-st',varargin{i})||strcmpi('--standardize',varargin{i})
            standardize=1;
            i=i+1;
            continue
        else
            error('Check input arguments or type -h, --help for more info.')
            
        end
        
    end
    
    % If no splash
    %  else
    % % error('MyComponent:incorrectType',...
    % %    'Not enough arguments. \nUsage: OPERA [OPTION]... <Input> <output>... \nType -h, --help for more info.')
    %
    %
    % type('intro_w.txt')
    % help=1;
    
    %fprintf(2,'Not enough arguments \n');
    %return
end


if help==1
    %     return
    %     %('End help file!')
    % end
    % % else
    
    res=0;
else
    
    if verbose==0 || isdeployed
        warning('off','MATLAB:table:ModifiedAndSavedVarnames');
        warning('off','MATLAB:table:RowsAddedExistingVars');
    else
        warning('on','MATLAB:table:ModifiedAndSavedVarnames');
        warning('on','MATLAB:table:RowsAddedExistingVars');
    end

    if  structure ==0
        if input==0
            error('No structure file or a comma delimited file with generated PaDEL descirptors. Usage: OPERA [OPTION]... <Input> <output>... Type -h, --help for more info.')
            %   fprintf(2,'You must at least enter an input file \n');
            %   return
        end
        if fp==1 && inputFP==0
            error('No structure file or a comma delimited file with generated fingerprints. Usage: OPERA [OPTION]... <Input> <output>... Type -h, --help for more info.')
        end
        if cdk==1 && inputCDK==0
            error('No structure file or a tab delimited file with calculated CDK2.0 descriptors. Usage: OPERA [OPTION]... <Input> <output>... Type -h, --help for more info.')
        end
    else
        if ~exist(StructureFile,'file')
            error('Input file does not exit or corrupt.');
        end
    end
    
    
    if all==1
        prop= {'StrP','BCF','BP','LogP','MP','VP','WS', 'AOH', 'BioDeg', 'RBioDeg','HL','KM','KOA','KOC','RT','pKa', 'LogD', 'CERAPP', 'FuB','Clint', 'CoMPARA', 'CATMoS'};
        if verbose >0
            fprintf(1,'\n All properties will be calculated: \nGeneral structural properties, Physchem, Env. fate, ADME and Tox Endpoints (CERAPP, CoMPARA and CATMoS)  \n');
            fprintf(1,'\n Initializing and loading models...\n');
        end
        fp=1;
        cdk=1;
        
    else
        if verbose >0
            if size(prop(:),1)>1
                endpoints=strjoin(prop(1:size(prop(:),1)-1),', ');
                fprintf(1,'\n Endpoints to be calculated: \n %s and %s\n',upper(endpoints),upper(prop{end}));
            else
                fprintf(1,'\n Endpoint to be calculated: %s\n',upper(prop{:}));
            end
            fprintf(1,'\n Initializing and loading models...\n');
        end
    end
%     data=upper(prop);
%     [a,indLOGD]=ismember('LOGD',data);
%     if a
%         data=[data, 'PKA', 'LOGP'];
%         data(indLOGD)=[];
%     end
    train=load ('OPERA_models.mat', '-mat','DSSToxQSARr','StructError','labels','labels_cdk','labels_fp','labels_in','PadelVarIn','PadelVarOut','reorder_CDK');%,data{:});

%     train=load ('OPERA_models.mat', '-mat');
    if importedLabels==0
        Xlabels=train.labels;
        XlabelsFP=train.labels_fp;
    end
    
    %if structure==1 && (InputDescPadel==0||(fp==1 && inputFP==0))
    %if ~isdeployed
        %installdir=pwd;
        %installdir=fullfile('C:','Program Files','OPERA','application');
    %else
        if ispc
            installdir=fullfile('C:','Program Files','OPERA','application');
        else
            installdir=fullfile('/','usr','local','bin','OPERA','application');
        end
    %end
    if ~exist(fullfile(installdir,'padel-full-1.00.jar'),'file')
        
        if isdeployed
            currentDir=ctfroot;
            
            if exist(fullfile(currentDir,'OPERA_installdir.txt'),'file')
                fid  = fopen(fullfile(currentDir,'OPERA_installdir.txt'),'r');
                installdir=strip(fread(fid,'*char')');
                fclose(fid);
                
                if ~exist(fullfile(installdir,'padel-full-1.00.jar'),'file')
                    error('Default install folder was changed during installation. Update OPERA_installdir.txt file in %s', currentDir);
                end
            else
                fid  = fopen(fullfile(currentDir,'OPERA_installdir.txt'),'w');
                fprintf(fid,'%s',installdir);
                fclose(fid);
                error('Default install folder was changed during installation. Update OPERA_installdir.txt file in %s', currentDir);
            end
            
        else
            currentDir = pwd;
            if exist(fullfile(currentDir,'OPERA_installdir.txt'),'file')
                fid  = fopen(fullfile(currentDir,'OPERA_installdir.txt'),'r');
                installdir=strip(fread(fid,'*char')');
                fclose(fid);
                %currentDir = pwd;
                if ~exist(fullfile(installdir,'padel-full-1.00.jar'),'file')
                    error(['Default install folder was changed during installation. Update OPERA_installdir.txt file in ', currentDir]);
                end
            else
                fid  = fopen(fullfile(currentDir,'OPERA_installdir.txt'),'w');
                fprintf(fid,'%s',installdir);
                fclose(fid);
                error(['Default install folder was changed during installation. Update OPERA_installdir.txt file in ', currentDir]);
            end
        end
    end
    
        %---------Output file---------
    %errmsg='Cannot write to output file \n';
    ext=FileOut(length(FileOut)-3:end);
    if sep==1
        outputname=cell(size(prop));
        %output=zeros(size(prop));
        
        FileOut=strrep(FileOut,ext,'');
        
        for i=1:length(prop)
            %         FileOut(i)=[FileOut prop(i) ext]
            outputname{i}=strrep(strjoin([FileOut '_' prop(i) ext]),' ', '');
            [output(i),errmsg]=fopen(outputname{i},'w');
        end
        FileOut=outputname;
    else
        
        [output,errmsg]=fopen(FileOut,'w');
    end
    
    
    if verbose>0 && ~isempty(errmsg)
        disp('Output file')
        error(errmsg)
        % disp(errmsg);
        %  return
    end
    %-----------------------------
    
    
    %Start input Matrix
    if InputMatrix==1
        if verbose> 0
            disp('Loading matrix of descriptors...');
        end
        load(InputDesc);
        Xin=eval(InputDesc(1:length(InputDesc)-4));
        if importedNames==0 && size(Xin,1)==1444
            %MoleculeNames=num2cell(1:1:size(Xin,1))';
            for i=1:size(Xin,1)
                MoleculeNames{i,1}=strcat('AUTOGEN_',num2str(i));
            end
            %         if verbose>0
            %             disp(' default PaDEL descriptor names considered...\n');
            %         end
        else
            for i=1:size(Xin,1)
                MoleculeNames{i,1}=strcat('AUTOGEN_',num2str(Xin(i)));
            end
            Xin(:,1)=[];
        end
     %End input Matrix
    else
        if structure==1
            if strcmpi(StructureFile(length(StructureFile)-3:end),'.smi')||strcmpi(StructureFile(length(StructureFile)-3:end),'.txt')
                if ispc
                    [~, numStruct] = system(['FINDSTR /R /N "^.*" ', strcat('"',char(StructureFile),'"'),' | FIND /C ":"']);%win
                else
                    [~, numStruct] = system(['cat ', strcat('"',char(StructureFile),'"'),' | sed "/^\s*$/d" | wc -l ']); %linux
                end
                
            elseif strcmpi(StructureFile(length(StructureFile)-3:end),'.sdf')
                if ispc
                    [~, numStruct] = system(['FINDSTR /R /N "^.*\$\$\$\$" ', strcat('"',char(StructureFile),'"') ,' | FIND /C ":"']);%win
                else
                    [~, numStruct] = system(['grep -F "\$\$\$\$" ', strcat('"',char(StructureFile),'"'), ' | wc -l']); %linux
                end
                
            elseif strcmpi(StructureFile(length(StructureFile)-3:end),'.mol')
                
                numStruct='1';
            else
                error('Check input file');
                
            end
            
%             if strcmpi(StructureFile(length(StructureFile)-3:end),'.txt')||(ismember('mp',lower(prop))||ismember('logp',lower(prop))) && isempty(FileSalt)
%                 
%             end
            
            if strcmpi(StructureFile(length(StructureFile)-3:end),'.txt')
                if verbose >0
                    fprintf(1,'Found IDs in input text file: %d.\n',str2double(numStruct));
                end
                fid = fopen(StructureFile);
                indic = 1;
                while 1
                    tline = fgetl(fid);
                    if ~ischar(tline)
                        break
                    end
                    strings{indic}=strtrim(tline);
                    indic = indic + 1;
                end
                fclose(fid);
                StructureFile=strcat(StructureFile(1:length(StructureFile)-3),'smi');
                fileID = fopen(StructureFile, 'w');
                %f=0;
                %nf=0;
                La=zeros(length(strings));
                Lb=zeros(length(strings));
                %FoundBy=nan(length(strings));
                for i=1:length(strings)

                    if regexp(strings{i},'[0-9]+-[0-9]+-[0-9]')
                        [La(i),Lb(i)] = ismember(strings{i},train.DSSToxQSARr{:,2});
                        SearchID='CASRN';
                    elseif regexp(strings{i},'DTXSID[0-9]+')
                        [La(i),Lb(i)] = ismember(strings{i},train.DSSToxQSARr{:,3});
                        SearchID='DTXSID';
                    elseif regexp(strings{i},'DTXCID[0-9]+')
                        [La(i),Lb(i)] = ismember(strings{i},train.DSSToxQSARr{:,4});
                        SearchID='DTXCID';
                    elseif regexp(strings{i},'[A-Z]+-[A-Z]+-[A-Z]')
                        [La(i),Lb(i)] = ismember(strings{i},train.DSSToxQSARr{:,5});
                        SearchID='InChiKey';
                    end
                    if La(i)
                        f=f+1;
                        FoundBy{f,1}=SearchID;
                        fprintf(fileID,'%s\t%s\n',train.DSSToxQSARr{Lb(i),1},strings{i});
                        if (ismember('mp',lower(prop))||ismember('logp',lower(prop))||ismember('logd',lower(prop))) && isempty(FileSalt)
                            salt=1;
                            %SaltInfo(f,1)=train.DSSToxQSARr.SaltInfo(Lb(i));
                            SaltIndex(f,1)=train.DSSToxQSARr.SaltInfo(Lb(i));
                        end
                    else
                        nf=nf+1;
                        nfID{nf,1}=strings{i};
                        err_index=0;
                        if regexp(strings{i},'[0-9]+-[0-9]+-[0-9]')
                            [~,err_index] = ismember(strings{i},train.StructError{:,2});
                        elseif regexp(strings{i},'DTXSID[0-9]+')
                            [~,err_index] = ismember(strings{i},train.StructError{:,3});
                        elseif regexp(strings{i},'DTXCID[0-9]+')
                            [~,err_index] = ismember(strings{i},train.StructError{:,4});
                        elseif regexp(strings{i},'[A-Z]+-[A-Z]+-[A-Z]')
                            [~,err_index] = ismember(strings{i},train.StructError{:,5});
                        end
                        if err_index
                            SearchError{nf,1}=['Error: ',char(train.StructError{err_index,6})];
                        else
                            SearchError{nf,1}='NotFound';
                        end
                    end
                end
                fclose(fileID);
                if nf>0
                    FoundBy=[FoundBy; SearchError];
                end
                if verbose >0
                    fprintf(1,'Found structures based on provided IDs: %d.\n',f);
                end
                if f==0
                    error('Check IDs in the input file.');
                end
                numStruct=num2str(f);
%                 if ismember('mp',lower(prop))
%                     salt=1;
%                     FileSalt=strcat(StructureFile(1:length(StructureFile)-4),'_SaltInfo','.csv');
%                     SaltFile.Name=strings(find(La))';
%                     SaltFile.SaltInfo=SaltInfo;
%                     SaltFile=struct2table(SaltFile);
%                     writetable(SaltFile,FileSalt,'Delimiter',',');
%                     clear('SaltInfo','SaltFile');
%                 end
                
            end
        end
        
        %========== Standardize Structures ==========
        if structure && standardize && f==0
            
            if verbose >0
                fprintf(1,'\n========== Structures standardization ==========\n');
                fprintf(1,'Input structures: %d.\n',str2double(numStruct));
                fprintf(1,'Generating QSAR-ready structures...\n');
            end
            
        
        %command=[strcat('"',fullfile('C:','Users','kmansouri','Downloads','knime_4.1.1','knime'),'"') ' -reset -nosplash -nosave -application org.knime.product.KNIME_BATCH_APPLICATION -workflowDir=' strcat('"',fullfile('C:\Users\kmansouri\Downloads','knime_4.1.1','knime-workspace','QSAR-ready_2.5.6'),'"') ' -workflow.variable=cmd_input,' strcat('"',char(StructureFile),'"') ',String']
%         [statusKnime,cmdoutKnime] =system ([strcat('"',fullfile('C:','Users','kmansouri','Downloads','knime_4.1.1','knime'),'"')...
%             ' -reset -nosplash -nosave -application org.knime.product.KNIME_BATCH_APPLICATION -workflowDir='...
%             strcat('"',fullfile('C:\Users\kmansouri\Downloads','knime_4.1.1','knime-workspace','QSAR-ready_2.5.6'),'"')...
%             ' -workflow.variable=cmd_input,' strcat('"',char(StructureFile),'"') ',String']);
        
        homedir = char(java.lang.System.getProperty('user.home'));
        if ~exist(fullfile(homedir,'knime-workspace'),'dir')
            mkdir(fullfile(homedir,'knime-workspace'));
        end
        if ~exist(fullfile(homedir,'knime-workspace','QSAR-ready_2.5.6'),'dir')
            mkdir(fullfile(homedir,'knime-workspace','QSAR-ready_2.5.6'));
            [statusCp,messageCp] = copyfile(fullfile(installdir,'knime_4.1.1','knime-workspace','QSAR-ready_2.5.6'),fullfile(homedir,'knime-workspace','QSAR-ready_2.5.6'));
            if ~statusCp && ~isempty(messageCp)
                error(messageCp);
            end
        end
        if ~exist(fullfile(homedir,'Sample_input'),'dir')
            mkdir(fullfile(homedir,'Sample_input'));
        end
        if ~exist(fullfile(homedir,'Sample_input','Sample_input.sdf'),'file')
            [statusCp,messageCp] = copyfile(fullfile(installdir,'knime_4.1.1','Sample_input'),fullfile(homedir,'Sample_input'));
            if ~statusCp && ~isempty(messageCp)
                error(messageCp);
            end
        end

        [statusKnime,cmdoutKnime] =system ([strcat('"',fullfile(installdir,'knime_4.1.1','knime'),'"')...
            ' -reset -nosplash -nosave -application org.knime.product.KNIME_BATCH_APPLICATION -workflowDir='...
            strcat('"',fullfile(homedir,'knime-workspace','QSAR-ready_2.5.6'),'"')...
            ' -workflow.variable=cmd_input,' strcat('"',char(StructureFile),'"') ',String']);
        
                    if statusKnime==0
                        salt=1;
                        FileSalt=strcat(StructureFile(1:length(StructureFile)-4),'_QSAR-ready_saltInfo.csv');
                        StructureFile=strcat(StructureFile(1:length(StructureFile)-4),'_QSAR-ready_smi.smi');
                        if ispc
                            [~, numStruct] = system(['FINDSTR /R /N "^.*" ', strcat('"',char(StructureFile),'"'),' | FIND /C ":"']);%win
                        else
                            [~, numStruct] = system(['cat ', strcat('"',char(StructureFile),'"'),' | sed "/^\s*$/d" | wc -l ']); %linux
                        end

                    if verbose >0   
                        fprintf(1,'Standardized structures: %d.\n',str2double(numStruct));
                    end
                        
                        
                    else
                        if verbose >0
                            disp(cmdoutKnime);
                        end
                        error('Standardization process failed. Check the input file.');
                    end
            
        end
        %========== Molecular Descriptors ==========
        
        %Calculating PaDEL descriptors...
        
        if verbose >0
            fprintf(1,'\n============= Molecular Descriptors ============\n');
        end
        
        if structure==1 && InputDescPadel==0
            InputDesc=strcat(StructureFile(1:length(StructureFile)-4),'_PadelDesc.csv');
            PaDELlogfile=strcat(StructureFile(1:length(StructureFile)-4),'_PaDELlogfile.log');
            if verbose >0
                fprintf(1,'Loaded structures: %d.\n',str2double(numStruct));
                if str2double(numStruct)==0
                    error('Check the input file.');
                end
                fprintf(1,'PaDEL calculating 2D descriptors...\n');
                if verbose ==1
                    [statusDesc,cmdoutDesc] =system (['java -Djava.awt.headless=true -jar ' strcat('"',fullfile(installdir,'padel-full-1.00.jar'),'"')...
                        ' -2d -removesalt -standardizenitro -detectaromaticity -retainorder -maxruntime 60000 -dir ' strcat('"',char(StructureFile),'"')...
                        ' -file ' strcat('"',InputDesc,'"') ' > ' strcat('"',PaDELlogfile,'"')]);
                    if statusDesc~=0 && ~isempty(cmdoutDesc)
                        disp(cmdoutDesc);
                        error('PaDEL descriptors failed. Check input structures!');
                    end
                        
                else
                    statusDesc =system (['java -Djava.awt.headless=true -jar ' strcat('"',fullfile(installdir,'padel-full-1.00.jar'),'"')...
                        ' -2d -removesalt -standardizenitro -detectaromaticity -retainorder -maxruntime 60000 -dir ' strcat('"',char(StructureFile),'"')...
                        ' -file ' strcat('"',InputDesc,'"')]);
                    if statusDesc~=0
                        error('PaDEL descriptors failed. Check input structures!');
                    end
                end
                fprintf(1,'PaDEL descriptors calculated for: ');
                
                if ispc
                    [~, numlines] = system(['FINDSTR /R /N "^.*" ',InputDesc,' | FIND /C ":"']); %win
                else
                    [~, numlines] = system( ['wc -l ', InputDesc] ); %linux
                end
                numlines=str2double(strrep(numlines,InputDesc,''))-1;
                fprintf(1, '%d molecules.\n',numlines);
                if numlines < str2double(numStruct)
                    error('PaDEL descriptors failed. Check input structures!');
                end
                
            else
                [~,~] =system (['java -Djava.awt.headless=true -jar ' strcat('"',fullfile(installdir,'padel-full-1.00.jar'),'"')...
                    ' -2d -removesalt -standardizenitro -detectaromaticity -retainorder -maxruntime 60000 -dir ' strcat('"',char(StructureFile),'"')...
                    ' -file ' strcat('"',InputDesc,'"') ' > ' strcat('"',PaDELlogfile,'"')]);
                if ispc
                    [~, numlines] = system(['FINDSTR /R /N "^.*" ',InputDesc,' | FIND /C ":"']); %win
                else
                    [~, numlines] = system( ['wc -l ', InputDesc] ); %linux
                end
                numlines=str2double(strrep(numlines,InputDesc,''))-1;
                if numlines < str2double(numStruct)
                    error('PaDEL descriptors failed. Check input structures!');
                end
            end
            
        end
        
        
        
        %if statusDesc==0 && verbose>0 && isempty(cmdoutDesc)
        %fprintf(1,'--------------------------------------------------------\n');
        
        %Windows OS: store the below two lines in countlines.pl
        %while (<>) {};
        %print $.,"\n";
        %Then to make a matlab call to count the lines for file XYZ.csv
        %numlines = str2num( perl('countlines.pl', 'XYZ.csv') );

        %end
        
        if verbose> 0
            disp('Loading of PaDEL descriptors file...');
        end
        
        %Xin=dataset('File',InputDesc,'delimiter',',');
        try
            Xin=readtable(InputDesc,'delimiter',',','DatetimeType','text');
        catch ME
            if strcmp(ME.identifier,'MATLAB:readtable:OpenFailed')
                error('Unable to open descriptors file');
            else
                error(ME.message);
                return;
            end
        end
        %Xlabels=Xin.Properties.VarNames;
        Xlabels=Xin.Properties.VariableNames;
        %Xin=dataset2table(Xin);
        
        
        if size(Xin,1)==0 || size(Xin,2)==0
            error('Check input file and re-run to calculate descriptors')
            %     elseif verbose>0
            %         fprintf(1,'The number of input molecules is: %d \n',size(Xin,1));
            
        end
        
        
        if strcmpi(Xlabels{1},'Name') || strcmpi(Xlabels{1},'MoleculeID') || strcmpi(Xlabels{1},'Molecule')
            
            if verbose> 1
                disp('Molecule names found in input file(s).');
            end
            Xin.Properties.VariableNames{1}='Name';
            Xlabels=Xlabels(2:end);
            Names=cellstr(Xin.Name);
            if isnumeric(Names) && strcmpi(ext,'.txt')
                
                for i=1:size(Xin,1)
                    MoleculeNames{i,1}=strcat('AUTOGEN_',num2str(Names(i)));
                end
            else
                MoleculeNames=Names;
                
                %MoleculeID=num2cell(MoleculeNames);
                
            end
            %Xin=Xin{:,2:end};
            Xin=Xin(:,2:end);
        else
            
            if verbose> 1
                disp('Molecule names not found in input file. Generated IDs will be assigned.');
            end
            %Xin=Xin{:,:};
            %Xin=Xin(:,:);
            
            for i=1:size(Xin,1)
                MoleculeNames{i,1}=strcat('AUTOGEN_',num2str(i));
            end
        end
        if nf>0
            MoleculeNames=[MoleculeNames; nfID];
        end
        if size(Xin,1)==0 || size(Xin,2)==0
            error('Empty descriptors file!');
        end
        i=1;
        Temp=zeros(size(Xin));
        if verbose> 0
            disp('Checking loaded variables.');
        end
        while i<=length(Xlabels)
            if cellfun(@ischar,table2cell(Xin(1,i)))
                Temp(:,i)=str2double(table2cell(Xin(:,i)));
            else
                
                Temp(:,i)=Xin{:,i};
            end
            i=i+1;
        end
        if verbose> 0
            disp(['Loaded ', num2str(length(Xlabels)),' PaDEL descriptors for ', num2str(size(Xin,1)),' molecules.']);
        end
        
        clear('Xin');
        Xin=Temp;
        clear('Temp');
 
        if cdk==1
            if structure==1 && inputCDK==0
                %Bond_HA_r=Xin(:,466)./Xin(:,9);
                Amb_str=intersect(find((Xin(:,466)./Xin(:,9))>1.3),find(Xin(:,9)>50));
                Amb_str=unique(sort([Amb_str; find(Xin(:,9)>150)]));
                if ~isempty(Amb_str)%||~isempty(find(Xin(:,9)>150, 1))
                    Amb_str=num2str(Amb_str);
                    Amb_str=strjoin(num2cell(Amb_str(1:length(Amb_str))),', ');
                    error('Structure(s) number: %s exceed recommended size limit. CDK descriptors might fail or take long time.',Amb_str);
                end
                
                InputDescCDK=strcat(StructureFile(1:length(StructureFile)-4),'_CDKDesc.csv');
                CDKlogfile=strcat(StructureFile(1:length(StructureFile)-4),'_CDKlogfile.log');
                CDKerr=strcat(StructureFile(1:length(StructureFile)-4),'_CDKerr.log');
                if verbose> 0
                    fprintf(1,'CDK 2.0 calculating 2D descriptors...\n');
                end
                    if verbose<2
                        [statusDesc,cmdoutDesc] =system (['java -jar ' strcat('"',fullfile(installdir,'CDKDescUI-2.0.jar'),'"') ' -b -t all -o ' strcat('"',InputDescCDK,'"')...
                            ' ' strcat('"',char(StructureFile),'"') ' > ' strcat('"',CDKlogfile,'"') ' 2> ' strcat('"',CDKerr,'"')]);
                        if statusDesc~=0 && ~isempty(cmdoutDesc)
                            disp(cmdoutDesc);
                            error('CDK descriptors failed. Check input structures!');
                        end
                    else
                        statusDesc =system (['java -jar ' strcat('"',fullfile(installdir,'CDKDescUI-2.0.jar'),'"') ' -b -t all -o ' strcat('"',InputDescCDK,'"')...
                            ' ' strcat('"',char(StructureFile),'"') ' > ' strcat('"',CDKlogfile,'"')]);
                        if statusDesc~=0
                            error('CDK descriptors failed. Check input structures!');
                        end
                    end
                if ispc
                    [~, numlines] = system(['FINDSTR /R /N "^.*" ',InputDescCDK,' | FIND /C ":"']); %win
                else
                    [~, numlines] = system( ['wc -l ', InputDescCDK] ); %linux
                end
                numlines=str2double(strrep(numlines,InputDescCDK,''))-1;
                if verbose>0
                    fprintf(1,'CDK descriptors calculated for: ');
                    fprintf(1, '%d molecules.\n',numlines);
                end
                if numlines < str2double(numStruct)
                    error('CDK descriptors failed. Check input structures!');
                end
                
                
            end
            if verbose> 0
                disp('Loading of CDK descriptors file...');
            end
            try
                XinCDK=readtable(InputDescCDK,'delimiter','\t','DatetimeType','text');
            catch ME
                if strcmp(ME.identifier,'MATLAB:readtable:OpenFailed')
                    error('Unable to open descriptors file');
                else
                    error(ME.message);
                    return;
                end
            end
            if size(XinCDK,1)==0 || size(XinCDK,2)==0
                error('Empty descriptors file!');
            end
            XinCDK(:,1)=[];
            if size(XinCDK,1)~=size(Xin,1)
                error('Mismatch between PaDEL and CDK descriptors files')
            elseif strcmpi(XinCDK.Properties.VariableNames(end),'Zagreb')
                XlabelsCDK=XinCDK.Properties.VariableNames;
            elseif strcmpi(XinCDK.Properties.VariableNames(end),'nAcid')
                XinCDK=XinCDK(:,train.reorder_CDK);
                XlabelsCDK=XinCDK.Properties.VariableNames;
            else
                error('Check or recalculate CDK descriptors');
            end
            if size(XinCDK,1)==size(Xin,1)
                %fprintf(1,'The number of input molecules is: %d \n',size(XinCDK,1));
                
                i=1;
                Temp=zeros(size(XinCDK));
                if verbose> 0
                    disp('Checking loaded variables.');
                end
                while i<=length(XlabelsCDK)
                    if cellfun(@ischar,table2cell(XinCDK(1,i)))
                        Temp(:,i)=str2double(table2cell(XinCDK(:,i)));
                    else
                        Temp(:,i)=XinCDK{:,i};
                    end
                    i=i+1;
                end
                if verbose> 0
                    %disp(['The number of loaded CDK descriptors is: ', num2str(length(XlabelsCDK))]);
                    disp(['Loaded ', num2str(length(XlabelsCDK)),' CDK descriptors for ', num2str(size(XinCDK,1)),' molecules.']);
                    
                end
                clear('XinCDK');
                XinCDK=Temp;
                clear('Temp');
            end
            
        end
        if fp==1
            if structure==1 && inputFP==0
                InputDescFP=strcat(StructureFile(1:length(StructureFile)-4),'_PadelFP.csv');
                PaDELlogfileFP=strcat(StructureFile(1:length(StructureFile)-4),'_PaDELlogfileFP.log');
                if verbose >0
                    fprintf(1,'PaDEL generating fingerprints...\n');
                    if verbose ==1
                        [statusDesc,cmdoutDesc] =system (['java -Djava.awt.headless=true -jar ' strcat('"',fullfile(installdir,'padel-full-1.00.jar'),'"')...
                            ' -fingerprints -descriptortypes ' strcat('"',fullfile(installdir,'desc_fp.xml'),'"') ' -removesalt -standardizenitro -detectaromaticity -retainorder -maxruntime 60000 -dir '...
                            strcat('"',char(StructureFile),'"') ' -file ' strcat('"',InputDescFP,'"') ' > ' strcat('"',PaDELlogfileFP,'"')]);
                        if statusDesc~=0 && ~isempty(cmdoutDesc)
                            disp(cmdoutDesc);
                        end
                    else
                        statusDesc =system (['java -Djava.awt.headless=true -jar ' strcat('"',fullfile(installdir,'padel-full-1.00.jar'),'"')...
                            ' -fingerprints -descriptortypes ' strcat('"',fullfile(installdir,'desc_fp.xml'),'"') ' -removesalt -standardizenitro -detectaromaticity -retainorder -maxruntime 60000 -dir '...
                            strcat('"',char(StructureFile),'"') ' -file ' strcat('"',InputDescFP,'"')]);
                        if statusDesc~=0
                            error('PaDEL fingerprints failed. Check input structures!');
                        end
                    end
                    fprintf(1,'PaDEL fingerprints generated for: ');
                    
                    if ispc
                        [~, numlines] = system(['FINDSTR /R /N "^.*" ',InputDescFP,' | FIND /C ":"']); %win
                    else
                        [~, numlines] = system( ['wc -l ', InputDescFP] ); %linux
                    end
                    numlines=str2double(strrep(numlines,InputDescFP,''))-1;
                    fprintf(1, '%d molecules.\n',numlines);
                    if numlines < str2double(numStruct)
                        error('PaDEL fingerprints failed. Check input structures!');
                    end

                else
                    [~,~] =system (['java -Djava.awt.headless=true -jar ' strcat('"',fullfile(installdir,'padel-full-1.00.jar'),'"')...
                        ' -fingerprints -descriptortypes ' strcat('"',fullfile(installdir,'desc_fp.xml'),'"') ' -removesalt -standardizenitro -detectaromaticity -retainorder -maxruntime 60000 -dir '...
                        strcat('"',char(StructureFile),'"') ' -file ' strcat('"',InputDescFP,'"') ' > ' strcat('"',PaDELlogfileFP,'"')]);
                    if ispc
                        [~, numlines] = system('FINDSTR /R /N "^.*" PadelFP.csv | FIND /C ":"'); %win
                    else
                        [~, numlines] = system( ['wc -l ', 'PadelFP.csv'] ); %linux
                    end
                    numlines=str2double(strrep(numlines,' PadelFP.csv',''))-1;
                    if numlines < str2double(numStruct)
                        error('PaDEL fingerprints failed. Check input structures!');
                    end
                end
                
            end
            
            %loading fingerpritns moved pKa sections%
            
        end
        
        %Start SaltInfo
        if salt==1 && ~isempty(FileSalt) && (ismember('mp',lower(prop))||ismember('logp',lower(prop))||ismember('logd',lower(prop)))
            if verbose> 0
                disp('Reading file with salt information.');
            end
            try
                SaltIndex=readtable(FileSalt,'delimiter',',');
                catch ME
                if strcmp(ME.identifier,'MATLAB:readtable:OpenFailed')
                    error('Unable to open descriptors file');
                else
                    error(ME.message);
                    return;
                end
            end
            %     if strcmpi(SaltIndex{1},'Name')
            %         SaltIndex=SaltIndex(
            if size(SaltIndex,1)==size(Xin,1)
                if cellfun(@ischar,table2cell(SaltIndex(1,end)))
                    Temp(:,:)=str2double(table2cell(SaltIndex(:,end)));
                else
                    
                    Temp(:,:)=SaltIndex{:,end};
                end
                
                clear('SaltIndex');
                SaltIndex=Temp;
                clear('Temp');
                
                if verbose> 0
                    disp(['The number of molecules with salt information:', num2str(length(find(SaltIndex)))]);
                end
            else
                error('The number of saltIDs and structures must match.')
                %fprintf(2,'Number of compounds must be the same in both files. \n');
                %return
            end
            
            %res.SaltID=SaltIndex;
        end
        %End SaltInfo
        
    end
    
    
    
    if verbose> 0 && size(prop(:),1)>=1
        fprintf(1,'\n============== Running The Models ==============\n');
    end
    
    
    % General Structural properties:
    [Lia,Locb] = ismember('strp',lower(prop));
    if Lia
        if verbose> 0 && size(prop(:),1)>1
            fprintf(1,'Generating the general structural properties...\n');
        end
        load ('OPERA_models.mat', '-mat','STRP');
        %             Desc={'MW','nAtom','nHeavyAtom','nC','nO','nN','naAromAtom','nRing','nHeteroRing','HybRatio','nRotB','nHBAcc','nHBDon','LipinskiFailures','TopoPSA','AMR','MLFER_S'};
        %              Xtest=zeros(size(Xin,1),length(Desc));
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,STRP.Desc_i);
        
        Desc={'MolWeight','nbAtoms','nbHeavyAtoms','nbC','nbO','nbN','nbAromAtom','nbRing','nbHeteroRing','Sp3Sp2HybRatio','nbRotBd','nbHBdAcc','ndHBdDon','nbLipinskiFailures','TopoPolSurfAir','MolarRefract','CombDipolPolariz'};
        Xtest=array2table(Xtest,'VariableNames',Desc);
        T=array2table(MoleculeNames,'VariableNames',{'MoleculeID'});
        if nf>0 && (sep==1 || strcmpi(ext,'.txt'))
            %T=[T; nfID];
            %FoundBy=array2table(FoundBy,'VariableNames',{'FoundBy'});
            T=[T array2table(FoundBy,'VariableNames',{'FoundBy'})]; 
            Xtest(end+1:end+nf,:)=array2table(nan(nf,size(Xtest,2)));
            T=[T Xtest];
        else
            T=[T(1:end-nf,:) Xtest];
        end
        %T=[T Xtest];
        if sep==1
            if strcmpi(ext,'.csv')
                %T=struct2table(res);
                %                     res.Descriptors=Xtest;
                
                writetable(T,FileOut{Locb},'Delimiter',',');%,'QuoteStrings',true);
                fclose(output(Locb));
            elseif strcmpi(ext,'.txt')
                fprintf(output(Locb(1)),'\n\n\t\t\t\t\t General Structural properties... \n\n			============================================================== \n\n');
                for i=1:size(Xtest,1)
                    fprintf(output(Locb(1)),'\t Molecule %s:\n', MoleculeNames{i});
                    if nf>0
                        fprintf(output(Locb(1)),'\t FoundBy: %s\n\n', FoundBy{i});
                    end
                    for j=1:length(Desc)
                        fprintf(output(Locb(1)),'%s= %.3f\t;\t', Desc{j},Xtest{i,j});
                    end
                    fprintf(output(Locb(1)),'\n');
                end
                fclose(output(Locb(1)));
            end
            
        elseif strcmpi(ext,'.txt')
            fprintf(output,'\n\n\t\t\t\t\t General Structural properties... \n\n			============================================================== \n\n');
            for i=1:size(Xtest,1)
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if nf>0
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
                for j=1:length(Desc)
                    fprintf(output,'%s= %.3f\t;\t', Desc{j},Xtest{i,j});
                end
                fprintf(output,'\n');
            end
        end
        res=table2struct(T,'ToScalar',true);
        
        if sep==1
            resf.StrP=table2struct(T,'ToScalar',true);
            clear('res');
        end
        clear('T');
    end
    
    
    DescMat=[];
    DescNames={};
    
    
    %for j=1:length(prop)
    %switch lower(prop{j})
    
    if verbose> 0 && (pc||all)
        fprintf(1,'---------- PhysChem properties ----------\n');
    end
    
    %Predict LogP values
    %case {'logp'}
    [Lia,Locb] =ismember({'logp','logd'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogP values (Log10)...');
        end
        
        load ('OPERA_models.mat', '-mat','LOGP');
        Desc=LOGP.Desc;
        Xtest=Xin(:,LOGP.Desc_i);

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if salt ==0
            SaltIndex=zeros(size(Xtest,1),1);

            La=zeros(length(MoleculeNames));
            Lb=zeros(length(MoleculeNames));
            for i=1:length(MoleculeNames)
                if ~contains(MoleculeNames(i),'AUTOGEN_')
                    if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,2});
                    elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,3});
                    elseif regexp(MoleculeNames{i},'DTXCID[0-9]+')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,4});
                    elseif regexp(MoleculeNames{i},'[A-Z]+-[A-Z]+-[A-Z]')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,5});
                    end
                    if La(i)
                        %salt=1;
                        SaltIndex(i,1)=train.DSSToxQSARr.SaltInfo(Lb(i));
                    end
                end
            end
            if any(La)
                salt=1;
            end
        end
        
        
        if verbose>0
            if salt==1 && ~isempty(FileSalt)
                disp('The provided salt information will be considered in the predictions');
            elseif salt==1 && isempty(FileSalt)
                disp('Salts info. was retrieved using structures IDs for LogP predictions');
            end
            
        end
        
        if strcmpi(ext,'.txt') && sep==0 && Lia(1)
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogP values... \n\n			==============================================================n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        

        AD=classical_leverage(LOGP.model.set.train(:,1:end-1),Xtest,'auto');
        
        Xtest=[Xtest SaltIndex];
        Desc=[Desc,'SaltIndex'];
        
        pred = nnrpred(Xtest,LOGP.model.set.train,LOGP.model.set.y,LOGP.model.set.K,LOGP.model.set.dist_type,LOGP.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogP_exp=NaN(size(Xtest,1),1);
        end
        res.LogP_pred(:,1)=pred.y_pred_weighted;
%         AD=classical_leverage(train.LOGP.model.set.train,Xtest,'auto');
        res.AD_LogP=abs(AD.inorout-1)';
        res.AD_LogP(round(pred.dc(:,1),3)==0)=1;
        
        %             res.AD_index1=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index1)
        %                 res.AD_index1(isnan(res.AD_index1))=0;
        %             end
        
        %res.AD_index1=1./(1+nanmedian(pred.dc,2));
        
        
        res.AD_index_LogP=zeros(size(Xtest,1),1);
        %             res.Conf_index1=zeros(size(Xtest,1),1);
        res.Conf_index_LogP=zeros(size(Xtest,1),1);
        
        %             res.dc=pred.dc;
        %             res.w=pred.w;
        if neighbors
            LogP_CAS_neighbor=cell(size(Xtest,1),5);
            LogP_InChiKey_neighbor=cell(size(Xtest,1),5);
            LogP_DTXSID_neighbor=cell(size(Xtest,1),5);
            LogP_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogP_Exp_neighbor=nan(size(Xtest,1),5);
        LogP_pred_neighbor=nan(size(Xtest,1),5);
        
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),LOGP.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},LOGP.DTXSID);
                end
                if Li
                    if Lo>size(LOGP.DTXSID,1)
                        Lo=mod(Lo,size(LOGP.DTXSID,1));
                    end
                    res.LogP_exp(i)=LOGP.model.set.y(Lo);
                end
            end
            
            
            LogP_Exp_neighbor(i,:)=LOGP.model.set.y(pred.neighbors(i,:));
            LogP_pred_neighbor(i,:)=LOGP.model.yc_weighted(pred.neighbors(i,:));
            
            res.AD_index_LogP(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_LogP(i,1)=((1/(1+sqrt(((LogP_Exp_neighbor(i,:)-LogP_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_LogP(i,1))/2;
            
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogP_pred(i,1)=NaN;
                res.AD_LogP(i)=0;
                res.AD_index_LogP(i)=0;
                res.Conf_index_LogP(i,1)=0;
            end
            
            if Xin(i,12)==0
                res.AD_LogP(i)=0;
                res.AD_index_LogP(i)=res.AD_index_LogP(i)/2;
                res.Conf_index_LogP(i,1)=res.Conf_index_LogP(i,1)/2;
            end
            
            %res.Conf_index_LogP(i,1)=((1/(1+sqrt(((LogP_Exp_neighbor(i,:)-LogP_pred_neighbor(i,:)).^2)*pred.w(i,:)'))));
            
            
            %                 rmse=calc_reg_param(res.LogP_Exp_neighbor(i,:),res.LogP_pred_neighbor(i,:));
            %                 res.Conf_index1(i,1)=1/(1+rmse.RMSEC);
            
            %res.Conf_index(i,1)=1/(1+sqrt(sum(diag((res.LogP_Exp_neighbor(i,:)-res.LogP_pred_neighbor(i,:))*pred.w(i,:)').^2)));
            
            if neighbors==1
                LOGP.CAS=strrep(strrep(join(LOGP.CAS,'|',2),'|||',''),'||','');
                LOGP.DTXSID=strrep(strrep(join(LOGP.DTXSID,'|',2),'|||',''),'||','');
            
                LogP_CAS_neighbor(i,:)=LOGP.CAS(pred.neighbors(i,:));
                LogP_InChiKey_neighbor(i,:)=LOGP.InChiKey(pred.neighbors(i,:));
                LogP_DTXSID_neighbor(i,:)=LOGP.DTXSID(pred.neighbors(i,:));
                LogP_DSSTOXMPID_neighbor(i,:)=LOGP.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_LogP(i)~=0
                    res.LogP_CAS_neighbor(i,:)=LogP_CAS_neighbor(i,:);
                    res.LogP_InChiKey_neighbor(i,:)=LogP_InChiKey_neighbor(i,:);
                    res.LogP_DTXSID_neighbor(i,:)=LogP_DTXSID_neighbor(i,:);
                    res.LogP_DSSTOXMPID_neighbor(i,:)=LogP_DSSTOXMPID_neighbor(i,:);
                    res.LogP_Exp_neighbor(i,:)=LogP_Exp_neighbor(i,:);
                    res.LogP_pred_neighbor(i,:)=LogP_pred_neighbor(i,:);
                else
                    res.LogP_CAS_neighbor(i,:)=cell(1,5);
                    res.LogP_InChiKey_neighbor(i,:)=cell(1,5);
                    res.LogP_DTXSID_neighbor(i,:)=cell(1,5);
                    res.LogP_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogP_Exp_neighbor(i,:)=nan(1,5);
                    res.LogP_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            
            
            if strcmpi(ext,'.txt') && sep==1 && Lia(1)
                %res.Xtest=Xtest;
                fprintf(output(Locb(1)),'\t Molecule %s:\n', res.MoleculeID{i});
                if exp
                    fprintf(output(Locb(1)),'LogP experimental= %.3f\n', res.LogP_exp(i));
                end
                fprintf(output(Locb(1)),'LogP predicted= %.3f\n', res.LogP_pred(i));
                if res.AD_LogP(i)==1
                    fprintf(output(Locb(1)),'AD: inside\n');
                else
                    fprintf(output(Locb(1)),'AD: outside\n');
                end
                fprintf(output(Locb(1)),'AD_index= %.2f\n', res.AD_index_LogP(i));
                fprintf(output(Locb(1)),'Conf_index= %.2f\n', res.Conf_index_LogP(i));
                %CAS=strjoin(res.LogP_CAS_neighbor(i,1:5),',\t');
                %calc=strjoin(num2cell(res.LogP_pred_neighbor(i,1:5)),', ');
                %exp=strjoin(num2cell(res.LogP_Exp_neighbor(i,1:5)),', ');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1 
                    fprintf(output(Locb(1)),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',LOGP.model.set.K,res.LogP_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(1)),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',LOGP.model.set.K, res.LogP_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(1)),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',LOGP.model.set.K, res.LogP_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0 && Lia(1)
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n',res.MoleculeID{i});
                if exp
                    fprintf(output,'LogP experimental= %.3f\n', res.LogP_exp(i));
                end
                fprintf(output,'LogP predicted= %.3f\n', res.LogP_pred(i));
                if res.AD_LogP(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_LogP(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_LogP(i));
                %CAS=strjoin(res.LogP_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',LOGP.model.set.K, res.LogP_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',LOGP.model.set.K, res.LogP_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',LOGP.model.set.K, res.LogP_pred_neighbor(i,1:5));
                end
            end
        end
        
        if nf>0 && strcmpi(ext,'.txt') && Lia(1)
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(1)),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(1)),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        
        if sep==1 && strcmpi(ext,'.csv') && Lia(1)
            
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find((T{end,:})==0)}=nan(nf,find((T{end,:})==0));
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
        
            
            writetable(T,FileOut{Locb(1)},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(1)));
            clear('T');
            
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv') && Lia(1)
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
            
            
        end
        
%         if nf>0
%             
%         end
        
        if sep==1
            resf.LogP=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('LOGP');
        %end clean memory
    end
    %Predict MP values
    [Lia,Locb] =ismember('mp',lower(prop));
    if find(Lia)
        %case 'mp'
        if verbose>0
            disp('Predicting MP values (Deg. C)...');
        end
        
        load ('OPERA_models.mat', '-mat','MP');
        Desc=MP.Desc;
        Xtest=Xin(:,MP.Desc_i);

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting MP values... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end

        
%         AD=classical_leverage(train.MP.model.set.train(:,1:end-1),Xtest,'auto');
        
%         if salt ==1
%             Xtest=[Xtest SaltIndex];
%             Desc=[Desc,'SaltIndex'];
%             %pred = nnrpred(Xtest,train.MP.model_s.set.train,train.MP.model_s.set.y,train.MP.model_s.set.K,train.MP.model_s.set.dist_type,train.MP.model_s.set.param.pret_type);
%             %pred.D=diag(pred.D);
%             %AD=classical_leverage(train.MP.model_s.set.train,Xtest,'auto');
%         else
        if salt ==0
            SaltIndex=zeros(size(Xtest,1),1);
            %pred = nnrpred(Xtest,train.MP.model.set.train,train.MP.model.set.y,train.MP.model.set.K,train.MP.model.set.dist_type,train.MP.model.set.param.pret_type);
            %pred.D=diag(pred.D);
            %AD=classical_leverage(train.MP.model.set.train,Xtest,'auto');

            La=zeros(length(MoleculeNames));
            Lb=zeros(length(MoleculeNames));
            for i=1:length(MoleculeNames)
                if ~contains(MoleculeNames(i),'AUTOGEN_')
                    if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,2});
                    elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,3});
                    elseif regexp(MoleculeNames{i},'DTXCID[0-9]+')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,4});
                    elseif regexp(MoleculeNames{i},'[A-Z]+-[A-Z]+-[A-Z]')
                        [La(i),Lb(i)] = ismember(MoleculeNames{i},train.DSSToxQSARr{:,5});
                    end
                    if La(i)
                        %salt=1;
                        SaltIndex(i,1)=train.DSSToxQSARr.SaltInfo(Lb(i));
                    end
                end
            end
            if any(La)
                salt=1;
            end
        end
        
        if verbose>0
%             disp('Predicting MP values (Deg. C)...');
%             if verbose>1
%                 disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
%             end
            if salt==1 && ~isempty(FileSalt)
                disp('The provided salt information will be considered in the predictions');
            elseif salt==1 && isempty(FileSalt)
                disp('Salts info. was retrieved using structures IDs for MP predictions');
            end
            
        end
        
        
        
        
        AD=classical_leverage(MP.model.set.train(:,1:end-1),Xtest,'auto');
        
        Xtest=[Xtest SaltIndex];
        Desc=[Desc,'SaltIndex'];
        pred = nnrpred(Xtest,MP.model.set.train,MP.model.set.y,MP.model.set.K,MP.model.set.dist_type,MP.model.set.param.pret_type);
        pred.D=diag(pred.D);
        
        res.MoleculeID=MoleculeNames;
        if exp
            res.MP_exp=NaN(size(Xtest,1),1);
        end
        res.MP_pred(:,1)=pred.y_pred_weighted;
        %AD=classical_leverage(train.MP.model.set.train,Xtest,'auto');
        res.AD_MP=abs(AD.inorout-1)';
        res.AD_MP(round(pred.dc(:,1),3)==0)=1;
        
        %            res.AD_index1=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        res.AD_index_MP=zeros(size(Xtest,1),1);
        res.Conf_index_MP=zeros(size(Xtest,1),1);
        if neighbors
            MP_CAS_neighbor=cell(size(Xtest,1),5);
            MP_InChiKey_neighbor=cell(size(Xtest,1),5);
            MP_DTXSID_neighbor=cell(size(Xtest,1),5);
            MP_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        MP_Exp_neighbor=nan(size(Xtest,1),5);
        MP_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),MP.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},MP.DTXSID);
                end
                if Li
                    if Lo>size(MP.DTXSID,1)
                        Lo=mod(Lo,size(MP.DTXSID,1));
                    end
                    res.MP_exp(i)=MP.model.set.y(Lo);
                end
            end
            
            MP_Exp_neighbor(i,:)=MP.model.set.y(pred.neighbors(i,:));
            MP_pred_neighbor(i,:)=MP.model.yc_weighted(pred.neighbors(i,:));

            %                 rmse=calc_reg_param(res.MP_Exp_neighbor(i,:),res.MP_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC/50);
            
            res.AD_index_MP(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_MP(i,1)=((1/(1+sqrt(((MP_Exp_neighbor(i,:)-MP_pred_neighbor(i,:)).^2)*pred.w(i,:)')/50))+res.AD_index_MP(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.MP_pred(i,1)=NaN;
                res.AD_MP(i)=0;
                res.AD_index_MP(i)=0;
                res.Conf_index_MP(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_MP(i)=0;
                res.AD_index_MP(i)=res.AD_index_MP(i)/2;
                res.Conf_index_MP(i,1)=res.Conf_index_MP(i,1)/2;
            end
            if neighbors==1 
                MP.CAS=strrep(strrep(join(MP.CAS,'|',2),'|||',''),'||','');
                MP.DTXSID=strrep(strrep(join(MP.DTXSID,'|',2),'|||',''),'||','');
                MP_CAS_neighbor(i,:)=MP.CAS(pred.neighbors(i,:));
                MP_InChiKey_neighbor(i,:)=MP.InChiKey(pred.neighbors(i,:));
                MP_DTXSID_neighbor(i,:)=MP.DTXSID(pred.neighbors(i,:));
                MP_DSSTOXMPID_neighbor(i,:)=MP.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_MP(i)~=0
                    res.MP_CAS_neighbor(i,:)=MP_CAS_neighbor(i,:);
                    res.MP_InChiKey_neighbor(i,:)=MP_InChiKey_neighbor(i,:);
                    res.MP_DTXSID_neighbor(i,:)=MP_DTXSID_neighbor(i,:);
                    res.MP_DSSTOXMPID_neighbor(i,:)=MP_DSSTOXMPID_neighbor(i,:);
                    res.MP_Exp_neighbor(i,:)=MP_Exp_neighbor(i,:);
                    res.MP_pred_neighbor(i,:)=MP_pred_neighbor(i,:);
                else
                    res.MP_CAS_neighbor(i,:)=cell(1,5);
                    res.MP_InChiKey_neighbor(i,:)=cell(1,5);
                    res.MP_DTXSID_neighbor(i,:)=cell(1,5);
                    res.MP_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.MP_Exp_neighbor(i,:)=nan(1,5);
                    res.MP_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            
            if strcmpi(ext,'.txt') && sep==1
                
                %res.Xtest=Xtest;
                fprintf(output(Locb),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb),'MP experimental= %.3f\n', res.MP_exp(i));
                end
                fprintf(output(Locb),'MP predicted= %.3f\n', res.MP_pred(i));
                if res.AD_MP(i)==1
                    fprintf(output(Locb),'AD: inside\n');
                else
                    fprintf(output(Locb),'AD: outside\n');
                end
                fprintf(output(Locb),'AD_index= %.2f\n', res.AD_index_MP(i));
                fprintf(output(Locb),'Conf_index= %.2f\n', res.Conf_index_MP(i));
                %CAS=strjoin(res.MP_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',MP.model.set.K, res.MP_CAS_neighbor{i,1:5});
                    fprintf(output(Locb),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',MP.model.set.K, res.MP_Exp_neighbor(i,1:5));
                    fprintf(output(Locb),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',MP.model.set.K, res.MP_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'MP experimental= %.3f\n', res.MP_exp(i));
                end
                fprintf(output,'MP predicted= %.3f\n', res.MP_pred(i));
                if res.AD_MP(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_MP(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_MP(i));
                %CAS=strjoin(res.MP_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',MP.model.set.K, res.MP_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',MP.model.set.K, res.MP_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',MP.model.set.K, res.MP_pred_neighbor(i,1:5));
                end
            end
        end 
        if nf>0 && strcmpi(ext,'.txt') 
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')  
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.MP=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('MP')
        %end clean memory
    end
    %Predict BP values
    [Lia,Locb] =ismember('bp',lower(prop));
    if find(Lia)
        %case 'bp'
        if verbose>0
            disp('Predicting BP values (Deg. C)...');
        end
        
        load ('OPERA_models.mat', '-mat','BP');
        Desc=BP.Desc;
  
            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting BP values... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,BP.Desc_i);
        
        pred = nnrpred(Xtest,BP.model.set.train,BP.model.set.y,BP.model.set.K,BP.model.set.dist_type,BP.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.BP_exp=NaN(size(Xtest,1),1);
        end
        res.BP_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(BP.model.set.train,Xtest,'auto');
        res.AD_BP=abs(AD.inorout-1)';
        res.AD_BP(round(pred.dc(:,1),3)==0)=1;
        
        %             res.AD_index_BP=1./(1+nanmedian(pred.dc,2));
        
        %            res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_BP=zeros(size(Xtest,1),1);
        res.Conf_index_BP=zeros(size(Xtest,1),1);
        if neighbors
            BP_CAS_neighbor=cell(size(Xtest,1),5);
            BP_InChiKey_neighbor=cell(size(Xtest,1),5);
            BP_DTXSID_neighbor=cell(size(Xtest,1),5);
            BP_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        BP_Exp_neighbor=nan(size(Xtest,1),5);
        BP_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),BP.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},BP.DTXSID);
                end
                if Li
                    if Lo>size(BP.DTXSID,1)
                        Lo=mod(Lo,size(BP.DTXSID,1));
                    end
                    res.BP_exp(i)=BP.model.set.y(Lo);
                end
            end
            
            BP_Exp_neighbor(i,:)=BP.model.set.y(pred.neighbors(i,:));
            BP_pred_neighbor(i,:)=BP.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(BP_Exp_neighbor(i,:),BP_pred_neighbor(i,:));
            %                 res.Conf_index_BP(i,1)=1/(1+rmse.RMSEC/50);
            
            res.AD_index_BP(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_BP(i,1)=((1/(1+sqrt(((BP_Exp_neighbor(i,:)-BP_pred_neighbor(i,:)).^2)*pred.w(i,:)')/50))+res.AD_index_BP(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.BP_pred(i,1)=NaN;
                res.AD_BP(i)=0;
                res.AD_index_BP(i)=0;
                res.Conf_index_BP(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_BP(i)=0;
                res.AD_index_BP(i)=res.AD_index_BP(i)/2;
                res.Conf_index_BP(i,1)=res.Conf_index_BP(i,1)/2;
            end
            if neighbors==1
                BP.CAS=strrep(strrep(join(BP.CAS,'|',2),'|||',''),'||','');
                BP.DTXSID=strrep(strrep(join(BP.DTXSID,'|',2),'|||',''),'||','');
                BP_CAS_neighbor(i,:)=BP.CAS(pred.neighbors(i,:));
                BP_InChiKey_neighbor(i,:)=BP.InChiKey(pred.neighbors(i,:));
                BP_DTXSID_neighbor(i,:)=BP.DTXSID(pred.neighbors(i,:));
                BP_DSSTOXMPID_neighbor(i,:)=BP.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_BP(i)~=0
                    res.BP_CAS_neighbor(i,:)=BP_CAS_neighbor(i,:);
                    res.BP_InChiKey_neighbor(i,:)=BP_InChiKey_neighbor(i,:);
                    res.BP_DTXSID_neighbor(i,:)=BP_DTXSID_neighbor(i,:);
                    res.BP_DSSTOXMPID_neighbor(i,:)=BP_DSSTOXMPID_neighbor(i,:);
                    res.BP_Exp_neighbor(i,:)=BP_Exp_neighbor(i,:);
                    res.BP_pred_neighbor(i,:)=BP_pred_neighbor(i,:);
                else
                    res.BP_CAS_neighbor(i,:)=cell(1,5);
                    res.BP_InChiKey_neighbor(i,:)=cell(1,5);
                    res.BP_DTXSID_neighbor(i,:)=cell(1,5);
                    res.BP_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.BP_Exp_neighbor(i,:)=nan(1,5);
                    res.BP_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                
                %res.Xtest=Xtest;
                fprintf(output(Locb),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb),'BP experimental= %.3f\n', res.BP_exp(i));
                end
                fprintf(output(Locb),'BP predicted= %.3f\n', res.BP_pred(i));
                if res.AD_BP(i)==1
                    fprintf(output(Locb),'AD: inside\n');
                else
                    fprintf(output(Locb),'AD: outside\n');
                end
                fprintf(output(Locb),'AD_index= %.2f\n', res.AD_index_BP(i));
                fprintf(output(Locb),'Conf_index= %.2f\n', res.Conf_index_BP(i));
                %CAS=strjoin(res.BP_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',BP.model.set.K, res.BP_CAS_neighbor{i,1:5});
                    fprintf(output(Locb),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',BP.model.set.K, res.BP_Exp_neighbor(i,1:5));
                    fprintf(output(Locb),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',BP.model.set.K, res.BP_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'BP experimental= %.3f\n', res.BP_exp(i));
                end
                fprintf(output,'BP predicted= %.3f\n', res.BP_pred(i));
                if res.AD_BP(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_BP(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_BP(i));
                %CAS=strjoin(res.BP_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',BP.model.set.K, res.BP_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',BP.model.set.K, res.BP_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',BP.model.set.K, res.BP_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.BP=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('BP');
        %end clean memory
        
    end
    %Predict VP values
    %case {'vp' ,'logvp'}
    [Lia,Locb] =ismember({'vp','logvp'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogVP values (Log10 mmHg)...');
        end
        load ('OPERA_models.mat', '-mat','VP');
        Desc=VP.Desc;
      
            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting VP values in Log mmHg... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,VP.Desc_i);
        
        pred = nnrpred(Xtest,VP.model.set.train,VP.model.set.y,VP.model.set.K,VP.model.set.dist_type,VP.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogVP_exp=NaN(size(Xtest,1),1);
        end
        res.LogVP_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(VP.model.set.train,Xtest,'auto');
        res.AD_VP=abs(AD.inorout-1)';
        res.AD_VP(round(pred.dc(:,1),3)==0)=1;
        
        
        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_VP=zeros(size(Xtest,1),1);
        res.Conf_index_VP=zeros(size(Xtest,1),1);
        if neighbors
            LogVP_CAS_neighbor=cell(size(Xtest,1),5);
            LogVP_InChiKey_neighbor=cell(size(Xtest,1),5);
            LogVP_DTXSID_neighbor=cell(size(Xtest,1),5);
            LogVP_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogVP_Exp_neighbor=nan(size(Xtest,1),5);
        LogVP_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),VP.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},VP.DTXSID);
                end
                if Li
                    if Lo>size(VP.DTXSID,1)
                        Lo=mod(Lo,size(VP.DTXSID,1));
                    end
                    res.LogVP_exp(i)=VP.model.set.y(Lo);
                end
            end
            
            LogVP_Exp_neighbor(i,:)=VP.model.set.y(pred.neighbors(i,:));
            LogVP_pred_neighbor(i,:)=VP.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogVP_Exp_neighbor(i,:),res.LogVP_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_VP(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            res.Conf_index_VP(i,1)=((1/(1+sqrt(((LogVP_Exp_neighbor(i,:)-LogVP_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+ res.AD_index_VP(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogVP_pred(i,1)=NaN;
                res.AD_VP(i)=0;
                res.AD_index_VP(i)=0;
                res.Conf_index_VP(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_VP(i)=0;
                res.AD_index_VP(i)=res.AD_index_VP(i)/2;
                res.Conf_index_VP(i,1)=res.Conf_index_VP(i,1)/2;
            end
            if neighbors==1 
                VP.CAS=strrep(strrep(join(VP.CAS,'|',2),'|||',''),'||','');
                VP.DTXSID=strrep(strrep(join(VP.DTXSID,'|',2),'|||',''),'||','');
                LogVP_CAS_neighbor(i,:)=VP.CAS(pred.neighbors(i,:));
                LogVP_InChiKey_neighbor(i,:)=VP.InChiKey(pred.neighbors(i,:));
                LogVP_DTXSID_neighbor(i,:)=VP.DTXSID(pred.neighbors(i,:));
                LogVP_DSSTOXMPID_neighbor(i,:)=VP.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_VP(i)~=0
                    res.LogVP_CAS_neighbor(i,:)=LogVP_CAS_neighbor(i,:);
                    res.LogVP_InChiKey_neighbor(i,:)=LogVP_InChiKey_neighbor(i,:);
                    res.LogVP_DTXSID_neighbor(i,:)=LogVP_DTXSID_neighbor(i,:);
                    res.LogVP_DSSTOXMPID_neighbor(i,:)=LogVP_DSSTOXMPID_neighbor(i,:);
                    res.LogVP_Exp_neighbor(i,:)=LogVP_Exp_neighbor(i,:);
                    res.LogVP_pred_neighbor(i,:)=LogVP_pred_neighbor(i,:);
                else
                    res.LogVP_CAS_neighbor(i,:)=cell(1,5);
                    res.LogVP_InChiKey_neighbor(i,:)=cell(1,5);
                    res.LogVP_DTXSID_neighbor(i,:)=cell(1,5);
                    res.LogVP_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogVP_Exp_neighbor(i,:)=nan(1,5);
                    res.LogVP_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogVP experimental= %.3f\n', res.LogVP_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogVP predicted= %.3f\n', res.LogVP_pred(i));
                if res.AD_VP(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_VP(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_VP(i));
                %CAS=strjoin(res.LogVP_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',VP.model.set.K, res.LogVP_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',VP.model.set.K, res.LogVP_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',VP.model.set.K, res.LogVP_pred_neighbor(i,1:5));
                end
                
                
            elseif strcmpi(ext,'.txt') && sep==0

                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogVP experimental= %.3f\n', res.LogVP_exp(i));
                end
                fprintf(output,'LogVP predicted= %.3f\n', res.LogVP_pred(i));
                if res.AD_VP(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_VP(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_VP(i));
                %CAS=strjoin(res.LogVP_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',VP.model.set.K, res.LogVP_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',VP.model.set.K, res.LogVP_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',VP.model.set.K, res.LogVP_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.VP=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('VP');
        %end clean memory
        
    end
    
    %Predict WS values
    %case {'ws','logws'}
    [Lia,Locb] =ismember({'ws','logws'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogWS values (Log10 M)...');
        end
        
        load ('OPERA_models.mat', '-mat','WS');
        Desc=WS.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogWS values... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,WS.Desc_i);
        
        pred = nnrpred(Xtest,WS.model.set.train,WS.model.set.y,WS.model.set.K,WS.model.set.dist_type,WS.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogWS_exp=NaN(size(Xtest,1),1);
        end
        res.LogWS_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(WS.model.set.train,Xtest,'auto');
        res.AD_WS=abs(AD.inorout-1)';
        res.AD_WS(round(pred.dc(:,1),3)==0)=1;
        
        
        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_WS=zeros(size(Xtest,1),1);
        res.Conf_index_WS=zeros(size(Xtest,1),1);
        if neighbors
            LogWS_CAS_neighbor=cell(size(Xtest,1),5);
            LogWS_InChiKey_neighbor=cell(size(Xtest,1),5);
            LogWS_DTXSID_neighbor=cell(size(Xtest,1),5);
            LogWS_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogWS_Exp_neighbor=nan(size(Xtest,1),5);
        LogWS_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),WS.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},WS.DTXSID);
                end
                if Li
                    if Lo>size(WS.DTXSID,1)
                        Lo=mod(Lo,size(WS.DTXSID,1));
                    end
                    res.LogWS_exp(i)=WS.model.set.y(Lo);
                end
            end
            
            LogWS_Exp_neighbor(i,:)=WS.model.set.y(pred.neighbors(i,:));
            LogWS_pred_neighbor(i,:)=WS.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogWS_Exp_neighbor(i,:),res.LogWS_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_WS(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_WS(i,1)=((1/(1+sqrt(((LogWS_Exp_neighbor(i,:)-LogWS_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_WS(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogWS_pred(i,1)=NaN;
                res.AD_WS(i)=0;
                res.AD_index_WS(i)=0;
                res.Conf_index_WS(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_WS(i)=0;
                res.AD_index_WS(i)=res.AD_index_WS(i)/2;
                res.Conf_index_WS(i,1)=res.Conf_index_WS(i,1)/2;
            end
            if neighbors==1
                WS.CAS=strrep(strrep(join(WS.CAS,'|',2),'|||',''),'||','');
                WS.DTXSID=strrep(strrep(join(WS.DTXSID,'|',2),'|||',''),'||','');
                LogWS_CAS_neighbor(i,:)=WS.CAS(pred.neighbors(i,:));
                LogWS_InChiKey_neighbor(i,:)=WS.InChiKey(pred.neighbors(i,:));
                LogWS_DTXSID_neighbor(i,:)=WS.DTXSID(pred.neighbors(i,:));
                LogWS_DSSTOXMPID_neighbor(i,:)=WS.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_WS(i)~=0
                    res.LogWS_CAS_neighbor(i,:)=LogWS_CAS_neighbor(i,:);
                    res.LogWS_InChiKey_neighbor(i,:)=LogWS_InChiKey_neighbor(i,:);
                    res.LogWS_DTXSID_neighbor(i,:)=LogWS_DTXSID_neighbor(i,:);
                    res.LogWS_DSSTOXMPID_neighbor(i,:)=LogWS_DSSTOXMPID_neighbor(i,:);
                    res.LogWS_Exp_neighbor(i,:)=LogWS_Exp_neighbor(i,:);
                    res.LogWS_pred_neighbor(i,:)=LogWS_pred_neighbor(i,:);
                else
                    res.LogWS_CAS_neighbor(i,:)=cell(1,5);
                    res.LogWS_InChiKey_neighbor(i,:)=cell(1,5);
                    res.LogWS_DTXSID_neighbor(i,:)=cell(1,5);
                    res.LogWS_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogWS_Exp_neighbor(i,:)=nan(1,5);
                    res.LogWS_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogWS experimental= %.3f\n', res.LogWS_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogWS predicted= %.3f\n', res.LogWS_pred(i));
                if res.AD_WS(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_WS(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_WS(i));
                %CAS=strjoin(res.LogWS_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',WS.model.set.K, res.LogWS_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',WS.model.set.K, res.LogWS_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',WS.model.set.K, res.LogWS_pred_neighbor(i,1:5));
                end
                
                
            elseif strcmpi(ext,'.txt') && sep==0
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogWS experimental= %.3f\n', res.LogWS_exp(i));
                end
                fprintf(output,'LogWS predicted= %.3f\n', res.LogWS_pred(i));
                if res.AD_WS(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_WS(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_WS(i));
                %CAS=strjoin(res.LogWS_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',WS.model.set.K, res.LogWS_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',WS.model.set.K, res.LogWS_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',WS.model.set.K, res.LogWS_pred_neighbor(i,1:5));
                end
                
            end
        end  
        if nf>0 && strcmpi(ext,'.txt') 
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')       
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.WS=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('WS');
        %end clean memory
        
    end
    
    %Predict HL values
    %case {'hl','loghl'}
    [Lia,Locb] =ismember({'hl','loghl'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogHL values (Log10 atm-m3/V)...');
        end
        load ('OPERA_models.mat', '-mat','HL');
        Desc=HL.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogHL values... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,HL.Desc_i);
        
        pred = nnrpred(Xtest,HL.model.set.train,HL.model.set.y,HL.model.set.K,HL.model.set.dist_type,HL.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogHL_exp=NaN(size(Xtest,1),1);
        end
        res.LogHL_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(HL.model.set.train,Xtest,'auto');
        res.AD_HL=abs(AD.inorout-1)';
        res.AD_HL(round(pred.dc(:,1),3)==0)=1;
        
        
        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_HL=zeros(size(Xtest,1),1);
        res.Conf_index_HL=zeros(size(Xtest,1),1);
        if neighbors
            HL_CAS_neighbor=cell(size(Xtest,1),5);
            HL_InChiKey_neighbor=cell(size(Xtest,1),5);
            HL_DTXSID_neighbor=cell(size(Xtest,1),5);
            HL_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogHL_Exp_neighbor=nan(size(Xtest,1),5);
        LogHL_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),HL.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},HL.DTXSID);
                end
                if Li
                    if Lo>size(HL.DTXSID,1)
                        Lo=mod(Lo,size(HL.DTXSID,1));
                    end
                    res.LogHL_exp(i)=HL.model.set.y(Lo);
                end
            end
            
            LogHL_Exp_neighbor(i,:)=HL.model.set.y(pred.neighbors(i,:));
            LogHL_pred_neighbor(i,:)=HL.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogHL_Exp_neighbor(i,:),res.LogHL_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_HL(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_HL(i,1)=((1/(1+sqrt(((LogHL_Exp_neighbor(i,:)-LogHL_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_HL(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogHL_pred(i,1)=NaN;
                res.AD_HL(i)=0;
                res.AD_index_HL(i)=0;
                res.Conf_index_HL(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_HL(i)=0;
                res.AD_index_HL(i)=res.AD_index_HL(i)/2;
                res.Conf_index_HL(i,1)=res.Conf_index_HL(i,1)/2;
            end
            if neighbors==1 
                HL.CAS=strrep(strrep(join(HL.CAS,'|',2),'|||',''),'||','');
                HL.DTXSID=strrep(strrep(join(HL.DTXSID,'|',2),'|||',''),'||','');
                HL_CAS_neighbor(i,:)=HL.CAS(pred.neighbors(i,:));
                HL_InChiKey_neighbor(i,:)=HL.InChiKey(pred.neighbors(i,:));
                HL_DTXSID_neighbor(i,:)=HL.DTXSID(pred.neighbors(i,:));
                HL_DSSTOXMPID_neighbor(i,:)=HL.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_HL(i)~=0
                    res.HL_CAS_neighbor(i,:)=HL_CAS_neighbor(i,:);
                    res.HL_InChiKey_neighbor(i,:)=HL_InChiKey_neighbor(i,:);
                    res.HL_DTXSID_neighbor(i,:)=HL_DTXSID_neighbor(i,:);
                    res.HL_DSSTOXMPID_neighbor(i,:)=HL_DSSTOXMPID_neighbor(i,:);
                    res.LogHL_Exp_neighbor(i,:)=LogHL_Exp_neighbor(i,:);
                    res.LogHL_pred_neighbor(i,:)=LogHL_pred_neighbor(i,:);
                else
                    res.HL_CAS_neighbor(i,:)=cell(1,5);
                    res.HL_InChiKey_neighbor(i,:)=cell(1,5);
                    res.HL_DTXSID_neighbor(i,:)=cell(1,5);
                    res.HL_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogHL_Exp_neighbor(i,:)=nan(1,5);
                    res.LogHL_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogHL experimental= %.3f\n', res.LogHL_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogHL predicted= %.3f\n', res.LogHL_pred(i));
                if res.AD_HL(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_HL(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_HL(i));
                %CAS=strjoin(res.HL_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',HL.model.set.K, res.HL_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',HL.model.set.K, res.LogHL_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',HL.model.set.K, res.LogHL_pred_neighbor(i,1:5));
                end
                        
            elseif strcmpi(ext,'.txt') && sep==0
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogHL experimental= %.3f\n', res.LogHL_exp(i));
                end
                fprintf(output,'LogHL predicted= %.3f\n', res.LogHL_pred(i));
                if res.AD_HL(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_HL(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_HL(i));
                %CAS=strjoin(res.HL_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',HL.model.set.K, res.HL_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',HL.model.set.K, res.LogHL_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',HL.model.set.K, res.LogHL_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end

        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end

            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.HL=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('HL');
        %end clean memory
        
    end
    
    %Predict RT values
    %case {'rt'}
    [Lia,Locb] =ismember('rt',lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting RT values (Mins.)...');
        end
        load ('OPERA_models.mat', '-mat','RT');
        Desc=RT.Desc;

            if verbose>1
                disp(['PLS model with ', num2str(length(Desc)),' descriptors']);
            end
        
        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting RT values... \n\n			==============================================================  \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,RT.Desc_i);
        
        pred = nnrpred(Xtest,RT.model.set.train,RT.model.set.y,RT.model.set.K,RT.model.set.dist_type,RT.model.set.scal);
        pred.D=diag(pred.D);
        predpls=plstest(Xtest,RT.model);
        
        res.MoleculeID=MoleculeNames;
        if exp
            res.RT_exp=NaN(size(Xtest,1),1);
        end
        res.RT_pred(:,1)=predpls.yc;
        AD=classical_leverage(RT.model.set.train,Xtest,'auto');
        res.AD_RT=abs(AD.inorout-1)';
        res.AD_RT(round(pred.dc(:,1),3)==0)=1;
        
        
        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_RT=zeros(size(Xtest,1),1);
        res.Conf_index_RT=zeros(size(Xtest,1),1);
        if neighbors
            RT_CAS_neighbor=cell(size(Xtest,1),5);
            RT_DTXSID_neighbor=cell(size(Xtest,1),5);
        end
        RT_Exp_neighbor=nan(size(Xtest,1),5);
        RT_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),RT.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},RT.DTXSID);
                end
                if Li
                    if Lo>size(RT.DTXSID,1)
                        Lo=mod(Lo,size(RT.DTXSID,1));
                    end
                    res.RT_exp(i)=RT.model.set.y(Lo);
                end
            end
           
            RT_Exp_neighbor(i,:)=RT.model.set.y(pred.neighbors(i,:));
            RT_pred_neighbor(i,:)=RT.model.yc(pred.neighbors(i,:));

            res.AD_index_RT(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            res.Conf_index_RT(i,1)=((1/(1+sqrt(((RT_Exp_neighbor(i,:)-RT_pred_neighbor(i,:)).^2)*pred.w(i,:)')/4.5))+res.AD_index_RT(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.RT_pred(i,1)=NaN;
                res.AD_RT(i)=0;
                res.AD_index_RT(i)=0;
                res.Conf_index_RT(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_RT(i)=0;
                res.AD_index_RT(i)=res.AD_index_RT(i)/2;
                res.Conf_index_RT(i,1)=res.Conf_index_RT(i,1)/2;
            end
            if res.RT_pred(i,1)<0
                res.RT_pred(i,1)=0;
                res.AD_RT(i)=0;
            end
            if neighbors==1
                RT.CAS=strrep(strrep(join(RT.CAS,'|',2),'|||',''),'||','');
                RT.DTXSID=strrep(strrep(join(RT.DTXSID,'|',2),'|||',''),'||','');
                RT_CAS_neighbor(i,:)=RT.CAS(pred.neighbors(i,:));
                RT_DTXSID_neighbor(i,:)=RT.DTXSID(pred.neighbors(i,:));
                if res.AD_index_RT(i)~=0
                    res.RT_CAS_neighbor(i,:)=RT_CAS_neighbor(i,:);
                    res.RT_DTXSID_neighbor(i,:)=RT_DTXSID_neighbor(i,:);
                    res.RT_Exp_neighbor(i,:)=RT_Exp_neighbor(i,:);
                    res.RT_pred_neighbor(i,:)=RT_pred_neighbor(i,:);
                else
                    res.RT_CAS_neighbor(i,:)=cell(1,5);
                    res.RT_DTXSID_neighbor(i,:)=cell(1,5);
                    res.RT_Exp_neighbor(i,:)=nan(1,5);
                    res.RT_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'RT experimental= %.3f\n', res.RT_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'RT predicted= %.3f\n', res.RT_pred(i));
                if res.AD_RT(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_RT(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_RT(i));
                %CAS=strjoin(res.RT_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',RT.model.set.K, res.RT_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',RT.model.set.K, res.RT_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',RT.model.set.K, res.RT_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'RT experimental= %.3f\n', res.RT_exp(i));
                end
                fprintf(output,'RT predicted= %.3f\n', res.RT_pred(i));
                if res.AD_RT(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_RT(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_RT(i));
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',RT.model.set.K, res.RT_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',RT.model.set.K, res.RT_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',RT.model.set.K, res.RT_pred_neighbor(i,1:5));
                end
                
            end
        end 
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end

            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.RT=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('predpls');
        clear('AD');
        clear('RT');
        %end clean memory
        
    end
    
    %Predict KOA values
    %case {'koa','logkoa'}
    [Lia,Locb] =ismember({'koa','logkoa'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogKOA values (Log10)...');
        end
        load ('OPERA_models.mat', '-mat','KOA');
        Desc=KOA.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end
        
        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogKOA values... \n\n			==============================================================  \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,KOA.Desc_i);
        
        pred = nnrpred(Xtest,KOA.model.set.train,KOA.model.set.y,KOA.model.set.K,KOA.model.set.dist_type,KOA.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogKOA_exp=NaN(size(Xtest,1),1);
        end
        res.LogKOA_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(KOA.model.set.train,Xtest,'auto');
        res.AD_KOA=abs(AD.inorout-1)';
        res.AD_KOA(round(pred.dc(:,1),3)==0)=1;

        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_KOA=zeros(size(Xtest,1),1);
        res.Conf_index_KOA=zeros(size(Xtest,1),1);
        if neighbors
            KOA_CAS_neighbor=cell(size(Xtest,1),5);
            KOA_InChiKey_neighbor=cell(size(Xtest,1),5);
            KOA_DTXSID_neighbor=cell(size(Xtest,1),5);
            KOA_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogKOA_Exp_neighbor=nan(size(Xtest,1),5);
        LogKOA_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),KOA.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},KOA.DTXSID);
                end
                if Li
                    if Lo>size(KOA.DTXSID,1)
                        Lo=mod(Lo,size(KOA.DTXSID,1));
                    end
                    res.LogKOA_exp(i)=KOA.model.set.y(Lo);
                end
            end
            
            LogKOA_Exp_neighbor(i,:)=KOA.model.set.y(pred.neighbors(i,:));
            LogKOA_pred_neighbor(i,:)=KOA.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogKOA_Exp_neighbor(i,:),res.LogKOA_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_KOA(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_KOA(i,1)=((1/(1+sqrt(((LogKOA_Exp_neighbor(i,:)-LogKOA_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_KOA(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogKOA_pred(i,1)=NaN;
                res.AD_KOA(i)=0;
                res.AD_index_KOA(i)=0;
                res.Conf_index_KOA(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_KOA(i)=0;
                res.AD_index_KOA(i)=res.AD_index_KOA(i)/2;
                res.Conf_index_KOA(i,1)=res.Conf_index_KOA(i,1)/2;
            end
            if neighbors==1
                KOA.CAS=strrep(strrep(join(KOA.CAS,'|',2),'|||',''),'||','');
                KOA.DTXSID=strrep(strrep(join(KOA.DTXSID,'|',2),'|||',''),'||','');
                KOA_CAS_neighbor(i,:)=KOA.CAS(pred.neighbors(i,:));
                KOA_InChiKey_neighbor(i,:)=KOA.InChiKey(pred.neighbors(i,:));
                KOA_DTXSID_neighbor(i,:)=KOA.DTXSID(pred.neighbors(i,:));
                KOA_DSSTOXMPID_neighbor(i,:)=KOA.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_KOA(i)~=0
                    res.KOA_CAS_neighbor(i,:)=KOA_CAS_neighbor(i,:);
                    res.KOA_InChiKey_neighbor(i,:)=KOA_InChiKey_neighbor(i,:);
                    res.KOA_DTXSID_neighbor(i,:)=KOA_DTXSID_neighbor(i,:);
                    res.KOA_DSSTOXMPID_neighbor(i,:)=KOA_DSSTOXMPID_neighbor(i,:);
                    res.LogKOA_Exp_neighbor(i,:)=LogKOA_Exp_neighbor(i,:);
                    res.LogKOA_pred_neighbor(i,:)=LogKOA_pred_neighbor(i,:);
                else
                    res.KOA_CAS_neighbor(i,:)=cell(1,5);
                    res.KOA_InChiKey_neighbor(i,:)=cell(1,5);
                    res.KOA_DTXSID_neighbor(i,:)=cell(1,5);
                    res.KOA_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogKOA_Exp_neighbor(i,:)=nan(1,5);
                    res.LogKOA_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogKOA experimental= %.3f\n', res.LogKOA_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogKOA predicted= %.3f\n', res.LogKOA_pred(i));
                if res.AD_KOA(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_KOA(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_KOA(i));
                %CAS=strjoin(res.KOA_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',KOA.model.set.K, res.KOA_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',KOA.model.set.K, res.LogKOA_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',KOA.model.set.K, res.LogKOA_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogKOA experimental= %.3f\n', res.LogKOA_exp(i));
                end
                fprintf(output,'LogKOA predicted= %.3f\n', res.LogKOA_pred(i));
                if res.AD_KOA(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_KOA(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_KOA(i));
                %CAS=strjoin(res.KOA_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',KOA.model.set.K, res.KOA_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',KOA.model.set.K, res.LogKOA_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',KOA.model.set.K, res.LogKOA_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.KOA=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('KOA');
        %end clean memory
    end
    
    %Predict pka values
    %case {'pka'}
    [Lia,Locb] =ismember({'pka','logd'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting pKa values (unitless)...');
        end
        load ('OPERA_models.mat', '-mat','PKA');
        Desc=PKA.Desc;
        if verbose>1
            disp(['SVM models with ', num2str(length(Desc)),' descriptors']);
        end
        if verbose>0
            disp('Loading of fingerprints file...');
        end
        
        
        %             Desc_a=train.PKA.Desc_a;
        %             Desc_b=train.PKA.Desc_b;
        %load fingerprints%
%         if verbose> 0
%                 disp('Loading of fingerprints file...');
%         end
            try
                XinFP=readtable(InputDescFP,'delimiter',',','DatetimeType','text');
            catch ME
                if strcmp(ME.identifier,'MATLAB:readtable:OpenFailed')
                    error('Unable to open descriptors file');
                else
                    error(ME.message);
                    return;
                end
            end
            XlabelsFP=XinFP.Properties.VariableNames;
            if size(XinFP,1)==0 || size(XinFP,2)==0
                error('Empty descriptors file!');
            end
            XinFP=XinFP(:,2:end);
            %XlabelsFP=XlabelsFP(2:end);
            if size(XinFP,1)~=size(Xin,1)
                error('Mismatch between descriptors and fingerprint files')
            elseif verbose>0
                %fprintf(1,'The number of input molecules is: %d \n',size(XinFP,1));
                %disp(['The number of loaded fingerprints bits is: ', num2str(length(XlabelsFP)-1)]);
                disp(['Loaded ', num2str(length(XlabelsFP)-1),' PaDEL fingerprints for ', num2str(size(XinFP,1)),' molecules.']);
            end
         %end load fingerprints
            

        
        if strcmpi(ext,'.txt') && sep==0 && Lia(1)
            fprintf(output,'\n\n\t\t\t\t\t Predicting pKa values... \n\n			==============================================================  \n\n');
        end
        
        
        Xtest=Xin(:,PKA.Desc_i);
        Xtest_a=table2array(XinFP(:,PKA.Desc_ai));
        Xtest_b=table2array(XinFP(:,PKA.Desc_bi));
        
        
        pred = knnpred(Xtest,PKA.model.set.train,PKA.model.set.class,PKA.model.set.K,PKA.model.set.dist_type,PKA.model.set.param.pret_type);
        pred.D=diag(pred.D);
        pKa_a(:,1)=svmpredict([1:1:length(Xtest_a(:,1))]',Xtest_a,PKA.model_a,'-q');
        %AD_a = nnrpred(Xtest_a,train.PKA_a.model.set.train,train.PKA_a.model.set.y,train.pka_a.model.set.K,train.pka_a.model.set.dist_type,train.pka_a.model.set.param.pret_type);
        
        pKa_b(:,1)=svmpredict([1:1:length(Xtest_b(:,1))]',Xtest_b,PKA.model_b,'-q');
        %AD_b = nnrpred(Xtest_b,train.pka_b.model.set.train,train.pka_b.model.set.y,train.pka_b.model.set.K,train.pka_b.model.set.dist_type,train.pka_b.model.set.param.pret_type);
        
        res.MoleculeID=MoleculeNames;
        if exp
            res.pKa_a_exp=NaN(size(Xtest,1),1);
            res.pKa_b_exp=NaN(size(Xtest,1),1);
        end
        res.ionization=zeros(size(Xtest,1),1);
        pKa_ac_ba_amp=pred.class_pred;
        res.pKa_a_pred=pKa_a;
        res.pKa_b_pred=pKa_b;
        
        AD=classical_leverage(PKA.model.set.train,Xtest,'auto');
        res.AD_pKa=abs(AD.inorout-1)';
        res.AD_pKa(round(pred.dc(:,1),3)==0)=1;
        
        
        res.AD_index_pKa=zeros(size(Xtest,1),1);
        res.Conf_index_pKa=zeros(size(Xtest,1),1);
        if neighbors
            pKa_CAS_neighbor=cell(size(Xtest,1),3);
            pKa_InChiKey_neighbor=cell(size(Xtest,1),3);
            pKa_DTXSID_neighbor=cell(size(Xtest,1),3);
            pKa_DSSTOXMPID_neighbor=cell(size(Xtest,1),3);
        end
        pKa_Exp_neighbor=nan(size(Xtest,1),3);
        pKa_pred_neighbor=nan(size(Xtest,1),3);
        
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),PKA.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},PKA.DTXSID);
                end
                if Li
                    res.pKa_a_exp(i,1)=PKA.model.set.y_exp(Lo,1);
                    res.pKa_b_exp(i,1)=PKA.model.set.y_exp(Lo,2);
                end
            end
            % Xin(,13)=nN, Xin(,14)= nO, Xin(,722)=ntN, Xin(,731)=ndO, Xin(,732)= nssO, Xin(,747)=nsSH
            %XinFP(,5911)=KRFP1406

            if XinFP{i,5911}==0 && Xin(i,747)==0 && (sum(Xin(i,13:14))-sum(Xin(i,[722 731:732]))==0 || (Xin(i,13)==Xin(i,731) && Xin(i,14)==2*Xin(i,13) && Xin(i,722)==0 && Xin(i,732)==0))
                pKa_ac_ba_amp(i)=NaN;
                res.ionization(i)=0;
                res.pKa_a_pred(i)=NaN;
                res.pKa_b_pred(i)=NaN;
                
            else
                
                if pred.class_pred(i)==1
                    res.pKa_b_pred(i,1)=NaN;
                    res.ionization(i)=1;
                elseif pred.class_pred(i)==2 && XinFP{i,5911}==0 && Xin(i,747)==0
                    res.pKa_a_pred(i,1)=NaN;
                    res.ionization(i)=1;
                elseif pred.class_pred(i)==3 || (pred.class_pred(i)==2 && (XinFP{i,5911}||Xin(i,747)))
                    res.ionization(i)=2;
                    
                end
            end
            
            pKa_Exp_neighbor(i,:)=PKA.model.set.y(pred.neighbors(i,:));
            pKa_pred_neighbor(i,:)=PKA.model.set.yc(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogKOA_Exp_neighbor(i,:),res.LogKOA_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_pKa(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            res.Conf_index_pKa(i,1)=((1/(1+sqrt(((pKa_Exp_neighbor(i,:)-pKa_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_pKa(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.pKa_a_pred(i,1)=NaN;
                res.pKa_b_pred(i,1)=NaN;
                res.AD_pKa(i,1)=0;
                res.AD_index_pKa(i,1)=0;
                res.Conf_index_pKa(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_pKa(i)=0;
                res.AD_index_pKa(i)=res.AD_index_pKa(i)/2;
                res.Conf_index_pKa(i,1)=res.Conf_index_pKa(i,1)/2;
            end
            if neighbors==1
                PKA.CAS=strrep(strrep(join(PKA.CAS,'|',2),'|||',''),'||','');
                PKA.DTXSID=strrep(strrep(join(PKA.DTXSID,'|',2),'|||',''),'||','');
                pKa_CAS_neighbor(i,:)=PKA.CAS(pred.neighbors(i,:));
                pKa_InChiKey_neighbor(i,:)=PKA.InChiKey(pred.neighbors(i,:));
                pKa_DTXSID_neighbor(i,:)=PKA.DTXSID(pred.neighbors(i,:));
                pKa_DSSTOXMPID_neighbor(i,:)=PKA.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_pKa(i,1)~=0
                    res.pKa_CAS_neighbor(i,:)=pKa_CAS_neighbor(i,:);
                    res.pKa_InChiKey_neighbor(i,:)=pKa_InChiKey_neighbor(i,:);
                    res.pKa_DTXSID_neighbor(i,:)=pKa_DTXSID_neighbor(i,:);
                    res.pKa_DSSTOXMPID_neighbor(i,:)=pKa_DSSTOXMPID_neighbor(i,:);
                    res.pKa_Exp_neighbor(i,:)=pKa_Exp_neighbor(i,:);
                    res.pKa_pred_neighbor(i,:)=pKa_pred_neighbor(i,:);
                else
                    res.pKa_CAS_neighbor(i,:)=cell(1,3);
                    res.pKa_InChiKey_neighbor(i,:)=cell(1,3);
                    res.pKa_DTXSID_neighbor(i,:)=cell(1,3);
                    res.pKa_DSSTOXMPID_neighbor(i,:)=cell(1,3);
                    res.pKa_Exp_neighbor(i,:)=nan(1,3);
                    res.pKa_pred_neighbor(i,:)=nan(1,3);
                end
            end
        
            if strcmpi(ext,'.txt') && sep==1 && Lia(1)
                %res.Xtest=Xtest;
                fprintf(output(Locb(1)),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(1)),'pKa acidic and basic experimental= %.3f, %.3f\n', res.pKa_a_exp(i),res.pKa_b_exp(i));
                end
                fprintf(output(Locb(1)),'pKa acidic and basic predicted= %.3f, %.3f\n', res.pKa_a_pred(i),res.pKa_b_pred(i));
                if res.AD_pKa(i)==1
                    fprintf(output(Locb(1)),'AD: inside\n');
                else
                    fprintf(output(Locb(1)),'AD: outside\n');
                end
                fprintf(output(Locb(1)),'AD_index= %.2f\n', res.AD_index_pKa(i));
                fprintf(output(Locb(1)),'Conf_index= %.2f\n', res.Conf_index_pKa(i));
                %CAS=strjoin(res.RT_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(1)),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',PKA.model.set.K, res.pKa_CAS_neighbor{i,1:3});
                    fprintf(output(Locb(1)),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',PKA.model.set.K, res.pKa_Exp_neighbor(i,1:3));
                    fprintf(output(Locb(1)),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',PKA.model.set.K, res.pKa_pred_neighbor(i,1:3));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0 && Lia(1)
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'pKa acidic and basic experimental= %.3f, %.3f\n', res.pKa_a_exp(i),res.pKa_b_exp(i));
                end
                fprintf(output,'pKa acidic and basic predicted= %.3f, %.3f\n', res.pKa_a_pred(i),res.pKa_b_pred(i));
                if res.AD_pKa(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_pKa(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_pKa(i));
                %CAS=strjoin(res.KOA_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',PKA.model.set.K, res.pKa_CAS_neighbor{i,1:3});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',PKA.model.set.K, res.pKa_Exp_neighbor(i,1:3));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',PKA.model.set.K, res.pKa_pred_neighbor(i,1:3));
                end
                
            end
        end
        
        if nf>0 && strcmpi(ext,'.txt') && Lia(1)
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(1)),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(1)),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
   
        if sep==1 && strcmpi(ext,'.csv') && Lia(1)
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(1)},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(1)));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv') && Lia(1)
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.pKa=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('XinFP');
        clear('Xtest_a');
        clear('Xtest_b');
        clear('pred');
        clear('AD');
        clear('PKA');
        %end clean memory
    end
    %Predict LogD values
    %case 'logd'
    [Lia,Locb] =ismember('logd',lower(prop));
    if find(Lia)

        if verbose>0
            disp('Predicting LogD values (Log10)...');
            if verbose>1
                disp('Predictions based on pKa and LogP ');
            end
        end
        res.MoleculeID=MoleculeNames;
        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogD values... \n\n			==============================================================  \n\n');
        end
        if sep==1
            
            res.LogD55_pred=resf.LogP.LogP_pred;
            res.LogD74_pred=resf.LogP.LogP_pred;
            res.AD_LogD=resf.LogP.AD_LogP+resf.pKa.AD_pKa;
            res.AD_LogD(find(res.AD_LogD==1))=0;
            res.AD_LogD(find(res.AD_LogD==2))=1;
            res.AD_index_LogD=0.5*resf.pKa.AD_index_pKa+0.5*resf.LogP.AD_index_LogP;
            res.Conf_index_LogD=0.5*resf.pKa.Conf_index_pKa+0.5*resf.LogP.Conf_index_LogP;
            
            if neighbors==1 
                    res.LogD_CAS_neighbor=resf.LogP.LogP_CAS_neighbor;
                    res.LogD_InChiKey_neighbor=resf.LogP.LogP_InChiKey_neighbor;
                    res.LogD_DTXSID_neighbor=resf.LogP.LogP_DTXSID_neighbor;
                    res.LogD_DSSTOXMPID_neighbor=resf.LogP.LogP_DSSTOXMPID_neighbor;
                    %res.LogD_Exp_neighbor(res.AD_index_LogD~=0)=LogP_Exp_neighbor(res.AD_index_LogD~=0);
                    %res.LogD_pred_neighbor(res.AD_index_LogD~=0)=LogP_pred_neighbor(res.AD_index_LogD~=0);
            end
            
            for i=1:length(res.LogD55_pred)
                if Xin(i,12)==0
                    res.AD_LogD(i)=0;
                    res.AD_index_LogD(i)=res.AD_index_LogD(i)/2;
                    res.Conf_index_LogD(i,1)=res.Conf_index_LogD(i,1)/2;
                end
                if pKa_ac_ba_amp(i)==1
                    res.LogD55_pred(i,1)=resf.LogP.LogP_pred(i,1)-log10(1+10^(5.5-resf.pKa.pKa_a_pred(i,1)));
                    res.LogD74_pred(i,1)=resf.LogP.LogP_pred(i,1)-log10(1+10^(7.4-resf.pKa.pKa_a_pred(i,1)));
                elseif pKa_ac_ba_amp(i)==2
                    res.LogD55_pred(i,1)=resf.LogP.LogP_pred(i,1)-log10(1+10^(resf.pKa.pKa_b_pred(i,1)-5.5));
                    res.LogD74_pred(i,1)=resf.LogP.LogP_pred(i,1)-log10(1+10^(resf.pKa.pKa_b_pred(i,1)-7.4));
                elseif pKa_ac_ba_amp(i)==3
                    res.LogD55_pred(i,1)=resf.LogP.LogP_pred(i,1)-log10(1+10^abs(0.5*resf.pKa.pKa_a_pred(i,1)+0.5*resf.pKa.pKa_b_pred(i,1)-5.5));
                    res.LogD74_pred(i,1)=resf.LogP.LogP_pred(i,1)-log10(1+10^abs(0.5*resf.pKa.pKa_a_pred(i,1)+0.5*resf.pKa.pKa_b_pred(i,1)-7.4));
                end
                
                if strcmpi(ext,'.txt')
                    fprintf(output(Locb(1)),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(1)),'LogD pH 5.5 predicted= %.3f\n', res.LogD55_pred(i));
                    fprintf(output(Locb(1)),'LogD pH 7.4 predicted= %.3f\n', res.LogD74_pred(i));
                    if res.AD_LogD(i)==1
                        fprintf(output(Locb(1)),'AD: inside\n');
                    else
                        fprintf(output(Locb(1)),'AD: outside\n');
                    end
                    fprintf(output(Locb(1)),'AD_index= %.2f\n', res.AD_index_LogD(i));
                    fprintf(output(Locb(1)),'Conf_index= %.2f\n', res.Conf_index_LogD(i));
                    if neighbors==1
                        fprintf(output(Locb(1)),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',5,resf.LogP.LogP_CAS_neighbor{i,1:5});
                        %fprintf(output(Locb(1)),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',train.LOGP.model.set.K, res.LogP_Exp_neighbor(i,1:5));
                        %fprintf(output(Locb(1)),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',train.LOGP.model.set.K, res.LogP_pred_neighbor(i,1:5));
                    end
                end
            end
            if nf>0 && strcmpi(ext,'.txt')
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(1)),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(1)),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
            if strcmpi(ext,'.csv')
                if nf>0
                    res=rmfield(res,'MoleculeID');
                    T=struct2table(res);
                    T{end+1:end+nf,1:4}=nan(nf,4);
                    %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                    %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                    T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                else
                    T=struct2table(res);
                end
                %T=struct2table(res);
                writetable(T,FileOut{Locb(1)},'Delimiter',',');%,'QuoteStrings',true);
                fclose(output(Locb(1)));
                clear('T');
            end
            resf.LogD=res;
            clear('res');
            
            
        else
            res.LogD55_pred=res.LogP_pred;
            res.LogD74_pred=res.LogP_pred;
            res.AD_LogD=res.AD_LogP+res.AD_pKa;
            res.AD_LogD(find(res.AD_LogD==1))=0;
            res.AD_LogD(find(res.AD_LogD==2))=1;
            res.AD_index_LogD=0.5*res.AD_index_pKa+0.5*res.AD_index_LogP;
            res.Conf_index_LogD=0.5*res.Conf_index_pKa+0.5*res.Conf_index_LogP;
            
           if neighbors==1 
                    res.LogD_CAS_neighbor=res.LogP_CAS_neighbor;
                    res.LogD_InChiKey_neighbor=res.LogP_InChiKey_neighbor;
                    res.LogD_DTXSID_neighbor=res.LogP_DTXSID_neighbor;
                    res.LogD_DSSTOXMPID_neighbor=res.LogP_DSSTOXMPID_neighbor;
                    %res.LogD_Exp_neighbor(res.AD_index_LogD~=0)=LogP_Exp_neighbor(res.AD_index_LogD~=0);
                    %res.LogD_pred_neighbor(res.AD_index_LogD~=0)=LogP_pred_neighbor(res.AD_index_LogD~=0);
            end
            
            for i=1:length(res.LogD55_pred)
                if pKa_ac_ba_amp(i)==1
                    res.LogD55_pred(i,1)=res.LogP_pred(i,1)-log10(1+10^(5.5-res.pKa_a_pred(i,1)));
                    res.LogD74_pred(i,1)=res.LogP_pred(i,1)-log10(1+10^(7.4-res.pKa_a_pred(i,1)));
                elseif pKa_ac_ba_amp(i)==2
                    res.LogD55_pred(i,1)=res.LogP_pred(i,1)-log10(1+10^(res.pKa_b_pred(i,1)-5.5));
                    res.LogD74_pred(i,1)=res.LogP_pred(i,1)-log10(1+10^(res.pKa_b_pred(i,1)-7.4));
                elseif pKa_ac_ba_amp(i)==3
                    res.LogD55_pred(i,1)=res.LogP_pred(i,1)-log10(1+10^abs(0.5*res.pKa_a_pred(i,1)+0.5*res.pKa_b_pred(i,1)-5.5));
                    res.LogD74_pred(i,1)=res.LogP_pred(i,1)-log10(1+10^abs(0.5*res.pKa_a_pred(i,1)+0.5*res.pKa_b_pred(i,1)-7.4));
                end
                
                if strcmpi(ext,'.txt')
                    fprintf(output,'\t Molecule %s:\n',res.MoleculeID{i});
                    fprintf(output,'LogD pH 5.5 predicted= %.3f\n', res.LogD55_pred(i));
                    fprintf(output,'LogD pH 7.4 predicted= %.3f\n', res.LogD74_pred(i));
                    if res.AD_LogD(i)==1
                        fprintf(output,'AD: inside\n');
                    else
                        fprintf(output,'AD: outside\n');
                    end
                    fprintf(output,'AD_index= %.2f\n', res.AD_index_LogD(i));
                    fprintf(output,'Conf_index= %.2f\n', res.Conf_index_LogD(i));
                    if neighbors==1
                        fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.LOGP.model.set.K, res.LogP_CAS_neighbor{i,1:5});
                        %fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',train.LOGP.model.set.K, res.LogP_Exp_neighbor(i,1:5));
                        %fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',train.LOGP.model.set.K, res.LogP_pred_neighbor(i,1:5));
                    end                   
                end
            end
            
            if nf>0 && strcmpi(ext,'.txt')
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        
    end
    
    %  Env. Fate Endpoints
    
    if verbose> 0 && (ef||all)
        fprintf(1,'---------- Env. Fate Endpoints ----------\n');
    end
    %Predict AOH values
    %case {'aop','logoh','aoh'}
    [Lia,Locb] =ismember({'aop','logoh','aoh'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogOH values (Log10 cm3/molecule-sec)...');
        end
        load ('OPERA_models.mat', '-mat','AOH');
        Desc=AOH.Desc;
    
            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogOH values... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,AOH.Desc_i);
        
        pred = nnrpred(Xtest,AOH.model.set.train,AOH.model.set.y,AOH.model.set.K,AOH.model.set.dist_type,AOH.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogOH_exp=NaN(size(Xtest,1),1);
        end
        res.LogOH_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(AOH.model.set.train,Xtest,'auto');
        res.AD_AOH=abs(AD.inorout-1)';
        res.AD_AOH(round(pred.dc(:,1),3)==0)=1;
        
        
        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_AOH=zeros(size(Xtest,1),1);
        res.Conf_index_AOH=zeros(size(Xtest,1),1);
        if neighbors
            AOH_CAS_neighbor=cell(size(Xtest,1),5);
            AOH_InChiKey_neighbor=cell(size(Xtest,1),5);
            AOH_DTXSID_neighbor=cell(size(Xtest,1),5);
            AOH_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogOH_Exp_neighbor=nan(size(Xtest,1),5);
        LogOH_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),AOH.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},AOH.DTXSID);
                end
                if Li
                    if Lo>size(AOH.DTXSID,1)
                        Lo=mod(Lo,size(AOH.DTXSID,1));
                    end
                    res.LogOH_exp(i)=AOH.model.set.y(Lo);
                end
            end
            
            LogOH_Exp_neighbor(i,:)=AOH.model.set.y(pred.neighbors(i,:));
            LogOH_pred_neighbor(i,:)=AOH.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogOH_Exp_neighbor(i,:),res.LogOH_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_AOH(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_AOH(i,1)=((1/(1+sqrt(((LogOH_Exp_neighbor(i,:)-LogOH_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_AOH(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogOH_pred(i,1)=NaN;
                res.AD_AOH(i)=0;
                res.AD_index_AOH(i)=0;
                res.Conf_index_AOH(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_AOH(i)=0;
                res.AD_index_AOH(i)=res.AD_index_AOH(i)/2;
                res.Conf_index_AOH(i,1)=res.Conf_index_AOH(i,1)/2;
            end
            if neighbors==1
                AOH.CAS=strrep(strrep(join(AOH.CAS,'|',2),'|||',''),'||','');
                AOH.DTXSID=strrep(strrep(join(AOH.DTXSID,'|',2),'|||',''),'||','');
                AOH_CAS_neighbor(i,:)=AOH.CAS(pred.neighbors(i,:));
                AOH_InChiKey_neighbor(i,:)=AOH.InChiKey(pred.neighbors(i,:));
                AOH_DTXSID_neighbor(i,:)=AOH.DTXSID(pred.neighbors(i,:));
                AOH_DSSTOXMPID_neighbor(i,:)=AOH.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_AOH(i)~=0
                    res.AOH_CAS_neighbor(i,:)=AOH_CAS_neighbor(i,:);
                    res.AOH_InChiKey_neighbor(i,:)=AOH_InChiKey_neighbor(i,:);
                    res.AOH_DTXSID_neighbor(i,:)=AOH_DTXSID_neighbor(i,:);
                    res.AOH_DSSTOXMPID_neighbor(i,:)=AOH_DSSTOXMPID_neighbor(i,:);
                    res.LogOH_Exp_neighbor(i,:)=LogOH_Exp_neighbor(i,:);
                    res.LogOH_pred_neighbor(i,:)=LogOH_pred_neighbor(i,:);
                else
                    res.AOH_CAS_neighbor(i,:)=cell(1,5);
                    res.AOH_InChiKey_neighbor(i,:)=cell(1,5);
                    res.AOH_DTXSID_neighbor(i,:)=cell(1,5);
                    res.AOH_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogOH_Exp_neighbor(i,:)=nan(1,5);
                    res.LogOH_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogOH experimental= %.3f\n', res.LogOH_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogOH predicted= %.3f\n', res.LogOH_pred(i));
                if res.AD_AOH(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_AOH(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_AOH(i));
                %CAS=strjoin(res.AOH_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',AOH.model.set.K, res.AOH_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',AOH.model.set.K, res.LogOH_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',AOH.model.set.K, res.LogOH_pred_neighbor(i,1:5));
                end
                
                
            elseif strcmpi(ext,'.txt') && sep==0

                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogOH experimental= %.3f\n', res.LogOH_exp(i));
                end
                fprintf(output,'LogOH predicted= %.3f\n', res.LogOH_pred(i));
                if res.AD_AOH(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_AOH(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_AOH(i));
                %CAS=strjoin(res.AOH_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',AOH.model.set.K, res.AOH_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',AOH.model.set.K, res.LogOH_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',AOH.model.set.K, res.LogOH_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
 
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')           
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.AOH=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('AOH');
        %end clean memory
        
    end
    
    %Predict BCF values
    %case {'bcf', 'logbcf'}
    [Lia,Locb] =ismember({'bcf','logbcf'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogBCF values (Log10)...');
        end
        load ('OPERA_models.mat', '-mat','BCF');
        Desc=BCF.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogBCF values... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,BCF.Desc_i);
        
        pred = nnrpred(Xtest,BCF.model.set.train,BCF.model.set.y,BCF.model.set.K,BCF.model.set.dist_type,BCF.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogBCF_exp=NaN(size(Xtest,1),1);
        end
        res.LogBCF_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(BCF.model.set.train,Xtest,'auto');
        res.AD_BCF=abs(AD.inorout-1)';
        res.AD_BCF(round(pred.dc(:,1),3)==0)=1;
        
        
        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_BCF=zeros(size(Xtest,1),1);
        res.Conf_index_BCF=zeros(size(Xtest,1),1);
        if neighbors
            LogBCF_CAS_neighbor=cell(size(Xtest,1),5);
            LogBCF_InChiKey_neighbor=cell(size(Xtest,1),5);
            LogBCF_DTXSID_neighbor=cell(size(Xtest,1),5);
            LogBCF_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogBCF_Exp_neighbor=nan(size(Xtest,1),5);
        LogBCF_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),BCF.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},BCF.DTXSID);
                end
                if Li
                    if Lo>size(BCF.DTXSID,1)
                        Lo=mod(Lo,size(BCF.DTXSID,1));
                    end
                    res.LogBCF_exp(i)=BCF.model.set.y(Lo);
                end
            end
            
            LogBCF_Exp_neighbor(i,:)=BCF.model.set.y(pred.neighbors(i,:));
            LogBCF_pred_neighbor(i,:)=BCF.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogBCF_Exp_neighbor(i,:),res.LogBCF_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            %res.Conf_index2(i,1)=(res.Conf_index(i)*res.AD_index(i))^0.5;
            
            res.AD_index_BCF(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_BCF(i,1)=((1/(1+sqrt(((LogBCF_Exp_neighbor(i,:)-LogBCF_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_BCF(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogBCF_pred(i,1)=NaN;
                res.AD_BCF(i)=0;
                res.AD_index_BCF(i)=0;
                res.Conf_index_BCF(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_BCF(i)=0;
                res.AD_index_BCF(i)=res.AD_index_BCF(i)/2;
                res.Conf_index_BCF(i,1)=res.Conf_index_BCF(i,1)/2;
            end

            if neighbors==1
                BCF.CAS=strrep(strrep(join(BCF.CAS,'|',2),'|||',''),'||','');
                BCF.DTXSID=strrep(strrep(join(BCF.DTXSID,'|',2),'|||',''),'||','');
                LogBCF_CAS_neighbor(i,:)=BCF.CAS(pred.neighbors(i,:));
                LogBCF_InChiKey_neighbor(i,:)=BCF.InChiKey(pred.neighbors(i,:));
                LogBCF_DTXSID_neighbor(i,:)=BCF.DTXSID(pred.neighbors(i,:));
                LogBCF_DSSTOXMPID_neighbor(i,:)=BCF.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_BCF(i)~=0
                    res.LogBCF_CAS_neighbor(i,:)=LogBCF_CAS_neighbor(i,:);
                    res.LogBCF_InChiKey_neighbor(i,:)=LogBCF_InChiKey_neighbor(i,:);
                    res.LogBCF_DTXSID_neighbor(i,:)=LogBCF_DTXSID_neighbor(i,:);
                    res.LogBCF_DSSTOXMPID_neighbor(i,:)=LogBCF_DSSTOXMPID_neighbor(i,:);
                    res.LogBCF_Exp_neighbor(i,:)=LogBCF_Exp_neighbor(i,:);
                    res.LogBCF_pred_neighbor(i,:)=LogBCF_pred_neighbor(i,:);
                else
                    res.LogBCF_CAS_neighbor(i,:)=cell(1,5);
                    res.LogBCF_InChiKey_neighbor(i,:)=cell(1,5);
                    res.LogBCF_DTXSID_neighbor(i,:)=cell(1,5);
                    res.LogBCF_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogBCF_Exp_neighbor(i,:)=nan(1,5);
                    res.LogBCF_pred_neighbor(i,:)=nan(1,5);
                end
            end

            if strcmpi(ext,'.txt') && sep==1
                
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogBCF experimental= %.3f\n', res.LogBCF_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogBCF predicted= %.3f\n', res.LogBCF_pred(i));
                if res.AD_BCF(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_BCF(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_BCF(i));
                %CAS=strjoin(res.LogBCF_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',BCF.model.set.K, res.LogBCF_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',BCF.model.set.K, res.LogBCF_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',BCF.model.set.K, res.LogBCF_pred_neighbor(i,1:5));
                end

            elseif strcmpi(ext,'.txt') && sep==0
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogBCF experimental= %.3f\n', res.LogBCF_exp(i));
                end
                fprintf(output,'LogBCF predicted= %.3f\n', res.LogBCF_pred(i));
                if res.AD_BCF(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_BCF(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_BCF(i));
                %CAS=strjoin(res.LogBCF_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',BCF.model.set.K, res.LogBCF_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',BCF.model.set.K, res.LogBCF_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',BCF.model.set.K, res.LogBCF_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end

        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
  
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.BCF=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('BCF');
        %end clean memory
    end
    
    %Predict Biodegradability values
    %case {'biohc','biohl','biodeg','biodeghl'}
    [Lia,Locb] =ismember({'biohc','biohl','biodeg','biodeghl'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting Biodeg. half-life values (Log10 days)...');
        end
        load ('OPERA_models.mat', '-mat','BIODEG');
        Desc=BIODEG.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting Biodegradability in LogHalfLife... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,BIODEG.Desc_i);
        
        pred = nnrpred(Xtest,BIODEG.model.set.train,BIODEG.model.set.y,BIODEG.model.set.K,BIODEG.model.set.dist_type,BIODEG.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.BioDeg_exp=NaN(size(Xtest,1),1);
        end
        res.BioDeg_LogHalfLife_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(BIODEG.model.set.train,Xtest,'auto');
        res.AD_BioDeg=abs(AD.inorout-1)';
        res.AD_BioDeg(round(pred.dc(:,1),3)==0)=1;
        
        
        %             res.dc=pred.dc;
        %res.AD_index1=1./(1+nanmedian(pred.dc,2));
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index1)
        %                 res.AD_index1=0;
        %             end
        
        res.AD_index_BioDeg=zeros(size(Xtest,1),1);
        res.Conf_index_BioDeg=zeros(size(Xtest,1),1);
        if neighbors
            BioDeg_CAS_neighbor=cell(size(Xtest,1),5);
            BioDeg_InChiKey_neighbor=cell(size(Xtest,1),5);
            BioDeg_DTXSID_neighbor=cell(size(Xtest,1),5);
            BioDeg_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        BioDeg_LogHalfLife_Exp_neighbor=nan(size(Xtest,1),5);
        BioDeg_LogHalfLife_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),BIODEG.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},BIODEG.DTXSID);
                end
                if Li
                    if Lo>size(BIODEG.DTXSID,1)
                        Lo=mod(Lo,size(BIODEG.DTXSID,1));
                    end
                    res.BioDeg_exp(i)=BIODEG.model.set.y(Lo);
                end
            end
            
            BioDeg_LogHalfLife_Exp_neighbor(i,:)=BIODEG.model.set.y(pred.neighbors(i,:));
            BioDeg_LogHalfLife_pred_neighbor(i,:)=BIODEG.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.BioDeg_LogHalfLife_Exp_neighbor(i,:),res.BioDeg_LogHalfLife_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_BioDeg(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_BioDeg(i,1)=((1/(1+sqrt(((BioDeg_LogHalfLife_Exp_neighbor(i,:)-BioDeg_LogHalfLife_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_BioDeg(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.BioDeg_LogHalfLife_pred(i,1)=NaN;
                res.AD_BioDeg(i)=0;
                res.AD_index_BioDeg(i)=0;
                res.Conf_index_BioDeg(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_BioDeg(i)=0;
                res.AD_index_BioDeg(i)=res.AD_index_BioDeg(i)/2;
                res.Conf_index_BioDeg(i,1)=res.Conf_index_BioDeg(i,1)/2;
            end
            if neighbors==1
                BIODEG.CAS=strrep(strrep(join(BIODEG.CAS,'|',2),'|||',''),'||','');
                BIODEG.DTXSID=strrep(strrep(join(BIODEG.DTXSID,'|',2),'|||',''),'||','');
                BioDeg_CAS_neighbor(i,:)=BIODEG.CAS(pred.neighbors(i,:));
                BioDeg_InChiKey_neighbor(i,:)=BIODEG.InChiKey(pred.neighbors(i,:));
                BioDeg_DTXSID_neighbor(i,:)=BIODEG.DTXSID(pred.neighbors(i,:));
                BioDeg_DSSTOXMPID_neighbor(i,:)=BIODEG.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_BioDeg(i)~=0
                    res.BioDeg_CAS_neighbor(i,:)=BioDeg_CAS_neighbor(i,:);
                    res.BioDeg_InChiKey_neighbor(i,:)=BioDeg_InChiKey_neighbor(i,:);
                    res.BioDeg_DTXSID_neighbor(i,:)=BioDeg_DTXSID_neighbor(i,:);
                    res.BioDeg_DSSTOXMPID_neighbor(i,:)=BioDeg_DSSTOXMPID_neighbor(i,:);
                    res.BioDeg_LogHalfLife_Exp_neighbor(i,:)=BioDeg_LogHalfLife_Exp_neighbor(i,:);
                    res.BioDeg_LogHalfLife_pred_neighbor(i,:)=BioDeg_LogHalfLife_pred_neighbor(i,:);
                else
                    res.BioDeg_CAS_neighbor(i,:)=cell(1,5);
                    res.BioDeg_InChiKey_neighbor(i,:)=cell(1,5);
                    res.BioDeg_DTXSID_neighbor(i,:)=cell(1,5);
                    res.BioDeg_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.BioDeg_LogHalfLife_Exp_neighbor(i,:)=nan(1,5);
                    res.BioDeg_LogHalfLife_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'BioDeg_LogHalfLife experimental= %.3f\n', res.BioDeg_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'BioDeg_LogHalfLife predicted= %.3f\n', res.BioDeg_LogHalfLife_pred(i));
                if res.AD_BioDeg(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_BioDeg(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_BioDeg(i));
                %CAS=strjoin(res.BioDeg_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',BIODEG.model.set.K, res.BioDeg_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',BIODEG.model.set.K, res.BioDeg_LogHalfLife_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',BIODEG.model.set.K, res.BioDeg_LogHalfLife_pred_neighbor(i,1:5));
                end
 
            elseif strcmpi(ext,'.txt') && sep==0

                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'BioDeg_LogHalfLife experimental= %.3f\n', res.BioDeg_exp(i));
                end
                fprintf(output,'BioDeg_LogHalfLife predicted= %.3f\n', res.BioDeg_LogHalfLife_pred(i));
                if res.AD_BioDeg(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_BioDeg(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_BioDeg(i));
                %CAS=strjoin(res.BioDeg_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',BIODEG.model.set.K, res.BioDeg_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',BIODEG.model.set.K, res.BioDeg_LogHalfLife_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',BIODEG.model.set.K, res.BioDeg_LogHalfLife_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end

        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end

            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.BioDeg=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('BIODEG');
        %end clean memory
    end
    %Predict RBiodeg values
    %case {'biowin','rb','readybiodeg','rbiodeg'}
    [Lia,Locb] =ismember({'biowin','rb','readybiodeg','rbiodeg'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting Ready-Biodegradability (Binary 0/1)...');
        end
        load ('OPERA_models.mat', '-mat','RBIODEG');
        Desc=RBIODEG.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting Ready Biodegradability... \n\n			============================================================== \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,RBIODEG.Desc_i);
        
        pred = knnpred(Xtest,RBIODEG.model.set.train,RBIODEG.model.set.class,RBIODEG.model.set.K,RBIODEG.model.set.dist_type,RBIODEG.model.set.param.pret_type);
        pred.D=diag(pred.D);
        %pred.w = (ones(1,train.RBIODEG.model.set.K)./train.RBIODEG.model.set.K)';
        
        res.MoleculeID=MoleculeNames;
        if exp
            res.ReadyBiodeg_exp=NaN(size(Xtest,1),1);
        end
        res.ReadyBiodeg_pred(:,1)=pred.class_pred-1;
        AD=classical_leverage(RBIODEG.model.set.train,Xtest,'auto');
        res.AD_ReadyBiodeg=abs(AD.inorout-1)';
        res.AD_ReadyBiodeg(round(pred.dc(:,1),3)==0)=1;
        %
        %res.dc=pred.dc;
        res.AD_index_ReadyBiodeg=1./(1+nanmedian(pred.dc,2));
        res.AD_index_ReadyBiodeg(isnan(res.AD_index_ReadyBiodeg))=0;
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end

        %             res.AD_index=zeros(size(Xtest,1),1);
        %             res.Conf_index1=zeros(size(Xtest,1),1);
        res.Conf_index_ReadyBiodeg=zeros(size(Xtest,1),1);
        if neighbors
            ReadyBiodeg_CAS_neighbor=cell(size(Xtest,1),5);
            ReadyBiodeg_InChiKey_neighbor=cell(size(Xtest,1),5);
            ReadyBiodeg_DTXSID_neighbor=cell(size(Xtest,1),5);
            ReadyBiodeg_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        ReadyBiodeg_Exp_neighbor=nan(size(Xtest,1),5);
        ReadyBiodeg_pred_neighbor=nan(size(Xtest,1),5);
 
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),RBIODEG.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},RBIODEG.DTXSID);
                end
                if Li
                    if Lo>size(RBIODEG.DTXSID,1)
                        Lo=mod(Lo,size(RBIODEG.DTXSID,1));
                    end
                    res.ReadyBiodeg_exp(i)=RBIODEG.model.set.class(Lo);
                end
            end
            
            ReadyBiodeg_Exp_neighbor(i,:)=RBIODEG.model.set.class(pred.neighbors(i,:))-1;
            ReadyBiodeg_pred_neighbor(i,:)=RBIODEG.model.class_calc(pred.neighbors(i,:))-1;
            
            rmse=calc_reg_param(ReadyBiodeg_Exp_neighbor(i,:),ReadyBiodeg_pred_neighbor(i,:));

            res.Conf_index_ReadyBiodeg(i,1)=((1/(1+rmse.RMSEC))+res.AD_index_ReadyBiodeg(i))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.ReadyBiodeg_pred(i,1)=NaN;
                res.AD_ReadyBiodeg(i)=0;
                res.AD_index_ReadyBiodeg(i)=0;
                res.Conf_index_ReadyBiodeg(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_ReadyBiodeg(i)=0;
                res.AD_index_ReadyBiodeg(i)=res.AD_index_ReadyBiodeg(i)/2;
                res.Conf_index_ReadyBiodeg(i,1)=res.Conf_index_ReadyBiodeg(i,1)/2;
            end
            
            %                 res.AD_index(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            %
            %                 if isnan(res.AD_index(i))
            %                     res.AD_index(i)=0;
            %                 end
            
            
            %                res.Conf_index(i,1)=1/(1+sqrt(((res.ReadyBiodeg_Exp_neighbor(i,:)-res.ReadyBiodeg_pred_neighbor(i,:)).^2)*pred.w(i,:)'));
            if neighbors==1
                RBIODEG.CAS=strrep(strrep(join(RBIODEG.CAS,'|',2),'|||',''),'||','');
                RBIODEG.DTXSID=strrep(strrep(join(RBIODEG.DTXSID,'|',2),'|||',''),'||','');
                ReadyBiodeg_CAS_neighbor(i,:)=RBIODEG.CAS(pred.neighbors(i,:));
                ReadyBiodeg_InChiKey_neighbor(i,:)=RBIODEG.InChiKey(pred.neighbors(i,:));
                ReadyBiodeg_DTXSID_neighbor(i,:)=RBIODEG.DTXSID(pred.neighbors(i,:));
                ReadyBiodeg_DSSTOXMPID_neighbor(i,:)=RBIODEG.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_ReadyBiodeg(i)~=0
                    res.ReadyBiodeg_CAS_neighbor(i,:)=ReadyBiodeg_CAS_neighbor(i,:);
                    res.ReadyBiodeg_InChiKey_neighbor(i,:)=ReadyBiodeg_InChiKey_neighbor(i,:);
                    res.ReadyBiodeg_DTXSID_neighbor(i,:)=ReadyBiodeg_DTXSID_neighbor(i,:);
                    res.ReadyBiodeg_DSSTOXMPID_neighbor(i,:)=ReadyBiodeg_DSSTOXMPID_neighbor(i,:);
                    res.ReadyBiodeg_Exp_neighbor(i,:)=ReadyBiodeg_Exp_neighbor(i,:);
                    res.ReadyBiodeg_pred_neighbor(i,:)=ReadyBiodeg_pred_neighbor(i,:);
                else
                    res.ReadyBiodeg_CAS_neighbor(i,:)=cell(1,5);
                    res.ReadyBiodeg_InChiKey_neighbor(i,:)=cell(1,5);
                    res.ReadyBiodeg_DTXSID_neighbor(i,:)=cell(1,5);
                    res.ReadyBiodeg_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.ReadyBiodeg_Exp_neighbor(i,:)=nan(1,5);
                    res.ReadyBiodeg_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'ReadyBiodeg experimental= %.3f\n', res.ReadyBiodeg_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'ReadyBiodeg predicted= %d\n', res.ReadyBiodeg_pred(i));
                if res.AD_ReadyBiodeg(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_ReadyBiodeg(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_ReadyBiodeg(i));
                %CAS=strjoin(res.ReadyBiodeg_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',RBIODEG.model.set.K, res.ReadyBiodeg_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15d,%15d,%15d,%15d,%15d\n',RBIODEG.model.set.K, res.ReadyBiodeg_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14d,%15d,%15d,%15d,%15d\n\n',RBIODEG.model.set.K, res.ReadyBiodeg_pred_neighbor(i,1:5));
                end
  
            elseif strcmpi(ext,'.txt') && sep==0

                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'ReadyBiodeg experimental= %.3f\n', res.ReadyBiodeg_exp(i));
                end
                fprintf(output,'ReadyBiodeg predicted= %d\n', res.ReadyBiodeg_pred(i));
                if res.AD_ReadyBiodeg(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_ReadyBiodeg(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_ReadyBiodeg(i));
                %CAS=strjoin(res.ReadyBiodeg_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',RBIODEG.model.set.K, res.ReadyBiodeg_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15d,%15d,%15d,%15d,%15d\n',RBIODEG.model.set.K, res.ReadyBiodeg_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14d,%15d,%15d,%15d,%15d\n\n',RBIODEG.model.set.K, res.ReadyBiodeg_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end

        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end

            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.RBioDeg=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('RBIODEG');
        %end clean memory
        
    end
    %Predict KM values
    %case {'km','logkm'}
    [Lia,Locb] =ismember({'km','logkm'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogKm half-life values (Log10 days)...');
        end
        load ('OPERA_models.mat', '-mat','KM');
        Desc=KM.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end
        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogKmHL values... \n\n			==============================================================  \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,KM.Desc_i);
        
        pred = nnrpred(Xtest,KM.model.set.train,KM.model.set.y,KM.model.set.K,KM.model.set.dist_type,KM.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogKM_exp=NaN(size(Xtest,1),1);
        end
        res.LogKM_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(KM.model.set.train,Xtest,'auto');
        res.AD_KM=abs(AD.inorout-1)';
        res.AD_KM(round(pred.dc(:,1),3)==0)=1;

        %res.AD_index=1./(1+nanmedian(pred.dc,2));
        
        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end
        
        res.AD_index_KM=zeros(size(Xtest,1),1);
        res.Conf_index_KM=zeros(size(Xtest,1),1);
        if neighbors
            KM_CAS_neighbor=cell(size(Xtest,1),5);
            KM_InChiKey_neighbor=cell(size(Xtest,1),5);
            KM_DTXSID_neighbor=cell(size(Xtest,1),5);
            KM_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogKM_Exp_neighbor=nan(size(Xtest,1),5);
        LogKM_pred_neighbor=nan(size(Xtest,1),5);

        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),KM.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},KM.DTXSID);
                end
                if Li
                    if Lo>size(KM.DTXSID,1)
                        Lo=mod(Lo,size(KM.DTXSID,1));
                    end
                    res.LogKM_exp(i)=KM.model.set.y(Lo);
                end
            end
            
            LogKM_Exp_neighbor(i,:)=KM.model.set.y(pred.neighbors(i,:));
            LogKM_pred_neighbor(i,:)=KM.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogKM_Exp_neighbor(i,:),res.LogKM_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_KM(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_KM(i,1)=((1/(1+sqrt(((LogKM_Exp_neighbor(i,:)-LogKM_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_KM(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogKM_pred(i,1)=NaN;
                res.AD_KM(i)=0;
                res.AD_index_KM(i)=0;
                res.Conf_index_KM(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_KM(i)=0;
                res.AD_index_KM(i)=res.AD_index_KM(i)/2;
                res.Conf_index_KM(i,1)=res.Conf_index_KM(i,1)/2;
            end
            if neighbors==1
                KM.CAS=strrep(strrep(join(KM.CAS,'|',2),'|||',''),'||','');
                KM.DTXSID=strrep(strrep(join(KM.DTXSID,'|',2),'|||',''),'||','');
                KM_CAS_neighbor(i,:)=KM.CAS(pred.neighbors(i,:));
                KM_InChiKey_neighbor(i,:)=KM.InChiKey(pred.neighbors(i,:));
                KM_DTXSID_neighbor(i,:)=KM.DTXSID(pred.neighbors(i,:));
                KM_DSSTOXMPID_neighbor(i,:)=KM.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_KM(i)~=0
                    res.KM_CAS_neighbor(i,:)=KM_CAS_neighbor(i,:);
                    res.KM_InChiKey_neighbor(i,:)=KM_InChiKey_neighbor(i,:);
                    res.KM_DTXSID_neighbor(i,:)=KM_DTXSID_neighbor(i,:);
                    res.KM_DSSTOXMPID_neighbor(i,:)=KM_DSSTOXMPID_neighbor(i,:);
                    res.LogKM_Exp_neighbor(i,:)=LogKM_Exp_neighbor(i,:);
                    res.LogKM_pred_neighbor(i,:)=LogKM_pred_neighbor(i,:);
                else
                    res.KM_CAS_neighbor(i,:)=cell(1,5);
                    res.KM_InChiKey_neighbor(i,:)=cell(1,5);
                    res.KM_DTXSID_neighbor(i,:)=cell(1,5);
                    res.KM_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogKM_Exp_neighbor(i,:)=nan(1,5);
                    res.LogKM_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogKM experimental= %.3f\n', res.LogKM_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogKM predicted= %.3f\n', res.LogKM_pred(i));
                if res.AD_KM(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_KM(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_KM(i));
                %CAS=strjoin(res.KM_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',KM.model.set.K, res.KM_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',KM.model.set.K, res.LogKM_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',KM.model.set.K, res.LogKM_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogKM experimental= %.3f\n', res.LogKM_exp(i));
                end
                fprintf(output,'LogKmHL predicted= %.3f\n', res.LogKM_pred(i));
                if res.AD_KM(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_KM(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_KM(i));
                %CAS=strjoin(res.KM_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',KM.model.set.K, res.KM_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',KM.model.set.K, res.LogKM_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',KM.model.set.K, res.LogKM_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end

            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.KM=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('KM');
        %end clean memory
    end
    
    %Predict KOC values
    %case {'logkoc','koc'}
    [Lia,Locb] =ismember({'koc','logkoc'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting LogKoc values (Log10 L/Kg)...');
        end
        load ('OPERA_models.mat', '-mat','KOC');
        Desc=KOC.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting LogKoc values... \n\n			==============================================================  \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        Xtest=Xin(:,KOC.Desc_i);
        
        pred = nnrpred(Xtest,KOC.model.set.train,KOC.model.set.y,KOC.model.set.K,KOC.model.set.dist_type,KOC.model.set.param.pret_type);
        pred.D=diag(pred.D);
        res.MoleculeID=MoleculeNames;
        if exp
            res.LogKoc_exp=NaN(size(Xtest,1),1);
        end
        res.LogKoc_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(KOC.model.set.train,Xtest,'auto');
        res.AD_LogKoc=abs(AD.inorout-1)';
        res.AD_LogKoc(round(pred.dc(:,1),3)==0)=1;

        %res.AD_index=1./(1+median(pred.dc(~isnan(pred.dc)),2));

        %             res.AD_index=1./(1+median(pred.dc,2));
        %             if isnan(res.AD_index)
        %                 res.AD_index=0;
        %             end

        res.AD_index_LogKoc=zeros(size(Xtest,1),1);
        res.Conf_index_LogKoc=zeros(size(Xtest,1),1);
        if neighbors
            Koc_CAS_neighbor=cell(size(Xtest,1),5);
            Koc_InChiKey_neighbor=cell(size(Xtest,1),5);
            Koc_DTXSID_neighbor=cell(size(Xtest,1),5);
            Koc_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        LogKoc_Exp_neighbor=nan(size(Xtest,1),5);
        LogKoc_pred_neighbor=nan(size(Xtest,1),5);

        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),KOC.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},KOC.DTXSID);
                end
                if Li
                    if Lo>size(KOC.DTXSID,1)
                        Lo=mod(Lo,size(KOC.DTXSID,1));
                    end
                    res.LogKoc_exp(i)=KOC.model.set.y(Lo);
                end
            end
            
            LogKoc_Exp_neighbor(i,:)=KOC.model.set.y(pred.neighbors(i,:));
            LogKoc_pred_neighbor(i,:)=KOC.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.LogKoc_Exp_neighbor(i,:),res.LogKoc_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_LogKoc(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_LogKoc(i,1)=((1/(1+sqrt(((LogKoc_Exp_neighbor(i,:)-LogKoc_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_LogKoc(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.LogKoc_pred(i,1)=NaN;
                res.AD_LogKoc(i)=0;
                res.AD_index_LogKoc(i)=0;
                res.Conf_index_LogKoc(i,1)=0;
            end
             if Xin(i,12)==0
                res.AD_LogKoc(i)=0;
                res.AD_index_LogKoc(i)=res.AD_index_LogKoc(i)/2;
                res.Conf_index_LogKoc(i,1)=res.Conf_index_LogKoc(i,1)/2;
            end
            if neighbors==1
                KOC.CAS=strrep(strrep(join(KOC.CAS,'|',2),'|||',''),'||','');
                KOC.DTXSID=strrep(strrep(join(KOC.DTXSID,'|',2),'|||',''),'||','');
                Koc_CAS_neighbor(i,:)=KOC.CAS(pred.neighbors(i,:));
                Koc_InChiKey_neighbor(i,:)=KOC.InChiKey(pred.neighbors(i,:));
                Koc_DTXSID_neighbor(i,:)=KOC.DTXSID(pred.neighbors(i,:));
                Koc_DSSTOXMPID_neighbor(i,:)=KOC.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_LogKoc(i)~=0
                    res.Koc_CAS_neighbor(i,:)=Koc_CAS_neighbor(i,:);
                    res.Koc_InChiKey_neighbor(i,:)=Koc_InChiKey_neighbor(i,:);
                    res.Koc_DTXSID_neighbor(i,:)=Koc_DTXSID_neighbor(i,:);
                    res.Koc_DSSTOXMPID_neighbor(i,:)=Koc_DSSTOXMPID_neighbor(i,:);
                    res.LogKoc_Exp_neighbor(i,:)=LogKoc_Exp_neighbor(i,:);
                    res.LogKoc_pred_neighbor(i,:)=LogKoc_pred_neighbor(i,:);
                else
                    res.Koc_CAS_neighbor(i,:)=cell(1,5);
                    res.Koc_InChiKey_neighbor(i,:)=cell(1,5);
                    res.Koc_DTXSID_neighbor(i,:)=cell(1,5);
                    res.Koc_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LogKoc_Exp_neighbor(i,:)=nan(1,5);
                    res.LogKoc_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'LogKOC experimental= %.3f\n', res.LogKoc_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'LogKOC predicted= %.3f\n', res.LogKoc_pred(i));
                if res.AD_LogKoc(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_LogKoc(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_LogKoc(i));
                %CAS=strjoin(res.Koc_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',KOC.model.set.K, res.Koc_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',KOC.model.set.K, res.LogKoc_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',KOC.model.set.K, res.LogKoc_pred_neighbor(i,1:5));
                end
 
            elseif strcmpi(ext,'.txt') && sep==0

                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LogKOC experimental= %.3f\n', res.LogKoc_exp(i));
                end
                fprintf(output,'LogKOC predicted= %.3f\n', res.LogKoc_pred(i));
                if res.AD_LogKoc(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_LogKoc(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_LogKoc(i));
                %CAS=strjoin(res.Koc_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',KOC.model.set.K, res.Koc_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',KOC.model.set.K, res.LogKoc_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',KOC.model.set.K, res.LogKoc_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end

        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
            
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end

            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.KOC=res;
            clear('res');
        end
        % Clean memory
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('KOC');
        %end clean memory
    end
    
    % ADME
    if verbose> 0 && (adme||all)
        fprintf(1,'------------- ADME Endpoints ------------\n');
    end
    
    %--------------------------------------------    
    %Predict FUB values
    %case {'fub','fu'}
    [Lia,Locb] =ismember({'fu','fub'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting FuB values (fraction)...');
        end
        load ('OPERA_models.mat', '-mat','FUB');
        Desc=FUB.Desc;
    
            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting FuB values... \n\n			==============================================================  \n\n');
        end
        
        %             Temp=XinCDK(:,train.FUB.cdk_in);
        %             i=1;
        %             XinCDK_FUB=zeros(size(Temp));
        %             while i<=length(train.FUB.cdk_in)
        %                 if cellfun(@ischar,table2cell(Temp(1,i)))
        %                     XinCDK_FUB(:,i)=str2double(table2cell(Temp(:,i)));
        %                 else
        %                     XinCDK_FUB(:,i)=Temp{:,i};
        %                 end
        %                 i=i+1;
        %             end
        %             clear('Temp');
        
        XinCDK_FUB=XinCDK(:,FUB.cdk_in);
        Xtest=[Xin(:,train.PadelVarIn(FUB.Padel_in)), XinCDK_FUB];
        
        Xtest=Xtest(:,FUB.Desc_i);
        
        pred = nnrpred(Xtest,FUB.model.set.train,FUB.model.set.y,FUB.model.set.K,FUB.model.set.dist_type,FUB.model.set.param.pret_type);
        pred.D=diag(pred.D);
        %pred.D=[];
        res.MoleculeID=MoleculeNames;
        if exp
            res.FUB_exp=NaN(size(Xtest,1),1);
        end
        res.FUB_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(FUB.model.set.train,Xtest,'auto');
        res.AD_FUB=abs(AD.inorout-1)';
        res.AD_FUB(round(pred.dc(:,1),3)==0)=1;
        
        res.AD_index_FUB=zeros(size(Xtest,1),1);
        res.Conf_index_FUB=zeros(size(Xtest,1),1);
        if neighbors
            FUB_CAS_neighbor=cell(size(Xtest,1),5);
            %FUB_InChiKey_neighbor=cell(size(Xtest,1),5);
            FUB_DTXSID_neighbor=cell(size(Xtest,1),5);
            %FUB_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        FUB_Exp_neighbor=nan(size(Xtest,1),5);
        FUB_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),FUB.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},FUB.DTXSID);
                end
                if Li
                    res.FUB_exp(i)=FUB.model.set.y(Lo);
                end
            end
            
            FUB_Exp_neighbor(i,:)=FUB.model.set.y(pred.neighbors(i,:));
            FUB_pred_neighbor(i,:)=FUB.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.FUB_Exp_neighbor(i,:),res.FUB_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_FUB(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_FUB(i,1)=((1/(1+sqrt(((FUB_Exp_neighbor(i,:)-FUB_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_FUB(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.FUB_pred(i,1)=NaN;
                res.AD_FUB(i)=0;
                res.AD_index_FUB(i)=0;
                res.Conf_index_FUB(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_FUB(i)=0;
                res.AD_index_FUB(i)=res.AD_index_FUB(i)/2;
                res.Conf_index_FUB(i,1)=res.Conf_index_FUB(i,1)/2;
            end
            if neighbors==1
                FUB.CAS=strrep(strrep(join(FUB.CAS,'|',2),'|||',''),'||','');
                FUB.DTXSID=strrep(strrep(join(FUB.DTXSID,'|',2),'|||',''),'||','');
                FUB_CAS_neighbor(i,:)=FUB.CAS(pred.neighbors(i,:));
                %FUB_InChiKey_neighbor(i,:)=FUB.InChiKey(pred.neighbors(i,:));
                FUB_DTXSID_neighbor(i,:)=FUB.DTXSID(pred.neighbors(i,:));
                %FUB_DSSTOXMPID_neighbor(i,:)=FUB.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_FUB(i)~=0
                    res.FUB_CAS_neighbor(i,:)=FUB_CAS_neighbor(i,:);
                    %res.FUB_InChiKey_neighbor(i,:)=FUB_InChiKey_neighbor(i,:);
                    res.FUB_DTXSID_neighbor(i,:)=FUB_DTXSID_neighbor(i,:);
                    %res.FUB_DSSTOXMPID_neighbor(i,:)=FUB_DSSTOXMPID_neighbor(i,:);
                    res.FUB_Exp_neighbor(i,:)=FUB_Exp_neighbor(i,:);
                    res.FUB_pred_neighbor(i,:)=FUB_pred_neighbor(i,:);
                else
                    res.FUB_CAS_neighbor(i,:)=cell(1,5);
                    %res.FUB_InChiKey_neighbor(i,:)=cell(1,5);
                    res.FUB_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.FUB_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.FUB_Exp_neighbor(i,:)=nan(1,5);
                    res.FUB_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'FUB experimental= %.3f\n', res.FUB_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'FUB predicted= %.3f\n', res.FUB_pred(i));
                if res.AD_FUB(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_FUB(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_FUB(i));
                %CAS=strjoin(res.FUB_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',FUB.model.set.K, res.FUB_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',FUB.model.set.K, res.FUB_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',FUB.model.set.K, res.FUB_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'FUB experimental= %.3f\n', res.FUB_exp(i));
                end
                fprintf(output,'FUB predicted= %.3f\n', res.FUB_pred(i));
                if res.AD_FUB(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_FUB(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_FUB(i));
                %CAS=strjoin(res.FUB_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',FUB.model.set.K, res.FUB_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',FUB.model.set.K, res.FUB_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',FUB.model.set.K, res.FUB_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
            
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.FUB=res;
            clear('res');
        end
        % Clean memory
        clear('XinCDK_FUB');
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('FUB');
        %end clean memory
    end
    
    %Predict Clint values
    %case {'clint','cl'}
    [Lia,Locb] =ismember({'cl','clint'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting Clint values...');
        end
        load ('OPERA_models.mat', '-mat','CLINT');
        Desc=CLINT.Desc;

            if verbose>1
                disp(['Weighted kNN model with ', num2str(length(Desc)),' descriptors']);
            end

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting Clint values... \n\n			==============================================================  \n\n');
        end
        
        %             Temp=XinCDK(:,train.CLINT.cdk_in);
        %             i=1;
        %             XinCDK_Clint=zeros(size(Temp));
        %             while i<=length(train.CLINT.cdk_in)
        %                 if cellfun(@ischar,table2cell(Temp(1,i)))
        %                     XinCDK_Clint(:,i)=str2double(table2cell(Temp(:,i)));
        %                 else
        %                     XinCDK_Clint(:,i)=Temp{:,i};
        %                 end
        %                 i=i+1;
        %             end
        %             clear('Temp');
        
        XinCDK_Clint=XinCDK(:,CLINT.cdk_in);
        Xtest=[Xin(:,train.PadelVarIn(CLINT.Padel_in)), XinCDK_Clint];
        
        Xtest=Xtest(:,CLINT.Desc_i);
        
        pred = nnrpred(Xtest,CLINT.model.set.train,CLINT.model.set.y,CLINT.model.set.K,CLINT.model.set.dist_type,CLINT.model.set.param.pret_type);
        pred.D=diag(pred.D);
        %pred.D=[];
        res.MoleculeID=MoleculeNames;
        if exp
            res.Clint_exp=NaN(size(Xtest,1),1);
        end
        res.Clint_pred(:,1)=pred.y_pred_weighted;
        AD=classical_leverage(CLINT.model.set.train,Xtest,'auto');
        res.AD_Clint=abs(AD.inorout-1)';
        res.AD_Clint(round(pred.dc(:,1),3)==0)=1;
        
        res.AD_index_Clint=zeros(size(Xtest,1),1);
        res.Conf_index_Clint=zeros(size(Xtest,1),1);
        if neighbors
            Clint_CAS_neighbor=cell(size(Xtest,1),5);
            Clint_InChiKey_neighbor=cell(size(Xtest,1),5);
            Clint_DTXSID_neighbor=cell(size(Xtest,1),5);
            %Clint_DSSTOXMPID_neighbor=cell(size(Xtest,1),5);
        end
        Clint_Exp_neighbor=nan(size(Xtest,1),5);
        Clint_pred_neighbor=nan(size(Xtest,1),5);
        
        for i=1:size(Xtest,1)
            Li=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li,Lo] = ismember(MoleculeNames(i),CLINT.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li,Lo] = ismember(MoleculeNames{i},CLINT.DTXSID);
                end
                if Li
                    res.Clint_exp(i)=CLINT.model.set.y(Lo);
                end
            end
            
            Clint_Exp_neighbor(i,:)=CLINT.model.set.y(pred.neighbors(i,:));
            Clint_pred_neighbor(i,:)=CLINT.model.yc_weighted(pred.neighbors(i,:));
            
            %                 rmse=calc_reg_param(res.Clint_Exp_neighbor(i,:),res.Clint_pred_neighbor(i,:));
            %                 res.Conf_index(i,1)=1/(1+rmse.RMSEC);
            
            res.AD_index_Clint(i,1)=1./(1+pred.dc(i,~isnan(pred.dc(i,:)))*pred.w(i,~isnan(pred.dc(i,:)))');
            
            res.Conf_index_Clint(i,1)=((1/(1+sqrt(((Clint_Exp_neighbor(i,:)-Clint_pred_neighbor(i,:)).^2)*pred.w(i,:)')))+res.AD_index_Clint(i,1))/2;
            if isempty(find(~isnan(pred.dc(i,:)), 1))
                res.Clint_pred(i,1)=NaN;
                res.AD_Clint(i)=0;
                res.AD_index_Clint(i)=0;
                res.Conf_index_Clint(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_Clint(i)=0;
                res.AD_index_Clint(i)=res.AD_index_Clint(i)/2;
                res.Conf_index_Clint(i,1)=res.Conf_index_Clint(i,1)/2;
            end
            if neighbors==1
                CLINT.CAS=strrep(strrep(join(CLINT.CAS,'|',2),'|||',''),'||','');
                CLINT.DTXSID=strrep(strrep(join(CLINT.DTXSID,'|',2),'|||',''),'||','');
                Clint_CAS_neighbor(i,:)=CLINT.CAS(pred.neighbors(i,:));
                Clint_InChiKey_neighbor(i,:)=CLINT.InChiKey(pred.neighbors(i,:));
                Clint_DTXSID_neighbor(i,:)=CLINT.DTXSID(pred.neighbors(i,:));
                %Clint_DSSTOXMPID_neighbor(i,:)=CLINT.DSSTOXMPID(pred.neighbors(i,:));
                if res.AD_index_Clint(i)~=0
                    res.Clint_CAS_neighbor(i,:)=Clint_CAS_neighbor(i,:);
                    res.Clint_InChiKey_neighbor(i,:)=Clint_InChiKey_neighbor(i,:);
                    res.Clint_DTXSID_neighbor(i,:)=Clint_DTXSID_neighbor(i,:);
                    %res.Clint_DSSTOXMPID_neighbor(i,:)=Clint_DSSTOXMPID_neighbor(i,:);
                    res.Clint_Exp_neighbor(i,:)=Clint_Exp_neighbor(i,:);
                    res.Clint_pred_neighbor(i,:)=Clint_pred_neighbor(i,:);
                else
                    res.Clint_CAS_neighbor(i,:)=cell(1,5);
                    res.Clint_InChiKey_neighbor(i,:)=cell(1,5);
                    res.Clint_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.Clint_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.Clint_Exp_neighbor(i,:)=nan(1,5);
                    res.Clint_pred_neighbor(i,:)=nan(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'Clint experimental= %.3f\n', res.Clint_exp(i));
                end
                fprintf(output(Locb(find(Locb))),'Clint predicted= %.3f\n', res.Clint_pred(i));
                if res.AD_Clint(i)==1
                    fprintf(output(Locb(find(Locb))),'AD: inside\n');
                else
                    fprintf(output(Locb(find(Locb))),'AD: outside\n');
                end
                fprintf(output(Locb(find(Locb))),'AD_index= %.2f\n', res.AD_index_Clint(i));
                fprintf(output(Locb(find(Locb))),'Conf_index= %.2f\n', res.Conf_index_Clint(i));
                %CAS=strjoin(res.Clint_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',CLINT.model.set.K, res.Clint_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',CLINT.model.set.K, res.Clint_Exp_neighbor(i,1:5));
                    fprintf(output(Locb(find(Locb))),'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',CLINT.model.set.K, res.Clint_pred_neighbor(i,1:5));
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                
                %res.Xtest=Xtest;
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'Clint experimental= %.3f\n', res.Clint_exp(i));
                end
                fprintf(output,'Clint predicted= %.3f\n', res.Clint_pred(i));
                if res.AD_Clint(i)==1
                    fprintf(output,'AD: inside\n');
                else
                    fprintf(output,'AD: outside\n');
                end
                fprintf(output,'AD_index= %.2f\n', res.AD_index_Clint(i));
                fprintf(output,'Conf_index= %.2f\n', res.Conf_index_Clint(i));
                %CAS=strjoin(res.Clint_CAS_neighbor(i,1:5),',\t');
                %CAS=strrep([res.CAS_neighbors(i,1:5)],' ',', ');
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',CLINT.model.set.K, res.Clint_CAS_neighbor{i,1:5});
                    fprintf(output,'Exp of the %i nearest neighbors:%15.3f,%15.3f,%15.3f,%15.3f,%15.3f\n',CLINT.model.set.K, res.Clint_Exp_neighbor(i,1:5));
                    fprintf(output,'Pred of the %i nearest neighbors:%14.3f,%15.3f,%15.3f,%15.3f,%15.3f\n\n',CLINT.model.set.K, res.Clint_pred_neighbor(i,1:5));
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
            
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            Xtest(:,ismember(Desc,DescNames))=[];
            
            Desc(ismember(Desc,DescNames))=[];
            
            DescNames=[DescNames Desc];
            
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.Clint=res;
            clear('res');
        end
        % Clean memory
        clear('XinCDK_Clint');
        clear('Xtest');
        clear('pred');
        clear('AD');
        clear('CLINT');
        %end clean memory
    end
    
    % Tox properties
    
    if verbose> 0 && (tox||all)
        fprintf(1,'----------- Toxcity Endpoints -----------\n');
    end
    
    %--------------------------------------------
    
    %Predict CERAPP endpoints
    %case {'CERAPP','ER'}
    [Lia,Locb] =ismember({'cerapp','er'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting Estrogen Receptor Activity (CERAPP)...');
            if verbose>1
                disp('Agonist, Antagonist & Binding consensus models from the CERAPP project.');
            end
        end
        load ('OPERA_models.mat', '-mat','CERAPP');
        Desc=CERAPP.DescIn;

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting CERAPP endpoints... \n\n			==============================================================  \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        
        %XlabelsCDK
        
        XinCDK_CERAPP=XinCDK(:,CERAPP.cdk_in);
        Xtest=[Xin(:,train.PadelVarIn(CERAPP.Padel_in)), XinCDK_CERAPP];
        
        XtestAG=Xtest(:,CERAPP.model_AG.DescAG_i);
        XtestAN=Xtest(:,CERAPP.model_AN.DescAN_i);
        XtestBD=Xtest(:,CERAPP.model_BD.DescBD_i);
        %tic
        predAG = knnpred2(XtestAG,CERAPP.model_AG.set.train,CERAPP.model_AG.set.class,CERAPP.model_AG.set.class_Exp_N,CERAPP.model_AG.set.K,CERAPP.model_AG.set.dist_type,CERAPP.model_AG.set.param.pret_type);
        %predAG.D=diag(predAG.D);
        predAG.D=[];
        predAN = knnpred2(XtestAN,CERAPP.model_AN.set.train,CERAPP.model_AN.set.class,CERAPP.model_AN.set.class_Exp_N,CERAPP.model_AN.set.K,CERAPP.model_AN.set.dist_type,CERAPP.model_AN.set.param.pret_type);
        %predAN.D=diag(predAN.D);
        predAN.D=[];
        predBD = knnpred2(XtestBD,CERAPP.model_BD.set.train,CERAPP.model_BD.set.class,CERAPP.model_BD.set.class_Exp_N,CERAPP.model_BD.set.K,CERAPP.model_BD.set.dist_type,CERAPP.model_BD.set.param.pret_type);
        %predBD.D=diag(predBD.D);
        predBD.D=[];
        %toc
        res.MoleculeID=MoleculeNames;
        if exp
            res.CERAPP_Ago_exp=cell(size(Xtest,1),1);
        end
        res.CERAPP_Ago_pred(:,1)=predAG.class_pred-1;
        AD=classical_leverage(CERAPP.model_AG.set.train,XtestAG,'auto');
        res.AD_CERAPP_Ago=abs(AD.inorout-1)';
        res.AD_index_CERAPP_Ago=1-test_pretreatment(predAG.dc(:,1),CERAPP.model_AG.set.dc_param);
        res.AD_index_CERAPP_Ago(find(res.AD_index_CERAPP_Ago<0),1)=1./(1+predAG.dc(find(res.AD_index_CERAPP_Ago<0),1));
        res.CERAPP_Ago_pred(find(isnan(predAG.dc(:,1))))=NaN;
        res.AD_CERAPP_Ago(find(isnan(predAG.dc(:,1))))=0;
        res.AD_index_CERAPP_Ago(find(isnan(predAG.dc(:,1))))=0;
        res.AD_CERAPP_Ago(find(res.AD_index_CERAPP_Ago>0.5))=1;
        res.Conf_index_CERAPP_Ago=zeros(size(XtestAG,1),1);
        if exp
            res.CERAPP_Anta_exp=cell(size(Xtest,1),1);
        end
        res.CERAPP_Anta_pred(:,1)=predAN.class_pred-1;
        AD=classical_leverage(CERAPP.model_AN.set.train,XtestAN,'auto');
        res.AD_CERAPP_Anta=abs(AD.inorout-1)';
        res.AD_index_CERAPP_Anta=1-test_pretreatment(predAN.dc(:,1),CERAPP.model_AN.set.dc_param);
        res.AD_index_CERAPP_Anta(find(res.AD_index_CERAPP_Anta<0),1)=1./(1+predAN.dc(find(res.AD_index_CERAPP_Anta<0),1));
        res.CERAPP_Anta_pred(find(isnan(predAN.dc(:,1))))=NaN;
        res.AD_CERAPP_Anta(find(isnan(predAN.dc(:,1))))=0;
        res.AD_index_CERAPP_Anta(find(isnan(predAN.dc(:,1))))=0;
        res.AD_CERAPP_Anta(find(res.AD_index_CERAPP_Anta>0.5))=1;
        res.Conf_index_CERAPP_Anta=zeros(size(XtestAN,1),1);
        if exp
            res.CERAPP_Bind_exp=cell(size(Xtest,1),1);
        end
        res.CERAPP_Bind_pred(:,1)=predBD.class_pred-1;
        AD=classical_leverage(CERAPP.model_BD.set.train,XtestBD,'auto');
        res.AD_CERAPP_Bind=abs(AD.inorout-1)';
        res.AD_index_CERAPP_Bind=1-test_pretreatment(predBD.dc(:,1),CERAPP.model_BD.set.dc_param);
        res.AD_index_CERAPP_Bind(find(res.AD_index_CERAPP_Bind<0),1)=1./(1+predBD.dc(find(res.AD_index_CERAPP_Bind<0),1));
        res.CERAPP_Bind_pred(find(isnan(predBD.dc(:,1))))=NaN;
        res.AD_CERAPP_Bind(find(isnan(predBD.dc(:,1))))=0;
        res.AD_index_CERAPP_Bind(find(isnan(predBD.dc(:,1))))=0;
        res.AD_CERAPP_Bind(find(res.AD_index_CERAPP_Bind>0.5))=1;
        res.Conf_index_CERAPP_Bind=zeros(size(XtestBD,1),1);
        
        
        for i=1:size(Xtest,1)
            Li_ag=0;
            Li_an=0;
            Li_bd=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li_ag,Lo_ag] = ismember(MoleculeNames(i),CERAPP.model_AG.CAS);
                    [Li_an,Lo_an] = ismember(MoleculeNames(i),CERAPP.model_AN.CAS);
                    [Li_bd,Lo_bd] = ismember(MoleculeNames(i),CERAPP.model_BD.CAS);
                    if Li_ag
                        if Lo_ag>size(CERAPP.model_AG.CAS,1)
                            Lo_ag=mod(Lo_ag,size(CERAPP.model_AG.CAS,1));
                        end
                        res.CERAPP_Ago_exp(i,1)=CERAPP.model_AG.set.class_Exp(Lo_ag);
                    else
                        res.CERAPP_Ago_exp(i,1)={'NA'};
                    end
                    if Li_an
                        if Lo_an>size(CERAPP.model_AN.CAS,1)
                            Lo_an=mod(Lo_an,size(CERAPP.model_AN.CAS,1));
                        end
                        res.CERAPP_Anta_exp(i,1)=CERAPP.model_AN.set.class_Exp(Lo_an);
                    else
                        res.CERAPP_Anta_exp(i,1)={'NA'};
                    end
                    if Li_bd
                        if Lo_bd>size(CERAPP.model_BD.CAS,1)
                            Lo_bd=mod(Lo_bd,size(CERAPP.model_BD.CAS,1));
                        end
                        res.CERAPP_Bind_exp(i,1)=CERAPP.model_BD.set.class_Exp(Lo_bd);
                    else
                        res.CERAPP_Bind_exp(i,1)={'NA'};
                    end
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li_ag,Lo_ag] = ismember(MoleculeNames{i},CERAPP.model_AG.DTXSID);
                    [Li_an,Lo_an] = ismember(MoleculeNames{i},CERAPP.model_AN.DTXSID);
                    [Li_bd,Lo_bd] = ismember(MoleculeNames{i},CERAPP.model_BD.DTXSID);
                    
                    if Li_ag
                        if Lo_ag>size(CERAPP.model_AG.DTXSID,1)
                            Lo_ag=mod(Lo_ag,size(CERAPP.model_AG.DTXSID,1));
                        end
                        res.CERAPP_Ago_exp(i,1)=CERAPP.model_AG.set.class_Exp(Lo_ag);
                    else
                        res.CERAPP_Ago_exp(i,1)={'NA'};
                    end
                    if Li_an
                        if Lo_an>size(CERAPP.model_AN.DTXSID,1)
                            Lo_an=mod(Lo_an,size(CERAPP.model_AN.DTXSID,1));
                        end
                        res.CERAPP_Anta_exp(i,1)=CERAPP.model_AN.set.class_Exp(Lo_an);
                    else
                        res.CERAPP_Anta_exp(i,1)={'NA'};
                    end
                    if Li_bd
                        if Lo_bd>size(CERAPP.model_BD.DTXSID,1)
                            Lo_bd=mod(Lo_bd,size(CERAPP.model_BD.DTXSID,1));
                        end
                        res.CERAPP_Bind_exp(i,1)=CERAPP.model_BD.set.class_Exp(Lo_bd);
                    else
                        res.CERAPP_Bind_exp(i,1)={'NA'};
                    end
                else
                    res.CERAPP_Ago_exp(i,1)={'NA'};
                    res.CERAPP_Anta_exp(i,1)={'NA'};
                    res.CERAPP_Bind_exp(i,1)={'NA'};
                end
            end
            res.Conf_index_CERAPP_Ago(i,1)=(CERAPP.model_AG.conc_AG(predAG.neighbors(i,:),1)'*predAG.w(i,:)'+res.AD_index_CERAPP_Ago(i))/2;
            if res.AD_index_CERAPP_Ago(i)==0
                res.Conf_index_CERAPP_Ago(i,1)=0;
            end
            res.Conf_index_CERAPP_Anta(i,1)=(CERAPP.model_AN.conc_AN(predAN.neighbors(i,:),1)'*predAN.w(i,:)'+res.AD_index_CERAPP_Anta(i))/2;
            if res.AD_index_CERAPP_Anta(i)==0
                res.Conf_index_CERAPP_Anta(i,1)=0;
            end
            res.Conf_index_CERAPP_Bind(i,1)=(CERAPP.model_BD.conc_BD(predBD.neighbors(i,:),1)'*predBD.w(i,:)'+res.AD_index_CERAPP_Bind(i))/2;
            if res.AD_index_CERAPP_Bind(i)==0
                res.Conf_index_CERAPP_Bind(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_CERAPP_Ago(i)=0;
                res.AD_index_CERAPP_Ago(i)=res.AD_index_CERAPP_Ago(i)/2;
                res.Conf_index_CERAPP_Ago(i,1)=res.Conf_index_CERAPP_Ago(i,1)/2;
                res.AD_CERAPP_Anta(i)=0;
                res.AD_index_CERAPP_Anta(i)=res.AD_index_CERAPP_Anta(i)/2;
                res.Conf_index_CERAPP_Anta(i,1)=res.Conf_index_CERAPP_Anta(i,1)/2;
                res.AD_CERAPP_Bind(i)=0;
                res.AD_index_CERAPP_Bind(i)=res.AD_index_CERAPP_Bind(i)/2;
                res.Conf_index_CERAPP_Bind(i,1)=res.Conf_index_CERAPP_Bind(i,1)/2;
            end

            if neighbors==1
                CERAPP.model_AG.CAS=strrep(strrep(join(CERAPP.model_AG.CAS,'|',2),'|||',''),'||','');
                CERAPP.model_AG.DTXSID=strrep(strrep(join(CERAPP.model_AG.DTXSID,'|',2),'|||',''),'||','');
                CERAPP.model_AN.CAS=strrep(strrep(join(CERAPP.model_AN.CAS,'|',2),'|||',''),'||','');
                CERAPP.model_AN.DTXSID=strrep(strrep(join(CERAPP.model_AN.DTXSID,'|',2),'|||',''),'||','');
                CERAPP.model_BD.CAS=strrep(strrep(join(CERAPP.model_BD.CAS,'|',2),'|||',''),'||','');
                CERAPP.model_BD.DTXSID=strrep(strrep(join(CERAPP.model_BD.DTXSID,'|',2),'|||',''),'||','');
                
                if res.AD_index_CERAPP_Ago(i)~=0
                    res.CERAPP_Ago_CAS_neighbor(i,:)=CERAPP.model_AG.CAS(predAG.neighbors(i,:));
                    res.CERAPP_Ago_InChiKey_neighbor(i,:)=CERAPP.model_AG.InChiKey(predAG.neighbors(i,:));
                    res.CERAPP_Ago_DTXSID_neighbor(i,:)=CERAPP.model_AG.DTXSID(predAG.neighbors(i,:));
                    %res.CERAPP_Ago_DSSTOXMPID_neighbor(i,:)=CERAPP.model_AG.DSSTOXMPID(pred.neighbors(i,:));
                    res.CERAPP_Ago_Exp_neighbor(i,:)=CERAPP.model_AG.set.class_Exp(predAG.neighbors(i,:));
                    res.CERAPP_Ago_pred_neighbor(i,:)=CERAPP.model_AG.set.class_S(predAG.neighbors(i,:));
                else
                    res.CERAPP_Ago_CAS_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Ago_InChiKey_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Ago_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.CERAPP_Ago_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Ago_Exp_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Ago_pred_neighbor(i,:)=cell(1,5);
                end
                if res.AD_index_CERAPP_Anta(i) ~=0
                    res.CERAPP_Anta_CAS_neighbor(i,:)=CERAPP.model_AN.CAS(predAN.neighbors(i,:));
                    res.CERAPP_Anta_InChiKey_neighbor(i,:)=CERAPP.model_AN.InChiKey(predAN.neighbors(i,:));
                    res.CERAPP_Anta_DTXSID_neighbor(i,:)=CERAPP.model_AN.DTXSID(predAN.neighbors(i,:));
                    %res.CERAPP_Anta_DSSTOXMPID_neighbor(i,:)=CERAPP.model_AN.DSSTOXMPID(pred.neighbors(i,:));
                    res.CERAPP_Anta_Exp_neighbor(i,:)=CERAPP.model_AN.set.class_Exp(predAN.neighbors(i,:));
                    res.CERAPP_Anta_pred_neighbor(i,:)=CERAPP.model_AN.set.class_S(predAN.neighbors(i,:));
                else
                    res.CERAPP_Anta_CAS_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Anta_InChiKey_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Anta_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.CERAPP_Anta_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Anta_Exp_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Anta_pred_neighbor(i,:)=cell(1,5);
                end
                if res.AD_index_CERAPP_Bind(i) ~=0
                    res.CERAPP_Bind_CAS_neighbor(i,:)=CERAPP.model_BD.CAS(predBD.neighbors(i,:));
                    res.CERAPP_Bind_InChiKey_neighbor(i,:)=CERAPP.model_BD.InChiKey(predBD.neighbors(i,:));
                    res.CERAPP_Bind_DTXSID_neighbor(i,:)=CERAPP.model_BD.DTXSID(predBD.neighbors(i,:));
                    %res.CERAPP_Bind_DSSTOXMPID_neighbor(i,:)=CERAPP.model_BD.DSSTOXMPID(predBD.neighbors(i,:));
                    res.CERAPP_Bind_Exp_neighbor(i,:)=CERAPP.model_BD.set.class_Exp(predBD.neighbors(i,:));
                    res.CERAPP_Bind_pred_neighbor(i,:)=CERAPP.model_BD.set.class_S(predBD.neighbors(i,:));
                else
                    res.CERAPP_Bind_CAS_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Bind_InChiKey_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Bind_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.CERAPP_Bind_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Bind_Exp_neighbor(i,:)=cell(1,5);
                    res.CERAPP_Bind_pred_neighbor(i,:)=cell(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'AG experimental= %s, AN experimental= %s, BD experimental= %s\n', res.CERAPP_Ago_exp{i},res.CERAPP_Anta_exp{i},res.CERAPP_Bind_exp{i});
                end
                fprintf(output(Locb(find(Locb))),'AG predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CERAPP_Ago_pred(i),res.AD_CERAPP_Ago(i),res.AD_index_CERAPP_Ago(i),res.Conf_index_CERAPP_Ago(i));
                fprintf(output(Locb(find(Locb))),'AN predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CERAPP_Anta_pred(i),res.AD_CERAPP_Anta(i),res.AD_index_CERAPP_Anta(i),res.Conf_index_CERAPP_Anta(i));
                fprintf(output(Locb(find(Locb))),'BD predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CERAPP_Bind_pred(i),res.AD_CERAPP_Bind(i),res.AD_index_CERAPP_Bind(i),res.Conf_index_CERAPP_Bind(i));
                
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors (Agonist):%15s,%15s,%15s,%15s,%15s\n',CERAPP.model_AG.set.K, res.CERAPP_Ago_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors (Antagonist):%15s,%15s,%15s,%15s,%15s\n',CERAPP.model_AN.set.K, res.CERAPP_Anta_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors (Binding):%15s,%15s,%15s,%15s,%15s\n',CERAPP.model_BD.set.K, res.CERAPP_Bind_CAS_neighbor{i,1:5});
                end

            elseif strcmpi(ext,'.txt') && sep==0
                
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'AG experimental= %s, AN experimental= %s, BD experimental= %s\n', res.CERAPP_Ago_exp{i},res.CERAPP_Anta_exp{i},res.CERAPP_Bind_exp{i});
                end
                fprintf(output,'AG predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CERAPP_Ago_pred(i),res.AD_CERAPP_Ago(i),res.AD_index_CERAPP_Ago(i),res.Conf_index_CERAPP_Ago(i));
                fprintf(output,'AN predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CERAPP_Anta_pred(i),res.AD_CERAPP_Anta(i),res.AD_index_CERAPP_Anta(i),res.Conf_index_CERAPP_Anta(i));
                fprintf(output,'BD predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CERAPP_Bind_pred(i),res.AD_CERAPP_Bind(i),res.AD_index_CERAPP_Bind(i),res.Conf_index_CERAPP_Bind(i));
                
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors (Agonist):%15s,%15s,%15s,%15s,%15s\n',CERAPP.model_AG.set.K, res.CERAPP_Ago_CAS_neighbor{i,1:5});
                    fprintf(output,'CAS of the %i nearest neighbors (Antagonist):%15s,%15s,%15s,%15s,%15s\n',CERAPP.model_AN.set.K, res.CERAPP_Anta_CAS_neighbor{i,1:5});
                    fprintf(output,'CAS of the %i nearest neighbors (Binding):%15s,%15s,%15s,%15s,%15s\n',CERAPP.model_BD.set.K, res.CERAPP_Bind_CAS_neighbor{i,1:5});
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                if exp
                    T{end+1:end+nf,2:5}=nan(nf,4);
                else
                    T{end+1:end+nf,1:4}=nan(nf,4);
                end
                
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                %Xtest=[XtestAG; XtestAN; XtestBD; XtestGHS; XtestLD50];
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
            
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            %Xtest=[XtestAG; XtestAN; XtestBD; XtestGHS; XtestLD50];
            Xtest(:,ismember(Desc,DescNames))=[];
            Desc(ismember(Desc,DescNames))=[];
            DescNames=[DescNames Desc];
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.CERAPP=res;
            clear('res');
            
        end
        % Clean memory
        clear('XinCDK_CERAPP');
        clear('Xtest');
        clear('XtestAG');
        clear('XtestAN');
        clear('XtestBD');
        clear('predAG');
        clear('predAN');
        clear('predBD')
        clear('AD');
        clear('CERAPP');
        %end clean memory
    end
    
    %--------------------------------------------
    
    %Predict CoMPARA endpoints
    %case {'CoMPARA','AR'}
    [Lia,Locb] =ismember({'compara','ar'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting Androgen Receptor Activity (CoMPARA)...');
            if verbose>1
                disp('Agonist, Antagonist & Binding consensus models from the CATMoS project.');
            end
        end
        load ('OPERA_models.mat', '-mat','COMPARA');
        Desc=COMPARA.DescIn;

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting CoMPARA endpoints... \n\n			==============================================================  \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        
        %XlabelsCDK
        XinCDK_CoMPARA=XinCDK(:,COMPARA.cdk_in);
        Xtest=[Xin(:,train.PadelVarIn(COMPARA.Padel_in)), XinCDK_CoMPARA];
        
        XtestAG=Xtest(:,COMPARA.model_AG.DescAG_i);
        XtestAN=Xtest(:,COMPARA.model_AN.DescAN_i);
        XtestBD=Xtest(:,COMPARA.model_BD.DescBD_i);
        
        predAG = knnpred2(XtestAG,COMPARA.model_AG.set.train,COMPARA.model_AG.set.class,COMPARA.model_AG.set.class_Exp_N,COMPARA.model_AG.set.K,COMPARA.model_AG.set.dist_type,COMPARA.model_AG.set.param.pret_type);
        %predAG.D=diag(predAG.D);
        predAG.D=[];
        predAN = knnpred2(XtestAN,COMPARA.model_AN.set.train,COMPARA.model_AN.set.class,COMPARA.model_AN.set.class_Exp_N,COMPARA.model_AN.set.K,COMPARA.model_AN.set.dist_type,COMPARA.model_AN.set.param.pret_type);
        %predAN.D=diag(predAN.D);
        predAN.D=[];
        predBD = knnpred2(XtestBD,COMPARA.model_BD.set.train,COMPARA.model_BD.set.class,COMPARA.model_BD.set.class_Exp_N,COMPARA.model_BD.set.K,COMPARA.model_BD.set.dist_type,COMPARA.model_BD.set.param.pret_type);
        %predBD.D=diag(predBD.D);
        predBD.D=[];
        
        res.MoleculeID=MoleculeNames;
        if exp
            res.CoMPARA_Ago_exp=cell(size(Xtest,1),1);
        end
        res.CoMPARA_Ago_pred(:,1)=predAG.class_pred-1;
        AD=classical_leverage(COMPARA.model_AG.set.train,XtestAG,'auto');
        res.AD_CoMPARA_Ago=abs(AD.inorout-1)';
        res.AD_index_CoMPARA_Ago=1-test_pretreatment(predAG.dc(:,1),COMPARA.model_AG.set.dc_param);
        res.AD_index_CoMPARA_Ago(find(res.AD_index_CoMPARA_Ago<0),1)=1./(1+predAG.dc(find(res.AD_index_CoMPARA_Ago<0),1));
        res.CoMPARA_Ago_pred(find(isnan(predAG.dc(:,1))))=NaN;
        res.AD_CoMPARA_Ago(find(isnan(predAG.dc(:,1))))=0;
        res.AD_index_CoMPARA_Ago(find(isnan(predAG.dc(:,1))))=0;
        res.AD_CoMPARA_Ago(find(res.AD_index_CoMPARA_Ago>0.5))=1;
        res.Conf_index_CoMPARA_Ago=zeros(size(XtestAG,1),1);
        if exp
            res.CoMPARA_Anta_exp=cell(size(Xtest,1),1);
        end
        res.CoMPARA_Anta_pred(:,1)=predAN.class_pred-1;
        AD=classical_leverage(COMPARA.model_AN.set.train,XtestAN,'auto');
        res.AD_CoMPARA_Anta=abs(AD.inorout-1)';
        res.AD_index_CoMPARA_Anta=1-test_pretreatment(predAN.dc(:,1),COMPARA.model_AN.set.dc_param);
        res.AD_index_CoMPARA_Anta(find(res.AD_index_CoMPARA_Anta<0),1)=1./(1+predAN.dc(find(res.AD_index_CoMPARA_Anta<0),1));
        res.CoMPARA_Anta_pred(find(isnan(predAN.dc(:,1))))=NaN;
        res.AD_CoMPARA_Anta(find(isnan(predAN.dc(:,1))))=0;
        res.AD_index_CoMPARA_Anta(find(isnan(predAN.dc(:,1))))=0;
        res.AD_CoMPARA_Anta(find(res.AD_index_CoMPARA_Anta>0.5))=1;
        res.Conf_index_CoMPARA_Anta=zeros(size(XtestAN,1),1);
        if exp
            res.CoMPARA_Bind_exp=cell(size(Xtest,1),1);
        end
        res.CoMPARA_Bind_pred(:,1)=predBD.class_pred-1;
        AD=classical_leverage(COMPARA.model_BD.set.train,XtestBD,'auto');
        res.AD_CoMPARA_Bind=abs(AD.inorout-1)';
        res.AD_index_CoMPARA_Bind=1-test_pretreatment(predBD.dc(:,1),COMPARA.model_BD.set.dc_param);
        res.AD_index_CoMPARA_Bind(find(res.AD_index_CoMPARA_Bind<0),1)=1./(1+predBD.dc(find(res.AD_index_CoMPARA_Bind<0),1));
        res.CoMPARA_Bind_pred(find(isnan(predBD.dc(:,1))))=NaN;
        res.AD_CoMPARA_Bind(find(isnan(predBD.dc(:,1))))=0;
        res.AD_index_CoMPARA_Bind(find(isnan(predBD.dc(:,1))))=0;
        res.AD_CoMPARA_Bind(find(res.AD_index_CoMPARA_Bind>0.5))=1;
        res.Conf_index_CoMPARA_Bind=zeros(size(XtestBD,1),1);
        
        for i=1:size(Xtest,1)
            Li_ag=0;
            Li_an=0;
            Li_bd=0;
            if exp && ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
                    [Li_ag,Lo_ag] = ismember(MoleculeNames(i),COMPARA.model_AG.CAS);
                    [Li_an,Lo_an] = ismember(MoleculeNames(i),COMPARA.model_AN.CAS);
                    [Li_bd,Lo_bd] = ismember(MoleculeNames(i),COMPARA.model_BD.CAS);
                    if Li_ag
                        if Lo_ag>size(COMPARA.model_AG.CAS,1)
                            Lo_ag=mod(Lo_ag,size(COMPARA.model_AG.CAS,1));
                        end
                        res.CoMPARA_Ago_exp(i,1)=COMPARA.model_AG.set.class_Exp(Lo_ag);
                    else
                        res.CoMPARA_Ago_exp(i,1)={'NA'};
                    end
                    if Li_an
                        if Lo_an>size(COMPARA.model_AN.CAS,1)
                            Lo_an=mod(Lo_an,size(COMPARA.model_AN.CAS,1));
                        end
                        res.CoMPARA_Anta_exp(i,1)=COMPARA.model_AN.set.class_Exp(Lo_an);
                    else
                        res.CoMPARA_Anta_exp(i,1)={'NA'};
                    end
                    if Li_bd
                        if Lo_bd>size(COMPARA.model_BD.CAS,1)
                            Lo_bd=mod(Lo_bd,size(COMPARA.model_BD.CAS,1));
                        end
                        res.CoMPARA_Bind_exp(i,1)=COMPARA.model_BD.set.class_Exp(Lo_bd);
                    else
                        res.CoMPARA_Bind_exp(i,1)={'NA'};
                    end
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
                    [Li_ag,Lo_ag] = ismember(MoleculeNames{i},COMPARA.model_AG.DTXSID);
                    [Li_an,Lo_an] = ismember(MoleculeNames{i},COMPARA.model_AN.DTXSID);
                    [Li_bd,Lo_bd] = ismember(MoleculeNames{i},COMPARA.model_BD.DTXSID);
                    
                    if Li_ag
                        if Lo_ag>size(COMPARA.model_AG.DTXSID,1)
                            Lo_ag=mod(Lo_ag,size(COMPARA.model_AG.DTXSID,1));
                        end
                        res.CoMPARA_Ago_exp(i,1)=COMPARA.model_AG.set.class_Exp(Lo_ag);
                    else
                        res.CoMPARA_Ago_exp(i,1)={'NA'};
                    end
                    if Li_an
                        if Lo_an>size(COMPARA.model_AN.DTXSID,1)
                            Lo_an=mod(Lo_an,size(COMPARA.model_AN.DTXSID,1));
                        end
                        res.CoMPARA_Anta_exp(i,1)=COMPARA.model_AN.set.class_Exp(Lo_an);
                    else
                        res.CoMPARA_Anta_exp(i,1)={'NA'};
                    end
                    if Li_bd
                        if Lo_bd>size(COMPARA.model_BD.DTXSID,1)
                            Lo_bd=mod(Lo_bd,size(COMPARA.model_BD.DTXSID,1));
                        end
                        res.CoMPARA_Bind_exp(i,1)=COMPARA.model_BD.set.class_Exp(Lo_bd);
                    else
                        res.CoMPARA_Bind_exp(i,1)={'NA'};
                    end
                else
                    res.CoMPARA_Ago_exp(i,1)={'NA'};
                    res.CoMPARA_Anta_exp(i,1)={'NA'};
                    res.CoMPARA_Bind_exp(i,1)={'NA'};
                end
                
            end
            res.Conf_index_CoMPARA_Ago(i,1)=(COMPARA.model_AG.conc_AG(predAG.neighbors(i,:),1)'*predAG.w(i,:)'+res.AD_index_CoMPARA_Ago(i))/2;
            if res.AD_index_CoMPARA_Ago(i)==0
                res.Conf_index_CoMPARA_Ago(i,1)=0;
            end
            res.Conf_index_CoMPARA_Anta(i,1)=(COMPARA.model_AN.conc_AN(predAN.neighbors(i,:),1)'*predAN.w(i,:)'+res.AD_index_CoMPARA_Anta(i))/2;
            if res.AD_index_CoMPARA_Anta(i)==0
                res.Conf_index_CoMPARA_Anta(i,1)=0;
            end
            res.Conf_index_CoMPARA_Bind(i,1)=(COMPARA.model_BD.conc_BD(predBD.neighbors(i,:),1)'*predBD.w(i,:)'+res.AD_index_CoMPARA_Bind(i))/2;
            if res.AD_index_CoMPARA_Bind(i)==0
                res.Conf_index_CoMPARA_Bind(i,1)=0;
            end
            if Xin(i,12)==0
                res.AD_CoMPARA_Ago(i)=0;
                res.AD_index_CoMPARA_Ago(i)=res.AD_index_CoMPARA_Ago(i)/2;
                res.Conf_index_CoMPARA_Ago(i,1)=res.Conf_index_CoMPARA_Ago(i,1)/2;
                res.AD_CoMPARA_Anta(i)=0;
                res.AD_index_CoMPARA_Anta(i)=res.AD_index_CoMPARA_Anta(i)/2;
                res.Conf_index_CoMPARA_Anta(i,1)=res.Conf_index_CoMPARA_Anta(i,1)/2;
                res.AD_CoMPARA_Bind(i)=0;
                res.AD_index_CoMPARA_Bind(i)=res.AD_index_CoMPARA_Bind(i)/2;
                res.Conf_index_CoMPARA_Bind(i,1)=res.Conf_index_CoMPARA_Bind(i,1)/2;
            end
            if neighbors==1
                COMPARA.model_AG.CAS=strrep(strrep(join(COMPARA.model_AG.CAS,'|',2),'|||',''),'||','');
                COMPARA.model_AG.DTXSID=strrep(strrep(join(COMPARA.model_AG.DTXSID,'|',2),'|||',''),'||','');
                COMPARA.model_AN.CAS=strrep(strrep(join(COMPARA.model_AN.CAS,'|',2),'|||',''),'||','');
                COMPARA.model_AN.DTXSID=strrep(strrep(join(COMPARA.model_AN.DTXSID,'|',2),'|||',''),'||','');
                COMPARA.model_BD.CAS=strrep(strrep(join(COMPARA.model_BD.CAS,'|',2),'|||',''),'||','');
                COMPARA.model_BD.DTXSID=strrep(strrep(join(COMPARA.model_BD.DTXSID,'|',2),'|||',''),'||','');
                if res.AD_index_CoMPARA_Ago(i)~=0
                    res.CoMPARA_Ago_CAS_neighbor(i,:)=COMPARA.model_AG.CAS(predAG.neighbors(i,:));
                    res.CoMPARA_Ago_InChiKey_neighbor(i,:)=COMPARA.model_AG.InChiKey(predAG.neighbors(i,:));
                    res.CoMPARA_Ago_DTXSID_neighbor(i,:)=COMPARA.model_AG.DTXSID(predAG.neighbors(i,:));
                    %res.CoMPARA_Ago_DSSTOXMPID_neighbor(i,:)=COMPARA.model_AG.DSSTOXMPID(pred.neighbors(i,:));
                    res.CoMPARA_Ago_Exp_neighbor(i,:)=COMPARA.model_AG.set.class_Exp(predAG.neighbors(i,:));
                    res.CoMPARA_Ago_pred_neighbor(i,:)=COMPARA.model_AG.set.class_S(predAG.neighbors(i,:));
               else
                    res.CoMPARA_Ago_CAS_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Ago_InChiKey_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Ago_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.CoMPARA_Ago_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Ago_Exp_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Ago_pred_neighbor(i,:)=cell(1,5);
                end
                if res.AD_index_CoMPARA_Anta(i)~=0
                    res.CoMPARA_Anta_CAS_neighbor(i,:)=COMPARA.model_AN.CAS(predAN.neighbors(i,:));
                    res.CoMPARA_Anta_InChiKey_neighbor(i,:)=COMPARA.model_AN.InChiKey(predAN.neighbors(i,:));
                    res.CoMPARA_Anta_DTXSID_neighbor(i,:)=COMPARA.model_AN.DTXSID(predAN.neighbors(i,:));
                    %res.CoMPARA_Anta_DSSTOXMPID_neighbor(i,:)=COMPARA.model_AN.DSSTOXMPID(pred.neighbors(i,:));
                    res.CoMPARA_Anta_Exp_neighbor(i,:)=COMPARA.model_AN.set.class_Exp(predAN.neighbors(i,:));
                    res.CoMPARA_Anta_pred_neighbor(i,:)=COMPARA.model_AN.set.class_S(predAN.neighbors(i,:));
               else
                    res.CoMPARA_Anta_CAS_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Anta_InChiKey_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Anta_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.CoMPARA_Anta_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Anta_Exp_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Anta_pred_neighbor(i,:)=cell(1,5);
                end
                if res.AD_index_CoMPARA_Bind(i)~=0
                    res.CoMPARA_Bind_CAS_neighbor(i,:)=COMPARA.model_BD.CAS(predBD.neighbors(i,:));
                    res.CoMPARA_Bind_InChiKey_neighbor(i,:)=COMPARA.model_BD.InChiKey(predBD.neighbors(i,:));
                    res.CoMPARA_Bind_DTXSID_neighbor(i,:)=COMPARA.model_BD.DTXSID(predBD.neighbors(i,:));
                    %res.CoMPARA_Bind_DSSTOXMPID_neighbor(i,:)=COMPARA.model_BD.DSSTOXMPID(predBD.neighbors(i,:));
                    res.CoMPARA_Bind_Exp_neighbor(i,:)=COMPARA.model_BD.set.class_Exp(predBD.neighbors(i,:));
                    res.CoMPARA_Bind_pred_neighbor(i,:)=COMPARA.model_BD.set.class_S(predBD.neighbors(i,:));
                else
                    res.CoMPARA_Bind_CAS_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Bind_InChiKey_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Bind_DTXSID_neighbor(i,:)=cell(1,5);
                    %res.CoMPARA_Bind_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Bind_Exp_neighbor(i,:)=cell(1,5);
                    res.CoMPARA_Bind_pred_neighbor(i,:)=cell(1,5);
                end
            end
            
            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output(Locb(find(Locb))),'AG experimental= %s, AN experimental= %s, BD experimental= %s\n', res.CoMPARA_Ago_exp{i},res.CoMPARA_Anta_exp{i},res.CoMPARA_Bind_exp{i});
                end
                fprintf(output(Locb(find(Locb))),'AG predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CoMPARA_Ago_pred(i),res.AD_CoMPARA_Ago(i),res.AD_index_CoMPARA_Ago(i),res.Conf_index_CoMPARA_Ago(i));
                fprintf(output(Locb(find(Locb))),'AN predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CoMPARA_Anta_pred(i),res.AD_CoMPARA_Anta(i),res.AD_index_CoMPARA_Anta(i),res.Conf_index_CoMPARA_Anta(i));
                fprintf(output(Locb(find(Locb))),'BD category predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CoMPARA_Bind_pred(i),res.AD_CoMPARA_Bind(i),res.AD_index_CoMPARA_Bind(i),res.Conf_index_CoMPARA_Bind(i));
                
                if neighbors==1
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors (Agonist):%15s,%15s,%15s,%15s,%15s\n',COMPARA.model_AG.set.K, res.CoMPARA_Ago_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors (Antagonist):%15s,%15s,%15s,%15s,%15s\n',COMPARA.model_AN.set.K, res.CoMPARA_Anta_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors (Binding):%15s,%15s,%15s,%15s,%15s\n',COMPARA.model_BD.set.K, res.CoMPARA_Bind_CAS_neighbor{i,1:5});
                end
                
            elseif strcmpi(ext,'.txt') && sep==0
                
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'AG experimental= %s, AN experimental= %s, BD experimental= %s\n', res.CoMPARA_Ago_exp{i},res.CoMPARA_Anta_exp{i},res.CoMPARA_Bind_exp{i});
                end
                fprintf(output,'AG predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CoMPARA_Ago_pred(i),res.AD_CoMPARA_Ago(i),res.AD_index_CoMPARA_Ago(i),res.Conf_index_CoMPARA_Ago(i));
                fprintf(output,'AN predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CoMPARA_Anta_pred(i),res.AD_CoMPARA_Anta(i),res.AD_index_CoMPARA_Anta(i),res.Conf_index_CoMPARA_Anta(i));
                fprintf(output,'BD category predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CoMPARA_Bind_pred(i),res.AD_CoMPARA_Bind(i),res.AD_index_CoMPARA_Bind(i),res.Conf_index_CoMPARA_Bind(i));
                
                if neighbors==1
                    fprintf(output,'CAS of the %i nearest neighbors (Agonist):%15s,%15s,%15s,%15s,%15s\n',COMPARA.model_AG.set.K, res.CoMPARA_Ago_CAS_neighbor{i,1:5});
                    fprintf(output,'CAS of the %i nearest neighbors (Antagonist):%15s,%15s,%15s,%15s,%15s\n',COMPARA.model_AN.set.K, res.CoMPARA_Anta_CAS_neighbor{i,1:5});
                    fprintf(output,'CAS of the %i nearest neighbors (Binding):%15s,%15s,%15s,%15s,%15s\n',COMPARA.model_BD.set.K, res.CoMPARA_Bind_CAS_neighbor{i,1:5});
                end
                
            end
        end
        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                if exp
                    T{end+1:end+nf,2:5}=nan(nf,4);
                else
                    T{end+1:end+nf,1:4}=nan(nf,4);
                end
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                %Xtest=[XtestAG; XtestAN; XtestBD; XtestGHS; XtestLD50];
                Xtest=array2table(Xtest,'VariableNames',Desc);
                
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
            
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            %Xtest=[XtestAG; XtestAN; XtestBD; XtestGHS; XtestLD50];
            Xtest(:,ismember(Desc,DescNames))=[];
            Desc(ismember(Desc,DescNames))=[];
            DescNames=[DescNames Desc];
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.CoMPARA=res;
            clear('res');
            
        end
        % Clean memory
        clear('XinCDK_CoMPARA');
        clear('Xtest');
        clear('XtestAG');
        clear('XtestAN');
        clear('XtestBD');
        clear('predAG');
        clear('predAN');
        clear('predBD')
        clear('AD');
        clear('COMPARA');
        %end clean memory
    end
    
    %--------------------------------------------
    %Predict CATMoS endpoints
    %case {'CATMoS','AcuteTox'}
    [Lia,Locb] =ismember({'catmos','acutetox'},lower(prop));
    if find(Lia)
        if verbose>0
            disp('Predicting Acute Oral Tox. endpoints (CATMoS)...');
            if verbose>1
                disp('VT, NT, EPA, GHS & LD50 consensus models from the CATMoS project.');
            end
        end
        
        load ('OPERA_models.mat', '-mat','CATMOS');
        Desc=CATMOS.DescIn;

        if strcmpi(ext,'.txt') && sep==0
            fprintf(output,'\n\n\t\t\t\t\t Predicting CATMoS endpoints... \n\n			==============================================================  \n\n');
        end
        
        %             Xtest=zeros(size(Xin,1),length(Desc));
        %
        %             for i=1:length(Desc)
        %                 for l=1:length(Xin(1,:))
        %                     if strcmp(Desc(i),Xlabels(l))
        %                         Xtest(:,i)=Xin(:,l);
        %                         break;
        %                     end
        %                 end
        %             end
        
        %XlabelsCDK
        XinCDK_CATMoS=XinCDK(:,CATMOS.cdk_in);
        Xtest=[Xin(:,train.PadelVarIn(CATMOS.Padel_in)), XinCDK_CATMoS];
        
        XtestVT=Xtest(:,CATMOS.model_VT.DescVT_i);
        XtestNT=Xtest(:,CATMOS.model_NT.DescNT_i);
        XtestEPA=Xtest(:,CATMOS.model_EPA.DescEPA_i);
        XtestGHS=Xtest(:,CATMOS.model_GHS.DescGHS_i);
        XtestLD50=Xtest(:,CATMOS.model_LD50.DescLD50_i);
        
        %new data temp
%         XtestVT= [XtestVT XtestEPA XtestGHS XtestLD50];
%         XtestNT=XtestVT;
%         XtestEPA=XtestVT;
%         XtestGHS=XtestVT;
%         XtestLD50=XtestVT;
% 
%         train.CATMOS.model_VT.set.train=[train.CATMOS.model_VT.set.train train.CATMOS.model_EPA.set.train train.CATMOS.model_GHS.set.train train.CATMOS.model_LD50.set.train];
%         train.CATMOS.model_NT.set.train=train.CATMOS.model_VT.set.train;
%         train.CATMOS.model_EPA.set.train=train.CATMOS.model_VT.set.train;
%         train.CATMOS.model_GHS.set.train=train.CATMOS.model_VT.set.train;
%         train.CATMOS.model_LD50.set.train=train.CATMOS.model_VT.set.train;

        %new data temp end
        
        
        predVT = knnpred2(XtestVT,CATMOS.model_VT.set.train,CATMOS.model_VT.set.class,CATMOS.model_VT.set.class_Exp+1,CATMOS.model_VT.set.K,CATMOS.model_VT.set.dist_type,CATMOS.model_VT.set.param.pret_type);
        %predVT.D=diag(predVT.D);
        predVT.D=[];
        predNT = knnpred2(XtestNT,CATMOS.model_NT.set.train,CATMOS.model_NT.set.class,CATMOS.model_NT.set.class_Exp+1,CATMOS.model_NT.set.K,CATMOS.model_NT.set.dist_type,CATMOS.model_NT.set.param.pret_type);
        %predNT.D=diag(predNT.D);
        predNT.D=[];
        predEPA = knnpred2(XtestEPA,CATMOS.model_EPA.set.train,CATMOS.model_EPA.set.class,CATMOS.model_EPA.set.class_Exp,CATMOS.model_EPA.set.K,CATMOS.model_EPA.set.dist_type,CATMOS.model_EPA.set.param.pret_type);
        %predEPA.D=diag(predEPA.D);
        predEPA.D=[];
        predGHS = knnpred2(XtestGHS,CATMOS.model_GHS.set.train,CATMOS.model_GHS.set.class,CATMOS.model_GHS.set.class_Exp,CATMOS.model_GHS.set.K,CATMOS.model_GHS.set.dist_type,CATMOS.model_GHS.set.param.pret_type);
        %predGHS.D=diag(predGHS.D);
        predGHS.D=[];
        predLD50 = nnrpred2(XtestLD50,CATMOS.model_LD50.set.train,CATMOS.model_LD50.set.y,CATMOS.model_LD50.set.y_Exp_nAll,CATMOS.model_LD50.set.K,CATMOS.model_LD50.set.dist_type,CATMOS.model_LD50.set.param.pret_type);
        %predLD50.D=diag(predLD50.D);
        predLD50.D=[];
        
        %AD=classical_leverage(CATMOS.model.set.train,Xtest,'auto');
        
        res.MoleculeID=MoleculeNames;
%         if exp
%             res.CATMoS_VT_exp=NaN(size(Xtest,1),1);
%         end
        res.CATMoS_VT_pred(:,1)=predVT.class_pred-1;
        AD=classical_leverage(CATMOS.model_VT.set.train,XtestVT,'auto');
        res.AD_VT=abs(AD.inorout-1)';
        res.AD_index_VT=1-test_pretreatment(predVT.dc(:,1),CATMOS.model_VT.set.dc_param);
        res.AD_index_VT(find(res.AD_index_VT<0),1)=1./(1+predVT.dc(find(res.AD_index_VT<0),1));
        res.CATMoS_VT_pred(find(isnan(predVT.dc(:,1))))=NaN;
        res.AD_VT(find(isnan(predVT.dc(:,1))))=0;
        res.AD_index_VT(find(isnan(predVT.dc(:,1))))=0;
        res.AD_index_VT(find(res.AD_index_VT>0.9999),1)=1;
        res.AD_VT(find(res.AD_index_VT>0.5))=1;
        res.Conf_index_VT=zeros(size(XtestVT,1),1);
%         if exp
%             res.CATMoS_NT_exp=NaN(size(Xtest,1),1);
%         end
        res.CATMoS_NT_pred(:,1)=predNT.class_pred-1;
        AD=classical_leverage(CATMOS.model_NT.set.train,XtestNT,'auto');
        res.AD_NT=abs(AD.inorout-1)';
        res.AD_index_NT=1-test_pretreatment(predNT.dc(:,1),CATMOS.model_NT.set.dc_param);
        res.AD_index_NT(find(res.AD_index_NT<0),1)=1./(1+predNT.dc(find(res.AD_index_NT<0),1));
        res.CATMoS_NT_pred(find(isnan(predNT.dc(:,1))))=NaN;
        res.AD_NT(find(isnan(predNT.dc(:,1))))=0;
        res.AD_index_NT(find(isnan(predNT.dc(:,1))))=0;
        res.AD_index_NT(find(res.AD_index_NT>0.9999),1)=1;
        res.AD_NT(find(res.AD_index_NT>0.5))=1;
        res.Conf_index_NT=zeros(size(XtestNT,1),1);
%         if exp
%             res.CATMoS_EPA_exp=NaN(size(Xtest,1),1);
%         end
        res.CATMoS_EPA_pred(:,1)=predEPA.class_pred;
        AD=classical_leverage(CATMOS.model_EPA.set.train,XtestEPA,'auto');
        res.AD_EPA=abs(AD.inorout-1)';
        res.AD_index_EPA=1-test_pretreatment(predEPA.dc(:,1),CATMOS.model_EPA.set.dc_param);
        res.AD_index_EPA(find(res.AD_index_EPA<0),1)=1./(1+predEPA.dc(find(res.AD_index_EPA<0),1));
        res.CATMoS_EPA_pred(find(isnan(predEPA.dc(:,1))))=NaN;
        res.AD_EPA(find(isnan(predEPA.dc(:,1))))=0;
        res.AD_index_EPA(find(isnan(predEPA.dc(:,1))))=0;
        res.AD_index_EPA(find(res.AD_index_EPA>0.9999),1)=1;
        res.AD_EPA(find(res.AD_index_EPA>0.5))=1;
        res.Conf_index_EPA=zeros(size(XtestEPA,1),1);
%         if exp
%             res.CATMoS_GHS_exp=NaN(size(Xtest,1),1);
%         end
        res.CATMoS_GHS_pred(:,1)=predGHS.class_pred;
        AD=classical_leverage(CATMOS.model_GHS.set.train,XtestGHS,'auto');
        res.AD_GHS=abs(AD.inorout-1)';
        res.AD_index_GHS=1-test_pretreatment(predGHS.dc(:,1),CATMOS.model_GHS.set.dc_param);
        res.AD_index_GHS(find(res.AD_index_GHS<0),1)=1./(1+predGHS.dc(find(res.AD_index_GHS<0),1));
        res.CATMoS_GHS_pred(find(isnan(predGHS.dc(:,1))))=NaN;
        res.AD_GHS(find(isnan(predGHS.dc(:,1))))=0;
        res.AD_index_GHS(find(isnan(predGHS.dc(:,1))))=0;
        res.AD_index_GHS(find(res.AD_index_GHS>0.9999),1)=1;
        res.AD_GHS(find(res.AD_index_GHS>0.5))=1;
        res.Conf_index_GHS=zeros(size(XtestGHS,1),1);
        if exp
            %res.CATMoS_LD50_exp=NaN(size(Xtest,1),1);
            res.CATMoS_LD50_exp=cell(size(Xtest,1),1);
        end
        res.CATMoS_LD50_pred(:,1)=predLD50.y_pred_weighted;
        res.CATMoS_LD50_predRange=cell(size(Xtest,1),1);
        AD=classical_leverage(CATMOS.model_LD50.set.train,XtestLD50,'auto');
        res.AD_LD50=abs(AD.inorout-1)';
        res.AD_index_LD50=1-test_pretreatment(predLD50.dc(:,1),CATMOS.model_LD50.set.dc_param);
        res.AD_index_LD50(find(res.AD_index_LD50<0),1)=1./(1+predLD50.dc(find(res.AD_index_LD50<0),1));
        res.CATMoS_LD50_pred(find(isnan(predLD50.dc(:,1))))=NaN;
        res.AD_LD50(find(isnan(predLD50.dc(:,1))))=0;
        res.AD_index_LD50(find(isnan(predLD50.dc(:,1))))=0;
        res.AD_index_LD50(find(res.AD_index_LD50>0.9999),1)=1;
        res.AD_LD50(find(res.AD_index_LD50>0.5))=1;
        res.Conf_index_LD50=zeros(size(XtestLD50,1),1);
        
        for i=1:size(Xtest,1)
%             Li_vt=0;
%             Li_nt=0;
%             Li_epa=0;
%             Li_ghs=0;
            Li_ld50=0;
            if ~contains(MoleculeNames(i),'AUTOGEN_')
                if regexp(MoleculeNames{i},'[0-9]+-[0-9]+-[0-9]')
%                     [Li_vt,Lo_vt] = ismember(MoleculeNames(i),train.CATMOS.model_VT.CAS);
%                     [Li_nt,Lo_nt] = ismember(MoleculeNames(i),train.CATMOS.model_NT.CAS);
%                     [Li_epa,Lo_epa] = ismember(MoleculeNames(i),train.CATMOS.model_EPA.CAS);
%                     [Li_ghs,Lo_ghs] = ismember(MoleculeNames(i),train.CATMOS.model_GHS.CAS);
                    [Li_ld50,Lo_ld50] = ismember(MoleculeNames(i),CATMOS.model_LD50.CAS);
                elseif regexp(MoleculeNames{i},'DTXSID[0-9]+')
%                     [Li_vt,Lo_vt] = ismember(MoleculeNames{i},train.CATMOS.model_VT.DTXSID);
%                     [Li_nt,Lo_nt] = ismember(MoleculeNames{i},train.CATMOS.model_NT.DTXSID);
%                     [Li_epa,Lo_epa] = ismember(MoleculeNames{i},train.CATMOS.model_EPA.DTXSID);
%                     [Li_ghs,Lo_ghs] = ismember(MoleculeNames{i},train.CATMOS.model_GHS.DTXSID);
                    [Li_ld50,Lo_ld50] = ismember(MoleculeNames{i},CATMOS.model_LD50.DTXSID);
                end
%                 if Li_vt
%                     res.CATMoS_VT_exp(i,1)=train.CATMOS.model_VT.set.class_Exp(Lo_vt);
%                 end
%                 if Li_nt
%                     res.CATMoS_NT_exp(i,1)=train.CATMOS.model_NT.set.class_Exp(Lo_nt);
%                 end
%                 if Li_epa
%                     res.CATMoS_EPA_exp(i,1)=train.CATMOS.model_EPA.set.class_Exp(Lo_epa);
%                 end
%                 if Li_ghs
%                     res.CATMoS_GHS_exp(i,1)=train.CATMOS.model_GHS.set.class_Exp(Lo_ghs);
%                 end
                if Li_ld50
                    res.AD_VT(i)=1;
                    res.AD_index_VT(i,1)=1;
                    res.CATMoS_VT_pred(i,1)=CATMOS.model_VT.set.class(Lo_ld50)-1;
                    res.AD_NT(i)=1;
                    res.AD_index_NT(i,1)=1;
                    res.CATMoS_NT_pred(i,1)=CATMOS.model_NT.set.class(Lo_ld50)-1;
                    res.AD_EPA(i)=1;
                    res.AD_index_EPA(i,1)=1;
                    res.CATMoS_EPA_pred(i,1)=CATMOS.model_EPA.set.class(Lo_ld50);
                    res.AD_GHS(i)=1;
                    res.AD_index_GHS(i,1)=1;
                    res.CATMoS_GHS_pred(i,1)=CATMOS.model_GHS.set.class(Lo_ld50);
                    res.AD_LD50(i)=1;
                    res.AD_index_LD50(i,1)=1;
                    res.CATMoS_LD50_pred(i,1)=CATMOS.model_LD50.set.y(Lo_ld50);
                    if exp
                        res.CATMoS_LD50_exp(i,1)=CATMOS.model_LD50.set.y_Exp(Lo_ld50);
                    end
                else
                    if exp
                        res.CATMoS_LD50_exp(i,1)={'NA'};
                    end
                end
            end
            %res.AD_index_VT(i,1)=1./(1+predVT.dc(i,1)*predVT.w(i,~isnan(predVT.dc(i,1)))');
            
            res.Conf_index_VT(i,1)=(CATMOS.model_VT.conc_VT(predVT.neighbors(i,:),1)'*predVT.w(i,:)'+res.AD_index_VT(i))/2;
            if res.AD_index_VT(i)==0
                res.Conf_index_VT(i,1)=0;
            end
            res.Conf_index_NT(i,1)=(CATMOS.model_NT.conc_NT(predNT.neighbors(i,:),1)'*predNT.w(i,:)'+res.AD_index_NT(i))/2;
            if res.AD_index_NT(i)==0
                res.Conf_index_NT(i,1)=0;
            end
            res.Conf_index_EPA(i,1)=(CATMOS.model_EPA.conc_EPA(predEPA.neighbors(i,:),1)'*predEPA.w(i,:)'+res.AD_index_EPA(i))/2;
            if res.AD_index_EPA(i)==0
                res.Conf_index_EPA(i,1)=0;
            end
            res.Conf_index_GHS(i,1)=(CATMOS.model_GHS.conc_GHS(predGHS.neighbors(i,:),1)'*predGHS.w(i,:)'+res.AD_index_GHS(i))/2;
            if res.AD_index_GHS(i)==0
                res.Conf_index_GHS(i,1)=0;
            end
            res.Conf_index_LD50(i,1)=(CATMOS.model_LD50.conc_LD50(predLD50.neighbors(i,:),1)'*predLD50.w(i,:)'+res.AD_index_LD50(i))/2;
            if res.AD_index_LD50(i)==0
                res.Conf_index_LD50(i,1)=0;
            end
            
            %WOE corrections
            %res.CATMoS_LD50_pred_i(i,1)=10^res.CATMoS_LD50_pred(i);
            %res.CATMoS_LD50_range{i,1}='';
            res=woe_corr(res,i);
            %res.CATMoS_LD50_predRange{i,1}=strcat('[',num2str(floor(10^(res.CATMoS_LD50_pred(i)-0.3))),'-',num2str(ceil(10^(res.CATMoS_LD50_pred(i)+0.3))),']');
            if  res.CATMoS_LD50_pred(i)<=2.3
                res.CATMoS_LD50_predRange{i,1}=strcat('[',num2str(round(10^(res.CATMoS_LD50_pred(i)-0.3),1,'significant')),'-',num2str(round(10^(res.CATMoS_LD50_pred(i)+0.3),2,'significant')),']');
            else
                res.CATMoS_LD50_predRange{i,1}=strcat('[',num2str(round(10^(res.CATMoS_LD50_pred(i)-0.3),2,'significant')),'-',num2str(round(10^(res.CATMoS_LD50_pred(i)+0.3),2,'significant')),']');
            end
            if 10^(res.CATMoS_LD50_pred(i))>=5
                res.CATMoS_LD50_pred(i)=round(10^res.CATMoS_LD50_pred(i));
            else
                res.CATMoS_LD50_pred(i)=round(10^res.CATMoS_LD50_pred(i),2);
            end
            
            if Xin(i,12)==0
                res.AD_CATMoS(i)=0;
                res.AD_index_CATMoS(i)=res.AD_index_CATMoS(i)/2;
                res.Conf_index_CATMoS(i,1)=res.Conf_index_CATMoS(i,1)/2;
            end

            
            %neighbors
            if neighbors==1
%                 if res.AD_index_VT(i,:)~=0
%                     %res.VT_CATMoS_ID_neighbor(i,:)=train.CATMOS.model_VT.ChemID(predVT.neighbors(i,:));
%                     res.VT_CAS_neighbor(i,:)=train.CATMOS.model_VT.CAS(predVT.neighbors(i,:));
%                     res.VT_InChiKey_neighbor(i,:)=train.CATMOS.model_VT.InChiKey(predVT.neighbors(i,:));
%                     res.VT_DTXSID_neighbor(i,:)=train.CATMOS.model_VT.DTXSID(predVT.neighbors(i,:));
%                     %res.VT_DSSTOXMPID_neighbor(i,:)=train.CATMOS.model_VT.DSSTOXMPID(pred.neighbors(i,:));
%                     res.VT_Exp_neighbor(i,:)=train.CATMOS.model_VT.set.class_Exp(predVT.neighbors(i,:));
%                     res.VT_pred_neighbor(i,:)=train.CATMOS.model_VT.set.class(predVT.neighbors(i,:))-1;
%                 else
%                     res.VT_CAS_neighbor(i,:)=cell(1,5);
%                     res.VT_InChiKey_neighbor(i,:)=cell(1,5);
%                     res.VT_DTXSID_neighbor(i,:)=cell(1,5);
%                     %res.VT_DSSTOXMPID_neighbor(i,:)=cell(1,5);
%                     res.VT_Exp_neighbor(i,:)=nan(1,5);
%                     res.VT_pred_neighbor(i,:)=nan(1,5);
%                 end
%                 if res.AD_index_NT(i,:)~=0
%                     %res.NT_CATMoS_ID_neighbor(i,:)=train.CATMOS.model_NT.ChemID(predNT.neighbors(i,:));
%                     res.NT_CAS_neighbor(i,:)=train.CATMOS.model_NT.CAS(predNT.neighbors(i,:));
%                     res.NT_InChiKey_neighbor(i,:)=train.CATMOS.model_NT.InChiKey(predNT.neighbors(i,:));
%                     res.NT_DTXSID_neighbor(i,:)=train.CATMOS.model_NT.DTXSID(predNT.neighbors(i,:));
%                     %res.NT_DSSTOXMPID_neighbor(i,:)=train.CATMOS.model_NT.DSSTOXMPID(pred.neighbors(i,:));
%                     res.NT_Exp_neighbor(i,:)=train.CATMOS.model_NT.set.class_Exp(predNT.neighbors(i,:));
%                     res.NT_pred_neighbor(i,:)=train.CATMOS.model_NT.set.class(predNT.neighbors(i,:))-1;
%                 else
%                     res.NT_CAS_neighbor(i,:)=cell(1,5);
%                     res.NT_InChiKey_neighbor(i,:)=cell(1,5);
%                     res.NT_DTXSID_neighbor(i,:)=cell(1,5);
%                     %res.NT_DSSTOXMPID_neighbor(i,:)=cell(1,5);
%                     res.NT_Exp_neighbor(i,:)=nan(1,5);
%                     res.NT_pred_neighbor(i,:)=nan(1,5);
%                 end
%                 if res.AD_index_EPA(i,:)~=0
%                     %res.EPA_CATMoS_ID_neighbor(i,:)=train.CATMOS.model_EPA.ChemID(predEPA.neighbors(i,:));
%                     res.EPA_CAS_neighbor(i,:)=train.CATMOS.model_EPA.CAS(predEPA.neighbors(i,:));
%                     res.EPA_InChiKey_neighbor(i,:)=train.CATMOS.model_EPA.InChiKey(predEPA.neighbors(i,:));
%                     res.EPA_DTXSID_neighbor(i,:)=train.CATMOS.model_EPA.DTXSID(predEPA.neighbors(i,:));
%                     %res.EPA_DSSTOXMPID_neighbor(i,:)=train.CATMOS.model_EPA.DSSTOXMPID(predEPA.neighbors(i,:));
%                     res.EPA_Exp_neighbor(i,:)=train.CATMOS.model_EPA.set.class_Exp(predEPA.neighbors(i,:));
%                     res.EPA_pred_neighbor(i,:)=train.CATMOS.model_EPA.set.class(predEPA.neighbors(i,:));
%                 else
%                     res.EPA_CAS_neighbor(i,:)=cell(1,5);
%                     res.EPA_InChiKey_neighbor(i,:)=cell(1,5);
%                     res.EPA_DTXSID_neighbor(i,:)=cell(1,5);
%                     %res.EPA_DSSTOXMPID_neighbor(i,:)=cell(1,5);
%                     res.EPA_Exp_neighbor(i,:)=nan(1,5);
%                     res.EPA_pred_neighbor(i,:)=nan(1,5);
%                 end
%                 if res.AD_index_GHS(i,:)~=0
%                     %res.GHS_CATMoS_ID_neighbor(i,:)=train.CATMOS.model_GHS.ChemID(predGHS.neighbors(i,:));
%                     res.GHS_CAS_neighbor(i,:)=train.CATMOS.model_GHS.CAS(predGHS.neighbors(i,:));
%                     res.GHS_InChiKey_neighbor(i,:)=train.CATMOS.model_GHS.InChiKey(predGHS.neighbors(i,:));
%                     res.GHS_DTXSID_neighbor(i,:)=train.CATMOS.model_GHS.DTXSID(predGHS.neighbors(i,:));
%                     %res.GHS_DSSTOXMPID_neighbor(i,:)=train.CATMOS.model_GHS.DSSTOXMPID(pred.neighbors(i,:));
%                     res.GHS_Exp_neighbor(i,:)=train.CATMOS.model_GHS.set.class_Exp(predGHS.neighbors(i,:));
%                     res.GHS_pred_neighbor(i,:)=train.CATMOS.model_GHS.set.class(predGHS.neighbors(i,:));
%                 else
%                     res.GHS_CAS_neighbor(i,:)=cell(1,5);
%                     res.GHS_InChiKey_neighbor(i,:)=cell(1,5);
%                     res.GHS_DTXSID_neighbor(i,:)=cell(1,5);
%                     %res.GHS_DSSTOXMPID_neighbor(i,:)=cell(1,5);
%                     res.GHS_Exp_neighbor(i,:)=nan(1,5);
%                     res.GHS_pred_neighbor(i,:)=nan(1,5);
%                 end
%                 CATMOS.model_LD50.CAS=strrep(strrep(join(CATMOS.model_LD50.CAS,'|',2),'|||',''),'||','');
%                 CATMOS.model_LD50.DTXSID=strrep(strrep(join(CATMOS.model_LD50.DTXSID,'|',2),'|||',''),'||','');
                if res.AD_index_LD50(i,:)~=0
                    %res.LD50_CATMoS_ID_neighbor(i,:)=train.CATMOS.model_LD50.ChemID(predLD50.neighbors(i,:));
                    res.CAS_neighbor(i,:)=CATMOS.model_LD50.CAS(predLD50.neighbors(i,:));
                    res.InChiKey_neighbor(i,:)=CATMOS.model_LD50.InChiKey(predLD50.neighbors(i,:));
                    res.DTXSID_neighbor(i,:)=CATMOS.model_LD50.DTXSID(predLD50.neighbors(i,:));
                    %res.LD50_DSSTOXMPID_neighbor(i,:)=train.CATMOS.model_LD50.DSSTOXMPID(pred.neighbors(i,:));
                    res.LD50_Exp_neighbor(i,:)=CATMOS.model_LD50.set.y_Exp(predLD50.neighbors(i,:));
                    res.LD50_pred_neighbor(i,:)=round(10.^(CATMOS.model_LD50.set.y(predLD50.neighbors(i,:))),2);
                else
                    res.CAS_neighbor(i,:)=cell(1,5);
                    res.InChiKey_neighbor(i,:)=cell(1,5);
                    res.DTXSID_neighbor(i,:)=cell(1,5);
                    %res.LD50_DSSTOXMPID_neighbor(i,:)=cell(1,5);
                    res.LD50_Exp_neighbor(i,:)=cell(1,5);
                    res.LD50_pred_neighbor(i,:)=nan(1,5);
                end
            end

            if strcmpi(ext,'.txt') && sep==1
                %res.Xtest=Xtest;
                fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    %fprintf(output(Locb(find(Locb))),'LD50 experimental= %.3f\n', res.CATMoS_LD50_exp(i));
                    fprintf(output(Locb(find(Locb))),'LD50 experimental= %s\n', res.CATMoS_LD50_exp{i,1});
                end
%                 fprintf(output(Locb(find(Locb))),'VT predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_VT_pred(i),res.AD_VT(i),res.AD_index_VT(i),res.Conf_index_VT(i));
%                 fprintf(output(Locb(find(Locb))),'NT predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_NT_pred(i),res.AD_NT(i),res.AD_index_NT(i),res.Conf_index_NT(i));
%                 fprintf(output(Locb(find(Locb))),'EPA category predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_EPA_pred(i),res.AD_EPA(i),res.AD_index_EPA(i),res.Conf_index_EPA(i));
%                 fprintf(output(Locb(find(Locb))),'GHS category predicted= %i, AD: %i,AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_GHS_pred(i),res.AD_GHS(i),res.AD_index_GHS(i),res.Conf_index_GHS(i));
%                 fprintf(output(Locb(find(Locb))),'LD50 predicted= %.3f, AD: %i,AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_LD50_pred(i),res.AD_LD50(i),res.AD_index_LD50(i),res.Conf_index_LD50(i));
                fprintf(output(Locb(find(Locb))),'VT predicted= %i, NT predicted= %i, EPA category predicted= %i, GHS category predicted= %i, LD50 predicted= %.2f\n', res.CATMoS_VT_pred(i),...
                    res.CATMoS_NT_pred(i),res.CATMoS_EPA_pred(i),res.CATMoS_GHS_pred(i),res.CATMoS_LD50_pred(i));
                
                fprintf(output(Locb(find(Locb))),'AD: %i,AD_index= %.2f, Conf_index= %.2f\n',res.AD_CATMoS(i),res.AD_index_CATMoS(i),res.Conf_index_CATMoS(i));
                if neighbors==1
%                     fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_VT.set.K, res.VT_CAS_neighbor{i,1:5});
%                     fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_NT.set.K, res.NT_CAS_neighbor{i,1:5});
%                     fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_EPA.set.K, res.EPA_CAS_neighbor{i,1:5});
%                     fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_GHS.set.K, res.GHS_CAS_neighbor{i,1:5});
                    fprintf(output(Locb(find(Locb))),'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',CATMOS.model_LD50.set.K, res.CAS_neighbor{i,1:5});
                end

            elseif strcmpi(ext,'.txt') && sep==0
                fprintf(output,'\t Molecule %s:\n', MoleculeNames{i});
                if exp
                    fprintf(output,'LD50 experimental= %s\n',res.CATMoS_LD50_exp{i,1});
                end
%                 fprintf(output,'VT predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_VT_pred(i),res.AD_VT(i),res.AD_index_VT(i),res.Conf_index_VT(i));
%                 fprintf(output,'NT predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_NT_pred(i),res.AD_NT(i),res.AD_index_NT(i),res.Conf_index_NT(i));
%                 fprintf(output,'EPA category predicted= %i, AD: %i, AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_EPA_pred(i),res.AD_EPA(i),res.AD_index_EPA(i),res.Conf_index_EPA(i));
%                 fprintf(output,'GHS category predicted= %i, AD: %i,AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_GHS_pred(i),res.AD_GHS(i),res.AD_index_GHS(i),res.Conf_index_GHS(i));
%                 fprintf(output,'LD50 predicted= %.3f, AD: %i,AD_index= %.2f, Conf_index= %.2f\n', res.CATMoS_LD50_pred(i),res.AD_LD50(i),res.AD_index_LD50(i),res.Conf_index_LD50(i));
                fprintf(output,'VT predicted= %i, NT predicted= %i, EPA category predicted= %i, GHS category predicted= %i, LD50 predicted= %.2f\n',res.CATMoS_VT_pred(i),...
                    res.CATMoS_NT_pred(i),res.CATMoS_EPA_pred(i),res.CATMoS_GHS_pred(i),res.CATMoS_LD50_pred(i));
                
                fprintf(output,'AD: %i,AD_index= %.2f, Conf_index= %.2f\n',res.AD_CATMoS(i),res.AD_index_CATMoS(i),res.Conf_index_CATMoS(i));
                
                if neighbors==1
%                     fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_VT.set.K, res.VT_CAS_neighbor{i,1:5});
%                     fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_NT.set.K, res.NT_CAS_neighbor{i,1:5});
%                     fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_EPA.set.K, res.EPA_CAS_neighbor{i,1:5});
%                     fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',train.CATMOS.model_GHS.set.K, res.GHS_CAS_neighbor{i,1:5});
                    fprintf(output,'CAS of the %i nearest neighbors:%15s,%15s,%15s,%15s,%15s\n',CATMOS.model_LD50.set.K, res.CAS_neighbor{i,1:5});
                end
                
            end
        end
        
res=rmfield(res,{'AD_VT','AD_index_VT','Conf_index_VT','AD_NT','AD_index_NT','Conf_index_NT','AD_EPA','AD_index_EPA','Conf_index_EPA',...
   'AD_GHS','AD_index_GHS','Conf_index_GHS','AD_LD50','AD_index_LD50','Conf_index_LD50'});

        if nf>0 && strcmpi(ext,'.txt')
            if sep==1
                for i=(f+1):(f+nf)
                    fprintf(output(Locb(find(Locb))),'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output(Locb(find(Locb))),'\t FoundBy: %s\n\n', FoundBy{i});
                end
            elseif sep==0
                for i=(f+1):(f+nf)
                    fprintf(output,'\t Molecule %s:\n', res.MoleculeID{i});
                    fprintf(output,'\t FoundBy: %s\n\n', FoundBy{i});
                end
            end
        end
        if sep==1 && strcmpi(ext,'.csv')
            if nf>0
                res=rmfield(res,'MoleculeID');
                T=struct2table(res);
                T{end+1:end+nf,1:4}=nan(nf,4);
                %T{end-nf:end,1:4}(T{end-nf:end,1:4}==0)=nan;
                %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
                T=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) T]; 
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            else
                T=struct2table(res);
            end
            if printtDesc==1
                %Xtest=[XtestVT; XtestNT; XtestEPA; XtestGHS; XtestLD50];
                Xtest=array2table(Xtest,'VariableNames',Desc);
                %Xtest=array2table(XtestLD50);
                T=[T Xtest];
                res.Descriptors=Xtest;
            end
            writetable(T,FileOut{Locb(find(Locb))},'Delimiter',',');%,'QuoteStrings',true);
            fclose(output(Locb(find(Locb))));
            clear('T');
            
        elseif sep==0 && printtDesc==1 && strcmpi(ext,'.csv')
            if nf>0
                Xtest(end+1:end+nf,:)=nan(nf,size(Xtest,2));
            end
            %Xtest=[XtestVT; XtestNT; XtestEPA; XtestGHS; XtestLD50];
            Xtest(:,ismember(Desc,DescNames))=[];
            Desc(ismember(Desc,DescNames))=[];
            DescNames=[DescNames Desc];
            DescMat=[DescMat Xtest];
        end
        
        if sep==1
            resf.CATMoS=res;
            clear('res');
            
        end
        % Clean memory
        clear('XinCDK_CATMoS');
        clear('Xtest');
        clear('XtestVT');
        clear('XtestNT');
        clear('XtestEPA');
        clear('XtestGHS');
        clear('XtestLD50');
        clear('predVT');
        clear('predNT');
        clear('predEPA');
        clear('predGHS');
        clear('predLD50');
        clear('AD');
        clear('CATMOS');
        %end clean memory
    end
    %--------------------------------------------------------------------------
    
    if sep==0 && strcmpi(ext,'.csv')
        if nf>0
            res=rmfield(res,'MoleculeID');
            res=struct2table(res);
            if exp && (strcmpi('cerapp',prop(1))||strcmpi('cerapp',prop(1))||strcmpi('er',prop(1))||strcmpi('ar',prop(1)))
                res{end+1:end+nf,2:5}=nan(nf,4);
            else
                res{end+1:end+nf,1:4}=nan(nf,4);
            end
            %res{end+1:end+nf,1:4}=nan(nf,4);
            if neighbors==0 && ~any(ismember({'catmos','acutetox'},lower(prop)))&& ((~any(ismember({'cerapp','er','compara','ar'},lower(prop)))&&exp)|| (any(ismember({'cerapp','er','compara','ar'},lower(prop)))&&~exp))
                res{end-nf:end,:}(res{end-nf:end,:}==0)=nan;
            end
            %T{end-nf:end,find(isnumeric(T{end-nf:end,:}))};
            res=[array2table(MoleculeNames,'VariableNames',{'MoleculeID'}) array2table(FoundBy,'VariableNames',{'FoundBy'}) res];
        else
            res=struct2table(res);
        end
        if printtDesc==1
            
            DescMat=array2table(DescMat,'VariableNames',DescNames);
            res=[res DescMat];
        end
        writetable(res,FileOut,'Delimiter',',');%,'QuoteStrings',true);
        %fclose('all');
    end
    
    if sep==1
        res=resf;
        %res=0;
    end
    
    fclose('all');
    tElapsed = toc(timerAll);
    if verbose>0
        
        fprintf(1,'\n=============== End Of Calculation =============\n');
        fprintf('%i molecules predicted. Total process time: %s.\n', length(Xin(:,1)),duration(0,0,tElapsed));
    end
    
    if clean==1 && structure==1
        delete(InputDesc);
        %delete(strcat('PadelDesc_',StructureFile(1:length(StructureFile)-3),'.csv'));
        if verbose <2
            delete(PaDELlogfile);
        end
        if fp==1
            delete(InputDescFP);
            %delete('PadelFP.csv');
            if verbose <2
                delete(PaDELlogfileFP);
            end
        end
        if cdk==1
            delete(InputDescCDK);
            %delete('CDKDesc.csv');
            if verbose <2
                delete(CDKlogfile);
                delete(CDKerr);
            end
        end
    end
    
end


