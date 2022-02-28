import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuckComponent;

class AHockeyPuck : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UMagnetGenericComponent MagnetComp;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.UpdateSettings.OptimalCount = 3;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;

	FVector OtherVelocity;

	FVector OtherSidePosition;

	FVector CurrentVelocity;
	
	float DefaultSpeed = 1200.f;
	float CurrentSpeed;

	float MaxSpeed = 6800.f; 
	float MinSpeed = 1200.f;

	UPROPERTY()
	bool bShouldNetwork;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapabilitySheet(CapabilitySheet);
	
		MoveComp.Setup(SphereComp);

		MoveComp.UseCollisionSolver(n"HockeyPuckCollisionSolver", n"DefaultCharacterRemoteCollisionSolver");

		bShouldNetwork = true;
	}

	void ZeroOutPuckValues()
	{
		CurrentSpeed = DefaultSpeed;
		CurrentVelocity = FVector(0.f);
	}

	void StartPuckPlay(int DirectionMultiplier = 1)
	{
		CurrentSpeed = DefaultSpeed;
		CurrentVelocity = (ActorRightVector * DirectionMultiplier) * CurrentSpeed;
	}
}