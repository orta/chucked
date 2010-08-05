//
//  grabbed_tooAppDelegate.m
//  grabbed too
//
//  Created by benmaslen on 14/03/2009.
//  Copyright ortatherox.com 2009. All rights reserved.
//

#import "grabbed_tooAppDelegate.h"


extern cpBody* makeCircle(int radius);
extern void drawObject(void *ptr, void *unused);
extern void createPlayer();
extern void makeStaticBox(float x, float y, float width, float height);
cpSpace *space;
cpBody *staticBody;

@implementation GameLayer
-(id) init {
	[super init];
  [self initChipmunk];
  isTouchEnabled = YES;
	isAccelerometerEnabled = YES;
  [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 60)];
  
  //seed the random generator
  srand([[NSDate date] timeIntervalSince1970]);
  
  // make a bunch of circles
  for (int i = 0; i < (rand() % 10) + 20; i++) {
    cpBody* circle = makeCircle((rand() % 40) + 5);
    circle->p = cpv( (rand() % 240) + 30,  (rand() % 360) + 30);
  }
  
  // Make it look slightly prettier
  glEnable(GL_LINE_SMOOTH);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glHint(GL_LINE_SMOOTH_HINT, GL_DONT_CARE);
  
  return self;
}

-(void) dealloc {
	[super dealloc];
}

- (void) initChipmunk{
  // start chipumnk
  // create the space for the bodies
  // and set the hash to a rough estimate of how many shapes there could be
  // set gravity, make the physics run loop
  // make a bounding box the size of the screen
  
  cpInitChipmunk();
  space = cpSpaceNew();
  cpSpaceResizeStaticHash(space, 60.0, 1000);
  cpSpaceResizeActiveHash(space, 60.0, 1000);
  
	space->gravity = cpv(0, -200);
  staticBody = cpBodyNew(INFINITY, INFINITY);  
  [self schedule: @selector(step:)];
  
  CGSize s = [[Director sharedDirector] winSize];

  int margin = 4;
  int dmargin = margin*2;
  makeStaticBox(margin, margin, s.width - dmargin, s.height - dmargin);
  createPlayer();
}

- (void) draw{  
  // rendering loop
  glColor4f(1.0, 1.0, 1.0, 1.0);
  cpSpaceHashEach(space->activeShapes, &drawObject, NULL);
  //by switching colour here we can make static stuff darker
  glColor4f(1.0, 1.0, 1.0, 0.7);
  cpSpaceHashEach(space->staticShapes, &drawObject, NULL);  
}


- (void)ccTouchesMoved:(NSSet*)touches withEvent:(UIEvent*)event{  
  UITouch *myTouch =  [touches anyObject];
  CGPoint location = [myTouch locationInView: [myTouch view]];
  location = [[Director sharedDirector] convertCoordinate: location];
  //move the nouse to the click
  cpMouseMove(mouse, cpv(location.x, location.y));
  if(mouse->grabbedBody == nil){
    //if there's no associated grabbed object
    // try get one
    cpMouseGrab(mouse, 0);
  }
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  UITouch *myTouch =  [touches anyObject];
  CGPoint location = [myTouch locationInView: [myTouch view]];
  location = [[Director sharedDirector] convertCoordinate: location];
  mouse = cpMouseNew(space);
  cpMouseMove(mouse, cpv(location.x, location.y));
  cpMouseGrab(mouse, 0);
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self ccTouchesCancelled:touches withEvent:event];
}
- (void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  cpMouseDestroy(mouse);
}


-(void) step: (ccTime) delta {
	int steps = 2;
	cpFloat dt = delta/(cpFloat)steps;
	for(int i=0; i<steps; i++){
		cpSpaceStep(space, dt);
	}
} 

- (void)accelerometer:(UIAccelerometer*)accelerometer didAccelerate:(UIAcceleration*)acceleration{	
  static float prevX=0, prevY=0;	
  #define kFilterFactor 0.05
  
  float accelX = acceleration.x * kFilterFactor + (1- kFilterFactor)*prevX;
  float accelY = acceleration.y * kFilterFactor + (1- kFilterFactor)*prevY;
  
  prevX = accelX;
  prevY = accelY;
  
  cpVect v = cpv( accelX, accelY);
  space->gravity = cpvmult(v, 200);
}


@end

@implementation grabbed_tooAppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	// NEW: Init the window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	[window setUserInteractionEnabled:YES];
	//[window setMultipleTouchEnabled:YES];

	//[[Director sharedDirector] setLandscape: YES];
	[[Director sharedDirector] setDisplayFPS:YES];

	[[Director sharedDirector] attachInWindow:window];

	Scene *scene = [Scene node];
	[scene add: [GameLayer node]];

	[window makeKeyAndVisible];
	
	[[Director sharedDirector] runWithScene: scene];

}
-(void)dealloc
{
	[super dealloc];
}
-(void) applicationWillResignActive:(UIApplication *)application
{
	[[Director sharedDirector] pause];
}
-(void) applicationDidBecomeActive:(UIApplication *)application
{
	[[Director sharedDirector] resume];
}
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	[[TextureMgr sharedTextureMgr] removeAllTextures];
}

@end
