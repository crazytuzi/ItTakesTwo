import Vino.Tilt.TiltComponent;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

class AFloatingPlanet : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlanetRoot;

	UPROPERTY(DefaultComponent, Attach = PlanetRoot)
	UStaticMeshComponent PlanetMesh;

	UPROPERTY(DefaultComponent, Attach = PlanetRoot)
	UTiltComponent TiltComp;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovementComp;

	UPROPERTY()
	FHazeConstrainedPhysicsValue PhysValue;
	default PhysValue.UpperBound = 0.f;
	default PhysValue.LowerBound = -500.f;
	default PhysValue.LowerBounciness = 0.2f;
	default PhysValue.UpperBounciness = 0.2f;
	default PhysValue.Friction = 1.75f;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"LandOnPlanet");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"LeavePlanet");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void LandOnPlanet(AHazePlayerCharacter Player, FHitResult Hit)
	{
		PhysValue.AddImpulse(-250.f);
		SetActorTickEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	void LeavePlanet(AHazePlayerCharacter Player)
	{
		PhysValue.AddImpulse(-100.f);
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, 15.f);
		PhysValue.Update(DeltaTime);

		PlanetRoot.SetRelativeLocation(FVector(0.f, 0.f, PhysValue.Value));

		if (FMath::Abs(PhysValue.Value) <= SMALL_NUMBER && FMath::Abs(PhysValue.Velocity) <= KINDA_SMALL_NUMBER)
			SetActorTickEnabled(false);
	}
}