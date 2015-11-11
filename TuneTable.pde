// we need to import the TUIO library
// and declare a TuioProcessing client variable
import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

//set resolution to 1280x1024

import java.util.Map.*;
import java.util.Iterator.*;
import java.util.concurrent.*;


// Creates Variable and junk  
Minim minim;
AudioOutput out;
FilePlayer filePlayer;
Delay myDelay;


boolean debug = true;
boolean invertColor = false;
boolean showFPS = true;
boolean hoverDebug = true;
boolean fullscreen = true;
boolean analyticsOn = false;

// these are some helper variables which are used
// to create scalable graphical feedback
float cursor_size = 15;
int block_diameter = 120;
float table_size = 760;
float scale_factor = 1;
float cur_size = cursor_size*scale_factor;
int bpm = 60;
int beatsPerMeasure = 4;
int millisPerBeat;
int beatNo = 0;
PFont font;

static int display_width = 640;
static int display_height = 480;

PImage lock;
PImage unlock;
PImage lock_reg;
PImage unlock_reg;
PImage lock_inv;
PImage unlock_inv;
PShape beatShadow;
PShape dashCircle;
PShape playShadow;
PShape circleShadow;


List<Block> allBlocks;
List<Block> missingBlocks;
LinkedList<Block> killBlocks;

List<Cursor> cursors;

List<FunctionBlock> allFunctionBlocks;
List<Button> allButtons;
List<PlayHead> allPlayHeads;
LinkedList<PlayHead> killPlayHeads;


Cursor mouse;


boolean isInitiated = false;

void setup()
{
  size(displayWidth, displayHeight, P2D);

  noStroke();
  fill(0);

  loop();
  frameRate(60);

  hint(ENABLE_NATIVE_FONTS);
  font = createFont("Arial", 18);
  scale_factor = height/table_size;

  //SHAPE Setup
  beatShadow = sinCircle(0, 0, block_diameter/2, 0, 8, block_diameter/20);
  dashCircle = dashedCircle(0, 0, block_diameter, 10);
  playShadow = polygon(block_diameter * .62, 6);
    playShadow.disableStyle();
  circleShadow = createShape(ELLIPSE, 0, 0, block_diameter, block_diameter);
    circleShadow.disableStyle();


  // we create an instance of the TuioProcessing client
  // since we add "this" class as an argument the TuioProcessing class expects
  // an implementation of the TUIO callback methods (see below)
  tuioClient  = new TuioProcessing(this);
  minim = new Minim(this);

  SetupClipDict();
  SetupFuncMap();
  SetupBoolMap();
  SetupIdToType();
  SetupBlockMap();
  SetupCursorMap();
  SetupIdToEffect();

  allBlocks = new ArrayList<Block>();
  missingBlocks = new ArrayList<Block>();
  killBlocks = new LinkedList<Block>();
  allFunctionBlocks = new ArrayList<FunctionBlock>();
  allButtons = new ArrayList<Button>();
  allPlayHeads = new ArrayList<PlayHead>();
  killPlayHeads = new LinkedList<PlayHead>();

  cursors = new ArrayList<Cursor>();

  //ICONS
  float scaleFactor = 1;
  lock_reg = loadImage("images/lock.png");
  lock_inv = loadImage("images/lock_inv.png");
  scaleFactor = ((float)block_diameter/3.0) / (float)lock_reg.height;
  lock_reg.resize((int)(lock_reg.width * scaleFactor), (int)(lock_reg.height * scaleFactor));
  lock_inv.resize((int)(lock_inv.width * scaleFactor), (int)(lock_inv.height * scaleFactor));

  unlock_reg = loadImage("images/unlock.png");
  unlock_inv = loadImage("images/unlock_inv.png");
  scaleFactor = ((float)block_diameter/3.0) / (float)unlock_reg.height;
  unlock_reg.resize((int)(unlock_reg.width * scaleFactor), (int)(unlock_reg.height * scaleFactor));
  unlock_inv.resize((int)(unlock_inv.width * scaleFactor), (int)(unlock_inv.height * scaleFactor));

  lock = lock_reg;
  unlock = unlock_reg;
  
  isInitiated = true;
  millisPerBeat = 60000/bpm;
  //playButt = new PlayButton(width - 50,height - 50,0,100);

  if (debug) {
    //FunctionBlock funcTest = new FunctionBlock(500,500, 0);
    //ClipBlock testCLip = new ClipBlock(700,500, 1);
    //ConditionalBlock testCond = new ConditionalBlock(900,500);
    //BooleanBlock testBool = new BooleanBlock(900, 200);
  }
}


void draw()
{

  beatNo = (millis() /millisPerBeat);
  background(invertColor ? 0 : 255);
      cornerBeatGlow();

  if (debug) {
    
    //shape(playShadow, 400,400);
  }

  if (showFPS) {
    textSize(32);
    textAlign(LEFT, TOP);
    fill(255, 0, 0);
    text((int)frameRate, 80, 80);
  }


  textFont(font, 18*scale_factor);

  killRemoved();
  TuioUpdate();


  for (Cursor c : cursors) {
    c.Update();
  }

  for (Block b : allBlocks) {
    b.inChain = false;
    if (!(b instanceof FunctionBlock))b.blockColor = color(255);
  }

  for (FunctionBlock func : allFunctionBlocks) {
    func.startUpdatePath();
  }

  for (Block b : allBlocks) {

    b.Update();

    if (b.leadsActive) {
      b.drawLeads();
    }

    b.drawShadow();


  }






  for (Button b : allButtons) {
    if (b.isShowing)
      b.drawButton();
  }


  for (PlayHead p : allPlayHeads) {
    p.Update();
    p.draw();
  }






  if (hoverDebug) {
    HoverDebug();
  }

}


boolean sketchFullScreen() {
  return (fullscreen);
}


void keyPressed() {
  if (key == ' ') {
    println("space " + millis());
    for (FunctionBlock func : allFunctionBlocks) {
      func.execute();
    }
  }
  if (key == 'i') {
    invertColor = !invertColor;   
   if(invertColor){
     lock = lock_inv;
     unlock = unlock_inv;
   } 
   else{
     lock = lock_reg;
     unlock = unlock_reg;
   }
  }
}

void Play() {
  for (FunctionBlock func : allFunctionBlocks) {
    func.execute();
  }
}

void mousePressed() {
  mouse = new Cursor();
}

void mouseReleased() {
  mouse.OnRemove();
}

void HoverDebug() {
  Block[] blocks = new Block[allBlocks.size()];
  allBlocks.toArray(blocks); // fill the array  
  for (Block b : blocks) {
    if (b.IsUnder(mouseX, mouseY)) {
      Tooltip(new String[] {
        "symbol id: " + b.sym_id, 
        "x: " + b.x_pos, 
        "y: " + b.y_pos, 
        "rotation: " + b.rotation, 
        "in chain? " + b.inChain, 
        "children: " + Arrays.toString(b.children)
      }
      );
    }
  }
}


void killRemoved() {
  while (killBlocks.peek () != null) {
    killBlocks.pop().Die();
  }
  while (killPlayHeads.peek () != null) {
    killPlayHeads.pop().Die();
  }
}

void cornerBeatGlow() {
  float beatPercent = (1.0 - ((float)(millis() % (millisPerBeat)) / (float)(millisPerBeat)));
  int glowRadius = (int)(beatPercent  * 300);
  color innerCol = color(invertColor ? 0 : 255);
  color outerCol = color(invertColor ? 100 : 150);

  fill(outerCol);
  noStroke();
  ellipse(0, 0, glowRadius, glowRadius);
  ellipse(width, 0, glowRadius, glowRadius);
  ellipse(0, height, glowRadius, glowRadius);
  ellipse(width, height, glowRadius, glowRadius);
  /*
  radialGradient(0, 0, glowRadius, c1, c2);
   radialGradient(width, 0, glowRadius, c1, c2);
   radialGradient(0, height, glowRadius, c1, c2);
   radialGradient(width, height, glowRadius, c1, c2);
   */
}

