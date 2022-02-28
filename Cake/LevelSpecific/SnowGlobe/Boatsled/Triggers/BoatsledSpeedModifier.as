import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

enum EBoatsledSpeedModifierType
{
	Boost,
	Hinder
}

class ABoatsledSpeedModifier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetWorldScale3D(FVector(0.65f, 0.5f, 0.65f));

	UPROPERTY(DefaultComponent, Attach = SpeedModifierMesh)
	UBoxComponent BoatsledTrigger;

	UPROPERTY(EditDefaultsOnly, DefaultComponent, Attach = Root)
	UStaticMeshComponent SpeedModifierMesh;


	// UPROPERTY(EditDefaultsOnly)
	// UMaterialInstance BoostMaterial;

	// UPROPERTY(EditDefaultsOnly)
	// UMaterialInstance HinderMaterial;

	// UPROPERTY(EditInstanceOnly)
	// UMaterialInstance ChunksMaterialOverride;

	UPROPERTY(EditInstanceOnly)
	AHazeActor SplineActor;

	EBoatsledSpeedModifierType SpeedModifierType = EBoatsledSpeedModifierType::Boost;


	TArray<AHazePlayerCharacter> AffectedPlayers;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// if(SpeedModifierType == EBoatsledSpeedModifierType::Boost)
		// {
		// 	SpeedModifierMesh.SetMaterial(0, BoostMaterial);

		// 	SpeedModifierMesh.SetRelativeRotation(FRotator(0.f, 180.f, 0.f));
		// 	SpeedModifierMesh.SetRelativeLocation(FVector(-300, 0.f, 0.f));
		// }
		// else
		// {
		// 	SpeedModifierMesh.SetMaterial(0, HinderMaterial);

		// 	SpeedModifierMesh.SetRelativeRotation(FRotator::ZeroRotator);
		// 	SpeedModifierMesh.SetRelativeLocation(FVector::ZeroVector);
		// }

		// if(ChunksMaterialOverride != nullptr)
		// 	SpeedModifierMesh.SetMaterial(3, ChunksMaterialOverride);

		// if(SplineActor == nullptr)
		// 	return;

		// UHazeSplineComponent SplineComponent = UHazeSplineComponent::Get(SplineActor, n"HazeGuideSpline");
		// if(SplineComponent == nullptr)
		// 	return;

		// float DistanceAlongSpline = SplineComponent.GetDistanceAlongSplineAtWorldLocation(ActorLocation);
		// FVector SplineForward = SplineComponent.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		// SetActorRotation(Math::MakeRotFromXZ(SplineForward, ActorUpVector));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoatsledTrigger.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerSteppedOnModifier");
	}

	UFUNCTION()
	void OnPlayerSteppedOnModifier(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)	
	{
		if(OtherActor.IsA(ABoatsled::StaticClass()))
		{
			ABoatsled Boatsled = Cast<ABoatsled>(OtherActor);
			AHazePlayerCharacter Boatsledder = Boatsled.GetCurrentBoatsledder();
			if(Boatsledder == nullptr)
				return;

			// Go away, slave!
			if(!Boatsledder.HasControl())
				return;

			// Don't activate if player has already interacted with this modifier
			if(AffectedPlayers.Contains(Boatsledder))
				return;

			// Get BoatsledComponent and communicate interaction
			UBoatsledComponent BoatsledComponent = UBoatsledComponent::Get(Boatsledder);
			if(BoatsledComponent != nullptr)
			{
				// Leave speed boost crumb
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"BoatsledComponent", BoatsledComponent);
				BoatsledComponent.Boatsled.CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"OnPlayerSteppedOnModifier_Crumb"), CrumbParams);

				// Store player so that it cannot be affected twice by speed modifier
				AffectedPlayers.AddUnique(Boatsledder);
			}
		}
	}

	UFUNCTION()
	void OnPlayerSteppedOnModifier_Crumb(const FHazeDelegateCrumbData& CrumbData)
	{
		UBoatsledComponent BoatsledComponent = Cast<UBoatsledComponent>(CrumbData.GetObject(n"BoatsledComponent"));
		if(SpeedModifierType == EBoatsledSpeedModifierType::Boost)
			BoatsledComponent.BoatsledEventHandler.OnBoatsledBoost.Broadcast();

		// Eman TODO: Do something with hindering too! (kanske?)
	}
}