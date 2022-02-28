
/* The FHazeConstrainedPhysicsValue struct can be used to add a bit of juiciness and believability to objects
	that are expected to behave in a physical way. Examples are springs, catapults, buttons, levers etc.

	No ACTUAL physics is applied, its just math :) So if you want collisions, reactions with objects, you
	have to implement that yourself in some way.

	The numbers are a bit hand-wavy and hard to visualize, so I recommend just playing around with them until
	you get the behaviour that you're looking for! With experience, you will get a feel for the numbers. */
class AExampleConstrainedPhysicsActor : AHazeActor
{
	// Here it is!
	FHazeConstrainedPhysicsValue PhysValue;

	// The mathematical bounds of the value, these should represent walls, or other physical
	//	constraints that the object will "bounce" against
	// If the value hits one of these constraints, it will be clamped, and the velocity reversed to simulate
	//	a bounce.
	// The order as far as bigger/smaller number doesn't matter. "Lower" and "upper" is just helpful terms, they
	//	dont have to be the litteral smaller or bigger number.
	default PhysValue.LowerBound = 0.f;
	default PhysValue.UpperBound = 6000.f;

	// How much the velocity should bounce when hitting a bound. 
	// 1 means 100% of the velocity is conserved, 0 means the velocity gets absorbed completely.
	// A value beyond 1 is not recommended...
	default PhysValue.LowerBounciness = 0.2f;
	default PhysValue.UpperBounciness = 1.f;

	// How much the velocity should gradually decay over time.
	// This can take a value from 0 to infinity, where 0 is no friction at all.
	default PhysValue.Friction = 2.1f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		/* Here are some example use-cases for the physics float */

		/* A springy button that the players can jump on */
		PhysValue.AddAcceleration(-800.f * NumPlayersOnPlatform); // Gravity from players
		PhysValue.SpringTowards(0.f, 180.f); // Spring the value towards 0, with 180 units of force for every unit of tension

		// (NOTE: You HAVE to call Update() for the value to simulate and update
		//		if you dont call it, nothing will happen)
		PhysValue.Update(DeltaTime); // <-- IMPORTANT

		// These functions can be used to poll what happened during the LAST update
		if (PhysValue.HasHitLowerBound())
		{
			PlayGnarlySoundEffect();
		}

		/* Remember: The physics float is just math. It wont affect the game in any way, so we have to show it somehow!
			There's no set "meaning" of the physics value. It could be location, rotation, anything! Its up to you. */
		PlatformMoveRoot.SetRelativeLocation(FVector::UpVector * PhysValue.Value);

		/* A door that slams shut automatically */
		if (bPlayersHitDoorThisFrame)
			PhysValue.AddImpulse(1200.f); // KICK!

		PhysValue.AccelerateTowards(0.f, 800.f); // Force pulling the door shut, applying a static 800 units/s force
		PhysValue.Update(DeltaTime);

		if (PhysValue.HasHitUpperBound())
		{
			PlayDoorShutVFX();
		}

		// Yaw the door based on the physics value
		DoorRotateRoot.SetRelativeRotation(FRotator(PhysValue.Value, 0.f, 0.f));
	}


	// Stuff used in the examples......
	USceneComponent PlatformMoveRoot;
	USceneComponent DoorRotateRoot;
	int NumPlayersOnPlatform;
	bool bPlayersHitDoorThisFrame;
	void PlayGnarlySoundEffect() {}
	void PlayDoorShutVFX() {}
}
