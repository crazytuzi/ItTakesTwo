import Cake.LevelSpecific.Garden.LevelActors.Shrubbery.AnimNotify_SinkingLogPierced;
import Cake.LevelSpecific.Garden.LevelActors.Shrubbery.SpinningLogActor;
import Cake.LevelSpecific.Garden.VOBanks.GardenShrubberyVOBank;

/*

- Add Disable Functionality for when cutscenes trigger (Remove Holes as they wont follow logmesh, disable vfx/etc)


*/

class ALogSwiperPlantActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase HazeSkelMeshComp;

	UPROPERTY(DefaultComponent, Attach = HazeSkelMeshComp, AttachSocket = HeadSocket)
	UCapsuleComponent CapsuleCollider;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LogHoleRoot;

	UPROPERTY(DefaultComponent, Attach = LogHoleRoot)
	UStaticMeshComponent LogHoleMesh;
	default LogHoleMesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = LogHoleMesh)
	UCapsuleComponent LogHoleCollider;

	UPROPERTY(DefaultComponent, Attach = LogHoleRoot)
	UNiagaraComponent HoleBreakVFXComp;

	UPROPERTY(DefaultComponent, Attach = LogHoleRoot)
	UNiagaraComponent HoleBreakWaterVFXComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent EndHoleRoot;

	UPROPERTY(DefaultComponent, Attach = EndHoleRoot)
	UStaticMeshComponent EndHoleMesh;

	UPROPERTY(DefaultComponent, Attach = EndHoleMesh)
	UCapsuleComponent EndHoleCollider;

	UPROPERTY(DefaultComponent, Attach = EndHoleRoot)
	UNiagaraComponent EndHoleBreakVFX;

	UPROPERTY(DefaultComponent, Attach = EndHoleRoot)
	UNiagaraComponent EndHoleBreakWaterVFXComp;

	UPROPERTY(DefaultComponent, Attach = HazeSkelMeshComp, AttachSocket = HeadSocket)
	UHazeAkComponent HazeAkCompPlant;

	UPROPERTY(DefaultComponent, Attach = HoleBreakWaterVFXComp)
	UHazeAkComponent HazeAkCompWater;
	
	UPROPERTY(DefaultComponent, Attach = EndHoleBreakWaterVFXComp)
	UHazeAkComponent HazeAkCompWaterEnd;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlantPierceLogAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlantStruggleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WaterSplashStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WaterSplashStopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WoodCreaksStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent WoodCreaksStopAudioEvent;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBoxComponent ActivationTrigger;
	default ActivationTrigger.ShapeColor = FColor::Red;
	default ActivationTrigger.RelativeRotation = FRotator(0.f, -27.5f, 0.f);
	default ActivationTrigger.SetBoxExtent(FVector(1920.f, 128.f, 1920.f));

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASpinningLogActor LogReference;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UGardenShrubberyVOBank ShrubberyVOBank;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TSubclassOf<UCameraShakeBase> CamShakeSetting;

	UPROPERTY(EditDefaultsOnly ,Category = "Setup")
	UForceFeedbackEffect ForceFeedbackSettings;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAnimSequence LogSwiperIdle;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAnimSequence LogSwiperPierce;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAnimSequence LogPiercedStruggle;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAnimSequence LogPiercedRetract;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	UAnimSequence DefaultRetract;

	UPROPERTY(Category = "Settings")
	bool bShouldActivateWaterVFX = false;

	UPROPERTY(Category = "Settings")
	bool bShouldActivateEndWaterVFX = false;

	UPROPERTY(Category = "Settings")
	bool bShouldBreakFirstLogHole = false;

	UPROPERTY(Category = "Settings")
	bool bShouldBreakSecondLogHole = false;

	UPROPERTY(Category = "Audio Events")
	bool bShouldActivateWoodCreaks = false;

	UPROPERTY(Category = "Debug")
	bool bPreviewIdlePosition = false;

	UPROPERTY(Category = "Debug")
	bool bPreviewPiercedPosition = false;

	UPROPERTY(Category = "Setup")	
	bool bShouldTriggerSwiperVO = false;

	//Used to check if Actor Should be reset on failstate
	bool bHasTriggeredPierce = false;

	FTimerHandle StruggleHandle;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bPreviewIdlePosition && LogSwiperIdle != nullptr)
		{
			HazeSkelMeshComp.AnimationData.AnimToPlay = LogSwiperIdle;
			HazeSkelMeshComp.AnimationData.SavedPosition = 0.f;
			LogHoleMesh.bHiddenInGame = true;
			EndHoleMesh.bHiddenInGame = true;
		}
		else if(bPreviewPiercedPosition)
		{
			HazeSkelMeshComp.AnimationData.AnimToPlay = LogSwiperPierce;
			HazeSkelMeshComp.AnimationData.SavedPosition = LogSwiperPierce.GetPlayLength();
			LogHoleMesh.bHiddenInGame = false;
			EndHoleMesh.bHiddenInGame = false;
		}
		else
		{
			HazeSkelMeshComp.AnimationData.AnimToPlay = nullptr;
			HazeSkelMeshComp.AnimationData.SavedPosition = 0.f;
			LogHoleMesh.bHiddenInGame = true;
			EndHoleMesh.bHiddenInGame = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//Debugging Reset
		HazeSkelMeshComp.AnimationData.AnimToPlay = nullptr;
		HazeSkelMeshComp.AnimationData.SavedPosition = 0.f;
		LogHoleMesh.SetHiddenInGame(true);
		EndHoleMesh.SetHiddenInGame(true);

		ActivationTrigger.OnComponentBeginOverlap.AddUFunction(this, n"PerformLogPierce");
	}

	//Play Pierce anim and trigger VFX/Collision changes.
	UFUNCTION()
	void PerformLogPierce(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player;
		Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(LogReference == nullptr || (LogReference != nullptr && !LogReference.bSinking))
			return;

		if(bHasTriggeredPierce)
			return;

		if(Player == nullptr)
			return;
		
		ActivationTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		FHazeAnimNotifyDelegate LogPiercedDelegate;
		LogPiercedDelegate.BindUFunction(this, n"OnLogPierced");
		BindAnimNotifyDelegate(UAnimNotify_SinkingLogPierced::StaticClass(), LogPiercedDelegate);

		FHazeAnimNotifyDelegate LogPiercedEndDelegate;
		LogPiercedEndDelegate.BindUFunction(this, n"OnLogPiercedEnd");
		BindAnimNotifyDelegate(UAnimNotify_SinkingLogPiercedEnd::StaticClass(), LogPiercedEndDelegate);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LogSwiperPierce;
		HazeSkelMeshComp.PlaySlotAnimation(AnimParams);

		bHasTriggeredPierce = true;
	}

	//On Animation Notify Log was penetrated
	UFUNCTION()
	void OnLogPierced(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		LogHoleMesh.SetHiddenInGame(false);
		LogHoleCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		HoleBreakVFXComp.Activate();
		HazeAkCompPlant.HazePostEvent(PlantPierceLogAudioEvent);

		if(bShouldActivateWaterVFX)
		{
			HoleBreakWaterVFXComp.Activate(false);
			HazeAkCompWater.HazePostEvent(WaterSplashStartAudioEvent);
		}
			

		if(CamShakeSetting.IsValid())
		{
			Game::Cody.PlayCameraShake(CamShakeSetting);
			Game::May.PlayCameraShake(CamShakeSetting);
		}

		if(ForceFeedbackSettings != nullptr)
		{
			Game::Cody.PlayForceFeedback(ForceFeedbackSettings,false, false, n"LogPierced");
			Game::May.PlayForceFeedback(ForceFeedbackSettings, false, false, n"LogPierced");
		}

		bHasTriggeredPierce = true;
	}

	//On Animation Notify Pierce Motion has stopped
	UFUNCTION()
	void OnLogPiercedEnd(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		if(bShouldBreakFirstLogHole && LogReference != nullptr)
		{
			LogReference.BreakFirstHole();
			EndHoleBreakVFX.Activate();
			EndHoleMesh.SetHiddenInGame(false);
			EndHoleCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		}
		else if(bShouldBreakSecondLogHole && LogReference != nullptr)
		{
			LogReference.BreakSecondHole();
		}
		else
		{
			EndHoleBreakVFX.Activate();
			EndHoleMesh.SetHiddenInGame(false);
			EndHoleCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		}

		if(bShouldActivateEndWaterVFX)
		{
			EndHoleBreakWaterVFXComp.Activate(false);
			HazeAkCompWaterEnd.HazePostEvent(WaterSplashStartAudioEvent);
		}

		if(bShouldActivateWoodCreaks)
		{
			HazeAkCompPlant.HazePostEvent(WoodCreaksStartAudioEvent);
		}
			
		StruggleHandle = System::SetTimer(this, n"PerformStruggle", 1.f, true, InitialStartDelayVariance = 1.f);

		if(bShouldTriggerSwiperVO)
		{
			if(ShrubberyVOBank != nullptr)
				PlayFoghornVOBankEvent(ShrubberyVOBank, n"FoghornSBGardenShrubberySpinningLogLogCollapse");
		}
	}
	
	//DebugFuction
	UFUNCTION(BlueprintCallable)
	void SetIdleState()
	{
		LogHoleMesh.SetHiddenInGame(true);
		EndHoleMesh.SetHiddenInGame(true);

		if(LogSwiperIdle == nullptr)
		{
			return;
		}

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.bLoop = true;
		AnimParams.Animation = LogSwiperIdle;

		HazeSkelMeshComp.PlaySlotAnimation(AnimParams);
	}

	//DebugFunction
	UFUNCTION(BlueprintCallable)
	void DebugPlayPierce()
	{
		ActivationTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		LogHoleMesh.SetHiddenInGame(true);

		FHazeAnimNotifyDelegate LogPiercedDelegate;
		LogPiercedDelegate.BindUFunction(this, n"OnLogPierced");

		FHazeAnimNotifyDelegate LogPiercedEndDelegate;
		LogPiercedEndDelegate.BindUFunction(this, n"OnLogPiercedEnd");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LogSwiperPierce;
		AnimParams.bLoop = false;

		BindAnimNotifyDelegate(UAnimNotify_SinkingLogPierced::StaticClass(), LogPiercedDelegate);
		BindAnimNotifyDelegate(UAnimNotify_SinkingLogPiercedEnd::StaticClass(), LogPiercedEndDelegate);

		HazeSkelMeshComp.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateMHState()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.bLoop = true;
		AnimParams.Animation = LogSwiperIdle;

		HazeSkelMeshComp.PlaySlotAnimation(AnimParams);
	}

	//Timer Based Function play short animation
	UFUNCTION()
	void PerformStruggle()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.BlendTime = 0.f;
		AnimParams.Animation = LogPiercedStruggle;
		HazeSkelMeshComp.PlaySlotAnimation(AnimParams);
		HazeAkCompPlant.HazePostEvent(PlantStruggleAudioEvent);
	}

	//Upon Failstate if plant is activated
	UFUNCTION()
	void RetractPlant()
	{
		System::ClearAndInvalidateTimerHandle(StruggleHandle);

		HazeSkelMeshComp.StopAllSlotAnimations();
		FHazePlaySlotAnimationParams AnimParams;

		FHazeAnimNotifyDelegate OnRetractVFXDelegate;
		OnRetractVFXDelegate.BindUFunction(this, n"RetractTriggerVFX");
		BindAnimNotifyDelegate(UAnimNotify_SinkingLogRetract::StaticClass(), OnRetractVFXDelegate);
		//sfx for retracting plant is triggered in animation

		if(bHasTriggeredPierce)
		{
			AnimParams.Animation = LogPiercedRetract;
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOutDelegate;
			OnBlendingOutDelegate.BindUFunction(this, n"OnRetracted");

			HazeSkelMeshComp.PlaySlotAnimation(OnBlendedIn, OnBlendingOutDelegate, AnimParams);
		}
		else
		{
			AnimParams.Animation = DefaultRetract;
			FHazeAnimationDelegate OnBlendedIn;
			FHazeAnimationDelegate OnBlendingOutDelegate;
			OnBlendingOutDelegate.BindUFunction(this, n"OnRetracted");

			HazeSkelMeshComp.PlaySlotAnimation(OnBlendedIn, OnBlendingOutDelegate, AnimParams);
		}
	}

	//On Retract, trigger Log VFX.
	UFUNCTION()
	void RetractTriggerVFX(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		HoleBreakVFXComp.Activate(false);
	}

	//Finished Retracting.
	UFUNCTION()
	void OnRetracted()
	{
		//this.DisableActor(this);
	}

	//Called to hide all mesh Holes/VFX Spawned on loginside
	UFUNCTION()
	void HideAllVisuals()
	{
		EndHoleMesh.SetHiddenInGame(true);
		LogHoleMesh.SetHiddenInGame(true);
		EndHoleBreakVFX.Deactivate();
		HoleBreakVFXComp.Deactivate();
		HoleBreakWaterVFXComp.Deactivate();
		EndHoleBreakWaterVFXComp.Deactivate();
		HazeAkCompWater.HazePostEvent(WaterSplashStopAudioEvent);
		HazeAkCompWaterEnd.HazePostEvent(WaterSplashStopAudioEvent);
		HazeAkCompPlant.HazePostEvent(WoodCreaksStopAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		System::ClearAndInvalidateTimerHandle(StruggleHandle);
	}
}