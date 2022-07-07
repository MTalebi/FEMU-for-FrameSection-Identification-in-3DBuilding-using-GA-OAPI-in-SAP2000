%% clean-up the workspace & command window
clear all;clc;close all;
% Author:
% Mohammad Talebi Kalaleh
% talebika@ualberta.ca
%% inputs
[ModelName,ModelDirectory,~] = uigetfile({'*.sdb'},'Select a <.sdb> SAP 23 File in folder for Updating'); 
[~,MeasuredDirectory,~] = uigetfile({'*.txt'},'Select a <.txt> File in folder for Measured Acc'); %time_col acc_point1_col acc_point2_col , ...
ProgramPath = "C:\Program Files\Computers and Structures\SAP2000 23\SAP2000.exe";
APIDLLPath = "C:\Program Files\Computers and Structures\SAP2000 23\SAP2000v1.dll";

Output_Sensor_Joints='Sensor_Points';

TH_LoadCase_Name='RHA_Earthquacke';
UseAllSectionsInAutoListMembers='No';%'Yes' or 'No'
InitialSectionsChangeRangeLB=-2; %with respect to Initial Sections
InitialSectionsChangeRangeUB=+2; %with respect to Initial Sections
ConsiderConstraintForBeams='Yes';
ConsiderConstraintForCols='Yes';

%% create API helper object, attach to a running instance of SAP & create SapModel object
a = NET.addAssembly(APIDLLPath);
helper = SAP2000v1.Helper;
helper = NET.explicitCast(helper,'SAP2000v1.cHelper');

SapObject = helper.GetObject('CSI.SAP2000.API.SapObject');
SapObject = NET.explicitCast(SapObject,'SAP2000v1.cOAPI');

helper = 0;
SapModel = NET.explicitCast(SapObject.SapModel,'SAP2000v1.cSapModel');

%% sap_etabs function generation for all interfaces
File = NET.explicitCast(SapModel.File,'SAP2000v1.cFile'); %Methods: OpenFile, Save  
LoadPatterns = NET.explicitCast(SapModel.LoadPatterns,'SAP2000v1.cLoadPatterns'); %Methods: Add, GetNameList, GetLoadType, GetAutoSeismicCode

Analyze=NET.explicitCast(SapModel.Analyze,'SAP2000v1.cAnalyze'); %Methods: RunAnalysis, SetRunCaseFlag, GetCaseStatus, GetRunCaseFlag
FrameObj=NET.explicitCast(SapModel.FrameObj,'SAP2000v1.cFrameObj'); %Methods: Count, GetLabelNameList, SetSection, GetSection, GetLabelFromName, GetNameListOnStory, GetDesignProcedure, GetPoints

PointObj=NET.explicitCast(SapModel.PointObj,'SAP2000v1.cPointObj'); %Methods: GetCoordCartesian, GetConnectivity
LoadCases=NET.explicitCast(SapModel.LoadCases,'SAP2000v1.cLoadCases'); %Methods: GetNameList, GetTypeOAPI_1, 
PropArea=NET.explicitCast(SapModel.PropArea,'SAP2000v1.cPropArea'); %Methods: Count, GetWall, GetNameList, SetWall, 
PropFrame=NET.explicitCast(SapModel.PropFrame,'SAP2000v1.cPropFrame'); %Methods: Count, GetAllFrameProperties, GetNameList, GetRebarColumn, SetISection, SetPipe, SetRectangle, SetRebarColumn, SetRebarBeam, SetTube, 
Group=NET.explicitCast(SapModel.GroupDef,'SAP2000v1.cGroup'); %Methods: GetNameList, GetAssignments, GetGroup 

AnalysisResults=NET.explicitCast(SapModel.Results,'SAP2000v1.cAnalysisResults'); %Methods: BaseReact, BaseReactWithCentroid, GeneralizedDispl, JointDrifts, ModalParticipatingMassRatios, ModalPeriod, StoryDrifts
AnalysisResultsSetup=NET.explicitCast(AnalysisResults.Setup,'SAP2000v1.cAnalysisResultsSetup'); %Methods: GetComboSelectedForOutput, SetCaseSelectedForOutput, SetComboSelectedForOutput, SetOptionModeShape
AreaObj=NET.explicitCast(SapModel.AreaObj,'SAP2000v1.cAreaObj'); %Methods: Count, GetLabelNameList, GetNameFromLabel, GetNameListOnStory, GetPier, GetRebarDataPier, GetRebarDataSpandrel, SetDiaphragm, SetLoadUniformToFrame, SetLoadUniform, SetModifiers, 
DirHistLinear=NET.explicitCast(LoadCases.DirHistLinear,'SAP2000v1.cCaseDirectHistoryLinear');
ModHistLinear=NET.explicitCast(LoadCases.ModHistLinear,'SAP2000v1.cCaseModalHistoryLinear');

ModalEigen = NET.explicitCast(LoadCases.ModalEigen,'SAP2000v1.cCaseModalEigen');
Select=NET.explicitCast(SapModel.SelectObj,'SAP2000v1.cSelect'); %Methods: All, Group, PreviousSelection, ClearSelection
%% Save As Model for Identification
ModelSaveAsPath = strcat(ModelDirectory,'Identified_', ModelName);
File.Save(ModelSaveAsPath);
SapModel.SetModelIsLocked(false);
SapModel.SetPresentUnits(SAP2000v1.eUnits.kgf_cm_C);

%% get frame names from model for each group of design
%get all beams tobe designed
[~,~,a]=FrameObj.GetNameList(0,cellstr(''));
Element_Name_GroupName(:,1)=cell(a)';
clear a

%% set groups of design
%assined autoselect for each frame
for i=1:size(Element_Name_GroupName,1)
    [~,~,a]=FrameObj.GetSection(cell2mat(Element_Name_GroupName(i,1)),'',''); %all elements must be assigned to autoselect
    Element_Name_GroupName(i,2)=cellstr(char(a));
    
end
Element_Name_GroupName=sortrows(Element_Name_GroupName,2);

%Number of all autoselect names assigned to frames
Count_Optimization_Groups=1;
Autoselect_List_Names(1,1)=Element_Name_GroupName(1,2);

[~,STPoint,ENDPoint]=FrameObj.GetPoints(Element_Name_GroupName{1,1},'','');
[~,x1,y1,z1]=PointObj.GetCoordCartesian(STPoint,0,0,0);
[~,x2,y2,z2]=PointObj.GetCoordCartesian(ENDPoint,0,0,0);
VecDir=[x2-x1,y2-y1,z2-z1]'; VecDir=VecDir/norm(VecDir);
if abs(VecDir'*[0;0;1])==0
    Autoselect_List_Names(Count_Optimization_Groups,2)={'Beam'};
elseif abs(VecDir'*[0;0;1])==1
    Autoselect_List_Names(Count_Optimization_Groups,2)={'Column'};
else
    Autoselect_List_Names(Count_Optimization_Groups,2)={'Brace'};
end
Autoselect_List_Names(Count_Optimization_Groups,3)={z2};


for i=2:size(Element_Name_GroupName,1)
    if ~strcmp(Element_Name_GroupName(i,2),Autoselect_List_Names(Count_Optimization_Groups,1))
        Count_Optimization_Groups=Count_Optimization_Groups+1;
        Autoselect_List_Names(Count_Optimization_Groups,1)=Element_Name_GroupName(i,2);
        [~,STPoint,ENDPoint]=FrameObj.GetPoints(Element_Name_GroupName{i,1},'','');
        [~,x1,y1,z1]=PointObj.GetCoordCartesian(STPoint,0,0,0);
        [~,x2,y2,z2]=PointObj.GetCoordCartesian(ENDPoint,0,0,0);
        VecDir=[x2-x1,y2-y1,z2-z1]'; VecDir=VecDir/norm(VecDir);
        if abs(VecDir'*[0;0;1])==0
            Autoselect_List_Names(Count_Optimization_Groups,2)={'Beam'};
        elseif abs(VecDir'*[0;0;1])==1
            Autoselect_List_Names(Count_Optimization_Groups,2)={'Column'};
        else
            Autoselect_List_Names(Count_Optimization_Groups,2)={'Brace'};
        end
        Autoselect_List_Names(Count_Optimization_Groups,3)={z2};


    end
end

%sorting by elevation : first beams after them columns
BeamsRows=find(strcmp(Autoselect_List_Names(:,2),{'Beam'}));
ColsRows=find(strcmp(Autoselect_List_Names(:,2),{'Column'}));
BRsRows=find(strcmp(Autoselect_List_Names(:,2),{'Brace'}));

Autoselect_List_Names=[sortrows(Autoselect_List_Names(BeamsRows',:),3);sortrows(Autoselect_List_Names(ColsRows',:),3);sortrows(Autoselect_List_Names(BRsRows',:),3)];
%% assign to be optimized frames to a group 

for i=1:Count_Optimization_Groups
    
    Group.SetGroup(Autoselect_List_Names{i,1});
    Frames_In_Group_Index=find(strcmp(Element_Name_GroupName(:,2),Autoselect_List_Names(i,1)));
    for j=1:size(Frames_In_Group_Index,1)
        FrameObj.SetGroupAssign(Element_Name_GroupName{Frames_In_Group_Index(j,1),1},Autoselect_List_Names{i,1});

    end
end

%% get frame section groups from auto select lists and Initial Section assigend to The Frames for starting optimization (X0)
Autoselect_Name_Sections=struct;
for i=1:size(Autoselect_List_Names,1)
    [~,~,a,b] = PropFrame.GetAutoSelectSteel(Autoselect_List_Names{i,1},0,cellstr(''),'','','');
    aa=cell(a)'; bb=char(b);
    for j=1:size(aa,1)
        [~,Sec_Area]=PropFrame.GetSectProps(aa{j,1},0,0,0,0,0,0,0,0,0,0,0,0);
        aa(j,2)={Sec_Area};
    end
    
    aa=sortrows(aa,2);
    Group_Initial_Section_Number(i,1)=find(strcmp(aa(:,1),bb));
    Group_UperBand(i,1)=size(aa,1);
    
    Autoselect_Name_Sections.(Autoselect_List_Names{i,1})=aa(:,1);
    clear a aa b bb
end


%% Nvariables lowerband and upperband and initial x
nvars=Count_Optimization_Groups;

x0=Group_Initial_Section_Number';

if strcmp(UseAllSectionsInAutoListMembers,'Yes')
    lb=ones(1,nvars);
    ub=Group_UperBand';
    
else
    lb=x0+InitialSectionsChangeRangeLB;
    lb(lb<=0)=1;
    
    ub=x0+InitialSectionsChangeRangeUB;  
    
    for i=1:nvars
        if ub(1,i)>Group_UperBand(i,1)
            ub(1,i)=Group_UperBand(i,1);
        end
    end
end

IntCon=1:nvars;% all variables are integer

%% load case for analysis and result
AnalysisResultsSetup.DeselectAllCasesAndCombosForOutput;
AnalysisResultsSetup.SetCaseSelectedForOutput(TH_LoadCase_Name);
AnalysisResultsSetup.SetOptionDirectHist(2);
AnalysisResultsSetup.SetOptionModalHist(2);

[~,~,Load_Case_Names]=LoadCases.GetNameList_1(0,cellstr(''));
Load_Case_Names=cell(Load_Case_Names)';
for i=1:size(Load_Case_Names,1)
    Analyze.SetRunCaseFlag(Load_Case_Names{i,1},false);
end
Analyze.SetRunCaseFlag(TH_LoadCase_Name,true);
Analyze.SetRunCaseFlag('MODAL',true);

%% Measured Accs for Sensor Points?
%sensor points in Sap2000 model must be assigned to group Output_Sensor_Joints
[~,~,~,Sensor_Points]=Group.GetAssignments(Output_Sensor_Joints,0,1,cellstr(''));
Sensor_Points=cell(Sensor_Points)';
for i=1:size(Sensor_Points,1)
    acc=dlmread([MeasuredDirectory,'Point',char(Sensor_Points(i,1)),'.txt']);
    Acc_Measured_Time.(['Point',char(Sensor_Points(i,1))])=acc;

end

%% optimization
tic
% GA

fun=@(x) Objective_Fun(x,Autoselect_Name_Sections,Autoselect_List_Names,Output_Sensor_Joints,Sensor_Points,Acc_Measured_Time,FrameObj,Analyze,AnalysisResults,SapModel);
nonlcon = @(x) Constraint(x,Autoselect_List_Names,Autoselect_Name_Sections,ConsiderConstraintForBeams,ConsiderConstraintForCols,PropFrame,SapModel);
%nonlcon(x0)
options=optimoptions('ga','InitialPopulationMatrix',x0,'MaxGenerations',10,'PopulationSize',10,'ConstraintTolerance',1e-6,'PlotFcn', @gaplotbestf,'Display','iter');
x_min=ga(fun,nvars,[],[],[],[],lb,ub,nonlcon,IntCon,options);
%xmin=[5 3 9 4]
ResponseEstimationError=fun(x_min)
RunTime=toc

%% Compare Results plot
[~,~,~,Point_Names,~,~,Time_Result,ACC_X,ACC_Y,~,~,~,~]=AnalysisResults.JointAcc(Output_Sensor_Joints,SAP2000v1.eItemTypeElm.GroupElm,0,cellstr(''),cellstr(''),cellstr(''),cellstr(''),0,0,0,0,0,0,0);
Point_Names=cell(Point_Names)'; Time_Result=double(Time_Result)';ACC_X=double(ACC_X)';ACC_Y=double(ACC_Y)';
for i=1:size(Sensor_Points,1)
    indix_Result_Point=find(strcmp(Point_Names(:,1),Sensor_Points(i,1)));
    Acc_Model_Time.(['Point',char(Sensor_Points(i,1))])=[Time_Result(indix_Result_Point,1),ACC_X(indix_Result_Point,1),ACC_Y(indix_Result_Point,1)];
end
 
for i=1:size(Sensor_Points,1)
    acc_model=Acc_Model_Time.(['Point',char(Sensor_Points(i,1))]);
    acc_measured=Acc_Measured_Time.(['Point',char(Sensor_Points(i,1))]);
    figure;
    subplot(2,1,1);plot(acc_measured(:,1),acc_measured(:,2),'-','color','r','DisplayName','Measured');hold on; grid on;
    plot(acc_model(:,1),acc_model(:,2),'--','color','b','DisplayName','SAPEstimated'); hold off;
    title(['X Acc for Sensor Point Number ',Sensor_Points{i,1}]);
    legend; xlabel('Time (sec)'); ylabel('Acc (cm/s^2)')

    subplot(2,1,2);plot(acc_measured(:,1),acc_measured(:,3),'-','color','r','DisplayName','Measured');hold on; grid on;
    plot(acc_model(:,1),acc_model(:,3),'--','color','b','DisplayName','SAPEstimated'); hold off;
    title(['Y Acc for Sensor Point Number ',Sensor_Points{i,1}]);
    legend; xlabel('Time (sec)'); ylabel('Acc (cm/s^2)')
end

