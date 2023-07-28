final static int iterations = 4;
final static int window_width = 1920;
final static int window_height = 1080;
boolean dr = false;

int operations = 0;

int pix = 350; 
float fade = 1;
boolean colorMode = true; //True = HSB, false = RGB
int visco = 0;
char clear = 'c';
int r = 50;
int bomb = 100;
int brush = pix/50;

int UNITx = window_width/pix;
int pixY = window_height/UNITx;

boolean cstagel(int x){
  return x > 1;
}

boolean bModeOn (int bomb){
  return bomb > 0;
}

Fluid fluid;
Stone st;

int StoneR = 20;
int shape = 10;
PImage Stonetx;
int UI = 100;

void settings() {

  fullScreen();
  //size(window_width, window_height);
}


void setup() {
  //print(len);
  if(brush < 1){
    brush = 1;
  }
  background(127);
  st = new Stone(width/2, height/2, 10);
  fluid = new Fluid(0.01, 0, visco);
}

void mouse() {
  float vX = (mouseX - pmouseX)/2;
  float vY = (mouseY - pmouseY)/2;
  int amt = 20;
  if (mouseButton == LEFT && mouseButton != RIGHT) {
    for (int i = 1; i <= brush; i++) {
      fluid.addDensity(mouseX/UNITx, mouseY/UNITx, amt, brush);
    }
  }
  if (mouseButton != RIGHT && mouseButton != CENTER) {
    fluid.addv(mouseX/UNITx, mouseY/UNITx, vX, vY);
  }

  if (mousePressed) {
    if (mouseButton == RIGHT) {
      //pressed = true;
      //st.update();
      st.visible = true;
      st.s = StoneR;
    }
  }

  if (mouseButton == CENTER) { 
    //pressed = true;
    //st.update();
    st.incr();
  }
}
int count;
void mouseWheel(MouseEvent event) {


  count += event.getCount();
  shape = count/2;
  if (shape < 0)shape = -shape;
}
int dx = mouseX;
int dy = mouseY;

void mouseReleased() {
  if (mouseButton == RIGHT) {
    if (st.visible) {
      dx = mouseX;
      dy = mouseY;
      st.dr = true;
    }
  }
}

void draw() {
  if(mouseX<width-UI){
  noCursor();
    //if(pix > 40){
    //  pix -= 20;
    //  pixY = window_height/UNITx;
    //}
  }
  else{
   cursor(ARROW); 
  }
  background(0);
  mouse();
  fluid.step();
  fluid.keyPressed();
  fluid.show();
  st.update();
  if (st.dr) {
    //st.drop(dx, dy);
    st.skip(1, 1, 5);
  }
  //if(!st.dr){
  st.render();
  //}

}


void polygon(float x, float y, float radius, int points) {
  float angle = TWO_PI / points;
  fill(127);
  beginShape();
  //texture(Stonetx);
  for (float a = PI*1.5; a < PI*3.5; a += angle) {
    float sx = x + cos(a) * radius;
    float sy = y + sin(a) * radius;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}

int IX(int x, int y){
  x = constrain(x, 0, pix-1);
  y = constrain(y, 0, pixY-1);
  return x + y * pix;
}

class Fluid{

  float dt;
  float diff;
  float visc;
    
  float[] s;
  float[] density;
    
  float[] Vx;
  float[] Vy;
  //float[] Vz;

  float[] Vx0;
  float[] Vy0;
  //float[] Vz0;
  
  Fluid(float dt, float diffusion, float viscosity){
    
    st = new Stone(width/2, mouseY, r);
    this.dt = dt;
    this.diff = diffusion;
    this.visc = viscosity*0.0000001;
    this.s = new float[pix*pixY];
    this.density = new float[pix*pixY];
    this.Vx = new float[pix*pixY];
    this.Vy = new float[pix*pixY];
    this.Vx0 = new float[pix*pixY];
    this.Vy0 = new float[pix*pixY];  
    
    
  }
  
  
  
  
  void step(){
    float visc     = this.visc;
    float diff     = this.diff;
    float dt       = this.dt;
    float[]Vx      = this.Vx;
    float[]Vy      = this.Vy;
    float[]Vx0     = this.Vx0;
    float[]Vy0     = this.Vy0;
    float[]s       = this.s;
    float[]density = this.density;
    
    diff(1, Vx0, Vx, visc, dt);
    diff(2, Vy0, Vy, visc, dt);
    
    project(Vx0, Vy0, Vx, Vy);
    
    advect(1, Vx, Vx0, Vx0, Vy0);
    advect(2, Vy, Vy0, Vx0, Vy0);
    project(Vx, Vy, Vx0, Vy0);
    
    diff(0, s, density, diff, dt);
    advect(0, density, s, Vx, Vy);
    //println(operations);
    operations = 0;
 
  }
  
  
  void addDensity(int x, int y, int den, int size){
    
   if(st.dr && bModeOn(bomb)){
    this.density[IX(x, y)] += den;
      for(int i = 1; i <= bomb; i++){
        this.density[IX(x-i,y  )] += den;
        this.density[IX(x+i,y  )] += den;
        this.density[IX(x  ,y-i)] += den;
        this.density[IX(x  ,y+i)] += den;
        this.density[IX(x-i,y-i)] += den;
        this.density[IX(x-i,y+i)] += den;
        this.density[IX(x+i,y-i)] += den;
        this.density[IX(x+i,y+i)] += den;
      }
   }
      
   if(cstagel(brush) || !bModeOn(bomb)){   
     for(int i = -size/2; i<=size/2; i++){
       for(int j = -size/2; j<=size/2; j++){        
         this.density[IX(x+i, y+j)] += den;
       }
     }     
   }
   else{
     this.density[IX(x, y)] += den;
   }
  }
  
  
  
  
void keyPressed(){
  if(key == clear){
    for(int j = 0; j < this.density.length; j++){
      this.density[j] -= 5;
    }
  }
  key = 'q';
}

  
  void addv(int x, int y, float Vx, float Vy){
    int i = IX(x, y);
    this.Vx[i] += Vx;
    this.Vy[i] += Vy;
  }
  
  
  
  
  void diff(int b, float[] x, float[] x0, float diff, float dt){
    float a = dt * diff * (pix - 2) * (pix - 2);
    linS(b, x, x0, a, 1+6*a);
  }
  
  
  
  
  void linS(int b, float[] x, float[] x0, float a, float c){
    float cRecip = 1.0 / c;
    for (int k = 0; k < iterations; k++) {
      for (int j = 1; j < pixY - 1; j++) {
         for (int i = 1; i < pix - 1; i++) {
           operations ++;
            x[IX(i, j)] =
                (x0[IX(i , j)]
            + a*(x[IX(i+1, j)]
              +x[IX(i-1, j  )]
              +x[IX(i  , j+1)]
              +x[IX(i  , j-1)]
             )) * cRecip;
          }
       }
    }
    set_bnd(b, x);
  }  
  
  
  
  
  void project(float[] velocX, float[] velocY, float[] p, float[] div){
  for (int i = 1; i < pix - 1; i++) {
    for (int j = 1; j < pixY - 1; j++) {
      div[IX(i, j)] = -0.5f*(
      velocX[IX(i+1, j)]
      -velocX[IX(i-1, j)]
      +velocY[IX(i  , j+1)]
      -velocY[IX(i  , j-1)]
      )/pix;
      p[IX(i, j)] = 0;
      operations ++;
    }
  }
  set_bnd(0, div); 
  set_bnd(0, p);
  linS(0, p, div, 1, 6);
  
  for (int i = 1; i < pix - 1; i++) {
    for (int j = 1; j < pixY - 1; j++) {
      velocX[IX(i, j)] -= 0.5f * (  p[IX(i+1, j)]
                           -p[IX(i-1, j)]) * pix;
      velocY[IX(i, j)] -= 0.5f * (  p[IX(i, j+1)]
                           -p[IX(i, j-1)]) * pix;
      operations ++;
    }
  }

  set_bnd(1, velocX);
  set_bnd(2, velocY);
    
 }
 
 
 
 
 void advect(int b, float[] d, float[] d0,  float[] velocX, float[] velocY){
  float i0, i1, j0, j1;
    
  float dtx = dt * (pix - 2);
  float dty = dt * (pix - 2);

    
  float s0, s1, t0, t1;
  float tmp1, tmp2, x, y;
  float pixfloat = pix;
  float pixfloatY = pixY;
  float ifloat, jfloat;
  int i, j;
    
  for(i = 1, ifloat = 1; i < pix - 1; i++, ifloat++) {
    for(j = 1, jfloat = 1; j < pixY - 1; j++, jfloat++) { 
        operations ++;
        tmp1 = dtx * velocX[IX(i, j)];
        tmp2 = dty * velocY[IX(i, j)];
        x    = ifloat - tmp1; 
        y    = jfloat - tmp2;
                
        if(x < 0.5f) x = 0.5f; 
        if(x > pixfloat + 0.5f) x = pixfloat + 0.5f; 
        i0 = floor(x); 
        i1 = i0 + 1.0f;
        
        if(y < 0.5f) y = 0.5f; 
        if(y > pixfloatY + 0.5f) y = pixfloatY + 0.5f; 
        j0 = floor(y);
        j1 = j0 + 1.0f; 
                
        s1 = x - i0; 
        s0 = 1.0f - s1; 
        t1 = y - j0; 
        t0 = 1.0f - t1;
                
        int i0i = int(i0);
        int i1i = int(i1);
        int j0i = int(j0);
        int j1i = int(j1);

        d[IX(i, j)] = 
                
             s0 * ( t0 * d0[IX(i0i, j0i)] + t1 * d0[IX(i0i, j1i)])
            +s1 * ( t0 * d0[IX(i1i, j0i)] + t1 * d0[IX(i1i, j1i)]);
            }
        }
    set_bnd(b, d);
  }
  
  
  
  
 void set_bnd(int b, float[] x){

   for(int i = 0; i < pix - 1; i++) {
       x[IX(i, 0   )] = b == 2 ? -x[IX(i, 1   )] : x[IX(i, 1   )];
       x[IX(i, pixY-1)] = b == 2 ? -x[IX(i, pixY-2)] : x[IX(i, pixY-2)];
       operations ++;
   }
    
   for(int j = 1; j < pixY - 1; j++) {
       x[IX(0    , j)] = b == 1 ? -x[IX(1   ,  j)] : x[IX(1    ,  j)];
       x[IX(pix-1, j)] = b == 1 ? -x[IX(pix-2, j)] : x[IX(pix-2, j)];
       operations ++;

   }
    
    x[IX(0, 0)]          = 0.5f * (x[IX(1, 0)]+ x[IX(0, 1)]);
    x[IX(0,pixY-1)]      = 0.5f * (x[IX(1, pixY-1)] + x[IX(0, pixY-2)]);
    x[IX(pix-1, 0)]      = 0.5f * (x[IX(pix-2, 0)] + x[IX(pix-1, 1)]);                     
    x[IX(pix-1, pixY-1)] = 0.5f * (x[IX(pix-2, pixY-1)] + x[IX(pix-1, pixY-2)]);
 }
  
  void show(){
    float UNITx = window_width/pix;
    //println(UNITx, pixY);

    for(int i = 0; i < pix; i++) {
      for(int j = 0; j < pixY; j++) {
        operations ++;
        float x = i*UNITx;
        float y = j*UNITx;
        float c = this.density[IX(i, j)];
        colorMode(HSB);
        fill(260 - c, 150, 250);
        //fill(255-c);
        noStroke();
        rect(x, y, UNITx, UNITx);
        
        float d = density[IX(i, j)];
        density[IX(i, j)] = constrain(d-fade/10, 30, 250);     
      }
    }  
  }
}




public class Stone{
  int x;
  int y;
  int s;
  boolean visible = false;
  boolean dr = false;
  int cs;
  int current_skip;
  boolean decr = true;
  boolean p_decr = true;
  Stone(int x, int y, int s){
    this.x = x;
    this.y = y;
    this.s = s;
    this.current_skip = 0;
    cs = 20;
  }
  
  void update(){
    this.x = mouseX;
    this.y = mouseY;

  }
  
  void incr(){
    this.s += 1;
    cs = this.s;
  }
  
  void skip(int vX, int vY, int skips){
    if(this.current_skip < skips){
      println(decr);
      println(this.s);
      println(this.current_skip);
      vX *= 0.99f;
      vY *= 0.99f;
      this.x += vX;
      this.y += vY;
      if (decr && this.current_skip % 1 == 0){
        decr = this.s - 20 * 0.01 >= 20 * 0.2; 
        this.s -= cs * 0.01;
      }
      else{
       decr = this.s > 20;
       this.s += 20 * 0.01;

      }
      if(decr != p_decr){
       this.current_skip += 0.5f; 
       p_decr = decr;
      }
    }
    else{
     this.drop(mouseX, mouseY, true);
     this.current_skip = 0;
    }
  }
  
  void drop(int dx, int dy, boolean is_skip){

    this.x = dx;
    this.y = dy;
    float threshold;
    //if(!is_skip) threshold = UNITx*2;
    //else threshold = cs * 0.8;
    
    //if(this.s > threshold){
    //  this.s -= cs* 0.05;
    //}
    //else if(this.s <= UNITx*2){
       fluid.addDensity(dx/UNITx, dy/UNITx,window_width/3, cs/UNITx/2);
       this.dr = false;
       this.visible = false; 
       for(int i = 0; i <= PI*100; i++){
         float vX = cos(i/100)*cs/100;
         float vY = sin(i/100)*cs/100;
         float ver = 0.5;
         fluid.addv(dx/UNITx  , dy/UNITx+4,  0,  ver);
         fluid.addv(dx/UNITx  , dy/UNITx-4,  0,  -ver);
         fluid.addv(dx/UNITx+4  , dy/UNITx,  ver,  0);
         fluid.addv(dx/UNITx-4  , dy/UNITx,  -ver,  0);
         fluid.addv(dx/UNITx+4, dy/UNITx+4,  vX,  vY);
         fluid.addv(dx/UNITx-4, dy/UNITx+4, -vX,  vY);
         fluid.addv(dx/UNITx-4, dy/UNITx-4, -vX, -vY);
         fluid.addv(dx/UNITx+4, dy/UNITx-4,  vX, -vY);
      }      
    //}
  }
  

  void render(){
    if(this.visible){

      if(shape%4 == 0) polygon(this.x, this.y, this.s, 50);
      if(shape%4 == 1) polygon(this.x, this.y, this.s, 3);
      if(shape%4 == 2) polygon(this.x, this.y, this.s, 4);
      if(shape%4 == 3) polygon(this.x, this.y, this.s, 5);  
   }
  }
}

int starting_pos = pix * UNITx;
int len = window_width - starting_pos;
//int slider_width = 10;
//int slider_radius = 10;

//class Slider{
// Slider(String categ, int y){
//  this.categ = categ;
//  this.y = y;
// }
 
// void slide(int x){
   
// }
 
// void render(){
//  rect(starting_pos, this.y, len, slider_width);
//  ellipse(this.x, this.y, slider_radius * 2, slider_radius * 2);
// }
//}

class UI{

  UI(){
    
  }
  
  void switch_color_mode(){
    colorMode = !colorMode;
    
  }
  
  
  
}
