% Brick is a set of handy general Matlab functions
% Version 2.0   06-Jan-2017
% 
% ARRAY MANIPULATION
% - manipulate dimensions and shape
%   column, row, third, fourth - Reshape ND array to column vector, row vector, or vector in the 3rd or 4th dimension 
%   matrix, threed    - Reshape ND array to 2D or 3D array
%   fn_reshapepermute - Full capability for dimensions and shape manipulation
%   fn_add, fn_mult, fn_subtract, fn_div, fn_eq - Operations between arrays whose dimensions only partially match
%   fn_indices        - Convert between global and per-dimension indices 
%   fn_interleave     - Interleave data 
%   fn_sizecompare    - Check whether two size vectors are equivalent
% - apply function to elements of array or cell array
%   fn_map            - Apply a given function to the elements, columns or rows of an array (more versatile than Matlab arrayfun)
%   fn_find           - Look for non-empty elements, or which evaluate to true when applying a certain function
%   fn_isemptyc       - Which elements of a cell array are empty
%   fn_itemlengths    - Return lengths of all elements inside a cell array
% - simple processing
%   fn_bin, fn_enlarge - Data binning and enlarging
%   fn_round          - Round x to the closest multiple of y
%   fn_coerce         - Restrict data to a specific range
%   fn_clip           - Rescale data, restrict the range, color
%   fn_normalize      - Normalize data based on averages in some specific dimension
% - min, max, mean,...
%   fn_min, fn_max    - Global minimum or maximum of an array and its coordinates
%   fn_minmax         - Basic min/max operations (e.g. intersection or union of 2 ranges)
%   fn_localmax       - Find local maxima in a vector 
%   fn_mean, fn_means - Average over several dimensions, average successive argumments
%   fn_meanc          - Return mean and confidence interval
%   fn_meanangle      - Average of angles (result in [-pi pi])
%   nmean, nmedian, nstd, nste, nrms, nsum - Treat NaNs as missing values for mean/median/std/ste/rms/sum computations 
%   fn_triggeravg     - Local average of data around specific indices in a given dimension
%   fn_arrangepergroup, fn_avgpergroup - Reorganize an array according to labels describing a specific dimension, or average accross different repetitions of the same label
% - other
%   fn_sym            - Convert a symmetric matrix to a vector and vice-versa
%   fn_timevector     - Convert set of times to vector of counts and vice-versa
%
% MATLAB TYPES
% - string
%   fn_strcut         - Cut string into pieces according to specified separator
%   fn_strrep         - Replace several text sequences in string
% - structures
%   fn_structdisp     - Recursive display of a structure content
%   fn_structmerge, fn_structcat - Merge and concatenate structures 
%   fn_structinit     - Initialize a structure with no field, or with same fields as a model
%   fn_structedit     - Edit a structure with a GUI interface; this is a wrapper of fn_control
% - conversions
%   fn_num2str        - Convert numeric to char, unless input is already char!, can return a cell array
%   fn_idx2str        - Convert indices to a compact string representation, e.g. '1:2 5:8' for [1 2 5 6 7 8] 
%   fn_str2double     - Convert to numeric if not already numeric
%   fn_strcat         - Concatenate strings and numbers into a single string, with optional separator sequence 
%   fn_float          - Convert integer to single, keep single or double as such 
% 
% PROGRAMMING
% - handy shortcuts
%   fn_switch, fn_cast - Shortcut for avoiding using if/else and switch 
%   fn_disp, fn_display - Display multiple arguments at once, display a variable name and value in a single line
%   fn_dispandexec    - Display commands in Matlab and executes them 
%   fn_subsref        - Shortcut for calling Matlab subsref function
%   fn_ismemberstr    - Check whether string is part of a set of strings (faster than Matlab ismember)
%   fn_flags          - Detect flags in the arguments of a function 
%   dealc             - Assign elements of an array to multiple outputs
%   fn_mod            - Return modulus between 1 and n instead of between 0 and n-1
%   fn_regexptokens   - Get the tokens of a regexp as a simple cell array
% - tools
%   fn_progress, pg   - Print the state of a calculation 
%   fn_hash           - Unique hash number for an array/cell/structure (Copyright M Kleder)
% - debugging
%   fn_dbstack        - Display current function name, with indent according to stack length 
%   fn_basevars       - Load base workspace variables in caller workspace and vice-versa 
%
% FILES
% - shortcuts
%   fn_cd             - User definition of shortcut to fast access directories
%   fn_fileparts, fn_fileext - Get specific file parts, replace file extension 
%   fn_ls             - Return folder content
%   fn_mkdir          - Create a directory if it does not exist
%   fn_movefile       - Rename files in current directory using regular expression
% - user selection
%   fn_getfile        - Select file and remember the containing folder of the last selected file 
%   fn_savefile       - User select file for saving and remember last containing folder 
%   fn_getdir         - Select directory and remember last containing folder 
% - handy
%   locate            - Reveal file in Explorer (Windows only)
% 
% IMPORT/EXPORT
% - read/save file
%   fn_readtext, fn_savetext    - Read/save text file
%   fn_readasciimatrix, fn_saveasciimatrix   - Read/save 2D array from/to text file
%   fn_readimg, fn_saveimg      - Read/save image or stack thereof, (read:) detects if color or grayscale, (save:) options for clipping, color map...
%   fn_readmovie, fn_savemovie  - Read AVI movie
%   fn_readxml, fn_savexml      - Read/save XML file (Copyright Jarek Tuszynski)
%   fn_loadvar, fn_savevar      - Load/save in MAT file in a more convenient way
% - read file
%   fn_readbin        - Read binary file containing some header followed by numerical data
% - save figure
%   fn_savefig        - Save figure with a number of options
% - Matlab workspaces
%   fn_exportvar      - Export data to a Matlab variable in base workspace
% 
% MATHEMATICS
% - filtering
%   fn_filt           - Gaussian low-, high- or band-pass filtering using fft
%   fn_smooth, fn_smooth3 - 1D, 2D and 3D smoothing using Gaussian convolution
%   fn_detrend        - Remove a linear trend estimated only from specific indices 
%   fn_spectrogram    - Compute spectrogram
% - optimization
%   fn_fit            - Fit the parameters of a given function
%   dichotomy         - Uses dichotomy method for one-dimensional optimization
% - statistics
%   fn_GLMtest        - Perform F-test and T-test in a GLM framework
%   fn_bootstrap      - Compare the mean or median of two ensembles using bootstrap method 
%   fn_chi2indenpendencetest - Chi2 independence test
%   fn_pcorrect       - Perform correction for multiple testing
%   fn_sample         - Draw samples from distribution
% - statistics + display
%   fn_regression     - Perform linear regression and display data points and result
%   fn_comparedistrib - Perform a nonparametric test and display data points and results
%   fn_markpvalue     - Draw stars to mark significancy of results
% - machine learning
%   fn_clustering     - Performs correlation-based clustering of data x
% - tools
%   fn_fftfrequencies - Frequencies corresponding to the output of Matlab fft function
%
% IMAGE PROCESSING
% - basic operations
%   fn_imageop        - Apply a series of transformations to an image 
%   fn_printnumber    - Add small numbers and text to images or movies
% - regions of interest
%   fn_maskselect     - Manual selection of a mask inside an image
%   fn_subrect        - Manual selection of a rectangular mask inside an image
%   fn_poly2mask      - Get the mask of a polygon interior
%   fn_imvect         - Convert an image to a vector of pixels inside a mask, and vice-versa 
%   fn_roiavg         - Compute average signal from a region of interest
% - coregistration
%   fn_register       - Coregister images or movie
%   fn_xregister      - Fast fft-based coregistration at pixel (but not sub-pixel) resolution
%   fn_translate, fn_affinity - Interpolate an image or movie after translation or affinity
% - GUI programs
%   fn_alignimage     - Manual alignment of 2 images
%   montage           - Manual alignment of a large set of images
%
% DATA DISPLAY
% - shortcuts
%   fn_drawpoly       - Shortcut for line(poly(:,1),poly(:,2))
% - figure
%   fn_figure         - Raise figures by name rather than by number (shortcut: ff)
%   fn_isfigurehandle - Is handle a plausible figure handle
%   fn_subplot        - Subplots cover the figure without leaving any space
% - drawings
%   fn_arrow          - Draw an arrow
%   fn_circle         - Draw a circle
%   fn_lines          - Draw a series of vertical and/or horizontal lines
% - bar displays
%   fn_histocol       - Display an histogram of values with colors
%                       indicating another set of values (e.g. p-values)
% - time courses displays
%   fn_stairs         - Display stairs in an intuitive way
%   fn_errorbar       - Display nice error bars 
%   fn_regression     - Display of data points together with linear regression
%   fn_spikedisplay, fn_rasterplot - Raster plot display (display of punctual events as small bars)
% - time courses tools
%   fn_axis           - Set axis range for a better visual aspect than 'axis tight' 
%   fn_nicegraph      - Improve aspect of graph display
%   fn_plotscale      - Add horizontal and vertical scale bars to graph
%   fn_linespecs      - Handle abbreviated plot options (e.g. 'r.') 
% - special 2D displays
%   fn_displayarrows  - Display an image and a velocity field on top of it 
%   fn_tensordisplay  - Display of a field of 2x2 symmetric matrices using ellipses
% - 2D tools
%   fn_imdistline     - Show the distance between two points (enhanced version of Matlab imdistline)
%   fn_scale          - Scale bar for image display
% - color tools
%   fn_colorset, fn_colorbyname - Different sets of colors, conversion between color numerical value and name
%   fn_showcolormap   - Display a color map in a given axes or in a separate figure
% - movie displays
%   fn_playmovie      - Simple showing of a movie
%   fn_movie          - Show a movie, large number of options
% - mesh computations and displays
%   fn_meshplot       - Display a mesh
%   fn_meshselectpoint - Display a mesh and let user select a point with mouse
%   fn_cubemesh, fn_cubeview - Render the "faces" of a 3D data (creates a mesh and texture, or an image) 
% - display ND data
%   fn_eegplot, fn_gridplot - Display multiple time courses dispatched vertically or arranged as a grid
%   fn_framedisplay   - Display images arranged as a grid
% - interactive displays
%   fn_imvalue        - Automatic link graphs and images for point selection and zooming
%   fn_review         - Navigate with arrow keys inside a set of data
%   fn_4Dview         - Navigation inside 3D, 4D or 5D imaging data
%
% GUI PROGRAMMING
% - shortcuts
%   fn_evalcallback   - Evaluate a callback, i.e. a char array, function handle or cell array 
%   fn_get, fn_set    - Get and set mutiple properties of multiple objects at once 
% - figure
%   fn_watch          - Change the pointer to a watch during long computations
%   panelorganizer    - Divide a figure into resizeable panels
% - object positions
%   fn_parentfigure   - Get parent figure
%   fn_pixelpos, fn_pixelsize - Position or size of an object in pixel units 
%   fn_pixelposlistener, fn_pixelsizelistener - Create a listnener detecting change in object position or size
%   fn_getpos         - Get object position in a specific unit
%   fn_coordinates    - Conversion of screen/figure/axes, normalized/pixel coordinates
%   fn_controlpositions - Set an object position using a combination of absolute and relative (to any other object) coordinates 
%   fn_setfigsize     - Change the size of a figure, while keeping it within screen 
%   fn_framedesign    - Utility to let user reposition graphic objects inside a figure 
% - mouse actions
%   fn_buttonmotion        - Execute a task while mouse pointer is movedaround 
%   fn_moveobject, fn_pan  - Move a graphic object or navigate in graph with mouse
%   fn_mouse, interactivePolygon - Manual selection of a variety of shapes
%   fn_scrollwheelregister - Define scrollwheel actions specific to which object the mouse is hovering over 
% - pre-defined arrangements of controls
%   fn_okbutton       - Small 'ok' button waits to be pressed
%   fn_menu           - Utility to create a basic GUI made of a line of buttons
% - special controls
%   fn_multcheck      - Special control made of multiple check boxes
%   fn_buttongroup    - Set of radio buttons or toggle buttons
%   fn_slider         - Special control that improves the functionality of Matlab slider
%   fn_sliderenhance  - Allow a slider uicontrol to evaluate its callback during scrolling
%   fn_stepper        - Edit a numeric value, includes increment/decrement buttons
%   fn_sensor         - Special control whose value is changed by clicking and dragging
%   fn_clipcontrol    - A wrapper of fn_sensor that controls the clipping range applied to an image 
%   fn_filecontrol    - Select a file
% - elaborate controls
%   fn_control        - Arrangement of control that reflect the state of a set of parameters 
%   fn_supercontrol   - Super arrangement of control 
%   fn_listorganize   - Edit a list of strings or of structured data
% - dialogs
%   fn_reallydlg      - Ask for confirmtaion
%   fn_dialog_questandmem   - Confirmation question with an option for not asking again 
%   fn_input          - Prompt user for a single value. Function based on fn_structedit 
% - GUI oriented-object programming
%   interface         - Parent class to create cool graphic interfaces
%   fn_propcontrol    - Create controls automatically linked to an object property
%   deleteValid       - Delete valid objects among the list of objects obj (particularly useful for Matlab graphic handles) 
%   disableListener   - Momentarily disable a listener (returns an onCleanup oject that reenable it when being garbage collected)
%
% MISCELLANEOUS
% - shortcuts
%   alias             - Create command shortcuts 
% - system
%   fn_lmstat         - Get information about how many Matlab floating licenses are used on the network 
%   fn_hostname       - Return an identifiant specific to the computer in use
%   fn_email          - Send e-mails from Matlab! Automatically attach figures, M-files and more
% - memory and pointers
%   whoisbig          - Get information about large variables
%   fn_getPr          - Get the address of the data stored in a variable: usefull to understand when two variables share the same data in memory 
%   fn_pointer        - A structure that can be modified when being passed to functions 
%   pointer           - Implement a pointer to any Matlab object
% - graphics
%   fn_figmenu        - An automatic custom menu for figures: save figure, distance tool, ... 
% - figure edition
%   fn_extractsvgdata - Extract data from SVG file! (PDFs can be converted to SVG with InkScape free software)
%   fn_getcolorindices- Extract from image displays by checking the color bar
%   fn_color2bw       - GUI to let user choose the best conversion to convert color image to grayscale
%   fn_editsignal     - Manually edit your signals data points!
% 
% HIGHLIGHTS
%   fn_imvalue        - Type 'fn_imvalue demo' to see how the fn_imvalue functions connects different displays for zooming, etc. 
%   fn_buttonmotion   - Type 'fn_buttonmotion demo' then click and drag in the figure
%   fn_figmenu        - Type 'fn_figmenu' to get a useful new menu in every figure 
%   pg                - Type 'for i=1:100, pg i, svd(rand(1000)); end' and check a very simple progress indicator 
%   whoisbig          - Type 'whoisbig' to check which data takes a lot of memory 
%
% For more help type 'doc', then go to Supplemental Software > Brick Toolbox. 

