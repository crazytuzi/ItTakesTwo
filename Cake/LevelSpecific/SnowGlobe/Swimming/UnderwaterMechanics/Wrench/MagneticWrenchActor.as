import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.WrenchNutActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.Wrench.MagneticWrenchComponent;
import Peanuts.Movement.CollisionSolver;

class AMagneticWrenchActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USphereComponent LeftCollision;

	UPROPERTY(DefaultComponent, Attach = Collision)
	USphereComponent RightCollision;
	
	UPROPERTY(DefaultComponent, Attach = MeshRotationPivot)
	UMagneticWrenchComponent BlueMagnet;

	UPROPERTY(DefaultComponent, Attach = MeshRotationPivot)
	UMagneticWrenchComponent RedMagnet;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.ControlSideDefaultCollisionSolver = n"CollisionSolver";
	default MoveComp.RemoteSideDefaultCollisionSolver = n"CollisionSolver";

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRotationPivot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereNutDetection;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.f;
	default DisableComp.bRenderWhileDisabled = true;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerSheet;

	AWrenchNutActor ActiveNut = nullptr;
	bool bIsAttachedToNut = false;

	bool bDisableMovement = false;

	FVector LinearVelocity;
	FVector AngularVelocity;

	const float AngularScale = 0.005f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.bAlignRotationWithWorldUp = false;
		MoveComp.Setup(Collision);

		SphereNutDetection.OnComponentBeginOverlap.AddUFunction(this, n"NutBeginOverlap");
		SphereNutDetection.OnComponentEndOverlap.AddUFunction(this, n"NutEndOverlap");

		AddCapability(n"MagneticWrenchNutAlignCapability");
		AddCapability(n"MagneticWrenchNutAttachCapability");
		AddCapability(n"MagneticWrenchMagnetCapability");
		AddCapability(n"MagneticWrenchMovementCapability");
		AddCapability(n"MagneticWrenchPhysicsCapability");

		Capability::AddPlayerCapabilitySheetRequest(PlayerSheet);

		// Manually check for overlapping nuts in the beginning
		TArray<AActor> OverlappingActors;
		SphereNutDetection.GetOverlappingActors(OverlappingActors);

		for(auto Actor : OverlappingActors)
		{
			auto Nut = Cast<AWrenchNutActor>(Actor);
			if (Nut != nullptr)
				ActiveNut = Nut;
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(PlayerSheet);
	}

	UFUNCTION()
	void NutBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
	{
		auto Nut = Cast<AWrenchNutActor>(OtherActor);
		if (Nut != nullptr)
			ActiveNut = Nut;
	}

	UFUNCTION()
	void NutEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if (OtherActor == ActiveNut)
			ActiveNut = nullptr;
	}

	void ApplyForce(FVector Location, FVector Force, float DeltaTime)
	{
		FVector Offset = Location - ActorLocation;
		Offset /= 1000.f;

		LinearVelocity += Force * DeltaTime;
		AngularVelocity += Offset.CrossProduct(Force) * AngularScale * DeltaTime;
	}

	void ApplyAngularForce(FVector Location, FVector Force, float DeltaTime)
	{
		FVector Offset = Location - ActorLocation;
		Offset /= 1000.f;
		AngularVelocity += Offset.CrossProduct(Force) * AngularScale * DeltaTime;
	}

	bool AreBothPlayersActive()
	{
		return
			RedMagnet.GetInfluencerNum() > 0 &&
			BlueMagnet.GetInfluencerNum() > 0;
	}

	UFUNCTION()
	void SetWrenchDisable(bool IsDisabled)
	{
		BlueMagnet.bIsDisabled = IsDisabled;
		RedMagnet.bIsDisabled = IsDisabled;
		bDisableMovement = IsDisabled;
	}
}