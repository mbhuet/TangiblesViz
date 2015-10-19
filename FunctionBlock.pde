class FunctionBlock extends Block {
  color funcColor;
  
  FunctionBlock(TuioObject tObj) {
    Init(tObj, 1);
    leadsActive = true;
    funcColor = color(0,255,0);
  }

  void Setup() {
    allFunctionBlocks.add(this);
    funcMap.put(sym_id, this);
  }

  void Update() {
    super.Update();
  }

  void OnRemove() {
        super.OnRemove();

    
  }
  
  void Die(){
    super.Die();
    allFunctionBlocks.remove(this);
    funcMap.remove(sym_id);
  }

    public void Activate(PlayHead play, Block previous) {
    super.Activate(play, previous);
    println("func activated");
    finish();
  }
  
  public int[] getSuccessors(){
    return new int[]{0};
  }
  
  
  void execute(){
     PlayHead pHead = new PlayHead(this, color(0, 102, 153));
  }
  
}

