import Cake.LevelSpecific.Garden.LevelActors.MoleTunnel.SleepingMoleFeature;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.SneakyBush.SneakyBush;
import Vino.BouncePad.CharacterBouncePadCapability;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.LevelActors.MoleTunnel.SleepingMole_AnimNotify;
import Peanuts.Triggers.PlayerTrigger;
import Vino.Movement.Capabilities.GroundPound.CharacterGroundPoundFallCapabilty;
import Cake.LevelSpecific.Garden.LevelActors.MoleTunnel.SleepingMoleLazyOverlapComponentManager;

//event void FOnPlayerKilled(bool RolledOver, float Delay);
event void FOnBounceOnMole(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ASleepingMole : AHazeCharacter
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent)
	UVineImpactComponent VineImpactComp;
	default VineImpactComp.bUseWidget = false;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseComp;
	UPROPERTY(DefaultComponent)
	UActorImpactedCallbackComponent ImpactComponent;
	default ImpactComponent.bCanBeActivedLocallyOnTheRemote = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;
	
	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerBody;
	default DeathTriggerBody.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerHips;
	default DeathTriggerHips.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerHead;
	default DeathTriggerHead.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathTriggerLeftHand;
	default DeathTriggerLeftHand.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathTriggerRightHand;
	default DeathTriggerRightHand.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathTriggerLeftArm;
	default DeathTriggerLeftArm.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent DeathTriggerRightArm;
	default DeathTriggerRightArm.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerRightFoot;
	default DeathTriggerRightFoot.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerLeftFoot;
	default DeathTriggerLeftFoot.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerRightLeg;
	default DeathTriggerRightLeg.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerLeftLeg;
	default DeathTriggerLeftLeg.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerTail;
	default DeathTriggerTail.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent BlockBounceVolumeLeftHand;
	default BlockBounceVolumeLeftHand.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent BlockBounceVolumeRightHand;
	default BlockBounceVolumeRightHand.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent BlockBounceVolumeLeftLeg;
	default BlockBounceVolumeLeftLeg.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UBoxComponent BlockBounceVolumeRightleg;
	default BlockBounceVolumeRightleg.bGenerateOverlapEvents = false;

	// This component handles all the lazy overlap evaluation events
	UPROPERTY(DefaultComponent)
	USleepingMoleLazyOverlapComponentManager OverlapManager;

	UPROPERTY()
	APlayerTrigger PlayerRangeCheckTrigger;
	UPROPERTY()
	APlayerTrigger PlayerAutoDisableTrigger;
	UPROPERTY()
	UHazeLocomotionStateMachineAsset MoleStateMachine;
	UPROPERTY()
	USleepingMoleFeature MoleFeature;
	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;
	UPROPERTY()
	UAnimSequence BeginLastMoleStruggleAnimation;
	UPROPERTY()
	UAnimSequence LastMoleStruggleAnimation;
	UPROPERTY()
	UAnimSequence BellySneezeGestureAnimation;
	UPROPERTY()
	UAnimSequence BellyScratchGestureAnimation;
	UPROPERTY()
	UAnimSequence BackYawnGestureAnimation;
	UPROPERTY()
	UAnimSequence BackSneezeGestureAnimation;
	UControllablePlantsComponent PlantsComponent;
	ASneakyBush SneakyBush;
	UPROPERTY()
	AMoleStealthManager StealthManager;


	//---------------BouncePad-------------
	UPROPERTY(DefaultComponent, Attach = RootComp)
    UArrowComponent VerticalBounceDirection;
    default VerticalBounceDirection.RelativeRotation = FRotator(90.f, 0.f, 0.f);
    default VerticalBounceDirection.ArrowSize = 3.f;
    default VerticalBounceDirection.RelativeLocation = FVector(0.f, 0.f, 100.f);
    default VerticalBounceDirection.bVisible = false;
	UPROPERTY(DefaultComponent, NotEditable)
    UHazeAkComponent HazeAkComponent;
    UPROPERTY(EditDefaultsOnly, Category = "Bounce Properties")
    TSubclassOf<UCharacterBouncePadCapability> BouncePadCapabilityClass;
    UPROPERTY(Category = "Bounce Properties")
    float VerticalVelocity = 1750.f;
    UPROPERTY(Category = "Bounce Properties")
    float HorizontalVelocityModifier = 0.5f;
    UPROPERTY(Category = "Bounce Properties")
    float MaximumHorizontalVelocity = 500.f;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent BounceEvent;
	UPROPERTY(Category = "Audio")
	UAkAudioEvent GroundPoundBounceEvent;
    UPROPERTY()
    FOnBounceOnMole OnBounceOnMole;
	//-------------------------------------

	TPerPlayer <bool> bGameOverHasBegun;
	float ClampNoiseLevelMin = 0;
	float ClampNoiseLevelMax = 1;

	//Params for Animations
	UPROPERTY()
	bool IsOnback;
	bool PlayerIsCloseBy = false;
	int AmountOfPlayersCloseBy = 0;
	int AmountOfPlayersCloseByAutoDisable = 0;
	UPROPERTY()
	bool bIsRollingRight = false;
	UPROPERTY()
	bool bIsRollingLeft = false;
	bool bIsRolling = false;
	UPROPERTY()
	bool bIsLastStruggleMole = false;
	bool bLastStruggleMoleStarted = false;
	bool bIsPlayingGestureAnimation = false;
	UPROPERTY()
	bool bShouldPlayNoiseLevelAnimation = true;
	UPROPERTY()
	float NoiseLevel = 0;
	float TargetNoiseLevel = 0;
	bool bMayInsideBlockBounce = false;
	bool bCodyInsideBlockBounce = false;
	UPROPERTY()
	bool TempCanBeWateredFix = true;

	UPROPERTY()
	bool bMayRecentlyWatered = false;
	float MayRecentlyWateredTimer = 1;
	bool bHasTriggeredExpectedGameTimer = false;
	

	bool bRecentlyBounced = false;
	float RecentlyBouncedTimer = 1;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		OverlapManager.AttachToComponent(Mesh, n"Spine1", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		
		OverlapManager.AddBeginOverlap(DeathTriggerBody, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerHips, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerHead, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerRightHand, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerLeftHand, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerRightArm, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerLeftArm, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerRightFoot, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerLeftFoot, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerLeftLeg, this, n"OnPlayerRolledOver");
		OverlapManager.AddBeginOverlap(DeathTriggerRightLeg, this, n"OnPlayerRolledOver");
		

		OverlapManager.AddBeginOverlap(BlockBounceVolumeLeftHand, this, n"OnPlayerEnterBlockBounce");
		OverlapManager.AddBeginOverlap(BlockBounceVolumeRightHand, this, n"OnPlayerEnterBlockBounce");
		OverlapManager.AddBeginOverlap(BlockBounceVolumeRightleg, this, n"OnPlayerEnterBlockBounce");
		OverlapManager.AddBeginOverlap(BlockBounceVolumeLeftLeg, this, n"OnPlayerEnterBlockBounce");
		OverlapManager.AddEndOverlap(BlockBounceVolumeLeftHand, this, n"OnPlayerLeaveBlockBounce");
		OverlapManager.AddEndOverlap(BlockBounceVolumeRightHand, this, n"OnPlayerLeaveBlockBounce");
		OverlapManager.AddEndOverlap(BlockBounceVolumeRightleg, this, n"OnPlayerLeaveBlockBounce");
		OverlapManager.AddEndOverlap(BlockBounceVolumeLeftLeg, this, n"OnPlayerLeaveBlockBounce");
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorImpactedByPlayerDelegate OnPlayerLanded;
        OnPlayerLanded.BindUFunction(this, n"PlayerLandedOnMole");
        BindOnDownImpactedByPlayer(this, OnPlayerLanded);

		FActorImpactedDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"OnPlayerTouchedMole");
		BindOnForwardImpacted(this, ImpactDelegate);

		Capability::AddPlayerCapabilityRequest(BouncePadCapabilityClass);

		FHazeAnimNotifyDelegate RollFinishedDelegate;
		RollFinishedDelegate.BindUFunction(this, n"RollAnimationFinished");
		BindAnimNotifyDelegate(UAnimNotify_SleepingMoleRoll::StaticClass(), RollFinishedDelegate);

		DeathTriggerBody.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Spine1"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerHips.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Hips"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerHips.AddLocalRotation(FRotator(0,0,-90));
		DeathTriggerHead.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Head"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerLeftHand.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"LeftHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerLeftHand.AddLocalOffset(FVector(0,0,100));
		DeathTriggerLeftHand.AddLocalRotation(FRotator(-20,0,0));
		DeathTriggerRightHand.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerRightHand.AddLocalOffset(FVector(0,0,100));
		DeathTriggerRightHand.AddLocalRotation(FRotator(-20,0,0));
		DeathTriggerLeftArm.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"LeftForeArm"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerRightArm.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightForeArm"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerRightFoot.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightToeBase"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerLeftFoot.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"LeftToeBase"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerLeftLeg.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"LeftLeg"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerRightLeg.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightLeg"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		DeathTriggerTail.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Tail3"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		BlockBounceVolumeLeftHand.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"LeftHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		BlockBounceVolumeRightHand.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		BlockBounceVolumeRightleg.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightFoot"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);
		BlockBounceVolumeLeftLeg.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"LeftFoot"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, false);

		//VineImpactComp.OnVineWhipped.AddUFunction(this, n"VineWhipped");
		VineImpactComp.OnVineConnected.AddUFunction(this, n"VineWhipped");
		WaterHoseComp.OnHitWithWater.AddUFunction(this, n"Watered");
		if(PlayerRangeCheckTrigger != nullptr)
		{
			PlayerRangeCheckTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterTrigger");
			PlayerRangeCheckTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeaveTrigger");
		}
		if(PlayerAutoDisableTrigger != nullptr)
		{
			PlayerAutoDisableTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterAutoDisableTrigger");
			PlayerAutoDisableTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeaveAutoDisableTrigger");
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Capability::RemovePlayerCapabilityRequest(BouncePadCapabilityClass);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	//	if(!TempCanBeWateredFix)
	//		PrintToScreen("AAAAAA");
		#if EDITOR
			if(bHazeEditorOnlyDebugBool)
			{
				PrintToScreen("bMayInsideBlockBounce " + bMayInsideBlockBounce);
				PrintToScreen("bRecentlyBounced " + bRecentlyBounced);
				PrintToScreen("RecentlyBouncedTimer " + RecentlyBouncedTimer);
				PrintToScreen("bMayRecentlyWatered " + bMayRecentlyWatered);
				PrintToScreen("MayRecentlyWateredTimer " + MayRecentlyWateredTimer);
			}
		#endif


		if(bIsRolling == true or bLastStruggleMoleStarted == true)
		{
			FHazeLocomotionTransform LocomotionRootMotion;
			if(Mesh.ConsumeLastExtractedRootMotion(LocomotionRootMotion))
			{
				FVector NewLocation = GetActorLocation() + LocomotionRootMotion.DeltaTranslation;
				SetActorLocation(NewLocation);
				SetActorRotation(LocomotionRootMotion.WorldRotation);
			}
		}

		if(PlayerIsCloseBy == true && bShouldPlayNoiseLevelAnimation == true)
		{
			TargetNoiseLevel = FMath::Clamp((StealthManager.GetCurrentSoundAmount()/100), ClampNoiseLevelMin, ClampNoiseLevelMax);
			NoiseLevel = FMath::Lerp(NoiseLevel, TargetNoiseLevel + 0.1f, DeltaTime/2.5f);
		}
		if(PlayerIsCloseBy != true && bShouldPlayNoiseLevelAnimation == true && NoiseLevel > 0)
		{
			TargetNoiseLevel = -0.05;
			NoiseLevel = FMath::Lerp(NoiseLevel, TargetNoiseLevel, DeltaTime/1.5f);
		}

		if(bRecentlyBounced == true)
		{
			RecentlyBouncedTimer -= DeltaTime * 0.35f;
			if(RecentlyBouncedTimer <= 0)
			{
				if(this.HasControl())
				{
					NetRecentlyBouncedStopped();
				}
			}
		}

		if(bMayRecentlyWatered == true)
		{
			MayRecentlyWateredTimer -= DeltaTime * 0.35f;
			if(MayRecentlyWateredTimer <= 0)
			{
				if(Game::GetMay().HasControl())
				{
					WateredStopped();
				}
			}
		}
	}

	//Networked via OnForward Impacted Delegate
	UFUNCTION()
	void OnPlayerTouchedMole(AHazeActor Actor, FHitResult Hit)
	{
		if(bIsPlayingGestureAnimation or bIsLastStruggleMole)
			return;

		auto Player = Cast<AHazePlayerCharacter>(Actor);

		if(Player == nullptr)
			return;

		if(bGameOverHasBegun[Player])
			return;

		bGameOverHasBegun[Player] = true;

		StealthManager.KilledByMole(Player, false, 0.75f);
		StealthManager.IncreaseSoundAmountManually(120, true);
	
		
		bRecentlyBounced = true;
		if(IsOnback == true)
		{
			StartGestureAnimationOnBack(5);
		}
		else
		{
			StartGestureAnimationOnBelly(5);
		}
	}

	//Networked via DownImpact delegate
	UFUNCTION(NotBlueprintCallable)
    void PlayerLandedOnMole(AHazePlayerCharacter Player, FHitResult HitResult)
    {
		if(bGameOverHasBegun[Player])
			return;

		if(Player == Game::GetMay())
		{
			BroadcastBounce(Player);
			if(bMayInsideBlockBounce == false)
			{
				bool bGroundPounded = false;
				if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
						bGroundPounded = true;

				Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
				Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
				Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
				HazeAkComponent.HazePostEvent(BounceEvent);
			}
		}
		if(Player == Game::GetCody())
		{
			BroadcastBounce(Player);
			if(bCodyInsideBlockBounce == false)
			{
				bool bGroundPounded = false;
				if (Player.IsAnyCapabilityActive(UCharacterGroundPoundFallCapability::StaticClass()))
						bGroundPounded = true;

				Player.SetCapabilityAttributeValue(n"VerticalVelocity", VerticalVelocity);
				Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", HorizontalVelocityModifier);
				Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
				HazeAkComponent.HazePostEvent(BounceEvent);
			}
		}

		if(bIsPlayingGestureAnimation or bIsLastStruggleMole)
			return;

		bRecentlyBounced = true;
		if(IsOnback == true)
		{
			StartGestureAnimationOnBack(5);
		}
		else
		{
			StartGestureAnimationOnBelly(5);
		}
    }

    void BroadcastBounce(AHazePlayerCharacter Player)
    {
		if(bGameOverHasBegun[Player])
			return;

		bGameOverHasBegun[Player] = true;
		StealthManager.KilledByMole(Player, false, 0.75f);
		StealthManager.IncreaseSoundAmountManually(120, true);
    }

	//Networked via PlayerTrigger
	UFUNCTION()
	void StartLastMoleStruggleAnimation()
	{
		if(bLastStruggleMoleStarted)
			return;

		bLastStruggleMoleStarted = true;
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"PlayLoopAnimationForLastStruggle");
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = BeginLastMoleStruggleAnimation, bLoop = false);
	}
	UFUNCTION()
	void PlayLoopAnimationForLastStruggle()
	{
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = LastMoleStruggleAnimation, bLoop = true);
	}
	
	//Networked via PlayerTrigger
	UFUNCTION()
	void StartGestureAnimationOnBack(int Version)
	{
		if(bIsPlayingGestureAnimation or bIsLastStruggleMole)
			return;

		bIsPlayingGestureAnimation = true;
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"GestureAnimationStopped");

		if(Version == 1)
		{
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = BackSneezeGestureAnimation, bLoop = false);
		}
		if(Version == 2)
		{
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = BackYawnGestureAnimation, bLoop = false);
		}
		if(Version == 3)
		{
			SetAnimBoolParam(n"MoleWhipping", true);
		}
		if(Version == 4)
		{
			if(bMayRecentlyWatered)	
				return;

			bMayRecentlyWatered = true;
			bIsPlayingGestureAnimation = true;
		}
		if(Version == 5)
		{
			SetAnimBoolParam(n"JumpOnMole", true);
		}
	}
	//Networked via PlayerTrigger
	UFUNCTION()
	void StartGestureAnimationOnBelly(int Version)
	{
		if(bIsPlayingGestureAnimation or bIsLastStruggleMole)
			return;

		bIsPlayingGestureAnimation = true;
		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"GestureAnimationStopped");

		if(Version == 1)
		{
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = BellySneezeGestureAnimation, bLoop = false);
		}
		if(Version == 2)
		{
			PlayEventAnimation(OnBlendedIn, OnBlendingOut, Animation = BellyScratchGestureAnimation, bLoop = false);
		}
		if(Version == 3)
		{
			SetAnimBoolParam(n"MoleWhipping", true);
		}
		if(Version == 4)
		{
			if(bMayRecentlyWatered)	
				return;

			bMayRecentlyWatered = true;
			bIsPlayingGestureAnimation = true;
		}
		if(Version == 5)
		{
			SetAnimBoolParam(n"JumpOnMole", true);
		}
	}
	//Don't need networking because start anim is networked which means that this will 
	//always fire for both players
	UFUNCTION(NotBlueprintCallable)
	void GestureAnimationStopped()
	{
		bIsPlayingGestureAnimation = false;
	}
	UFUNCTION(NetFunction)
	void NetRecentlyBouncedStopped()
	{
		bRecentlyBounced = false;
		RecentlyBouncedTimer = 1;
	}


	//Networked via PlayerTrigger
	UFUNCTION()
	void StartRollAnimation(bool Left)
	{
		bIsRolling = true;
		if(IsOnback == true)
		{
			if(Left == true)
			{
				bIsRollingLeft = true;
			}
			else
			{
				bIsRollingRight = true;
			}
		}
		else
		{
			if(Left == true)
			{
				bIsRollingLeft = true;
			}
			else
			{
				bIsRollingRight = true;
			}
		}
	}
	//Don't need networking because start anim is networked which means that this will 
	//always fire for both players
	UFUNCTION()
	void RollAnimationFinished(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		bIsRolling = false;
		bIsRollingRight = false;
		bIsRollingLeft = false;
		if(IsOnback == true)
		{
			IsOnback = false;
		}
		else
		{
			IsOnback = true;
		}
	}
	
	//Networked via PlayerTrigger
	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerRolledOver(UPrimitiveComponent Shape, AHazePlayerCharacter Player)
	{
		if(bIsRolling == true or bLastStruggleMoleStarted == true or bIsPlayingGestureAnimation == true)
		{
			if(bRecentlyBounced)
				return;

			if(Player.IsMay())
			{
				if(Player.HasControl())
				{
					KillPlayer(Player, DeathEffect);
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddObject(n"Player", Player);
					auto CrumbComp = UHazeCrumbComponent::Get(Player); 
					CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnPlayerRolledOver"), CrumbParams);
				}
			}
			else
			{
				PlantsComponent = UControllablePlantsComponent::Get(Player);
				ASneakyBush CurrentSneakyBush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);

				if(CurrentSneakyBush == nullptr)
				{
					if(Player.HasControl())
					{
						KillPlayer(Player, DeathEffect);
						FHazeDelegateCrumbParams CrumbParams;
						CrumbParams.AddObject(n"Player", Player);
						auto CrumbComp = UHazeCrumbComponent::Get(Player); 
						CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnPlayerRolledOver"), CrumbParams);
					}
				}
			}
		}
	}
	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnPlayerRolledOver(const FHazeDelegateCrumbData& CrumbData)
	{
		auto Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		StealthManager.KilledByMole(Player, true, 0.75f);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerEnterBlockBounce(UPrimitiveComponent Shape, AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
		{
			if(Player.HasControl())
			{
				bMayInsideBlockBounce = true;
			}
		}
		else
		{
			PlantsComponent = UControllablePlantsComponent::Get(Player);
			ASneakyBush CurrentSneakyBush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);

			if(CurrentSneakyBush == nullptr)
			{
				if(Player.HasControl())
				{
					bCodyInsideBlockBounce = true;
				}
			}
		}
	}
	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerLeaveBlockBounce(UPrimitiveComponent Shape, AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
		{
			if(Player.HasControl())
			{
				bMayInsideBlockBounce = false;
			}
		}
		else
		{
			PlantsComponent = UControllablePlantsComponent::Get(Player);
			ASneakyBush CurrentSneakyBush = Cast<ASneakyBush>(PlantsComponent.CurrentPlant);

			if(CurrentSneakyBush == nullptr)
			{
				if(Player.HasControl())
				{
					bCodyInsideBlockBounce = false;
				}
			}
		}
	}


	//////OnVineWhipped is Networked
	UFUNCTION(NotBlueprintCallable)
	void VineWhipped()
	{
		auto Player = Game::GetCody();

		if(bGameOverHasBegun[Player])
			return;

		bGameOverHasBegun[Player] = true;
		StealthManager.IncreaseSoundAmountManually(120, true);
		StealthManager.KilledByMole(Player, false, 1.f);

		if(IsOnback == true)
		{
			StartGestureAnimationOnBack(3);
		}
		else
		{
			StartGestureAnimationOnBelly(3);
		}
	}


	//////OnWaterd is networked
	UFUNCTION(NotBlueprintCallable)
	void Watered()
	{
		auto Player = Game::GetMay();

		if(!TempCanBeWateredFix)
			return;
		if(bGameOverHasBegun[Player])
				return;
				
		StealthManager.IncreaseSoundAmountManually(7.5f, true);
		if(StealthManager.GetCurrentSoundAmount() >= 100)
		{
			bGameOverHasBegun[Player] = true;
			StealthManager.KilledByMole(Player, false, 1.f);
		}

		if(IsOnback == true)
		{
			StartGestureAnimationOnBack(4);
		}
		else
		{
			StartGestureAnimationOnBelly(4);
		}
	}
	UFUNCTION(NetFunction)
	void WateredStopped()
	{
		if(!TempCanBeWateredFix)
			return;

		bMayRecentlyWatered = false;
		bIsPlayingGestureAnimation = false;
		MayRecentlyWateredTimer = 1;
	}
	

	//Networked via PlayerTrigger
	UFUNCTION()
	void OnPlayerEnterTrigger(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetMay() or Player == Game::GetCody())
		{
			PlayerIsCloseBy = true;
			AmountOfPlayersCloseBy ++;
		}
	}
	//Networked via PlayerTrigger
	UFUNCTION()
	void OnPlayerLeaveTrigger(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetMay() or Player == Game::GetCody())
		{
			AmountOfPlayersCloseBy --;
			if(AmountOfPlayersCloseBy == 0)
			{
				PlayerIsCloseBy = false;
			}
		}
	}
	//Networked via PlayerTrigger
	UFUNCTION()
	void OnPlayerEnterAutoDisableTrigger(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetMay() or Player == Game::GetCody())
		{
			if(IsActorDisabled())
				EnableActor(nullptr);

			AmountOfPlayersCloseByAutoDisable ++;
		}
	}
	//Networked via PlayerTrigger
	UFUNCTION()
	void OnPlayerLeaveAutoDisableTrigger(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetMay() or Player == Game::GetCody())
		{
			AmountOfPlayersCloseByAutoDisable --;
			if(AmountOfPlayersCloseByAutoDisable == 0)
			{
				if(!IsActorDisabled())
					DisableActor(nullptr);
			}
		}
	}
}
