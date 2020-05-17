
int generation = 0;
Car[] population = new Car[40]; //40 cars in population
PVector goal = new PVector(0.9,0); //goal position on the screen

boolean isPopulationDead = false;
float bestFitness = 0;
ArrayList<Shape> Shapes = new ArrayList();

boolean wasPressed = false;
float pressedX, pressedY;
float verX, verY;
Shape selected;
Shape current;

PImage car;
PImage finish; 
boolean textureFailed;

void setup(){
  
  size(640,640,P3D);
  colorMode(RGB,1.0);
  ortho(-1,1,1,-1);
  resetMatrix();
  
  //initializing the population
  for(int i=0; i< population.length ; i++){
    population[i] = new Car(new PVector(-0.9,0),1,1,1,null);
    population[i].generateGenes();
  }
  println(generation);
  
  //adding one obstacle 
  Shapes.add(new Shape(0.25,0.0,0.05,0.4));
  
  // loading the textures
  // if the textures fail, white blocks are used to draw cars
  try{
    textureMode(NORMAL); 
    car = loadImage("/assets/car.png");
    finish = loadImage("/assets/finish.png");
    textureWrap(REPEAT);
    textureFailed = false;
  }
  catch(Exception e){
    textureFailed = true;
  }
  if(finish==null || car == null){
    textureFailed = true;
  }
}

//draw function is repeatedly called at 60 times a second
void draw(){
  
  background(0,0,0.1);
  
  //if the population is dead create a new one
  if(isPopulationDead){
     generateNewPopulation();
     isPopulationDead = false;//reset
     generation++;
     println();
     println("Generation: "+ generation);
     println("Size:   " + population.length);
     println("Best Fitness:   " + bestFitness);
     bestFitness = 0;
   }
   else{
     //else draw it on the screen
     drawPopulation();
     
   }
   //draw the obstacles
   drawShapes();
   
   //draw the goal
   fill(1,0,0);
   stroke(1);
   ellipse(goal.x,goal.y,0.05,0.05);
   
   //load the textures
   if(!textureFailed){
     imageMode(CENTER);
     image(finish,goal.x+0.04,goal.y,0.1,0.1);
   }
   
   // if mouse pressed
   if(wasPressed){
     //if a shape is selected deselect it
     if(selected!=null){
       selected.selected = false;
       selected = null;
     }
     else if(current == null){
       //if current is not set, check if mouse hits a shape and select it
       for(int i =Shapes.size()-1 ; i >= 0; i--){
              if(Shapes.get(i).hit(pressedX, pressedY)){
                selected = Shapes.get(i);
                selected.selected = true;
                break;
              }
            else{
              Shapes.get(i).selected = false;
              selected=null;
            }
          }
          if(selected==null){
            //ifclick was on the drawing area
              //drawing something
              verX = pressedX;
              verY = pressedY;
              current = new Shape();
              current.addVertexToPolygon(new float[]{pressedX, pressedY});
          }
   }
   else if(current != null){
     //if current is set check if click was on first vertex
    if(pressedX <= verX+10f/width && pressedX >= verX-10f/height 
          && pressedY <= verY+10f/width && verY-10f/height <= pressedY){
          if(current != null){
              Shapes.add(current);
          }
          current = null;
        }//add the vertex
        else{
          //println(pressedX,pressedY);
          current.addVertexToPolygon(new float[]{pressedX, pressedY});
        }//add the vertex
   }
   wasPressed = false;
   }
   
   //rubberbanding
   if(current!=null){
       stroke(1,1,1);
       ellipse(verX,verY,1f/width*12,1f/height*12);
       beginShape(LINE_STRIP);
       for(float[] vertices: current.getVertices()){
           vertex(vertices[0],vertices[1]);
       }
       float x = 2.0 * mouseX / width - 1, y = 2.0 * (height-mouseY+1) / height - 1;
       vertex(x,y);
       endShape();
   }
}

/*
* drawPopulation on the screen and update it
*/
public void drawPopulation(){
  for(int i=0; i< population.length ; i++){
    population[i].drawCar();
    population[i].update();
    if(population[i].isDead){
      isPopulationDead = true;
    }
  }
}
/*
* drawShpes draws the obstacles on the screen
*/
public void drawShapes(){
  for(int i=0; i< Shapes.size() ; i++){
    stroke(1);
    Shapes.get(i).drawShape();
  }
}

/*
* Method to generate a New population, uses Genetic Algorithm
* to generate a new population
*/
public void generateNewPopulation(){
  //selection step
  ArrayList<Car> selectionPool = new ArrayList();
  for(int i =0; i<population.length ;i++){
    float fitness = population[i].fitness;
    if(fitness>bestFitness){
      bestFitness = fitness;
      }
     for(int j =0 ; j< fitness*100;j++){
      selectionPool.add(population[i].clone());
      }
   }  
  
  //crossover and replacing the old population with new population
  for(int i=0 ; i<population.length;i++){
    Car parent1 =selectionPool.get((int) random(0,selectionPool.size()));
    Car parent2 =selectionPool.get((int) random(0,selectionPool.size()));
    int strategy = (int)random(1,5);
    Car crossOvered = crossover(parent1, parent2, strategy);
    population[i] = crossOvered; 
  }
  
  //mutation of the new population
    mutatePopulation(1);
  
}

/*
*  Crossover step in genetic algorithm
*/
public Car crossover(Car parent1, Car parent2, int strategy){
  ArrayList<PVector> Genes1 = parent1.getGenes();
  ArrayList<PVector> Genes2 = parent2.getGenes();
  ArrayList<PVector> childGenes = new ArrayList();
    
  if(strategy==1){
    for(int i=0; i<Genes1.size();i++){
      if(i<=Genes1.size()/2){
        childGenes.add(Genes1.get(i));
      }
      else{
          childGenes.add(Genes2.get(i));
      }
    }
  }
  if(strategy==2){
    int cutoff = ((int) random(0,Genes1.size()));
    for(int i=0; i<Genes1.size();i++){
      if(i<=cutoff){
        childGenes.add(Genes1.get(i));
      }
      else{
         childGenes.add(Genes2.get(i));
      }
    }
  }
  if(strategy == 3){
    for(int i=0; i<Genes1.size();i++){
      int cutoff = ((int) random(0,2));
      if(cutoff==0){
        childGenes.add(Genes1.get(i));
      }
      else{
         childGenes.add(Genes2.get(i));
      }
    }
  }
  if(strategy == 4){
    //inherit more from the dominant parent, 70% or more
    int cutoff = ((int) random(70,100));
    float fit1 = parent1.fitness;
    float fit2 = parent2.fitness;
    if(fit1>=fit2){
    for(int i=0; i<Genes1.size();i++){
      if(i<=(cutoff/100)*Genes1.size()){
        childGenes.add(Genes1.get(i));
      }
      else{
         childGenes.add(Genes2.get(i));
      }
    }
  }
  else{
    for(int i=0; i<Genes1.size();i++){
      if(i>(cutoff/100)*Genes1.size()){
        childGenes.add(Genes1.get(i));
      }
      else{
         childGenes.add(Genes2.get(i));
      }
    }
  }
  }
  return new Car(new PVector(-0.9,0),1,1,1,childGenes);
}

/*
*  Mutation step in genetic algorithm
*/
public void mutatePopulation(float rate){
  for(int i =0 ;i < population.length;i++){
    population[i].mutateGenes(rate);
  }
}

class Car{
  
  PVector pos; //origin
  float r, g, b; //do not need this now as I added the textures
  ArrayList<PVector> Genes;
  
  int lifeSpan = 200; //should have a lifeSpan
  int currentPos = 0;
  boolean isDead = false;
  float fitness = 0;
  boolean crashed = false;
  
  PVector velocity = new PVector(0,0);
  
  //constructor for a car agent
  public Car(PVector pos, float r,float g,float b, ArrayList<PVector> Genes){
    this.pos = pos;
    this.r = r;
    this.g = g;
    this.b = b;
    this.Genes = Genes;
  }
  
  //generate genes randomly
  public void generateGenes(){
    this.Genes = new ArrayList();
    for(int i= 0; i<200; i++){
      PVector velocity = new PVector(random(-1.0/width,1.0/width), random(-1.0/height,1.0/height));
      this.Genes.add(velocity);
    }
  }
  //update the position of the car
  public void update(){
    velocity.add(Genes.get(currentPos));
    //check if it hit any obstacle
    if(hit()){
      crashed = true;
    }
    
    if(fitness<1&&!crashed){
      pos.add(velocity);
    }
    currentPos++;
    lifeSpan--;
    if(lifeSpan == 0){
      isDead = true;
    }
    
    //calculate a new fitness
    findFitness();
  }
  
  //draw the car on screen
  public void drawCar(){
    pushMatrix();
    noStroke();
    fill(r, g, b,0.8);
    translate(pos.x,pos.y);
    rotate(velocity.heading());
    translate(-pos.x,-pos.y);
    if(!textureFailed){
      beginShape(QUADS);
      texture(car);
      vertex(pos.x-0.05,pos.y+0.02,0,0,0.7);
      vertex(pos.x+0.05,pos.y+0.02,0,1,0.7);
      vertex(pos.x+0.05,pos.y-0.02,0,1,0.25);
      vertex(pos.x-0.05,pos.y-0.02,0,0,0.25);
      endShape();
    }
    else{
      beginShape(QUADS);
      vertex(pos.x-0.05,pos.y+0.02);
      vertex(pos.x+0.05,pos.y+0.02);
      vertex(pos.x+0.05,pos.y-0.02);
      vertex(pos.x-0.05,pos.y-0.02);
      endShape();
    }
    
    popMatrix();
  }

  //finds fitness
  public float findFitness(){
    
    //keeps the higher one
    float newFitness = 1/(dist(pos.x, pos.y, goal.x, goal.y)+1); 
    if(fitness < newFitness){
      fitness = newFitness;
      
      //fitness boost to cars that reach the goal
      if(fitness > 0.92 && fitness <=1){
          fitness = fitness*5;
      }
    }
    return fitness;  
  }
  
  public ArrayList<PVector> getGenes(){
    return Genes;
  }
  
  //mutating the genes of an agent
  public void mutateGenes(float rate){
    for(int i = 0; i< Genes.size(); i++){
      int value = ((int)random(0,100));
      boolean shouldMutate = ( value < rate);
      if(shouldMutate){
        Genes.set(i,new PVector(random(-1.0/width,1.0/width), random(-1.0/height,1.0/height))); 
      }
    }
  }
  
  
  //clnoe function
  public Car clone(){
    ArrayList<PVector> clonedGenes = new ArrayList();
    for(PVector gene: Genes){
      clonedGenes.add(gene.copy());
    }
    Car cloned = new Car(new PVector(0.9,0),1,1,1,clonedGenes);
    return cloned;
  }
  
  //hit testing
  public boolean hit(){
    for(Shape rect: Shapes){
      boolean hitAny = rect.hit(pos.x, pos.y);
      if(hitAny){
        return true;
      }
    }
    return false; //<>//
 }
}

/*
* functions checks if two lines intersect, required for hit testing
* uses the parametric equation of two lines
*/
boolean checkIntersection(float x1,float y1, float x2,float y2, float x3,float y3,
  float x4,float y4){
    float ta;
    float tb;
    //line-line intersection method
    ta = ((x4 - x3)*(y1-y3)) - ((y4-y3)*(x1-x3));
    ta = ta/((y4 - y3)*(x2-x1)) - ((x4-x3)*(y2-y1));
    
    tb = ((x2 - x1)*(y1-y3)) - ((y2-y1)*(x1-x3));
    tb = tb/((y4 - y3)*(x2-x1)) - ((x4-x3)*(y2-y1));
    
    return (ta<=1.0 && ta>0.0)&&(tb<=1.0 && tb>0.0);
}

//Obstacles

class Shape{
  float x, y;
  float l;
  float w;
  
  ArrayList<float[]> polyVertices;
  boolean rectangle;
  boolean selected = false;
  float[][] vertices = new float[4][];//quads
  
  //can be a predefined quadilateral
  public Shape(float x,float y,float l,float w){
    this.x = x;
    this.y = y;
    this.l = l;
    this.w = w;
    rectangle = true;
    this.vertices[0] = new float[]{x-l/2,y+w/2};
    this.vertices[1] = new float[]{x+l/2,y+w/2};
    this.vertices[2] = new float[]{x+l/2,y-w/2};
    this.vertices[3] = new float[]{x-l/2,y-w/2};
  }
  
  //or a polygon
  public Shape(){
    polyVertices = new ArrayList();
    rectangle = false;
  }
  
  public void addVertexToPolygon(float[] vertex){
    polyVertices.add(vertex);
  }
  
  //draw the obstacle on the screen
  public void drawShape(){
    if(rectangle){
      noStroke();
      fill(1);
      beginShape(QUADS);
      vertex(vertices[0][0],vertices[0][1]);
      vertex(vertices[1][0],vertices[1][1]);
      vertex(vertices[2][0],vertices[2][1]);
      vertex(vertices[3][0],vertices[3][1]);
      endShape();
      if(selected){
        strokeWeight(2.0);
        stroke(1,0.2,0.2);
        beginShape(LINE_LOOP);
        for(int i = 0 ;i < vertices.length ;i++){
          vertex(vertices[i][0],vertices[i][1]); 
        }
        endShape();
      }
    }
    else{
      beginShape(POLYGON);
      for(int i = 0 ;i < polyVertices.size() ;i++){
        vertex(polyVertices.get(i)[0],polyVertices.get(i)[1]);
      }
      vertex(polyVertices.get(0)[0],polyVertices.get(0)[1]);
      endShape();
      
     if(selected){
        strokeWeight(2.0);
        stroke(1,0.2,0.2);
        beginShape(LINE_LOOP);
        for(int i = 0 ;i < polyVertices.size() ;i++){
          vertex(polyVertices.get(i)[0],polyVertices.get(i)[1]); 
        }
        endShape();
      }
    }
  }
  /*
  * check if a point is inside a rectangle
  * used by cars.hit() to determine if a car is inside a polygon
  */
    public boolean hit(float pressedX, float pressedY){
    int numWinding = 0;
    if(!rectangle){
    for(int i = 0 ; i <polyVertices.size() ; i++){
      boolean intersection = checkIntersection(pressedX,pressedY,width,pressedY,polyVertices.get(i)[0],
              polyVertices.get(i)[1], polyVertices.get((i+1) % polyVertices.size())[0],
                polyVertices.get((i+1) % polyVertices.size())[1]);
      if(intersection){
             //else
             if(polyVertices.get((i+1) % polyVertices.size())[1] -polyVertices.get(i)[1]<0){
             numWinding++; //y increasing
             }
           else if(polyVertices.get((i+1) % polyVertices.size())[1] - polyVertices.get(i)[1]>0){
             numWinding--; //y decreasing
           }
        }
     }
     return numWinding != 0;
    }
    else{
        for(int i = 0 ; i <vertices.length ; i++){
      boolean intersection = checkIntersection(pressedX,pressedY,width,pressedY,vertices[i][0],
                vertices[i][1], vertices[(i+1) % vertices.length][0],
                  vertices[(i+1) % vertices.length][1]);
        if(intersection){
               //else
               if( vertices[(i+1) % vertices.length][1] - vertices[i][1]<0){
               numWinding++; //y increasing
               }
             else if(vertices[(i+1) % vertices.length][1] - vertices[i][1]>0){
               numWinding--; //y decreasing
             }
        }
     }
     return numWinding != 0;
    }   
}
  public ArrayList<float[]> getVertices(){
    return polyVertices;
  }
}

void mousePressed() {
  float x = 2.0 * mouseX / width - 1, y = 2.0 * (height-mouseY+1) / height - 1;
  //converting from window coordinates to eye coordinates
  wasPressed = true;
  pressedX = x ;
  pressedY = y ;
}

//to remove the obstacles from the screen
void keyPressed(){
  if(key == 'x'){
    if(selected != null){
      Shapes.remove(selected);
    }
    else{
      Shapes = new ArrayList();
      Shapes.add(new Shape(0.25,0.0,0.05,0.4));
    }
  }

}
