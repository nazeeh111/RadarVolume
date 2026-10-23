function render_point_targets(resultDir)
%RENDER_POINT_TARGETS Plot existing point_targets exports without rerunning them.
%   Run point_targets first, then pass its output directory. The figure uses
%   independently normalized magnitude and makes no hardware accuracy claim.
%   New PNG/SVG files are written beside the input MAT file; no overwrite.
inputs = fullfile(resultDir,'point-targets.mat');
pngPath = fullfile(resultDir,'focus.png');
svgPath = fullfile(resultDir,'focus.svg');
assert(exist(pngPath,'file')==0 && exist(svgPath,'file')==0, ...
    'Choose a result directory without existing focus.png or focus.svg.');
s = load(inputs,'volumes','x_mm','y_mm','z_mm','targets_mm');
assert(numel(s.volumes)==2 && isequal(size(s.targets_mm),[2 3]));
fig = figure('Visible','off','Color','w','Position',[100 100 1000 840]);
cleanup = onCleanup(@() close(fig)); %#ok<NASGU>
tiledlayout(2,2,'TileSpacing','compact','Padding','compact');
colors = [0.06 0.33 0.65; 0.65 0.18 0.38];
profiles = zeros(2,numel(s.z_mm));
for q = 1:2
    magnitude = abs(s.volumes{q});
    assert(all(isfinite(magnitude(:))) && max(magnitude(:))>0);
    target = s.targets_mm(q,:);
    [~,iz] = min(abs(s.z_mm-target(3)));
    [~,ix] = min(abs(s.x_mm-target(1)));
    [~,iy] = min(abs(s.y_mm-target(2)));
    slice = magnitude(:,:,iz);
    nexttile(q);
    imagesc(s.x_mm,s.y_mm,slice/max(slice(:)));
    axis image; axis xy; xlim([-32 32]); ylim([-32 32]);
    clim([0 1]); colormap(gray(256));
    xlabel('x (mm)'); ylabel('y (mm)');
    title(sprintf('Scene %d: target (%g, %g, %g) mm',q,target));
    colorbar;
    profiles(q,:) = reshape(magnitude(iy,ix,:),1,[]);
    profiles(q,:) = profiles(q,:)/max(profiles(q,:));
end
nexttile(3,[1 2]);
plot(s.z_mm,profiles(1,:),'-o','Color',colors(1,:),'LineWidth',1.8); hold on;
plot(s.z_mm,profiles(2,:),'-s','Color',colors(2,:),'LineWidth',1.8);
xlim([min(s.z_mm) max(s.z_mm)]); ylim([0 1.05]); grid on;
xlabel('Reconstruction depth (mm)'); ylabel('Normalized magnitude');
title('Focus at each target''s lateral position');
legend('Scene 1','Scene 2','Location','northeast');
sgtitle({'Two independent synthetic point scenes', ...
    'Top: magnitude at target depth. Each slice and depth curve normalized separately.'});
set(findall(fig,'Type','axes'),'FontSize',12);
exportgraphics(fig,pngPath,'Resolution',144);
print(fig,svgPath,'-dsvg');
end
