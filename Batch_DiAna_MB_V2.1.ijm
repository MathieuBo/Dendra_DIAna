/*
 * DENDRA ANALYSIS
 * ---------------
 * 
 * This macro was written by Mathieu Bourenx for Aurora Scrivo to 
 * decrease her pain during quantification of Dendra puncta.
 * Therefore, she has an eternal debt. 
 * 
 * Basically, the macro will first ask to select the folder where are the pictures
 * Then, allow to delineate the cells for future analysis (and save the ROIs)
 * Once all cells are selected, the macro will perform DIAna analysis, save all raw data and save summary data in a .csv file
 * 
 * 
 * Additional features can be added upon request. 
 * Mathieu Bourdenx (March 2021)
 * mathieu.bourdenx@u-bordeaux.fr
 */

path = getDirectory("Choose input directory");
files = getFileList(path);

Dialog.create("Channels");
Dialog.addNumber("Number of channels in the pictures", 4);
Dialog.show()

channels = Dialog.getNumber();

ch_list=newArray(channels);
for (i=0; i<channels; i++){
		ch_list[i]=""+i+1+"";
}

Dialog.create('Macro parameters')
Dialog.addMessage(files.length+" files found");
Dialog.addChoice('Channel for lysosomal marker (e.g. LAMP1)', ch_list, '2');
Dialog.addString('Name for lysosomal marker channel', 'LAMP1')
Dialog.addMessage("\n");
Dialog.addChoice('Channel for CMA reporter (e.g. Dendra endogenous or Dendra ab)', ch_list, '4');
Dialog.addString('Name for CMA reporter channel', 'Dendra ab')
Dialog.addMessage("\n");
Dialog.addCheckbox("Save ROI to file", true);
Dialog.addMessage("\n");
Dialog.addCheckbox("Save RAW data to file", true);
Dialog.addMessage("\n");
Dialog.addCheckbox("Save summary to file", true);
Dialog.addMessage("\n");
Dialog.addMessage("Click OK to start delineating the cells");
Dialog.addMessage("Let's do this =) !!");
Dialog.setLocation(1200,150);
Dialog.show();

ref_chan = Dialog.getChoice();
ref_name = Dialog.getString();
cma_chan = Dialog.getChoice();
cma_name = Dialog.getString();
saveroi = Dialog.getCheckbox();
saveraw = Dialog.getCheckbox();
savetofile = Dialog.getCheckbox();

cell_counter = 0

for (im_index=0; im_index < files.length; im_index++){

	open(path+files[im_index]);

	//Environment cleaning
	run("Select None");
	run("Clear Results");
	roiManager("reset");

	//Environment info
	wd = getDirectory("image");
	
	//IMAGE INFO
	im_name=getTitle();
	im_path=getDirectory("image")+getTitle();
	im_name=replace(im_name, " ", "_"); //Replace all empty spaces by underscores
	rename(im_name); //Rename the original image
	
	//getDimensions(width, height, channels, slices, frames);
	
	run("Make Composite");
	run("Z Project...", "projection=[Max Intensity]");
	
	// GUI DIALOG
	
	Dialog.create('Macro parameters')
	Dialog.addNumber('Number of cells to quantify', 1);
	Dialog.setLocation(1200,150);
	Dialog.show();
	
	ncell = Dialog.getNumber();

	
	//Delineate cells
	selectWindow("MAX_"+im_name);
	
	for (i = 0; i < ncell; i++) {
		setTool("freehand");
		waitForUser("Delineate cells", "Please delineate cell#"+(i+1)+" in the picture\n"+(ncell-i-1)+" cell(s) remaining\nThen click Ok.");
		roiManager("Add");
		roiManager("Show All with labels");
		cell_counter++;
	}
	close("MAX_"+im_name);
	
	// Saving all ROI for future use
	if (saveroi == true) {
		count=roiManager("count");
		array=newArray(count);
		for(i=0; i<count;i++) {
		        array[i] = i;
		}
		roiManager("Select", array);
		roiManager("Save", wd+"/Roiset"+im_name+".zip");
	}
}

waitForUser("Analysis", cell_counter+" cells were selected for analysis\nClick OK to start the analysis\n and go have a coffee (with milk and ice)");


for (im_index=0; im_index < files.length; im_index++){

	//Environment cleaning
	run("Select None");
	run("Clear Results");
	roiManager("reset");

	open(path+files[im_index]);
	im_name=getTitle();
	im_name=replace(im_name, " ", "_"); //Replace all empty spaces by underscores
	rename(im_name); //Rename the original image
	
	//Reload the ROIs
	roiManager("open",  wd+"/Roiset"+im_name+".zip");
		
	//DiAna Quantifications
	short_im_name = replace(im_name, ".tif", "");
	numROIs = roiManager("count");
	
	run("Close All");
	
	
	for(i=0; i<numROIs; i++) {
	
		open(im_path);
		rename(im_name);
	
		roiManager("Select", i);
		run("Duplicate...", "title=TEMP duplicate");
	
		close(im_name);
	
		selectWindow("TEMP");
	
		run("Clear Outside", "stack");
	
		run("Split Channels");
	
		title_ref = "C"+ref_chan+"-TEMP";
		title_cma = "C"+cma_chan+"-TEMP";
	
		run("DiAna_Segment", "img=["+title_ref+"] peaks=2.0-2.0-50.0 spots=150-2-1.5-3-2000-false");
		run("DiAna_Segment", "img=["+title_cma+"] peaks=2.0-2.0-50.0 spots=200-2-1.5-3-2000-false");
	
		ref_labelled = replace(title_ref, '.tif', '') + "-labelled";
		cma_labelled = replace(title_cma, '.tif', '') + "-labelled";
	
		run("DiAna_Analyse", "img1=["+title_ref+"] img2=["+title_cma+"] lab1=["+ref_labelled+"] lab2=["+cma_labelled+"] coloc distc=50.0 measure");
		close("*TEMP");
		close("*TEMP-labelled");
		close("coloc");

		selectWindow("ObjectsMeasuresResults-A");
		IJ.renameResults("ObjectsMeasuresResults-A","Results");
		n_ves_ref = nResults;
		IJ.renameResults("Results", "ObjectsMeasuresResults-A");

		selectWindow("ObjectsMeasuresResults-B");
		IJ.renameResults("ObjectsMeasuresResults-B","Results");
		n_ves_cma = nResults;
		IJ.renameResults("Results", "ObjectsMeasuresResults-B");

		IJ.renameResults("ColocResults","Results");
		myTable(im_name, (i+1), n_ves_ref, n_ves_cma, nResults); //Add results to a summary table
	
		if (saveraw == true){
			selectWindow("ObjectsMeasuresResults-A");
			saveAs("Text", wd+short_im_name+"Cell#"+(i+1)+ref_name+".csv");
			close(short_im_name+"Cell#"+(i+1)+ref_name+".csv");
	
			selectWindow("ObjectsMeasuresResults-B");
			saveAs("Text", wd+short_im_name+"Cell#"+(i+1)+cma_name+".csv");
			close(short_im_name+"Cell#"+(i+1)+cma_name+".csv");
	
			selectWindow("Results");
			saveAs("Text", wd+short_im_name+"Cell#"+(i+1)+"colocResults.csv");
			close("Results");
		}
	}
}

getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);

selectWindow("Quantification");
saveAs("Text", wd+"Quantification_"+year+"-"+month+"-"+dayOfMonth+".csv");
close("Quantification");
close("ObjectsMeasuresResults-A");
close("ObjectsMeasuresResults-B");

waitForUser("Brava!!", "Congratulations Scrivo!!! \nYou still have 20million cells to analyze before finishing your post doc :)\n Xoxo your nerdy friend");

//FUNCTION: CUSTOM TABLE
function myTable(a, b, c, d, e){
	title1="Quantification";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e);
	}
	else{
   		run("Table...", "name="+title2+" width=800 height=400");
   		print(title2, "\\Headings:File\tCell#\tn "+ref_name+"\tn "+cma_name+"\tn coloc");
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e);
	}
}
