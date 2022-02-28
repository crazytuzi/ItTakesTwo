
/**
 * All settings related to the hook. 
 */

struct FHookSettings
{
	// The impulse speed of the 'Overwatch' hookshot. 
	// unit: UU / Seconds. (don't use negative values please)
	float InitialSpeed = 4000.f;

	// The constant acceleration used while using the 'Overwatch' hookshot. 
	// unit: UU / Seconds^2 (don't use negative values please)
	float InitialAcceleration = 2000.0f;

	// Controls how far we are allowed to hook shot.
	// (Any auto aim components beyond this distance will be ignored.) 
	float HookShotDistance_MAX = 100000.f;

	// Can be used to prevent hook shooting when you are standing near a wall.
	// (Any auto aim components within this distance will be ignored.) 
	float HookShotDistance_MIN = 0.f;

	//////////////////////////////////////////////////////////////////////////
	// Will auto add additional Speed/acceleration in order to 
	// to make sure that we reach the target on the desired time. 
	// 
	// Useful tool to calculate additional Speed/Acceleration
	// needed to reach target on the desired time. The capability
	// will print additional Speed/acceleration needed in order to
	// reach the target.
	//  
	// (-1 means to ignore MaxLerpTime in calculations) 
	float MaxLerpTime = 1.5f;					
	//////////////////////////////////////////////////////////////////////////

	// Whether you are to detach upon reaching the target destination or not. 
	bool bAutoDetachAfterLanding = false;

	// How much of the 'WorldUp' vector that should 
	// be used when creating the fortnite impulse vector
	float Ratio_UP = 4.f;

	// How much of the 'Camera looking direction' vector 
	// that should be used when creating the fortnite impulse vector
	float Ratio_HOOKDIR = 8.f;

	// Strength of the fornite impulse 
	float FortniteImpulseMagnitude = 4500.f;

	// how many seconds until fortnite impulse should kick in after releasing the button
	float DelayAutoForniteTimer = 0.2f;

	// Strength of the slide impulse which will be pushed when playing the Slide_exit animation.
	float SlidingImpulseMagnitude = 0.f;
};
