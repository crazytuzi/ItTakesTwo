import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlant;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.Movement.Helpers.BurstForceStatics;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
import Vino.Tutorial.TutorialPrompt;
import Cake.LevelSpecific.Garden.VOBanks.GardenFrogPondVOBank;

UCLASS(Abstract)
class ABouncyPlant : AControllablePlant
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCharacterSkeletalMeshComponent PlantMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent EffectSceneComp;

   	UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent VerticalBounceDirection;
    default VerticalBounceDirection.RelativeRotation = FRotator(90.f, 0.f, 0.f);
    default VerticalBounceDirection.ArrowSize = 3.f;
    default VerticalBounceDirection.RelativeLocation = FVector(0.f, 0.f, 100.f);
    default VerticalBounceDirection.bVisible = false;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncChargeProgress;

	// UPROPERTY(DefaultComponent)
	// UHazeSmoothSyncVectorComponent SyncSize;

 	UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
    TSubclassOf<UHazeCapability> BouncePadCapabilityClass;

	UPROPERTY(NotEditable)
	bool bActive = false;

	UPROPERTY(NotEditable)
	bool bIsCharging = false;

	UPROPERTY(NotEditable)
	bool bBounced = false;

	float BouncedBoolDelay = 0.05f;
	float BouncedBoolTimer = 0.0f;

 	UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 300.f;

    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;

    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;

    UPROPERTY(Category = "Bounce Properties")
    bool bCustomVerticalDirection = false;

    UPROPERTY(Category = "Mesh")
    FVector EndScale = FVector(1.1f, 1.1f, 0.75f);

    UPROPERTY(Category = "Mesh")
    FHazeTimeLike ScaleBouncePadTimeLike;
    default ScaleBouncePadTimeLike.Duration = 0.2f;
    default ScaleBouncePadTimeLike.Curve.ExternalCurve = Asset("/Game/Blueprints/LevelMechanics/BouncePad/BouncePadScaleCurve.BouncePadScaleCurve");

    UPROPERTY(Category = "Mesh")
    float ScalePlayRate = 1.f;

    FVector StartScale = FVector::OneVector;

	FVector2D CurrentPlayerInput;
	float FireRate = 0.0f;

	UPROPERTY(Category="Bounce")
	float DefaultVerticalVelocity = 1500.0f;
	UPROPERTY(Category="Bounce")
	float HighVerticalVelocity = 4000.0f;

	UPROPERTY(Category="Bounce")
	UCurveFloat ReleaseCurve;

	UPROPERTY(Category = "Tutorial")
	FTutorialPrompt BounceTutorial;

	UPROPERTY(Category = "Audio")
	UGardenFrogPondVOBank VOBank;

	UPROPERTY(Category = "Settings")
	float TimeUntilReminderBark = 3.f;
	float ReminderTimer = 0.f;
	bool bShouldReminderBarkFire = true;

	float ChargeAlpha = 0.0f;
	float ChargeSpeed = 2.0f;

	bool bBurstActivated = false;
	bool bTutorialCompleted = false;
	bool bFullySpawned = false;

	const float SuperBounceReactionTime = 0.37f;
	float TimeLeftForSuperBounce = 0.0f;

	default AppearTime = 0.6f;
	default ExitTime = 0.6f;

	UPROPERTY()
	UNiagaraSystem SuperBounceEffect;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapability;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ReleaseChargeForceFeedback;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        VerticalBounceDirection.SetVisibility(bCustomVerticalDirection);
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		VerticalVelocity = DefaultVerticalVelocity;
		AddCapability(n"BouncyPlantChargingCapability");
		AddCapability(n"BouncyPlantReleaseChargeCapability");

        FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnBouncePad");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);
		
        //ScaleBouncePadTimeLike.BindUpdate(this, n"UpdateScaleBouncePad");
        ScaleBouncePadTimeLike.BindFinished(this, n"FinishScaleBouncePad");

        ScaleBouncePadTimeLike.SetPlayRate(ScalePlayRate);

        Capability::AddPlayerCapabilityRequest(BouncePadCapabilityClass);
		UClass AudioCapabilityClass = AudioCapability.Get();
		if(AudioCapabilityClass != nullptr)
			AddCapability(AudioCapabilityClass);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TimeLeftForSuperBounce = FMath::Max(TimeLeftForSuperBounce - DeltaTime, 0.0f);

		if(bBounced && BouncedBoolTimer >= BouncedBoolDelay) // added a delay for the bool to be switched so the animation has time to react
		{
			bBounced = false;
			BouncedBoolTimer = 0.0f;
		}
		else if(bBounced)
		{
			BouncedBoolTimer += DeltaTime;
		}

		if(bShouldReminderBarkFire)
		{
			ReminderTimer += DeltaTime;

			if(ReminderTimer >= TimeUntilReminderBark)
			{
				PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenFrogPondGreenhouseMushroomHint");
				bShouldReminderBarkFire = false;
			}
		}
	}

	void PreActivate(FVector InPlayerLocation, FRotator InPlayerRotation) override
	{
		AddPlayerSheet();
		if(ActivatingSoil != nullptr)
			SetActorLocation(ActivatingSoil.ActorLocation);
		else
			SetActorLocation(OwnerPlayer.ActorLocation);
		
		SetActorRotation(FRotator(0.f, Game::GetCody().ViewRotation.Yaw, 0.f));
		
		SetActorHiddenInGame(false);
		SetActorEnableCollision(true);
		bActive = true;
	}

	void OnActivatePlant() override
	{
		SetActorTickEnabled(true);
		bFullySpawned = true;
	}

	void PreDeactivate() override
	{
		bActive = false;
		bFullySpawned = false;
	}

	void OnDeactivatePlant() override
	{
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
		SetActorEnableCollision(false);
		OnUnpossessPlant(ActorLocation, ActorRotation, EControllablePlantExitBehavior::ExitSoil);
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
        Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityClass);
    }

    UFUNCTION()
    void PlayerLandedOnBouncePad(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		if(Player.IsCody())
			return;

        if (Player.HasControl())
        {
			bool bGroundPounded = false;
			if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
				bGroundPounded = true;

			if (bCustomVerticalDirection)
				Player.SetCapabilityAttributeVector(n"VerticalVelocityDirection", VerticalBounceDirection.ForwardVector);
			Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
			Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
			Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
			bBounced = true;
        }
		
		TimeLeftForSuperBounce = SuperBounceReactionTime;	
		SetCapabilityActionState(n"AudioPlayerBounced", EHazeActionState::ActiveForOneFrame);

		if(bShouldReminderBarkFire)
			bShouldReminderBarkFire = false;	
    }

	// void TriggerSquishEffect()
	// {
	// 	ScaleBouncePadTimeLike.PlayFromStart();
	// }

	UFUNCTION(BlueprintEvent)
	void BP_Bounced() {}

	UFUNCTION(BlueprintEvent)
	void BP_GroundPounded() {}

    // UFUNCTION()
    // void UpdateScaleBouncePad(float CurValue)
    // {
    //     FVector CurScale = FMath::Lerp(StartScale, EndScale, CurValue);
    //     PlantMesh.SetRelativeScale3D(CurScale);
    // }

    UFUNCTION()
    void FinishScaleBouncePad()
    {

    }

    UFUNCTION()
	void UpdatePlayerInput(FVector2D Input, float InFireRate)
	{
		if(!bActive)
		{
			return;
		}

		CurrentPlayerInput = Input;
		FireRate = InFireRate;
	}

	bool CanExitPlant() const override
	{
		return bFullySpawned;
	}
}
