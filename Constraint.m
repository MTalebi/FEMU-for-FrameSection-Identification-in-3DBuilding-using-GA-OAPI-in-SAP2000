function [c,ceq]=Constraint(x,Autoselect_List_Names,Autoselect_Name_Sections,ConsiderConstraintForBeams,ConsiderConstraintForCols,PropFrame,SapModel)
    Costraint_Tol=1e-3; ceq=[];
    SapModel.SetModelIsLocked(false);
    CountConst=0;
    BeamsRows=find(strcmp(Autoselect_List_Names(:,2),{'Beam'}));
    ColsRows=find(strcmp(Autoselect_List_Names(:,2),{'Column'}));

    if strcmp(ConsiderConstraintForBeams,'Yes')    
        for j=1:size(BeamsRows,1)-1
                CountConst=CountConst+1;
                FrameSection_Name1=Autoselect_Name_Sections.(Autoselect_List_Names{BeamsRows(j,1),1}){x(BeamsRows(j,1)),1};
                FrameSection_Name2=Autoselect_Name_Sections.(Autoselect_List_Names{BeamsRows(j+1,1),1}){x(BeamsRows(j+1,1)),1};
                [~,Sec_Area1]=PropFrame.GetSectProps(FrameSection_Name1,0,0,0,0,0,0,0,0,0,0,0,0);
                [~,Sec_Area2]=PropFrame.GetSectProps(FrameSection_Name2,0,0,0,0,0,0,0,0,0,0,0,0);
                
                c(CountConst,1)=(Sec_Area2 - Sec_Area1)/Sec_Area1;
        end
    end
    if strcmp(ConsiderConstraintForCols,'Yes')    
        for j=1:size(ColsRows,1)-1
                CountConst=CountConst+1;
                FrameSection_Name1=Autoselect_Name_Sections.(Autoselect_List_Names{ColsRows(j,1),1}){x(ColsRows(j,1)),1};
                FrameSection_Name2=Autoselect_Name_Sections.(Autoselect_List_Names{ColsRows(j+1,1),1}){x(ColsRows(j+1,1)),1};
                [~,Sec_Area1]=PropFrame.GetSectProps(FrameSection_Name1,0,0,0,0,0,0,0,0,0,0,0,0);
                [~,Sec_Area2]=PropFrame.GetSectProps(FrameSection_Name2,0,0,0,0,0,0,0,0,0,0,0,0);
                
                c(CountConst,1)=(Sec_Area2 - Sec_Area1)/Sec_Area1;
        end
    end
    
    c = c - Costraint_Tol;
end