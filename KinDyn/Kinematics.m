function [RB,RJ,RL,rB,rJ,rL,e,g]=Kinematics_urdf(R0,r0,qm,robot) %#codegen
%[RJ,RL,r,l,e,g,TEE]=Kinematics_serial_urdf(R0,r0,qm,robot)


%--- Number of links and joints ---%
n_links=robot.n_links;
n_joints=robot.n_joints;

%--- Homogeneous transformation matrices ---%
if not(isempty(coder.target)) %Only use during code generation (allowing symbolic computations)
    %Pre-allocate homogeneous transformations matrices
    TJ=zeros(4,4,n_joints);
    TL=zeros(4,4,n_links);
else
    %Create variables
    TJ=[];
    TL=[];
end


%--- Base link ---%
clink = robot.base_link;
T0=[R0,r0;zeros(1,3),1]*[clink.R,clink.s;zeros(1,3),1];
RB=T0(1:3,1:3);
rB=T0(1:3,4);

%--- Forward kinematics recursion ---%
%Obtain of joints and links kinematics
for n=1:length(clink.child_joint) 
    %Get child joint
    cjoint=robot.joints(clink.child_joint(n));
    % Forward Kinematics recursion
    [TJ,TL]=Kin_recursive(cjoint,robot,qm,T0,TJ,TL);
end

%--- Rotation matrices, translation, position and other geometry vectors ---%
if not(isempty(coder.target)) %Only use during code generation (allowing symbolic computations)
    %Pre-allocate rotation matrices, translation and position vectors
    RJ=zeros(3,3,n_joints);
    RL=zeros(3,3,n_links);
    rJ=zeros(3,n_joints);
    rL=zeros(3,n_links);
    %Pre-allocate rotation/sliding axis
    e=zeros(3,n_joints);
    %Pre-allocate other gemotery vectors
    g=zeros(3,n_joints);
end
%Format Rotation matrices, link positions, joint axis and other geometry
%vectors
%Joint associated quantities
for i=1:n_joints
    RJ(1:3,1:3,i)=TJ(1:3,1:3,i);
    rJ(1:3,i)=TJ(1:3,4,i);
    e(1:3,i)=RJ(1:3,1:3,i)*robot.joints(i).axis;
end
%Link associated quantities
for i=1:n_links
    RL(1:3,1:3,i)=TL(1:3,1:3,i);
    rL(1:3,i)=TL(1:3,4,i);
    g(1:3,i)=rL(1:3,i)-rJ(1:3,robot.links(i).parent_joint);
end


end

%--- Recursive function ---%
function [TJ,TL]=Kin_recursive(cjoint,robot,qm,T0,TJ,TL)

%Joint kinematics
if cjoint.parent_link==0
    %Parent link is base link
    TJ(1:4,1:4,cjoint.id)=T0*[cjoint.R,cjoint.s;zeros(1,3),1];
else
    %Transformation due to parent joint variable
    pjoint=robot.joints(robot.links(cjoint.parent_link).parent_joint);
    if strcmp(pjoint.type,'revolute')
        T_qm=[Euler_DCM(cjoint.axis,qm(pjoint.id)),zeros(3,1);zeros(1,3),1];
    elseif strcmp(cjoint.type,'prismatic')
        T_qm=[eye(3),pjoint.axis*qm(pjoint.id);zeros(1,3),1];
    else
        T_qm=[eye(3),zeros(3,1);zeros(1,3),1];
    end
    %Joint kinematics
    TJ(1:4,1:4,cjoint.id)=TJ(1:4,1:4,robot.links(cjoint.parent_link).parent_joint)*T_qm*[cjoint.R,cjoint.s;zeros(1,3),1];
end

%Transformation due to current joint variable
if strcmp(cjoint.type,'revolute')
    T_qm=[Euler_DCM(cjoint.axis,qm(cjoint.id)),zeros(3,1);zeros(1,3),1];
elseif strcmp(cjoint.type,'prismatic')
    T_qm=[eye(3),cjoint.axis*qm(cjoint.id);zeros(1,3),1];
else
    T_qm=[eye(3),zeros(3,1);zeros(1,3),1];
end

%Link Kinematics
clink=robot.links(cjoint.child_link);
TL(1:4,1:4,clink.id)=TJ(1:4,1:4,clink.parent_joint)*T_qm*[clink.R,clink.s;zeros(1,3),1];

%Forward recursive for rest of joints and links
for n=1:length(clink.child_joint)
    %Select child joint
    cjoint=robot.joints(clink.child_joint);
    %Recursive
    [TJ,TL]=Kin_recursive(cjoint,robot,qm,T0,TJ,TL); 
end

end