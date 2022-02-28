import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;
import Vino.Tilt.TiltComponent;
import Peanuts.Triggers.SquishTriggerBox;

class ASongHiHat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = HHMeshRoot)
	UStaticMeshComponent HHCymb02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent HHMeshRoot;

	UPROPERTY(DefaultComponent, Attach = HHMeshRoot)
	USquishTriggerBoxComponent SquishUp;
	
	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USquishTriggerBoxComponent SquishDown;

	UPROPERTY(DefaultComponent, Attach = HHMeshRoot)
	UStaticMeshComponent Cylinder;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent HHCymb01;

	UPROPERTY(DefaultComponent, Attach = HHMeshRoot)
	USongOfLifeComponent SongOfLifeComponent;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent HiHatRiseEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent HiHatFallEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent HiHatClosedEvent;

	UPROPERTY()
	bool bShowNonSingState = false;

	bool bSongOfLifeActive = false;
	FVector StartingLoc;
	FHazeConstrainedPhysicsValue PhysValue;
	FVector ImpulseDirection = FVector::UpVector;

	float AccelerationForce = 10000.f;
	float SpringValue = 0.f;
	float RESTING_PHYS_VALUE = 600.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowNonSingState)
			HHMeshRoot.SetRelativeLocation(FVector(0.f, 0.f, -200.f));
		else
			HHMeshRoot.SetRelativeLocation(FVector(0.f, 0.f, 400.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bShowNonSingState)
			HHMeshRoot.SetRelativeLocation(FVector(0.f, 0.f, 400.f));

		StartingLoc = HHMeshRoot.RelativeLocation;

		PhysValue.LowerBound = 600.f;
		PhysValue.UpperBound = 0.f;
		PhysValue.LowerBounciness = 1.f;
		PhysValue.UpperBounciness = 0.65f;
		PhysValue.Friction = 5.f;

		SongOfLifeComponent.OnStartAffectedBySongOfLife.AddUFunction(this, n"SongOfLifeStarted");
		SongOfLifeComponent.OnStopAffectedBySongOfLife.AddUFunction(this, n"SongOfLifeEnded");


		// Audio 
		AddCapability(n"SongHiHatAudioCapability");

		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"OnImpactedByPlayer");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		PhysValue.SpringTowards(0.f, SpringValue);
		PhysValue.AccelerateTowards(600.f, AccelerationForce);
		PhysValue.Update(DeltaTime);
		HHMeshRoot.SetRelativeLocation(StartingLoc + (ImpulseDirection * -PhysValue.Value));

		if (bSongOfLifeActive)
		{
			AccelerationForce = 0.f;
			SpringValue = 20.f;
		}
		else
		{
			AccelerationForce = 10000.f;
			SpringValue = 0.f;
		}
	}

	UFUNCTION()
	void SongOfLifeStarted(FSongOfLifeInfo Info)
	{
		bSongOfLifeActive = true;
	}
	
	UFUNCTION()
	void SongOfLifeEnded(FSongOfLifeInfo Info)
	{
		bSongOfLifeActive = false;
	}

	UFUNCTION()
	void OnImpactedByPlayer(AHazePlayerCharacter Player, const FHitResult& HitResult)
	{
		UAkAudioEvent WantedImpactEvent = PhysValue.Value == RESTING_PHYS_VALUE ? HiHatClosedEvent : HiHatFallEvent;
		HazeAkComp.HazePostEvent(WantedImpactEvent);
	}
}