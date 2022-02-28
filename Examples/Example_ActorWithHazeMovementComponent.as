import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSettings;

// Documentation on the movementsettings can be found in the MovementSettings angelscript file.
settings ExampleMovementActorDefaultSettings for UMovementSettings
{
	ExampleMovementActorDefaultSettings.MoveSpeed = 400.f;
	ExampleMovementActorDefaultSettings.GravityMultiplier = 3.f;
	ExampleMovementActorDefaultSettings.ActorMaxFallSpeed = 1800.f;
	ExampleMovementActorDefaultSettings.StepUpAmount = 40.f;
	ExampleMovementActorDefaultSettings.CeilingAngle = 30.f;
	ExampleMovementActorDefaultSettings.WalkableSlopeAngle = 55.f;
	ExampleMovementActorDefaultSettings.AirControlLerpSpeed = 2500.f;
	ExampleMovementActorDefaultSettings.GroundRotationSpeed = 20.f;
	ExampleMovementActorDefaultSettings.AirRotationSpeed = 10.f;
	ExampleMovementActorDefaultSettings.VerticalForceAirPushOffThreshold = 500.f;
}

// class UExampleVelocityCalculator : UHazeVelocityCalculator
// {
// 	UFUNCTION(BlueprintOverride)
// 	FVector CalculateVelocity(const UCollisionCheckActorData ActorData, FMovementCollisionData ImpactData, FVector DeltaMoved, float DeltaTime) const
// 	{
// 		//Actor data constains general data about the actor and the move it wants to do this frame.
// 		//Impact data contains the hits we have had this frame.

// 		return FVector(0.f, 0.f, 1000.f);
// 	}
// }

class AExampleActorWithMovementTestActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	// The Settings asset set here will be set as the default movement settins for this actor during beginplay.
	// If not set the MovementSettings normal defaults will be used by the movementsystem on this actor.
	default MoveComp.DefaultMovementSettings = ExampleMovementActorDefaultSettings;

	/*
		The MovementComponent uses a shapecomponent to know what shape to trace with and what does traces will collide with.
		Capsule and sphere are fully supported. Box can be used but does not support rotatations (undefined behaviour).
	*/
	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.SetCollisionProfileName(n"BlockAll");
	default CapsuleComponent.SetCapsuleHalfHeight(100.f);
	default CapsuleComponent.SetCapsuleRadius(65.f);

	/*
		It is important that all other PrimitiveComponents on the actor not have any blocks in its collision profile.
	*/
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionProfileName(n"NoCollision");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		/*
			Setup locks which ShapeComponent we are using.
			The MovementComponent will not work before setup has run.
		*/
		MoveComp.Setup(CapsuleComponent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		/*
			The only thing the MovementComponent will do on its own is reset its state.
			To get it to actually move, the actor or one of its capabilites need to call move.

			The move function takes a FHazeFrameMovement struct that describe how the actor should move this frame.
		*/

		FVector WantedMoveVelocity = CalculateVelocity();

		// Set what direction we want the actor to be facing, and how fast we want the actor turn. The Speed is set in radians per second.
		// This is just helper function. The capability or actor actually moving the actor has to apply the rotation for the actor to turn.
		// A turnspeed of 0.f will instantly set the facing direction towards that direcion.
		MoveComp.SetTargetFacingDirection(WantedMoveVelocity.GetSafeNormal(), 10.f);

		// To make a valid FrameMovementstruct you must construct it from a MovementComponent.
		FHazeFrameMovement ExampleMove = MoveComp.MakeFrameMovement(n"ExampleMovement");

		// ApplyVelocity will calculate the delta and velocity and accumulatively add it.
		ExampleMove.ApplyVelocity(WantedMoveVelocity);

		// The apply actor Vertical/Horizontal velocity functions gets the velocity from the previous frame and applies it to the struct.
		// Vertical and horizontal is defined by the worldup on the movementcomponent.
		ExampleMove.ApplyActorVerticalVelocity();
		ExampleMove.ApplyActorHorizontalVelocity();

		// Calculates how much acceleration gravity adds this frame and accumaltively adds it to the Delta and velocity of the struct. 
		// It will only accelerate the structs current vertical downwards velocity upto MaxFallSpeed set in the actors MovementSettings.
		ExampleMove.ApplyGravityAcceleration();

		// The SetRotation function will outright set to rotation we want the actor to look in after we have performed the move.
		FQuat RotationToSetActorIn;
		ExampleMove.SetRotation(RotationToSetActorIn);
		// Will rotate the Actors towards TargetFacing direction on the movecomponent.
		ExampleMove.ApplyTargetRotationDelta();

		// Will get all forces added on the movementcomponent and add them to the structs delta/velocity.
		ExampleMove.ApplyAndConsumeImpulses();

		// The LocomotionTransform is what we get back from animation system when we ask for RootMotion. 
		// Applying to the struct will accumulatively add its translation to the Delta and Set the rotation to the transforms rotation.
		// If you are applying rootmotion you probably don't want to apply anything else.
		FHazeLocomotionTransform ShouldHaveRecievedThisFromTheAnimationSystem;
		ExampleMove.ApplyRootMotion(ShouldHaveRecievedThisFromTheAnimationSystem);

		// You can set the Actor to move when another actor moves. 
		// When set the actor will move whenever the given primitive is moved until the movementcomponent performs a new move next frame
		// or we reach postphysics without moving the actor.
		UPrimitiveComponent PrimitiveWeProbablyGotFromSomeKindOfSceneQuery;
		ExampleMove.SetMoveWithComponent(PrimitiveWeProbablyGotFromSomeKindOfSceneQuery);
		// We can also flag to use the collision checks down hit if we get one as our movewithcomponent.
		ExampleMove.FlagToMoveWithDownImpact();

		/* -- OVERRIDES -- */
		/*
		*	We have several override settings that can be set for how the actor should handle its collision checks this frame.
		*/

		// With the override StepUp And StepDown functiosn we can override the specific step heights used this frame.
		// Normally the Height specificed in the actors MovementSettings would be used.
		ExampleMove.OverrideStepUpHeight(24.f);
		ExampleMove.OverrideStepDownHeight(14.f);

		// Groundedstate is normally set by collision checks we do in move.
		// If you use the Groundedstate override function then regardless of the result from the collisioncheck the groundedstate will be set to the given value.
		ExampleMove.OverrideGroundedState(EHazeGroundedState::Grounded);

		// The collisionhandler is the actual class that will handle the collision checking.
		// If you think you need to change the collisionhandler you should talk to Simon or Tyko.
		// To more permantly set what collisionhandler to set you should set it on the movementcomponent instead.
		ExampleMove.OverrideCollisionSolver(n"DefaultCharacterCollisionSolver");

		// --

		// If you want to ignore a specific actor or primtive when doing the collision checks then you can add them to the ignore list.
		// In most cases you probably want to use the movementcomponents StartIgnoring and StopIgnoring functions.
		// But if you have a case where you only want to do it for one frame you can use the functions below.
		AActor ActorYouWantIgnoreWhenCollisionCheckingForJustThisFrame;
		ExampleMove.AddActorToIgnore(ActorYouWantIgnoreWhenCollisionCheckingForJustThisFrame);
		UPrimitiveComponent PrimitiveComponentYouWantIgnoreWhenCollisionCheckForJustThisFrame;
		ExampleMove.AddComponentToIgnore(PrimitiveComponentYouWantIgnoreWhenCollisionCheckForJustThisFrame);

		// Move will run a collision check along the delta in the FrameMovementStruct and then set the actors locations and rotation.
		MoveComp.Move(ExampleMove);
	}

	FVector CalculateVelocity()
	{
		return FVector::ForwardVector * MoveComp.MoveSpeed;
	}
}
