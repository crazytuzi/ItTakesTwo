import Cake.LevelSpecific.Garden.LevelActors.Shrubbery.AnimNotify_SinkingLogPierced;
import Cake.LevelSpecific.Garden.LevelActors.Shrubbery.SpinningLogActor;

class ALogHammerPlantActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase HazeSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LogSmashRoot;

	UPROPERTY(DefaultComponent, Attach = LogSmashRoot)
	UNiagaraComponent LogSmashVFXComp;

	UPROPERTY(DefaultComponent, Attach = LogSmashVFXComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAnimSequence LogHammerSequence;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<UCameraShakeBase> CamShakeOnHit;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UForceFeedbackEffect ForceFeedBackOnHit;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnHitAudioEvent;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASpinningLogActor SinkingLogRef;

	UPROPERTY(Category = "Debug")
	bool bPreviewHammerAttackSequence = false;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float startPlayRateSpeed = 0.5f;
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float startForceFeedBackMod = 0.5f;

	//How long before Failstate do we maintain full HammerSpeed/feedback
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	float fullFeedbackDuration = 3.f;

	bool bShouldTriggerCamShake = true;
	float forcefeedbackMod = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bPreviewHammerAttackSequence && LogHammerSequence != nullptr)
		{
			HazeSkelMeshComp.AnimationData.AnimToPlay = LogHammerSequence;
			HazeSkelMeshComp.AnimationData.SavedPosition = 0.f;
		}
		else
		{
			HazeSkelMeshComp.AnimationData.AnimToPlay = nullptr;
			HazeSkelMeshComp.AnimationData.SavedPosition = 0.f;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(SinkingLogRef != nullptr)
		{
			float HammerSpeed = FMath::GetMappedRangeValueClamped(FVector2D(0.f, SinkingLogRef.DurationBeforeSinking - fullFeedbackDuration), FVector2D(startPlayRateSpeed, 1.f), SinkingLogRef.SinkTimer);
			HazeSkelMeshComp.SetSlotAnimationPlayRate(LogHammerSequence, HammerSpeed);

			forcefeedbackMod = FMath::GetMappedRangeValueClamped(FVector2D(0.f, SinkingLogRef.DurationBeforeSinking - fullFeedbackDuration), FVector2D(startForceFeedBackMod, 1.f), SinkingLogRef.SinkTimer);
		}
	}

	UFUNCTION()
	void SetHammeringState()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LogHammerSequence;
		AnimParams.bLoop = true;
		AnimParams.PlayRate = startPlayRateSpeed;

		FHazeAnimNotifyDelegate LogHammerHitDelegate;
		LogHammerHitDelegate.BindUFunction(this, n"OnHammerHit");
		BindAnimNotifyDelegate(UAnimNotify_HammerLogHit::StaticClass(), LogHammerHitDelegate);

		HazeSkelMeshComp.PlaySlotAnimation(AnimParams);

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void OnHammerHit(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		LogSmashVFXComp.Activate(false);
		HazeAkComp.HazePostEvent(OnHitAudioEvent);
		if(CamShakeOnHit.IsValid())
		{
			Game::Cody.PlayCameraShake(CamShakeOnHit);
			Game::May.PlayCameraShake(CamShakeOnHit);
		}

		if(ForceFeedBackOnHit != nullptr)
		{
			Game::May.PlayForceFeedback(ForceFeedBackOnHit, false, false, n"LogHammerHit", forcefeedbackMod);
			Game::Cody.PlayForceFeedback(ForceFeedBackOnHit, false, false, n"LogHammerHit", forcefeedbackMod);
		}
	}

	UFUNCTION()
	void DisableHammerPlantFunctionality()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void DisableHammerPlantCompletely()
	{
		SetActorTickEnabled(false);
		DisableActor(this);
	}
}