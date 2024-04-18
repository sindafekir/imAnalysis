function [SW, SF] = swft(x_list, varargin)

% Input Arguements: 
%   1) x_list - A numerical or cell matrix of data to be tested.  Rows are
%   observations.  Columns are treated as independent variables.
%   2) names (optional) - A single row cell array of variable names.
%   (Note: if x_list is a cell array, the first row can contain variable
%   names.)
%   3) flag (optional) - In output tables substitute "< 0.0001" for p 
%      values less than 0.0001:
%       0 (default) - display p values as calculated
%       1 - display "< 0.0001"
% Output:
%   1) SW - A table containing the results of the Shapiro-Wilks test.
%   2) SF - A table containing the results of the Shapiro-Francia test.
%
%   Example: [SW, SF] = swft(x, names, 1)
%
% This function calculates the Shapiro-Wilk (Wilk & Shapiro, 1965) and 
% Shapiro-Francia (Shapiro & Francia, 1972) tests of whether a given set of 
% numbers are normally distributed.  The Shapiro-Wilk test is valid for
% datasets with between 3 and 5000 data points.  The Shapiro-Francia test
% accepts between 5 and 5000 data points (Royston 1993; but note that the 
% STATA statistical software package which produced its algorithms in 
% in conjunction with Royston, puts the Shapiro-Francia minimum at 10).  
% P-values of less than 0.05 suggest the data are not normally distributed.
%
% Both tests have been found to be more powerful than other similar 
% normality tests (Ahmad & Sherwani, 2015; Henderson, 2006; Razali & Wah, 
% 2011).  Royston (1982b) states that the Shapiro-Wilk test is optimal for
% platykurtic distributions (kurtosis < 3), while the Shapiro-Francia test 
% is superior for leptokurtic distributions (kurtosis > 3).  My preference 
% is to simply provide the user with both results.  It should also be 
% noted that while this function doesn’t produce a p-p or q-q distribution 
% plot, it is a generally a good idea to create one to compare with the 
% test output (Gan, Koehler, & Thompson, 1991; Wilk & Gnanadesikan, 1968).
%
% The function takes one input matix which can be either a numerical array 
% or cell array.  The array should be structured such that rows represent 
% obervartions.  If the array has more than one column, the function treats
% each column as an independent variable.  An optional cell array of column
% names can also be passed to the function.  Note that if the input is a 
% cell array and the first row contains strings, the function will treat
% the first cell of each column as a variable name.
%
% The function returns two outputs: SW (a Shapiro-Wilk table) and SF 
% (a Shapiro-Francia table).  Both are cell matrices structured such that 
% rows represent (and are labeled as) input variables and columns contain 
% the statistics produced by the function.  Left to right, the columns show 
% the number of observations for the test variable, skewness, kurtosis, the
% W/W’ statistic, the z score, and the corresponding p value.
%
% Note: if the function is being used with a version of Matlab prior to
% 2018a, there is a short code block (line 166) that is currently commented 
% out that removes NaN's from the input matrix. Remove comment marks and
% remove NaNs.
%
% The actual algorithms used in the swft function are based on Royston’s 
% various treatments of both tests (J. P. Royston, 1982a, 1982b, 1983, 
% 1993; P. Royston, 1995).  Of these, Royston (1993) was the primary 
% source.  
%
%
% *** References ***
% Ahmad, F., & Sherwani, R. A. K. (2015). Power Comparison of Various 
%   Normality Tests. Pak.j.stat.oper.res., 11(3), 331-345. 
% Gan, F. F., Koehler, K. J., & Thompson, J. C. (1991). Probability Plots 
%   and Distribution Curves for Assessing the Fit of Probability Models. 
%   The American Statistician, 45(1), 14-21. 
% Henderson, A. R. (2006). Testing experimental data for univariate 
%   normality. Clin Chim Acta, 366(1-2), 112-129. doi:10.1016/j.cca.2005.11
%   .007
% Razali, N. M., & Wah, Y. B. (2011). Power Comparisons of Shapiro-Wilk, 
%   Kolmogorov-Smirnov, Lilliefors, and Anderson-Darling Tests. Journal of 
%   Statistical Modeling and Analytics, 2(1), 21-33. 
% Royston, J. P. (1982a). Algorithm AS 181: The W Test for Normality. 
%   Applied Statistics, 31(2), 176-180. 
% Royston, J. P. (1982b). An Extension of Shapiro and Wilk's W Test for 
%   Normality to Large Samples. Journal of the Royal Statistical Society. 
%   Series C (Applied Statistics), 31(2), 115-124. 
% Royston, J. P. (1983). A Simple Method for Evaluating the Shapiro-Francia
%   W' Test of Non-Normality. Journal of the Royal Statistical Society. 
%   Series D (The Statistician), 32(3), 297-300. 
% Royston, J. P. (1993). A Toolkit for Testing for Non-Normality in 
%   Complete and Censored Samples. Journal of the Royal Statistical 
%   Society. Series D (The Statistician), 42(1), 37-43. 
% Royston, P. (1995). Remark AS R94: A Remark on Algorithm AS 181: The 
%   W-test for Normality. Journal of the Royal Statistical Society. Series 
%   C (Applied Statistics), 44(4), 547-551. 
% Shapiro, S. S. & Francia, R. S. (1972) An approximate analysis of 
%   variance test for normality, Journal of the American Statistical 
%   Association, 67, pp. 215-216.
% Wilk, M. B., & Gnanadesikan, R. (1968). Probability Plotting Methods for
%   the Analysis of Data. Biometrika, 55(1), 1-17. 
% Wilk, M. B., & Shapiro, S. S. (1965). An Analysis of Variance Test for
%   Normaily (Complete Samples). Biometrika, 52(3/4), 591-611. 


%% Data Cleaning and Checking
% First: check the number of arguements being passed to the function and
% begin assigning default values.
%
% Second: if input is a cell matrix, find out if first row column names, 
% seperate them, and turn rest into numerical array.  If cells contain only 
% numbers, just convert to numerical array.

if nargin == 1 
    names = [];
    flag = 0;
elseif nargin == 2
    if iscell(varargin{1})
        names = varargin{1};
        flag = 0;
    elseif varargin{1} == 1 || varargin{1} == 0
        flag = varargin{1};
        names = [];
    
    end
elseif nargin == 3
    names = varargin{1};
    flag = varargin{2};
end


if iscell(x_list)
    if isstring(x_list{1,1}) || ischar(x_list{1,1})
        names = x_list(1,:);
        x_list = x_list(2:end,:);
        x_list = cell2mat(x_list);
    else
        x_list = cell2mat(x_list);
    end
end

% Get the size of the final unput matrix.  
szs = size(x_list);

% Warnings based on input matrix size.
% If the number of columns exceeds the number of observations a friendly
% warning is printed.
if szs(1) < szs(2)
    thewarning = ['Number of input variables(columns) exceeds number of observations(rows).' newline,...
        'Make sure input matrix oriented.' newline,...
        'Function will complete calculations normally.'];
    warning(thewarning)
elseif szs(1) < 3
    warning('Minimum of three observations required.')
    return
elseif szs(1) < 5
    warning('Shapiro-Francia inaccurate for N < 5 observations.')    
elseif szs(1) > 5000
    warning('Results for both tests may not be reliable for N > 5000 observations.')    
end

% If the user has supplied a list of variable names, or they weren't part
% of thin input matrix, create a list of generic names.
if isempty(names)
    for i_naming = 1:szs(2)
        names{1,i_naming} = ['Var. ' num2str(i_naming)];
    end
end

% Loop through each column of x_list.
for i_loop = 1:min(szs)
    
    % Remove NaN's and create a working array
    working_list = rmmissing(x_list(:,i_loop));
    
    % *** Note: If the swft function is being used with a pre 2018 version  
    % of Matlab, remove the comments from the code below and use it to 
    % remove NaN's and create the working_list vector.
    %
    % working_list = x_list(~isnan(x_list(:,1)));
        
    N = length(working_list);

    nl_sorted = sort(working_list);
   
    % This pre-allocates memory for the score and weight arrays.
    % Interestingly, for smaller input arrays this slowed the function down
    % a bit.  For larger inputs (5000 rows by 2000 column) there was a
    % slight increase in speed.
    mis = zeros(N,1);
    ais = zeros(N,1);  

    % Index for numbers for basic rankings.  The swft
    % function is using a "no-ties" method.
    indx = 1:1:N; 
    indx = indx';
    u = 1/sqrt(N); % upsilon

    mis = norminv((indx-0.375)/(N+0.25));

    Mm = sumsqr(mis);
    
    % For most N sizes the last two ais values are calculated indipendently.
    % Note: These are calculated in a reversed order than Royson(1993).
    ai_N =(-2.706056*u^5)+(4.434685*u^4)-(2.07119*u^3)-(0.147981*u^2)+(0.221157*u)+(mis(end,1)/sqrt(Mm));
    ai_N_min_1 =(-3.582633*u^5)+(5.682633*u^4)-(1.752461*u^3)-(0.293762*u^2)+(0.042981*u)+(mis(end-1,1)*(Mm^-0.5));

    Phi = (Mm-(2*mis(end,1)^2)-(2*mis(end-1,1)^2))/(1-(2*ai_N^2)-(2*ai_N_min_1^2));

    if N > 3 && N < 6
        Phi =(Mm - 2 * mis(end,1)^2) / (1 - 2 * ai_N^2);
    end

    ais = mis/sqrt(Phi);

    ais(end,1) = ai_N;
    if N>=6
        ais(end-1,1) = ai_N_min_1;
    end

    ais(1,1) = -ais(end,1);
    ais(2,1) = -ais(end-1,1);

    w_corr = corrcoef(nl_sorted,ais);

    W = w_corr(2,1)^2; % Shapiro-Wilk statistic

    % Royston's mu and ln(sigma)
    W_mean = (0.0038915*(log(N))^3)-(0.083751*(log(N))^2)-(0.31082*(log(N)))-1.5861;
    W_std = exp((0.0030302*(log(N)^2))-(0.082676*(log(N)))-0.4803);

    gW = log(1-W); % The transformation(g) value
    z = (gW-W_mean)/W_std; 
    
    p = 1 - normcdf(z); % significance


    %% Shapiro-Wilk N < 12
    % For N < 12 special weight, mu, ln(sigma), transformation(g), and
    % gamma calculations and values kick in. 
    
    % This is the only section where Royston's (1982) Algorithm AS 181 is
    % specifically used.

    if N < 12

        if N == 3
            ais(3,1) = .70710678;
            ais(1,1) = -ais(end,1);
            ais(2,1) = 0;

            W_mean = 0; 
            W_std = 1;

            w_corr = corrcoef(nl_sorted,ais);

            W = w_corr(2,1)^2;

            p  = 1.909859321 * (asin(sqrt(W))- 1.047198);
            z = norminv(p, W_mean, W_std);

        elseif N > 3 && N < 12

            W_mean = (-0.0006714*N^3)+(0.025054*N^2)-(0.39978*N)+0.544;
            W_std = exp((-0.0020322*N^3)+(0.062767*N^2)-(0.77857*N)+1.3822);

            gW1 = (0.459*N)-2.273; % transormation(g)
            gW2 = -log(1-W);
            gW3 = -log(gW1+gW2);

            z = (gW3-W_mean)/W_std;

            p = 1 - normcdf(z);

        end


    end
    %% Shapiro-Francia

    miX = mis.*nl_sorted; 
    X_mean = mean(nl_sorted);
    X_X_Mean_sqr = (nl_sorted-X_mean).^2;

    sum_miX = sum(miX);
    sum_XX = sum(X_X_Mean_sqr);

    W_f = (sum_miX^2)/(Mm*sum_XX); % Shapiro-Francia

    v = log(N); % nu
    u_2_mean = log(v) - v;
    u_2_std = log(v)+(2/v);
    
    gWf = log(1-W_f); % transformtion(g)
    W_f_mean = (1.0521*u_2_mean) - 1.2725;
    W_f_std = 1.0308-(0.26758*u_2_std);

    z_f = (gWf-W_f_mean)/W_f_std; 

    p_f = 1- normcdf(z_f); %  significance
    
    %% Skewness and Kurtosis
    
    sk = skewness(working_list);
    ku = kurtosis(working_list);    
    

    %% Output1 - Building Table Bodies

    sw_values(i_loop,:) = {N,sk, ku, W, z, p};
    sf_values(i_loop,:) = {N, sk, ku, W_f, z_f, p_f};
    names2(i_loop,1) = names(i_loop);
    
   
            
end

%% Output 2 - Finishing Tables to Output

sw_top = {"Shapiro-Wilk","Obervations", "Skewness", "Kurtosis", "W", "Z", "p value"};
sf_top = {"Shapiro-Francia","Obervations", "Skewness", "Kurtosis", "W'", "Z", "p value"};

% Build tables

sw_body = [names2 sw_values]; % Wilks
sf_body = [names2 sf_values]; % Francia

% *** If p-value is very small or zero, adjust output. *** %
if flag == 1
    for i_p = 1:i_loop
        if sw_body{i_p,7} < 0.0001
           sw_body{i_p,7} =  "< 0.0001";
        end
        if sf_body{i_p,7} < 0.0001
           sf_body{i_p,7} =  "< 0.0001";
        end
    end
end


   
SW = [sw_top; sw_body];
SF = [sf_top; sf_body];





