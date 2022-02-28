import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class AClockSpringJumpPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PhysicsRoot;

	UPROPERTY(DefaultComponent, Attach = PhysicsRoot)
	UStaticMeshComponent JumpPadMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent JumpToLoc;

	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.LowerBound = -75.f;
	default PhysValue.UpperBound = 150.f;
	default PhysValue.LowerBounciness = 1.f;
	default PhysValue.UpperBounciness = 0.65f;
	default PhysValue.Friction = 1.5f;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorGroundPoundedDelegate OnGroundPound;
		OnGroundPound.BindUFunction(this, n"OnActorGroundPounded");
		BindOnActorGroundPounded(this, OnGroundPound);

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlatform");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlatform");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlatform(AHazePlayerCharacter Player, FHitResult Hit)
	{

		PhysValue.AddImpulse(-370.f);

	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlatform(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(-100.f);
	}


	UFUNCTION(NotBlueprintCallable)
	void OnActorGroundPounded(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(-1500.f);
		FHazeJumpToData JumpToData;
		JumpToData.TargetComponent = JumpToLoc;
		JumpToData.AdditionalHeight = 1500.f;
		LaunchPlayer(JumpToData, Player, 0.f);
		
	}

	UFUNCTION(BlueprintEvent)
	void LaunchPlayer(FHazeJumpToData JumpData, AHazePlayerCharacter Player, float Delay)
	{

	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 35.f);
		PhysValue.Update(DeltaTime);

		PhysicsRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));
	}


}