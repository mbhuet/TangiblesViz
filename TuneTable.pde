// we need to import the TUIO library
// and declare a TuioProcessing client variable

//set resolution to 1280x1024

import ddf.minim.spi.*;
import ddf.minim.signals.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.ugens.*;
import ddf.minim.effects.*;

import java.util.Map.*;
import java.util.Iterator.*;
import java.util.concurrent.*;


// Creates Variable and junk  
Minim minim;
AudioOutput out;
FilePlayer filePlayer;
Delay myDelay;

//PlayButton playButt;




boolean debug = true;
boolean invertColor = false;
boolean showFPS = false;
boolean hoverDebug = true;
boolean fullscreen = true;
boolean analyticsOn = true;

// these are some helper variables which are used
// to create scalable graphical feedback
float cursor_size = 15;
int block_diameter = 120;
float table_size = 760;
float scale_factor = 1;
float cur_size = cursor_size*scale_factor;
int bpm = 60;
int millisPerBeat;
int beatNo = 0;
PFont font;

static int display_width = 640;
static int display_height = 480;

PImage lock;
PImage unlock;

List<Block> allBlocks;
List<Block> missingBlocks;
List<Block> killBlocks;

List<Cursor> cursors;

List<FunctionBlock> allFunctionBlocks;
List<Button> allButtons;
List<PlayHead> allPlayHeads;

Cursor mouse;


boolean isInitiated = false;

void setup()
{
  if (fullscreen)  size(displayWidth, displayHeight);
  else    size(display_width, display_height);

  noStroke();
  fill(0);

  loop();
  frameRate(60);

  hint(ENABLE_NATIVE_FONTS);
  font = createFont("Arial", 18);
  scale_factor = height/table_size;

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
  killBlocks = new ArrayList<Block>();
  allFunctionBlocks = new ArrayList<FunctionBlock>();
  allButtons = new ArrayList<Button>();
  allPlayHeads = new ArrayList<PlayHead>();
  
  cursors = new ArrayList<Cursor>();


  float scaleFactor = 1;
  lock = loadImage("images/lock.png");
    scaleFactor = ((float)block_diameter/3.0) / (float)lock.height;
    lock.resize((int)(lock.width * scaleFactor), (int)(lock.height * scaleFactor));
  unlock = loadImage("images/unlock.png");
    scaleFactor = ((float)block_diameter/3.0) / (float)unlock.height;
    unlock.resize((int)(unlock.width * scaleFactor), (int)(unlock.height * scaleFactor));
  

  isInitiated = true;
  millisPerBeat = 6000/bpm;
  //playButt = new PlayButton(width - 50,height - 50,0,100);

  if (debug) {
    BeatBlock testBeat = new BeatBlock(400,400);
  }
}


void draw()
{
  background(invertColor ? 0 : 255);

  if (showFPS) {
    textSize(32);
    textAlign(LEFT, TOP);
    fill(255, 0, 0);
    text((int)frameRate, 10, 10);
  }
  
  beatNo = (millis() /millisPerBeat);
  //println("millis " + millis() + " beat " + beatNo + " rem " + millis()%millisPerBeat);
  
  textFont(font, 18*scale_factor);
  
  killRemoved();
  TuioUpdate();

  strokeWeight(5);
  stroke(0);
  
  
  for (Cursor c : cursors) {
    c.Update();
  }

  for (Block b : allBlocks) {
    b.Update();
    if (b.leadsActive)
      b.drawLeads();
    b.drawShadow();
    b.inChain = false;
  }
  
  for (Button b : allButtons) {
    if (b.isShowing)
      b.drawButton();
  }
  
  for (PlayHead p : allPlayHeads) {
    p.Update();
    p.draw();
  }
  for(FunctionBlock func : allFunctionBlocks){
      func.startUpdatePath();
    
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
    for(FunctionBlock func : allFunctionBlocks){
      func.execute();
    
    }
  }
}

void Play(){
  for(FunctionBlock func : allFunctionBlocks){
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
        "children: " + Arrays.toString(b.children)
      }
      );
    }
  }
}


void killRemoved(){
  for(Block b : killBlocks){
    b.Die();
  }
  killBlocks.clear();
}
