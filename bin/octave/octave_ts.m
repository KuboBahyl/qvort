%read in the ts file and plot various dignostic information
%if given the option print will print to .eps file rather than screen
function octave_ts(option)
if nargin==0     
  option='empty';
end
switch option
case 'print'
  disp('will not print to screen but instead to .eps files')
case 'empty'
  otherwise
  disp('incorrect option, aborting script and printing help:')
  help ts
  return
end
A=load('./data/ts.log');
t=A(:,2) ; pcount=A(:,3) ; rcount=A(:,4) ; sep=A(:,5) ; l=A(:,6) ; 
maxu=A(:,7) ; maxdu=A(:,8) ; eval=A(:,9) ; curv=A(:,10) ;
rmcount=A(:,11) ;
switch option
  case 'print'
    figure('visible','off');
  otherwise
    figure('Name', 'filament information')      
end
  subplot(2,2,1)
    plot(t,pcount,'-r','LineWidth',2);
    set(gca,'FontSize',14)
    xlabel('t','FontSize',14)
    ylabel('pcount','FontSize',14)
  subplot(2,2,2)
    plot(t,rcount,'-b','LineWidth',2);
    set(gca,'FontSize',14)
    xlabel('t','FontSize',14)
    ylabel('recon count','FontSize',14)
  subplot(2,2,3)
    plot(t,sep,'-m','LineWidth',2);
    set(gca,'FontSize',14)
    xlabel('t','FontSize',14)
    ylabel('avg sep','FontSize',14)
  subplot(2,2,4)
    plot(t,l,'-g','LineWidth',2);
    set(gca,'FontSize',14)
    xlabel('t','FontSize',14)
    ylabel('L','FontSize',14)
if option=='print'
    disp('printing to filament_information.eps')
    print('-depsc','./filament_information.eps')
end
switch option
  case 'print'
    figure('visible','off');
  otherwise
    figure('Name', 'velocity information')      
end
  subplot(2,1,1)
    plot(t,maxu,'-b','LineWidth',2);
    set(gca,'FontSize',14)
    xlabel('t','FontSize',14)
    ylabel('max(u)','FontSize',14)
  subplot(2,1,2)
    plot(t,maxdu,'-r','LineWidth',2);
    set(gca,'FontSize',14)
    xlabel('t','FontSize',14)
    ylabel('max(du)','FontSize',14)
if option=='print'
  disp('printing to velocity_information.eps')
  print('-depsc','./velocity_information.eps')
end
if std(eval)>0.
  figure('Name', 'evalations (per particle) required')
    plot(t,eval,'-m','LineWidth',2);
    set(gca,'FontSize',14)
    xlabel('t','FontSize',14)
    ylabel('evaluations','FontSize',14)
end
switch option
  case 'print'
    figure('visible','off');
  otherwise
    figure('Name', 'mean curvature')      
end
  plot(t,curv,'-m','LineWidth',2);
  set(gca,'FontSize',14);
  xlabel('t','FontSize',14);
  ylabel('curv','FontSize',14);
if option=='print'
  disp('printing to mean_curvature.eps')
  print('-depsc','./mean_curvature.eps')
end
switch option
  case 'print'
    figure('visible','off');
  otherwise
    figure('Name', 'removed count')      
end
  plot(t,rmcount,'-k','LineWidth',2);
  set(gca,'FontSize',14);
  xlabel('t','FontSize',14);
  ylabel('rm count','FontSize',14);
if option=='print'
  disp('printing to rm_count.eps')
  print('-depsc','./rm_count.eps')
end
if exist('data/par_ts.log');
   B=load('data/par_ts.log');
   t=B(:,2) ; pmaxu=B(:,3) ; pmaxdu=B(:,4) ; purms=B(:,5) ; psep=B(:,6) ;
   switch option
     case 'print'
       figure('visible','off');
     otherwise
       figure('Name', 'particle information')      
   end
   subplot(2,2,1)
    plot(t,pmaxu,'-c','LineWidth',2);
    set(gca,'FontSize',14)
      xlabel('t','FontSize',14)
      ylabel('max u','FontSize',14)
      subplot(2,2,2)
    plot(t,pmaxdu,'-r','LineWidth',2);
      set(gca,'FontSize',14)
      xlabel('t','FontSize',14)
      ylabel('max du/dt','FontSize',14)
      subplot(2,2,3)
    plot(t,purms,'-y','LineWidth',2);
      set(gca,'FontSize',14)
      xlabel('t','FontSize',14)
      ylabel('urms','FontSize',14)
    subplot(2,2,4)
      plot(t,psep,'-g','LineWidth',2);
      set(gca,'FontSize',14)
      xlabel('t','FontSize',14)
      ylabel('particle sep.','FontSize',14)
      if option=='print'
        disp('printing to particle_information.eps')
        print('-depsc','./particle_information.eps')
      end
 end
 if exist('data/qp_ts.log');
   C=load('data/qp_ts.log');
   t=C(:,2) ; qpmaxu=C(:,3) ; qpmaxpdot=C(:,4) ; qpurms=C(:,5) ; 
   switch option
     case 'print'
       figure('visible','off');
     otherwise
       figure('Name', 'quasi particle information')      
   end
   subplot(2,2,1)
      plot(t,qpmaxu,'-c','LineWidth',2);
      set(gca,'FontSize',14)
      xlabel('t','FontSize',14)
      ylabel('max u','FontSize',14)
    subplot(2,2,2)
      plot(t,qpmaxpdot,'-r','LineWidth',2);
      set(gca,'FontSize',14)
      xlabel('t','FontSize',14)
      ylabel('max dp/dt','FontSize',14)
    subplot(2,2,3)
      plot(t,qpurms,'-y','LineWidth',2);
      set(gca,'FontSize',14)
      xlabel('t','FontSize',14)
      ylabel('urms','FontSize',14)
      if option=='print'
        disp('printing to quasi_information.eps')
        print('-depsc','./quasi_information.eps')
      end
 end
