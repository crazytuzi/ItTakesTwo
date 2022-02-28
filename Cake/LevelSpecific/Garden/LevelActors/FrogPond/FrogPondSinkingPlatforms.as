import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.VOBanks.GardenFrogPondVOBank;

event void FOnSinkingPlatformStartedSignature();

//Attempt to bind to player death and stop if player died while in array?
//fix networking
//Added landing impulse on impact end aswell for nicer feel + trying to prevent failed jump bug on frogs. (might be platforming catching up to frog).

class AFrogPondSinkingPlatforms : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComp;
	default ImpactComp.bCanBeActivedLocallyOnTheRemote = true;

	UPROPERTY(Category = "Settings")
	float DownwardsSpeed = 200.f;

	UPROPERTY(Category = "Settings")
	float ResetSpeed = 200.f;

	UPROPERTY(Category = "Settings")
	float LandingImpulse = 1000.f;

	UPROPERTY(Category = "Settings")
	float Acceleration = 5.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent WaterChurningEffect;
	default WaterChurningEffect.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.f;
	default DisableComp.bRenderWhileDisabled = true;
	default DisableComp.bActorIsVisualOnly = true;

	UPROPERTY()
	FOnSinkingPlatformStartedSignature SinkingEvent;

	UPROPERTY(Category = "Setup")
	UGardenFrogPondVOBank VOBank;

	TArray<AJumpingFrog> OverlappingFrogs;

	//Vertical Velocity we are accelerating towards
	float DesiredVelocity;
	
	//Current Vertical Velocity.
	float CurrentVelocity;

	bool Descending = false;
	bool bShouldTriggerMayVO = false;
	bool bShouldTriggerCodyVO = false;

	UFUNCTION(BlueprintEvent)
	void BP_StartMove() {}

	UFUNCTION(BlueprintEvent)
	void BP_StopMove() {}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnActorDownImpacted.AddUFunction(this, n"OnDownImpacted");
		ImpactComp.OnDownImpactEnding.AddUFunction(this, n"OnDownImpactEnd");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Descending || MeshComp.RelativeLocation.Z < 0.f)
		{
			CurrentVelocity = FMath::FInterpTo(CurrentVelocity, DesiredVelocity, DeltaTime, Acceleration);
			MeshComp.SetRelativeLocation(FVector(0.f, 0.f, MeshComp.RelativeLocation.Z + (CurrentVelocity * DeltaTime)));
		}
		else if(CurrentVelocity != 0.f)
		{
			CurrentVelocity = 0.f;
			WaterChurningEffect.Deactivate();		
		}

		HazeAkComp.SetRTPCValue("Rtpc_Garden_FrogPond_Platform_SinkingPlatform_Velocity", CurrentVelocity);

		if(FMath::Abs(CurrentVelocity) > 0)
			BP_StartMove();
		
		if(FMath::Abs(CurrentVelocity) < KINDA_SMALL_NUMBER)
		{
			BP_StopMove();
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void OnDownImpacted(AHazeActor Actor, const FHitResult& Hit)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr)
		{
			OverlappingFrogs.Add(Frog);
			ValidateFrogCount();
			CurrentVelocity -= LandingImpulse;

			WaterChurningEffect.Activate();
			SinkingEvent.Broadcast();
			SetActorTickEnabled(true);

			if(Frog.MountedPlayer.IsMay())
			{
				if(bShouldTriggerMayVO)
				{
					PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenFrogPondSinkingPuzzleMay", Actor2 = Frog);
				}
			}
			else if(Frog.MountedPlayer.IsCody())
			{
				if(bShouldTriggerCodyVO)
				{
					PlayFoghornVOBankEvent(VOBank, n"FoghornDBGardenFrogPondSinkingPuzzleCody", Actor = Frog);
				}
			}
		}
	}

	UFUNCTION()
	void OnDownImpactEnd(AHazeActor Actor)
	{
		AJumpingFrog Frog = Cast<AJumpingFrog>(Actor);

		if(Frog != nullptr)
		{
			CurrentVelocity -= LandingImpulse;

			OverlappingFrogs.Remove(Frog);
			ValidateFrogCount();
			Frog.MountedPlayer.StopAllCameraShakes();
		}
	}

	UFUNCTION()
	void RemoveFrogDueToDeath()
	{

	}

	void ValidateFrogCount()
	{
		if(OverlappingFrogs.Num() > 0)
		{
			Descending = true;
			DesiredVelocity = -DownwardsSpeed;
		}
		else
		{
			Descending = false;
			DesiredVelocity = ResetSpeed;
		}
	}

	UFUNCTION()
	void SetTriggerVO(bool ShouldTriggerVO)
	{
		bShouldTriggerMayVO = ShouldTriggerVO;
		bShouldTriggerCodyVO = ShouldTriggerVO;
	}
}