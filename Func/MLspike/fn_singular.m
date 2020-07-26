function sentence = fn_singular(varargin)
% function [sentence =] fn_singular([str0,]n1,str1,n2,str2,...)
%---
% display a sentence that talks about some number, and but nouns/verbs at
% the appropriate singular or plural form according to those numbers
%
% the parts of this sentence that are variable must be written initially in
% upper case and plural form (except when the plural form is empty: in this
% latter case, write in upper case and singular form)
%
% exemple:
% >> fn_singular('We found ',3,' occurenceS, among which ',2,' WERE A perfect matchES.')
% We found 3 occurences, among which 2 were perfect matches.
% >> fn_singular('We found ',3,' occurenceS, among which ',1,' WERE A perfect matchES.')
% We found 3 occurences, among which 1 was a perfect match.
% >> fn_singular('We found ',1,' occurenceS, among which ',1,' WERE A perfect matchES.')
% We found 1 occurence, among which 1 was a perfect match.

% Thomas Deneux
% Copyright 2015-2017

forms = {
    'a '        ''
    ''          'es'   
    ''          's'   
    'is'        'are' 
    'was'       'were'
    'has'       'have'
    };
nform = size(forms,1);
marks = upper(forms(:,2));
ie = find(fn_isemptyc(marks));
marks(ie) = upper(forms(ie,1));

n = 1;
sentence = [];
for i=1:nargin
    a = varargin{i};
    if isnumeric(a)
        n = a;
        sentence = [sentence num2str(n)];
    elseif ischar(a)
        str = a;
        for i=1:nform
            if n<2
                str = strrep(str,marks{i},forms{i,1});
            else
                str = strrep(str,marks{i},forms{i,2});
            end
        end
        sentence = [sentence str];
    else
        error argument
    end
end

if nargout==0
    disp(sentence)
    clear sentence
end
