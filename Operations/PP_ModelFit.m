% PP_ModelFit
% 
% Carries out a variety of preprocessings to look at improvement of fit to
% an AR model.
% 
% After performing the range of transformations to the time series, returns the
% in-sample root-mean-square (RMS) prediction errors for an AR model on each
% transformed time series as a ratio of the RMS prediction error of the original
% time series.
% 
% BF_preproc.m is used to perform the preprocessings
% 
% The AR model is fitted using the function ar and pe from Matlab's System
% Identification Toolbox
% 
% Transformations performed include:
% (i) incremental differencing,
% (ii) filtering of the power spectral density function,
% (iii) removal of piece-wise polynomial trends, and
% (iv) rank mapping the values of the time series to a Gaussian distribution.
% 
% INPUTS:
% 
% y, the input time series
% model, the time-series model to fit to the transformed time series (currently
%           'ar' is the only option)
%           
% order, the order of the AR model to fit to the data
% 

function out = PP_ModelFit(y,model,order)
% Ben Fulcher, 18/2/2010

%% Preliminaries
N = length(y); % length of the time series

%% Inputs
% Model: the model to fit preprocessed time series to
if nargin < 2 || isempty(model)
    model = 'ar';
end

% order: the order of model to fit
if nargin < 3 || isempty(order)
    order = 2;
end

%% Do a range of preprocessings
yp = BF_preproc(y,'');
% returns a structure, yp, with a range of time series in it, each a different
% transformation of the original, y.
%% ____________________FIT MODEL TO ALL:_______________________ %%

fields = fieldnames(yp);
nfields = length(fields);
% statstore = struct('fpes',{});

for i = 1:nfields
    data = [];
    % for each preprocessing, fit the model
    eval(sprintf('data = yp.%s;',fields{i})); 
    % data is the current preprocessed data

    switch model % SO MANY OPTIONS! ;-)
        case 'ar'
            % (0)
            data = BF_zscore(data); % zscore the data from this preprocessing
            if ~exist('ar')
                error('Can''t fit the AR model -- is the System Identification Toolbox installed??');
            end
            % (i) fit the model
            m = ar(data,order);
            % (ii) get statistics on fit
            %     () FPE
            statstore.fpe(i) = m.EstimationInfo.FPE;
            %     () in-sample prediction error
            e = pe(m,data);
            statstore.rmserr(i) = sqrt(mean(e.^2));
            statstore.mabserr(i) = mean(abs(e));
            statstore.ac1(i) = CO_autocorr(e,1);
            
        otherwise
            error('Unknown model ''%s''',model);
    end
end

%% Return statistics on statistics
% actually often as you make more stationary and remove trends it becomes
% harder to predict because these trends are very easy to predict, and
% making the series whiter will obviously decrease its predictability.

% (1) ratio of fpe of preprocessed to unprocessed time series
% I think just this is ok.
% for i=2:nfields
%     eval(['out.fperat_' fields{i} ' = ' num2str(statstore.fpe(i)/statstore.fpe(1)) ';']);
% end

% No, I'll just do in-sample rms error, for a single model no point fpeing
for i = 2:nfields
    wow = statstore.rmserr(i)/statstore.rmserr(1);
    eval(sprintf('out.rmserrrat_%s = wow;',fields{i}));
end
% In fact, greater error in this case means a better detrending in some
% sense -- it's remobed more of the 'obvious' linear structure (assuming
% that's the aim).

% could also return statistics on other things like prediction error, but
% not alot of point, I think.


% 
%     function ydt =  SUB_remps(y,n,method)
%         % Removes the first n (proportion) of power spectrum
%         % Based on my deseasonalize1.m code
%         
% 
%         %% Take the Fourier Transform
% 
%         Ny = length(y); % number of samples in y
% %         t = linspace(0,1,Ny); % time vector
%         NFFT = 2^nextpow2(Ny); % next power of 2
%         Fy = fft(y,NFFT); % fast fourier transform of y
%         Fy1 = Fy(1:NFFT/2+1);
% %         f = 1/2*linspace(0,1,NFFT/2+1); % frequency vector
% 
%         %% Remove this range
%         % set it to (mean of the rest) across this range
%         switch method
%             case 'lf'
%                 cullr = 1:floor(length(Fy1)*n);
%             case 'biggest'
%                 cullr = find(abs(Fy1)>quantile(abs(Fy1),n));
%         end
%             
%         meanrest = mean(abs(Fy1(setxor(1:end,cullr))));
% %         meanrest = 0;
%         FyF = Fy;
%         FyF(cullr)=meanrest;
%         FyF(end-cullr+2)=meanrest;
% 
%         
%         % PLOT
% %         plot(abs(Fy)),hold on; plot(abs(FyF),'--r'); hold off
% %         input('Here''s the filtered one...')
% %         plot(abs(FyF),'k');
% %         input('Again on it''s own...')
% 
%             
%         %% Inverse Fourier Transform
%         ydt = ifft(FyF,NFFT);
%         ydt = BF_zscore(ydt(1:Ny)); % crop to desired length
% 
%         
%         % PLOT
% %         plot(zscore(ydt),'b'); hold on; plot(y,'r'); hold off;
% %         input(['Mean difference is ' num2str(mean(y-ydt))])
%     
%     end
% 
%     function ydt = SUB_rempt(y,order,nbits)
%         N = length(y);
%         ydt = zeros(N,1);
%         bits = round(linspace(0,N,nbits+1));
%         for k=1:nbits
%             r = bits(k)+1 : bits(k+1); % range defined by adjacent 'bits'
%             x = (1:length(r))'; % faux x-range
%             ybit = y(r); % y-range
%             p = polyfit(x,ybit,order);
%             ydt(r) = ybit-polyval(p,x);
%         end
%         ydt = BF_zscore(ydt);
% %         plot(y,'b'); hold on; plot(ydt,'r');
% %         input('here we are')
%     end


end