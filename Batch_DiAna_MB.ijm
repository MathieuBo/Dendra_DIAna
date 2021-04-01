path = getDirectory("Choose input directory");
files = getFileList(path);

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

getDimensions(width, height, channels, slices, frames);

run("Make Composite");
run("Z Project...", "projection=[Max Intensity]");

// GUI DIALOG
ch_list=newArray(channels);
for (i=0; i<channels; i++){
		ch_list[i]=""+i+1+"";
}

Dialog.create('Macro parameters')
Dialog.addNumber('Number of cells to quantify', 1);
Dialog.addMessage("\n");
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
Dialog.setLocation(1200,150);
Dialog.show();

ncell = Dialog.getNumber();
ref_chan = Dialog.getChoice();
ref_name = Dialog.getString();
cma_chan = Dialog.getChoice();
cma_name = Dialog.getString();
saveroi = Dialog.getCheckbox();
saveraw = Dialog.getCheckbox();
savetofile = Dialog.getCheckbox();

//Delineate cells
selectWindow("MAX_"+im_name);

for (i = 0; i < ncell; i++) {
	setTool("freehand");
	waitForUser("Delineate cells", "Please delineate cell#"+(i+1)+" in the picture\n"+(ncell-i-1)+" cell(s) remaining\nThen click Ok.");
	roiManager("Add");
	roiManager("Show All with labels");
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

	IJ.renameResults("ColocResults","Results");
	myTable(im_name, (i+1), nResults); //Add results to a summary table

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

waitForUser("Brava!!", "Congratulations Scrivo, you still have 2000000 cells to analyze :)");

//FUNCTION: CUSTOM TABLE
function myTable(a, b, c){
	title1="Quantification";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c);
	}
	else{
   		run("Table...", "name="+title2+" width=800 height=400");
   		print(title2, "\\Headings:File\tCell#\tn coloc");
   		print(title2, a+"\t"+b+"\t"+c);
	}
}
