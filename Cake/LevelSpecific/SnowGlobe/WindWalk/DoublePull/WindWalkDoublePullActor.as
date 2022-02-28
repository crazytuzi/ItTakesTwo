import Vino.DoublePull.DoublePullActor;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullHazard;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.FocusTrackerComponent;
import Peanuts.Position.TransformActor;

event void FOnPlayerAttractionEvent();
event void FOnTumbleEvent();

class AWindWalkDoublePullActor : ADoublePullActor
{
	UPROPERTY(DefaultComponent)
	USphereComponent SphereCollider;
	default SphereCollider.SetSphereRadius(70.f);
	default SphereCollider.SetRelativeLocation(FVector(50.f, 0.f, 50.f));


	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;


	UPROPERTY()
	TSubclassOf<AWindWalkDoublePullHazard> HazardClass;
	AWindWalkDoublePullHazard CurrentHazard;

	TArray<AWindWalkDoublePullHazard> SpawnedHazards;

	// Local player in networked session
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter FullscreenPlayer;


	UPROPERTY()
	FOnPlayerAttractionEvent OnPlayerAttractionStartedEvent;

	UPROPERTY()
	FOnPlayerAttractionEvent OnPlayerAttractionEndedEvent;

	UPROPERTY()
	FOnPlayerAttractionEvent OnPlayersHitByHazardEvent;

	UPROPERTY()
	FOnTumbleEvent OnTumblingStarted;

	UPROPERTY()
	FOnTumbleEvent OnTumblingEnded;


	private bool bPlayersAreAttracted;

	bool bIsInStartZone;
	bool bDeliberateHazardMiss;
	bool bCanSpawnHazards;
	bool bIsTumbling;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		MovementComponent.Setup(SphereCollider);

		FullscreenPlayer = Game::GetFirstLocalPlayer();

		DoublePull.OnBothPlayersEnteredDoublePull.AddUFunction(this, n"OnBothPlayersEnteredDoublePull");
		SphereCollider.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		OnPlayerAttractionStartedEvent.AddUFunction(this, n"OnPlayerAttractionStarted");
		OnPlayerAttractionEndedEvent.AddUFunction(this, n"OnPlayerAttractionEnded");
		OnTumblingStarted.AddUFunction(this, n"OnTumblingStartedDelegate");
		OnTumblingEnded.AddUFunction(this, n"OnTumblingEndedDelegate");
	}

	UFUNCTION()
	void SpawnScriptedHazard()
	{
		bDeliberateHazardMiss = true;
		bCanSpawnHazards = true;
	}

	bool PlayersAreAttracted()
	{
		return bPlayersAreAttracted;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBothPlayersEnteredDoublePull()
	{
		// Go fullscreen and activate camera
		FullscreenPlayer.SetViewSize(EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		if(!HasControl() || !OtherActor.IsA(AWindWalkDoublePullHazard::StaticClass()))
			return;

		AWindWalkDoublePullHazard Hazard = Cast<AWindWalkDoublePullHazard>(OtherActor);
		if(!Hazard.bIsFlyingTowardsPlayer)
			return;

		HitByHazard(Hazard, Hit.Location);
		SetCapabilityActionState(WindWalkTags::ControlHitByHazard, EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerAttractionStarted()
	{
		bPlayersAreAttracted = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerAttractionEnded()
	{
		bPlayersAreAttracted = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTumblingStartedDelegate()
	{
		bIsTumbling = true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTumblingEndedDelegate()
	{
		bIsTumbling = false;
	}

	bool PlayerIsActivatingMagnet(AHazePlayerCharacter PlayerCharacter) const
	{
		return !PlayerCharacter.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger);
	}

	bool BothPlayersAreActivatingMagnet() const
	{
		return !Game::GetCody().IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger) && !Game::GetMay().IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger);
	}

	bool BothPlayersAreWalking()
	{
		return BothPlayersAreActivatingMagnet() && !IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullTumbleRecovery) && !IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullTumble) && !IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullStart);
	}

	// Net Functons /////////////////////////////////////////////////////////
	/////////////////////////////////////////////////////////////////////////
	UFUNCTION(NetFunction)
	void HitByHazard(AWindWalkDoublePullHazard Hazard, FVector BreakLocation)
	{
		// Break the damn thing
		Hazard.BreakHazard(BreakLocation);

		// Stahp magnetic attraction
		for(AHazePlayerCharacter PlayerCharacter : Game::Players)
			PlayerCharacter.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		// Fire away!
		OnPlayersHitByHazardEvent.Broadcast();
	}
}