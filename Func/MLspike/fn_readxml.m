function s = fn_readxml(fname,version)
% function s = fn_readxml(fname[,version])
%---
% This function is a wrapper for function xml_read.m downloaded on Matlab
% File Exchange.
% Additionally, the structure is slightly simplified.
%
% Input:
% - fname       file name
% - version     'xml_read' to use MatlabExchange Jarek Tuszynski xml_read.m [=default]
%               'xmlread' to use code provided in the Matlab help for xmlread

% Thomas Deneux
% Copyright 2007-2017

if nargin==0, help fn_readxml, return, end
if nargin<2, version = 'xml_read'; end

if fname(1)=='<'
    % XML string -> write it into a file to be able to call xml_read!!!
    xml = fname;
    fname = fullfile(tempdir,'fn_readxml.xml');
    fn_savetext(xml,fname)
end

switch version
    case 'xmlread'
        s = parseXML(fname);
    case 'xml_read'
        s = xml_read(fname);
    otherwise
        error argument
end


% The code below is provided in the Matlab help for xmlread function
function theStruct = parseXML(filename)
% PARSEXML Convert XML file to a MATLAB structure.
try
   tree = xmlread(filename);
catch
   error('Failed to read XML file %s.',filename);
end

% Recurse over child nodes. This could run into problems 
% with very deeply nested trees.
try
   theStruct = parseChildNodes(tree);
catch
   error('Unable to parse XML file %s.',filename);
end


% ----- Local function PARSECHILDNODES -----
function children = parseChildNodes(theNode)
% Recurse over node children.
children = [];
if theNode.hasChildNodes
   childNodes = theNode.getChildNodes;
   numChildNodes = childNodes.getLength;
   allocCell = cell(1, numChildNodes);

   children = struct(             ...
      'Name', allocCell, 'Attributes', allocCell,    ...
      'Data', allocCell, 'Children', allocCell);

    for count = 1:numChildNodes
        theChild = childNodes.item(count-1);
        children(count) = makeStructFromNode(theChild);
    end
end

% ----- Local function MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.

nodeStruct = struct(                        ...
   'Name', char(theNode.getNodeName),       ...
   'Attributes', parseAttributes(theNode),  ...
   'Data', '',                              ...
   'Children', parseChildNodes(theNode));

if any(strcmp(methods(theNode), 'getData'))
   nodeStruct.Data = char(theNode.getData); 
else
   nodeStruct.Data = '';
end

% ----- Local function PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
% Create attributes structure.

attributes = [];
if theNode.hasAttributes
   theAttributes = theNode.getAttributes;
   numAttributes = theAttributes.getLength;
   allocCell = cell(1, numAttributes);
   attributes = struct('Name', allocCell, 'Value', ...
                       allocCell);

   for count = 1:numAttributes
      attrib = theAttributes.item(count-1);
      attributes(count).Name = char(attrib.getName);
      attributes(count).Value = char(attrib.getValue);
   end
end
