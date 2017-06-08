//**************Presionar el mouse y moverlo hacia la dirección que querramos 
//que las luces vayan**********************

///////////////////////////////////////////////////////////////////////////////

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;


int CONTEO_PARTICULA = 256;
int PERIODO = 0;
float PARTICULA_ABAJO = 0.5;
float PARTICULA_ARRIBA = 1.2;
float SPRAY = 2.0;
float GRAVEDAD_TIERRA= 1.0 / 16.0;
float GRAVEDAD_LUNA = GRAVEDAD_TIERRA / 6.0;
float TERCERA_GRAVEDAD = GRAVEDAD_TIERRA * 2.5;
float GRAVEDAD = GRAVEDAD_TIERRA;
float TOLERANCIA = 0.3;
float DISTANCIA_FOCAL = 1000.0;
float DISTANCIA_INTERACCION = 4 * DISTANCIA_FOCAL;
Canvas3D canvas;
Particle sparks[] = new Particle[CONTEO_PARTICULA];
int nextSpark = 0;
int skipCount = 0;//inicial

Minim minim;
AudioPlayer player; //para que se reproduzca automaticamente

void setup() {
   minim = new Minim(this);
  
  player = minim.loadFile("piano.mp3");
//  song.play();//para que se reproduzca
player.play ();

  size(900, 680);
  background(0);
 
  canvas = new Canvas3D(DISTANCIA_FOCAL, DISTANCIA_INTERACCION);//para crear las canvas en 3D
  SoundBank soundBank = new SilentSoundBank();//SONIDO*******

  for (int i = 0; i < CONTEO_PARTICULA; i++) {//INICIALIZAR la particulas de la animacion
    sparks[i] = new Particle(random(256), random(256), random(256), soundBank.getRandomSound());//sonido y colores random para la animacion
  }
}


void mouseDragged() {//dibujar segun la velocidad y posicion del mouse
  if (skipCount >= PERIODO) {
   
    skipCount = 0;//iniciar el conteo
    Point3D prior = canvas.toModelCoordinates(pmouseX, pmouseY);
    Point3D current = canvas.toModelCoordinates(mouseX, mouseY);
    Vector3D velocity = current.diff(prior);//crea el efcto de luces, como de spray
    velocity.shift(new Vector3D(random(-SPRAY, SPRAY), 0, random(-SPRAY, SPRAY) * velocity.x));
    velocity.scale(1.0 / averageElapsedMillis);
    sparks[nextSpark].initializeMotion(current, velocity);
    nextSpark = (nextSpark + 1) % CONTEO_PARTICULA;
  } 
  else {
   
    skipCount++; //incrementar el conteo
  }
}

long lastFrameDrawn = millis();

float averageElapsedMillis = 20.0;


void draw() {//hacer los frames

//image(bg,0,0);

  long now = millis();//duracion del frame anterior dibujado 
  long elapsedMillis = now - lastFrameDrawn;
  lastFrameDrawn = now;
  averageElapsedMillis = .90 * averageElapsedMillis + .10 * elapsedMillis; 
  noStroke();    
  fill(0, 0, 0, constrain(2 * elapsedMillis, 0, 255));
  rect(0, 0, width, height);

  
  for (Particle spark : sparks) {
    if (spark.isActive()) {
      spark.paint(elapsedMillis);
      spark.evolve(elapsedMillis);
    }
  }
}

public static class Point2D {
  public final float x;
  public final float y;

  public Point2D(float x, float y) {
    this.x = x;
    this.y = y;
  }
}


public static class Vector3D {//los puntos para las coordenadas del vector en 3D
  public float x;
  public float y;
  public float z;

  public Vector3D(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public void shift(Vector3D v) {
    x += v.x;
    y += v.y;
    z += v.z;
  }

  public Vector3D add(Vector3D v) {
    return new Vector3D(x + v.x, y + v.y, z + v.z);
  }

  public void scale(float c) {
    x *= c;
    y *= c;
    z *= c;
  }

  public Vector3D mul(float c) {
    return new Vector3D(c * x, c * y, c * z);
  }
}

public static class Point3D {
  public float x;
  public float y;
  public float z;

  public Point3D(float x, float y, float z) {
    this.x = x;
    this.y = y;
    this.z = z;
  }

  public void shift(Vector3D v) {
    x += v.x;
    y += v.y;
    z += v.z;
  }

  public Point3D add(Vector3D v) {
    return new Point3D(x + v.x, y + v.y, z + v.z);
  }

  public Vector3D diff(Point3D p) {
    return new Vector3D(x - p.x, y - p.y, z - p.z);
  }
}


public class Canvas3D {
  private final float focalLength;

  private final float interactionPlane;

  public Canvas3D(float focalLength, float interactionPlane) {
    this.focalLength = focalLength;
    this.interactionPlane = interactionPlane;
  }

  
  public Point2D toScreenCoordinates(Point3D p) {
    float scale = focalLength / p.z;

    return new Point2D(p.x * scale + width / 2, p.y * scale + height / 2);
  }

 
  public Point3D toModelCoordinates(float x, float y) {//convertir en un plano
    float scale = interactionPlane / focalLength;

    return new Point3D((x - width / 2) * scale, (y - height / 2) * scale, interactionPlane);
  }


  public float scaleToScreen(float diameter, float distance) {//diametro de la esfera que centra la particula Z
    return diameter * focalLength / distance;
  }

  private void drawLine(Point2D from, Point2D to) {
    line(from.x, from.y, to.x, to.y);
  }

  private void drawPoint(Point2D p) {
    point(p.x, p.y);
  }

  public void drawLine(Point3D from, Point3D to, float weight) {
    strokeWeight(scaleToScreen(weight, to.z));
    drawLine(toScreenCoordinates(from), toScreenCoordinates(to));
  }

 
  public void drawPoint(Point3D p, float weight) {
    strokeWeight(scaleToScreen(weight, p.z));
    drawPoint(toScreenCoordinates(p));
  }

  
  public void drawHorizontalCircle(Point3D center, float radius) {
    float screenRadius = canvas.scaleToScreen(radius, center.z);
    Point2D p = toScreenCoordinates(center);
    
    ellipse(p.x, p.y, screenRadius, screenRadius * .3);
  }
}


float amplify(float n) {
  return constrain(4 * n, 0, 255);
}

public class Particle {
  
  private Point3D location;
  private Vector3D velocity;
  private float red;
  private float green;
  private float blue;
  private Sound sound;//SONIDO para cuando la particula toca el suelo
  private boolean pastLeftWall;
  private boolean pastRightWall;


  public Particle(float red, float green, float blue, Sound sound) {//caracteristicas de la particula(colores y sonido especifico)
    this.red = red;
    this.green = green;
    this.blue = blue;
    this.sound = sound;
  }

  
  public void initializeMotion(Point3D location, Vector3D velocity) {
    this.location = location;
    this.velocity = velocity;
  }

  
  public boolean isActive() {
    
    return location != null && location.z >= DISTANCIA_FOCAL;
  }

  
  private void drawMotion(Point3D from, Point3D to, float weight, float opacity) {//para que parezca motion blur
    stroke(red, green, blue, opacity);
    canvas.drawLine(from, to, weight);
  }

 
  public void paint(float elapsedMillis) {
    Point3D from = location;
    Point3D to = location.add(velocity.mul(elapsedMillis));
    drawMotion(from, to, 64, 8);//motioms blur, los siguientes tres
    drawMotion(from, to, 32, 32);
    drawMotion(from, to, 8, 255);

    
    if (isUnderground(elapsedMillis)) {
      splash(to);
    }

   
    Point2D p = canvas.toScreenCoordinates(to);
    pastLeftWall = p.x < 0;
    pastRightWall = p.x >= width;
  }

  
  private void splash(Point3D to) {
   
    stroke(red, green, blue, 128);
    fill(red, green, blue, 64);
    canvas.drawHorizontalCircle(to, 128);
    stroke(amplify(red), amplify(green), amplify(blue), 255);
    canvas.drawPoint(to, 16);
    sound.play(map(-velocity.y, 0, 6, 0, 1));
  }

  
  private boolean isUnderground(float elapsedMillis) {
    return location.y + velocity.y * elapsedMillis > height;
  }

  private boolean isMovingLeft() {
    return velocity.x <= -TOLERANCIA;
  }

  private boolean isMovingRight() {
    return velocity.x >= TOLERANCIA;
  }

  private boolean isMovingUp() {
    return velocity.y <= -TOLERANCIA;
  }

  private boolean isMovingDown() {
    return velocity.y >= TOLERANCIA;
  }

  private boolean isMovingVertically() {
    return isMovingUp() || isMovingDown();
  }
 
  private void bounceHorizontal() {
    velocity.x = -velocity.x;
  }

  private void bounceVertical() {
    
    velocity.y = -velocity.y * random(PARTICULA_ABAJO, PARTICULA_ARRIBA);
  }

  private void deactivate() {
    location.z = 0;
  }

 
  public void evolve(float elapsedMillis) {
   
    if ((pastLeftWall && isMovingLeft()) || (pastRightWall && isMovingRight())) {
      bounceHorizontal();
    } 

   
    if (isUnderground(elapsedMillis) && isMovingDown()) {
      bounceVertical();
      if (!isMovingVertically()) {
        deactivate();
      }
    } 

    
    location.shift(velocity.mul(elapsedMillis));
    velocity.y += GRAVEDAD;
  }
}


public interface Sound {
  public void play(float volume);
}

public interface SoundBank {
  public Sound getRandomSound();
}

Sound THE_SOUND_OF_SILENCE = new Sound() {
  public void play(float volume) {
  }
};

public class SilentSoundBank implements SoundBank {
  public Sound getRandomSound() {
    return THE_SOUND_OF_SILENCE;
  }
}