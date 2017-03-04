function Vel_Test(robot,Variables)
%This function test the Inverse Dynamics recursive functions by comparing them to the solutions obtained by H*qddot+C*qdot=tau+J'w.

%--- Assign variables ---%
%Base position
R0=eye(3);%Variables.R0;
r0=zeros(3,1);%Variables.r0;

%Joint variables
qm=Variables.qm;

%Velocities
q0dot=Variables.q0dot;
qmdot=Variables.qmdot;

%--- Compute NOC and velocities ---%
%Kinematics
[RJ,RL,rJ,rL,e,g]=Kinematics(R0,r0,qm,robot);
%Differential Kinematics
[Bij,Bi0,P0,pm]=DiffKinematics(R0,r0,rL,e,g,robot);
%Jacobians (in the form of NOC)
[N] = NOC(r0,rL,P0,pm,robot);
%Velocities from NOC
t_NOC=N*[q0dot;qmdot];


%--- Velocities ---%
[t0,tm]=Velocities(Bij,Bi0,P0,pm,q0dot,qmdot,robot);

%Test
test=abs(t_NOC-[t0;tm(:)])<1e-6;
assert(all(test(:)));

end


