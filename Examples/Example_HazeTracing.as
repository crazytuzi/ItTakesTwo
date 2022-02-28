import Vino.Movement.Components.MovementComponent;

/*
* HazeTracingParams - Contains all arguemtns you would normally need to send for each world trace.
*/

class AExampleTracingParamsActor : AHazeActor
{
	FHazeTraceParams TraceParams;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;

	// This component can be used to make cheap traces asynchronous
	// That means that the trace will be completed sometimes during this fram,
	// And can be used the next frame
	UHazeAsyncTraceComponent AsyncTrace;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup(SphereComp);

		// Before you trace you need to init the trace with what you want to hit.

		// You can do this with just trace channel, Primitives that has their response set to block for this trace channel will be hit by traces, overlap will pickup blocks and overlap.
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);

		// You can init with object types, Traces will hit any primtive set to any of the specified object types.
		TArray<EObjectTypeQuery> ObjectTypes;
		ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
		TraceParams.InitWithObjectTypes(ObjectTypes);

		// You can also init with a collisionprofile.
		TraceParams.InitWithCollisionProfile(n"BlockAll");

		// You can also init with any PrimitiveComponent or MovementComponent.
		// Shape, CollisionFilters and Component/Actor ignore will be copied from the component.
		TraceParams.InitWithPrimitiveComponent(SphereComp);
		TraceParams.InitWithMovementComponent(MoveComp);

		// You can change/set the shape to Sphere, capsule, box or line. Defaulted to Line, If you init with a MovementComponent or a primitive then the shape will be copied from there.
		TraceParams.SetToSphere(5.f);
		TraceParams.SetToBox(FVector(50.f, 50.f, 50.f));
		TraceParams.SetToCapsule(30.f, 80.f);
		// Can only be used with traces - Invalid to call with overlaps.
		TraceParams.SetToLineTrace();

		// All traces have a debug mode that will be shown if the debugdraw time is set to not -1.f.
		TraceParams.DebugDrawTime = 0.f; // If zero it will be shown for one frame.
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// -------------------------- Sweeps ----------------------------- //
		// You set the From and To with worldlocations.
		TraceParams.From = FVector(100.f, 100.f, 0.f);
		TraceParams.To = FVector(100.f, 100.f, 100.f);

		FHazeHitResult Hit;
		if (TraceParams.Trace(Hit))
		{
			// Had a hit.
		}

		// -------------------------- Overlap ----------------------------- //

		TraceParams.OverlapLocation = FVector(100.f, 10.f, 10000.f);

		TraceParams.SetToSphere(50.f);
		TArray<FOverlapResult> Overlaps;
		if (TraceParams.Overlap(Overlaps))
		{
			// Had overlaps.
		}

		// -------------------------- Character Sweeps ----------------------------- //
		/*
		* When we make characters we generally offset its collision so the origin is at its bottom but when tracing the from and to is from the center of the Shape.
		* To help with these cases you can mark the trace to be offseted and the traces From and To will be assumed to based of the origin of the actor.
		*/
		FHazeTraceParams CharacterTrace;
		/* If you init with a MovementComponent or a Primitive this offset will be calculated for you, otherwise you will have to set it manually */
		CharacterTrace.InitWithMovementComponent(MoveComp);
		//CharacterTrace.OverrideOriginOffset(FVector(0.f, 0.f, 10.f));

		// This function call will mark it.
		CharacterTrace.MarkToTraceWithOriginOffset();

		CharacterTrace.From = ActorLocation;
		// Helper function for setting the To with a delta from the trace Start location.
		CharacterTrace.SetToWithDelta(ActorForwardVector * 100.f * DeltaTime);

		FHazeHitResult CharacterHit;
		if (CharacterTrace.Trace(CharacterHit))
		{
			// Center of shape when impacted.
			CharacterHit.ShapeLocation;

			// Origin of actor when impacted.
			CharacterHit.ActorLocation;
		}

		// You bind a delegate with the function you want called when the trace is FCutsceneRelayDoneEventSignature
		// The TraceId can then be used to identify what kind of trace that has been completed
		FHazeAsyncTraceComponentCompleteDelegate Delegate;
		Delegate.BindUFunction(this, n"TestTraceFunction");
		AsyncTrace.TraceSingle(CharacterTrace, this, n"TestTraceId", Delegate);

		// It is also valid to just bind the function immediately
		// The trace ID  will then be the function name
		AsyncTrace.TraceMulti(CharacterTrace, this, n"TestTraceFunction");
	}

	UFUNCTION(NotBlueprintCallable)
	private void TestTraceFunction(UObject TraceInstigator, FName TraceId, TArray<FHitResult> Obstructions)
	{
		// This is called with the delegate bind
		if(TraceId == n"TestTraceId")
		{
			// This is filled with all the found collision.
			// OBS! This is Num() == 0 when no collisions are found.
			for(FHitResult Hit : Obstructions)
			{

			}
		}

		// This is called without the delegate bind
		else
		{
			ensure(TraceId == n"TestTraceFunction");
		}
	}
}

/*
* Primitive and Movementcomponent trace functions.
*/

/*
* We have also added some helper trace functions you can call on PrimitiveComponents and MovementComponents.
*/

class AExampleTracingComponentFunctions : AHazeActor
{
	FHazeTraceParams TraceParams;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	USphereComponent SphereComp;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// will overlap the the Primtive/MovementComponents shape and return all overlapping hits.
		TArray<FOverlapResult> Overlaps;
		//MoveComp.OverlapTrace(ActorLocation, Overlaps, 0.f)
		if (SphereComp.OverlapTrace(ActorLocation, Overlaps, 0.f))
		{}

		// Line trace will do a trace from the supplied location and hit what the Primitive/MovementComponent would hit.
		FHazeHitResult LineHit;
		//if (SphereComp.LineTrace(ActorLocation, ActorLocation + FVector::UpVector * 10.f, LineHit, DebugDraw = 0.f))
		if (MoveComp.LineTrace(ActorLocation, ActorLocation + FVector::UpVector * 10.f, LineHit, DebugDraw = 0.f))
		{
			// I Hit something.
		}

		// SweepTrace will do a trace from the supplied location with the primitives shape and hit what the Primitive/MovementComponent would hit.
		FHazeHitResult SweepHit;
		if (SphereComp.SweepTrace(ActorLocation, ActorLocation + ActorForwardVector * 100.f, SweepHit))
		{}

		// Same as above when doing a SweepAsCharacter the From and To will be assumed to be from the actors origin.
		FHazeHitResult Hit;
		if (SphereComp.SweepAsCharacter(ActorLocation, ActorLocation + ActorForwardVector * 100.f, Hit))
		{}

		// a sweep on the movementcomponent will always be assumed to be a SweepAsCharacter.
		if (MoveComp.SweepTrace(ActorLocation, ActorLocation + ActorForwardVector * 100.f, SweepHit))
		{}
	}
}
