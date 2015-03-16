
function [E,g,H] = myAffineObjective3DwithHessian(p,I,J,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Objective function for 3D Affine Transform  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% inputs - p,I,J                                                        %%
%% optional - dJ/dy,dJ/dx,dJ/dz                                          %%
%% p - 12 x 1 parameter vector                                           %%
%% I - fixed image                                                       %%
%% J - moving image                                                      %%
%% dJ/dy - gradient of moving image in y direction                       %%
%% dJ/dx - gradient of moving image in x direction                       %%
%% dJ/dz - gradient of moving image in z direction                       %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% outputs - E,g,H                                                       %%
%% E - value of the objective function                                   %%
%% g - gradient of the objective function                                %%
%% H - Hessian of the objective function                                 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if number of arguments are between 3 and 6 
minarg = 3;
maxarg = 6;
narginchk(minarg, maxarg);
    
A = reshape(p(1:9),[3,3]);
b = p(10:12);

% coordinates of voxels in fixed image    
[x, y, z] = ndgrid(1:1:size(I,1),1:1:size(I,2),1:1:size(I,3));
    
X = transpose([x(:) y(:) z(:)]);

b_rep = repmat(b, 1, numel(x));

% transformation parameters
phi = A*X + b_rep;

phi_x = phi(1,:);
phi_y = phi(2,:);
phi_z = phi(3,:);

phi_x = reshape(phi_x, size(I));
phi_y = reshape(phi_y, size(I));
phi_z = reshape(phi_z, size(I));

% resample moving image
data = my_interp3_precompute(size(I), phi_x, phi_y, phi_z);
J_t = my_interp3(J,data);

% J_t = interpn(J,phi_x,phi_y,phi_z,'linear',0);

% compute the difference image
diff_image = I - J_t;

% compute the value of the objective function
E = sum(sum(sum(diff_image.^2)));

% compute gradient of resampled image
if (nargin == 6 && ~isempty(varargin{1}) && ~isempty(varargin{2}) && ~isempty(varargin{3}))
    dJdy = varargin{1};
    dJdx = varargin{2};
    dJdz = varargin{3};
else
    [dJdy, dJdx, dJdz] = gradient(J);
end

dJdx_phi = my_interp3(dJdx,data);
dJdy_phi = my_interp3(dJdy,data);
dJdz_phi = my_interp3(dJdz,data);

% dJdx_phi = interpn(dJdx,phi_x,phi_y,phi_z,'linear',0);
% dJdy_phi = interpn(dJdy,phi_x,phi_y,phi_z,'linear',0);
% dJdz_phi = interpn(dJdz,phi_x,phi_y,phi_z,'linear',0);

% compute partial derivative of E w.r.t. p
g = [-2*sum(sum(sum(diff_image.*dJdx_phi.*x)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*x)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*x)));
    -2*sum(sum(sum(diff_image.*dJdx_phi.*y)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*y)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*y)));
    -2*sum(sum(sum(diff_image.*dJdx_phi.*z)));
    -2*sum(sum(sum(diff_image.*dJdy_phi.*z)));
    -2*sum(sum(sum(diff_image.*dJdz_phi.*z)));
    -2*sum(sum(sum(diff_image.*dJdx_phi)));
    -2*sum(sum(sum(diff_image.*dJdy_phi)));
    -2*sum(sum(sum(diff_image.*dJdz_phi)))];

% compute 2nd order partial derivatives
[Jxy, Jxx, Jxz] = gradient(dJdx);
[Jyy, Jyx, Jyz] = gradient(dJdy);
[Jzy, Jzx, Jzz] = gradient(dJdz);

Jxx_phi = my_interp3(Jxx,data);
Jxy_phi = my_interp3(Jxy,data);
Jxz_phi = my_interp3(Jxz,data);
Jyx_phi = my_interp3(Jyx,data);
Jyy_phi = my_interp3(Jyy,data);
Jyz_phi = my_interp3(Jyz,data);
Jzx_phi = my_interp3(Jzx,data);
Jzy_phi = my_interp3(Jzy,data);
Jzz_phi = my_interp3(Jzz,data);

% compute Hessian of E w.r.t. p
H = zeros(12,12);

H(1,:) = [-2*(sum(sum(sum(-(dJdx_phi.*x).^2 + diff_image.*Jxx_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdx_phi.*x + diff_image.*Jxy_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdx_phi.*x + diff_image.*Jxz_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdx_phi.*x + diff_image.*Jxx_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdx_phi.*x + diff_image.*Jxy_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdx_phi.*x + diff_image.*Jxz_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdx_phi.*x + diff_image.*Jxx_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdx_phi.*x + diff_image.*Jxy_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdx_phi.*x + diff_image.*Jxz_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi.*x + diff_image.*Jxx_phi.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi.*x + diff_image.*Jxy_phi.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi.*x + diff_image.*Jxz_phi.*x))))];

H(2,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdy_phi.*x + diff_image.*Jyx_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-(dJdy_phi.*x).^2 + diff_image.*Jyy_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdy_phi.*x + diff_image.*Jyz_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdy_phi.*x + diff_image.*Jyx_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdy_phi.*x + diff_image.*Jyy_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdy_phi.*x + diff_image.*Jyz_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdy_phi.*x + diff_image.*Jyx_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdy_phi.*x + diff_image.*Jyy_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdy_phi.*x + diff_image.*Jyz_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi.*x + diff_image.*Jyx_phi.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi.*x + diff_image.*Jyy_phi.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi.*x + diff_image.*Jyz_phi.*x))))];

H(3,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdz_phi.*x + diff_image.*Jzx_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdz_phi.*x + diff_image.*Jzy_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-(dJdz_phi.*x).^2 + diff_image.*Jzz_phi.*(x.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdz_phi.*x + diff_image.*Jzx_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdz_phi.*x + diff_image.*Jzy_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdz_phi.*x + diff_image.*Jzz_phi.*x.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdz_phi.*x + diff_image.*Jzx_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdz_phi.*x + diff_image.*Jzy_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdz_phi.*x + diff_image.*Jzz_phi.*x.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi.*x + diff_image.*Jzx_phi.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi.*x + diff_image.*Jzy_phi.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi.*x + diff_image.*Jzz_phi.*x))))];

H(4,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdx_phi.*y + diff_image.*Jxx_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdx_phi.*y + diff_image.*Jxy_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdx_phi.*y + diff_image.*Jxz_phi.*y.*x)))),...
    -2*(sum(sum(sum(-(dJdx_phi.*y).^2 + diff_image.*Jxx_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdx_phi.*y + diff_image.*Jxy_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdx_phi.*y + diff_image.*Jxz_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdx_phi.*y + diff_image.*Jxx_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdx_phi.*y + diff_image.*Jxy_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdx_phi.*y + diff_image.*Jxz_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi.*y + diff_image.*Jxx_phi.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi.*y + diff_image.*Jxy_phi.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi.*y + diff_image.*Jxz_phi.*y))))];

H(5,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdy_phi.*y + diff_image.*Jyx_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdy_phi.*y + diff_image.*Jyy_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdy_phi.*y + diff_image.*Jyz_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdy_phi.*y + diff_image.*Jyx_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-(dJdy_phi.*y).^2 + diff_image.*Jyy_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdy_phi.*y + diff_image.*Jyz_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdy_phi.*y + diff_image.*Jyx_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdy_phi.*y + diff_image.*Jyy_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdy_phi.*y + diff_image.*Jyz_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi.*y + diff_image.*Jyx_phi.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi.*y + diff_image.*Jyy_phi.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi.*y + diff_image.*Jyz_phi.*y))))];

H(6,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdz_phi.*y + diff_image.*Jzx_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdz_phi.*y + diff_image.*Jzy_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdz_phi.*y + diff_image.*Jzz_phi.*y.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdz_phi.*y + diff_image.*Jzx_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdz_phi.*y + diff_image.*Jzy_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdz_phi.*y + diff_image.*Jzz_phi.*(y.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdz_phi.*y + diff_image.*Jzx_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdz_phi.*y + diff_image.*Jzy_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdz_phi.*y + diff_image.*Jzz_phi.*y.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi.*y + diff_image.*Jzx_phi.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi.*y + diff_image.*Jzy_phi.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi.*y + diff_image.*Jzz_phi.*y))))];

H(7,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdx_phi.*z + diff_image.*Jxx_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdx_phi.*z + diff_image.*Jxy_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdx_phi.*z + diff_image.*Jxz_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdx_phi.*z + diff_image.*Jxx_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdx_phi.*z + diff_image.*Jxy_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdx_phi.*z + diff_image.*Jxz_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdx_phi.*z + diff_image.*Jxx_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdx_phi.*z + diff_image.*Jxy_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdx_phi.*z + diff_image.*Jxz_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi.*z + diff_image.*Jxx_phi.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi.*z + diff_image.*Jxy_phi.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi.*z + diff_image.*Jxz_phi.*z))))];

H(8,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdy_phi.*z + diff_image.*Jyx_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdy_phi.*z + diff_image.*Jyy_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdy_phi.*z + diff_image.*Jyz_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdy_phi.*z + diff_image.*Jyx_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdy_phi.*z + diff_image.*Jyy_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdy_phi.*z + diff_image.*Jyz_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdy_phi.*z + diff_image.*Jyx_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdy_phi.*z + diff_image.*Jyy_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdy_phi.*z + diff_image.*Jyz_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi.*z + diff_image.*Jyx_phi.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi.*z + diff_image.*Jyy_phi.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi.*z + diff_image.*Jyz_phi.*z))))];

H(9,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdz_phi.*z + diff_image.*Jzx_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdz_phi.*z + diff_image.*Jzy_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdz_phi.*z + diff_image.*Jzz_phi.*z.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdz_phi.*z + diff_image.*Jzx_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdz_phi.*z + diff_image.*Jzy_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdz_phi.*z + diff_image.*Jzz_phi.*z.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdz_phi.*z + diff_image.*Jzx_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdz_phi.*z + diff_image.*Jzy_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdz_phi.*z + diff_image.*Jzz_phi.*(z.^2))))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi.*z + diff_image.*Jzx_phi.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi.*z + diff_image.*Jzy_phi.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi.*z + diff_image.*Jzz_phi.*z))))];

H(10,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdx_phi + diff_image.*Jxx_phi.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdx_phi + diff_image.*Jxy_phi.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdx_phi + diff_image.*Jxz_phi.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdx_phi + diff_image.*Jxx_phi.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdx_phi + diff_image.*Jxy_phi.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdx_phi + diff_image.*Jxz_phi.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdx_phi + diff_image.*Jxx_phi.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdx_phi + diff_image.*Jxy_phi.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdx_phi + diff_image.*Jxz_phi.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdx_phi + diff_image.*Jxx_phi)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdx_phi + diff_image.*Jxy_phi)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdx_phi + diff_image.*Jxz_phi))))];

H(11,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdy_phi + diff_image.*Jyx_phi.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdy_phi + diff_image.*Jyy_phi.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdy_phi + diff_image.*Jyz_phi.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdy_phi + diff_image.*Jyx_phi.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdy_phi + diff_image.*Jyy_phi.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdy_phi + diff_image.*Jyz_phi.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdy_phi + diff_image.*Jyx_phi.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdy_phi + diff_image.*Jyy_phi.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdy_phi + diff_image.*Jyz_phi.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdy_phi + diff_image.*Jyx_phi)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdy_phi + diff_image.*Jyy_phi)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdy_phi + diff_image.*Jyz_phi))))];

H(12,:) = [-2*(sum(sum(sum(-dJdx_phi.*x.*dJdz_phi + diff_image.*Jzx_phi.*x)))),...
    -2*(sum(sum(sum(-dJdy_phi.*x.*dJdz_phi + diff_image.*Jzy_phi.*x)))),...
    -2*(sum(sum(sum(-dJdz_phi.*x.*dJdz_phi + diff_image.*Jzz_phi.*x)))),...
    -2*(sum(sum(sum(-dJdx_phi.*y.*dJdz_phi + diff_image.*Jzx_phi.*y)))),...
    -2*(sum(sum(sum(-dJdy_phi.*y.*dJdz_phi + diff_image.*Jzy_phi.*y)))),...
    -2*(sum(sum(sum(-dJdz_phi.*y.*dJdz_phi + diff_image.*Jzz_phi.*y)))),...
    -2*(sum(sum(sum(-dJdx_phi.*z.*dJdz_phi + diff_image.*Jzx_phi.*z)))),...
    -2*(sum(sum(sum(-dJdy_phi.*z.*dJdz_phi + diff_image.*Jzy_phi.*z)))),...
    -2*(sum(sum(sum(-dJdz_phi.*z.*dJdz_phi + diff_image.*Jzz_phi.*z)))),...
    -2*(sum(sum(sum(-dJdx_phi.*dJdz_phi + diff_image.*Jzx_phi)))),...
    -2*(sum(sum(sum(-dJdy_phi.*dJdz_phi + diff_image.*Jzy_phi)))),...
    -2*(sum(sum(sum(-dJdz_phi.*dJdz_phi + diff_image.*Jzz_phi))))];

end