import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatStreamComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.ToyCannonActor;
import Vino.Movement.Components.MovementComponent;
import Vino.Interactions.InteractionComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatHealthWidget;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatMovementData;
import Peanuts.DamageFlash.DamageFlashStatics;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCartRail;

import FVector GetPlayerWheelBoatInput(AHazePlayerCharacter) from "Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatPlayerInputCapability";

event void FOnPlayerInteractWithWheelBoat(AHazePlayerCharacter Player, bool InWheel);
event void FOnWheelBoatBossFightStart();
event void FOnWheelBoatBossFightStop();
event void FBothPlayersAreInWheelBoat();
event void FOnWheelBoatStartSpinning();
event void FOnWheelBoatStopSpinning();
event void FOnWheelBoatImpact();
event void FOnWheelBoatTakeDamage(float Amount);
event void FOnWheelBoatDeath();
event void FOnBoatJab();
event void FOnHitByTentacleSlam();

enum EWheelBoatHitType
{
	CannonBall,
	TentacleSlam,
	CollisionImpact,
	NoReaction
}

// This component is on the players and holds the players wheelboat params
class UOnWheelBoatComponent : UActorComponent
{
	UPROPERTY(Transient)
	AWheelBoatActor WheelBoat;

	FVector PlayerSteeringInput;

	UPROPERTY(Transient)
	bool CannonInput = false;

	UPROPERTY(Transient)
	float ChargeRange = 0.0f;

	UPROPERTY(Transient)
	bool bInBossFight = false;

	UPROPERTY()
	float LatestShotTimeStamp = 0.0f;

	// UPROPERTY()
	// int ShootSpamCounter = 0;

	AHazePlayerCharacter PlayerOwner;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if(WheelBoat != nullptr)
		{
			WheelBoat.SetWheelBoatBlocked(false);
			WheelBoat.ReleasePlayer(PlayerOwner);
		}
	}

	UFUNCTION(BlueprintPure)
	float GetPlayerWheelInput() const property
	{
		if(PlayerOwner == nullptr)
			return 0.f;

		if(WheelBoat == nullptr)
			return 0.f;
		
		auto SubWheelActor = PlayerOwner.IsMay() ? WheelBoat.LeftWheelSubActor : WheelBoat.RightWheelSubActor;
		if(SubWheelActor == nullptr)
			return 0.f;

		return SubWheelActor.MovementData.WheelBoatWheelAnimationRange;
	}
};


// This subactor is the representation of each player on the wheelboat
class AWheelBoatActorWheelActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	default ReplicateAsSubActor();


	UPROPERTY(DefaultComponent)	
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);
	default CrumbComponent.DebugHistorySize = 10;

	AHazePlayerCharacter Player;
	FWheelBoatMovementData MovementData;
	AWheelBoatActor ParentBoat;

	bool IsLeftSide()const
	{
		if(Player != nullptr)
			return ParentBoat.PlayerInLeftWheel == Player;
		
		return false;
	}

	bool IsRightSide()const
	{
		if(Player != nullptr)
			return ParentBoat.PlayerInRightWheel == Player;
		
		return false;
	}

	AWheelBoatActorWheelActor GetOtherSubActor()const property
	{
		if(ParentBoat.LeftWheelSubActor == this)
			return ParentBoat.RightWheelSubActor;
		else
			return ParentBoat.LeftWheelSubActor;
	}

	UFUNCTION(NetFunction)
	void NetReplicateDirectionInput(FVector InputDirection)
	{
		if(Player == nullptr)
			return;

		auto WheelBoatPlayerComp = UOnWheelBoatComponent::Get(Player);

		// Can happen during streaming
		if(WheelBoatPlayerComp == nullptr )
			return; 

		WheelBoatPlayerComp.PlayerSteeringInput = InputDirection;
	}

	UFUNCTION(NetFunction)
	void NetReplicateBothDirectionInput(FVector InputDirection)
	{
		if(Player == nullptr)
			return;
			
		auto WheelBoatPlayerComp = UOnWheelBoatComponent::Get(Player);
		auto WheelBoatOtherPlayerComp = UOnWheelBoatComponent::Get(Player.GetOtherPlayer());

		// Can happen during streaming
		if(WheelBoatPlayerComp == nullptr || WheelBoatOtherPlayerComp == nullptr)
			return; 

		WheelBoatPlayerComp.PlayerSteeringInput = InputDirection;
		WheelBoatOtherPlayerComp.PlayerSteeringInput = InputDirection;
	}
}

event void FOnSetPOI(float Time);

// This is the actual wheelboat
UCLASS(Abstract)
class AWheelBoatActor : AHazeActor
{
	default ReplicateAsMovingActor();

	FVector PointOfInterestLoc;
	FOnSetPOI OnSetPOIEvent;

	FHazeAudioEventInstance BoatStreamAudioEventInstance;
	FHazeAudioEventInstance LeftWheelEventInstance;
	FHazeAudioEventInstance RightWheelEventInstance;
	
	//Actor Components
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComponent)
	USceneComponent RotationBase;

	UPROPERTY(DefaultComponent, Attach = RotationBase)
	UHazeSkeletalMeshComponentBase BoatMesh;

	UPROPERTY(DefaultComponent, Attach = BoatMesh)
	USceneComponent BaseAttachments;
	
	UPROPERTY(DefaultComponent, Attach = BaseAttachments)
	USceneComponent LeftWheelBase;
	UPROPERTY(DefaultComponent, Attach = BaseAttachments)
	USceneComponent RightWheelBase;

	UPROPERTY(DefaultComponent, Attach = LeftWheelBase)
	USceneComponent LeftWheelPlayerAttachPoint;
	UPROPERTY(DefaultComponent, Attach = RightWheelBase)
	USceneComponent RightWheelPlayerAttachPoint;

	//NEED TO BE DISABLED WHEN THROWN IN AIR
	UPROPERTY(DefaultComponent, Attach = RightWheelBase)
	UNiagaraComponent RightWheelSplashEffect;
	UPROPERTY(DefaultComponent, Attach = LeftWheelBase)
	UNiagaraComponent LeftWheelSplashEffect;
	
	UPROPERTY(Category = "Niagara")
	UNiagaraSystem BoatLandInWaterSystem;

	UPROPERTY(EditDefaultsOnly)
	bool bUseSteeringInput = true;

	private bool bUpdatedMovement = false;
	private bool bLastUpdatedMovement = false;
	bool bReactingToImpact = false;
	int ImpactCount = 0;
	bool bIsDying = false;
	bool bDead = false;
	bool bTakingDamageReaction = false;

	UPROPERTY(Category = "NotEditable")
	USkeletalMesh WholeMesh;
	UPROPERTY(Category = "NotEditable")
	USkeletalMesh BrokenMesh;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.SetCollisionProfileName(n"BlockAll");
	default CapsuleComponent.SetCapsuleHalfHeight(100.f);
	default CapsuleComponent.SetCapsuleRadius(65.f);

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent AkComponent;

	//General Variables
	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatCollisionImpactEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatDamageTakenEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatLeftWheelStartEvent;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatLeftWheelStopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatRightWheelStartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatRightWheelStopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatMovingStartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatMovingStopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatSpinningStart;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatSpinningStop;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatStreamStartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatStreamStopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent WheelBoatTentacleHitEvent;

	UPROPERTY(Category = "Audio", EditDefaultsOnly)
	UGoldbergVOBank VOBank;

	UPROPERTY()
	FOnBoatJab OnBoatJabbedEvent;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet WheelBoatSheet;

	UPROPERTY(DefaultComponent)	
	UWheelBoatStreamComponent StreamComponent;

	UPROPERTY(Category = "Events")
	FOnPlayerInteractWithWheelBoat ShouldChangePlayerCamera;
	UPROPERTY(Category = "Events")
	FBothPlayersAreInWheelBoat BothPlayersAreInTheBoat;
	UPROPERTY(Category = "Events")
	FOnWheelBoatBossFightStart OnBossFightStart;
	UPROPERTY(Category = "Events")
	FOnWheelBoatBossFightStart OnBossFightSecondPartStart;
	UPROPERTY(Category = "Events")
	FOnWheelBoatBossFightStart OnBossFightThirdPartStart;
	UPROPERTY(Category = "Events")
	FOnWheelBoatBossFightStop OnBossFightStop;
	UPROPERTY(Category = "Events")
	FOnWheelBoatStartSpinning OnStartSpinning;
	UPROPERTY(Category = "Events")
	FOnWheelBoatStopSpinning OnStopSpinning;
	UPROPERTY(Category = "Events")
	FOnWheelBoatImpact OnImpact;
	UPROPERTY(Category = "Events")
	FOnWheelBoatTakeDamage OnTakeDamage;
	UPROPERTY(Category = "Events")
	FOnHitByTentacleSlam OnHitByTentacleSlam;
	UPROPERTY(Category = "Events")
	FOnWheelBoatDeath OnDeath;

	UPROPERTY(Category = "References")
	AHazePlayerCharacter PlayerInLeftWheel;
	UPROPERTY(Category = "References")
	AHazePlayerCharacter PlayerInRightWheel;
	UPROPERTY(Category = "References")
	AHazePlayerCharacter PlayerWithFullscreen;
	
	UPROPERTY(Category = "Animation")
	UHazeLocomotionAssetBase MayLocomotion;
	UPROPERTY(Category = "Animation")
	UHazeLocomotionAssetBase CodyLocomotion;

	UPROPERTY(Category = "Animation")
	UAnimSequence BoatSlamReaction;

	UPROPERTY(Category = "Settings")
	UBoatSettingsDataAsset BoatSettings;
	UPROPERTY(Category = "Settings")
	float WheelSplashMaxSpawnRate = 20.0f;

	UPROPERTY(Category = "Feedback")
	TSubclassOf<UPlayerDamageEffect> DamageEffect;
	
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect LowShootForceFeedback;
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect MediumShootForceFeedback;
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect HitForceFeedback;
	UPROPERTY(Category = "Feedback")
	UForceFeedbackEffect ImpactForceFeedback;

	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> HitCameraShake;
	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> BossHitCameraShake;
	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> ImpactCameraShake;
	UPROPERTY(Category = "Feedback")
	TSubclassOf<UCameraShakeBase> SpinCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Feedback")
	float DamageFlashDuration = 0.12f;
	UPROPERTY(EditDefaultsOnly, Category = "Feedback")
	FLinearColor DamageFlashColor = FLinearColor(0.5f, 0.5f, 0.5f, 0.15f);

	UPROPERTY(EditInstanceOnly, BlueprintReadOnly, Category = "Default")
	ARailCartRail RailCartRail;

	UPROPERTY(Category = "Default")
	UHazeCameraSettingsDataAsset ThirdPhaseCameraSettings; 

	UCameraShakeBase CurrentActiveShake = nullptr;
	FVector LastValidLocation = FVector::ZeroVector;

	UPROPERTY(NotEditable)
	bool bDocked = false;

	UPROPERTY(Category = "Default")
	AToyCannonActor RightCannon;
	UPROPERTY(Category = "Default")
	AToyCannonActor LeftCannon;	

	UPROPERTY(Category = "Default")
	AActor BoatCamera;	

	AHazeActor OctopusBoss;
	int OctopusBossAttackSequence = 0;
	bool bActivatedFromCheckpoint = false;

	bool bSpinning = false;
	float CurrentSpinForce = 0;
	float TotalAmountToSpin = 0.f;
	float SpinDirection = 0;
	int BossFightIndex = 0;

	bool bBossFightActive;
	bool bBossIsPreparingNextAttackSequence;
	bool bStreamActive;

	float TimeStampCollisionBark = 0.f;
	float CollisionBarkCooldown = 5.f;

	UPROPERTY(Category = "NotEditable")
	bool bIsAirborne;

	private int PlayerReadyCount = 0;

	// Health, we cant use the normal health system since its one health for both players
	UPROPERTY(NotEditable)
	float Health = 12.f;

	UPROPERTY(NotEditable)
	float MaxHealth = 12.f;

	// Widget class for the health bar
	UPROPERTY(Category = "Widget")
	TSubclassOf<UWheelBoatHealthWidget> HealthWidgetClass;

	float MoveSpeedMultiplier = 1.f;
	float TurnSpeedMultiplier = 1.f;

	AWheelBoatActorWheelActor LeftWheelSubActor;
	AWheelBoatActorWheelActor RightWheelSubActor;

	float BoatZLocation;

	AHazeActor PendingImpactWithActor;
	float AngularAccelerationSettingsOverride = -1;
	FWheelBoatAvoidPositionData AvoidPoint;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt MovementPrompt;
    default MovementPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;
    default MovementPrompt.MaximumDuration = -1.f;

	UPROPERTY(Category = "Prompts")
	FText ShootTutorialText;

	UPROPERTY(Category = "Prompts")
	FTutorialPrompt ShootingPrompt;
	default ShootingPrompt.Action = ActionNames::PrimaryLevelAbility;
    default ShootingPrompt.DisplayType = ETutorialPromptDisplay::ActionHold;
    default ShootingPrompt.MaximumDuration = -1.f;
	default ShootingPrompt.Text = ShootTutorialText;

	UPROPERTY()
	bool bShowHealthWidget = false;

	UPROPERTY()
	bool bShowTutorials = false;

	bool bUsingBrokenMesh = false;
	bool bHasBlockedWheelBoatTag = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementComponent.Setup(CapsuleComponent);
		MovementComponent.UseCollisionSolver(n"CollisionSolver", n"CollisionSolver");

		RightWheelSplashEffect.SetNiagaraVariableFloat("User.SpawnRate", 0.0f);
		LeftWheelSplashEffect.SetNiagaraVariableFloat("User.SpawnRate", 0.0f);

		InitializeSubActor(LeftWheelSubActor, LeftCannon, EHazePlayer::May);
		InitializeSubActor(RightWheelSubActor, RightCannon, EHazePlayer::Cody);

		BaseAttachments.AttachToComponent(BoatMesh, n"Base");

		AddCapability(n"WheelBoatFinalizeMovementCapability");
		AddCapability(n"WheelBoatBossMovementCapability");
		AddCapability(n"WheelBoatBossThrownInAirCapability");
		AddCapability(n"WheelBoatSearchForClosestStreamCapability");
		AddCapability(n"WheelBoatHealthWidgetCapability");
		AddCapability(n"WheelBoatHandleBlocksCapability");
		AddCapability(n"WheelBoatCannonCapability");
		//AddCapability(n"WheelBoatHitReactionCapability");
		//AddCapability(n"WheelBoatHealthRegenCapability"); 
		AddCapability(n"FullscreenSharedHealthAudioCapability");

		UPlayerHealthComponent HealthComp1 = UPlayerHealthComponent::Get(Game::May);
		UPlayerHealthComponent HealthComp2 = UPlayerHealthComponent::Get(Game::Cody);
		// OnStartSpinning.AddUFunction(this, n"PlaySpinFeedback");

		StreamComponent.OnWheelBoatEnteredStream.AddUFunction(this, n"EnteredStream");
		//StreamComponent.OnWheelBoatExitedStream.AddUFunction(this, n"LeftStream");

		BoatZLocation = GetActorLocation().Z;

		// Disable the generate overlaps since we are moving the boat a lot
		RailCartRail.ConnectStart.bGenerateOverlapEvents = false;
		RailCartRail.ConnectEnd.bGenerateOverlapEvents = false;
	}
	
	void InitializeSubActor(AWheelBoatActorWheelActor& WheelSubActor, AToyCannonActor CanonSubActor, EHazePlayer PlayerType)
	{
		AHazePlayerCharacter ControllingPlayer = Game::GetPlayer(PlayerType);

		// Wheels
		FName ActorName = PlayerType == EHazePlayer::May ? n"LeftWheelActor" : n"RightWheelActor";
		WheelSubActor = Cast<AWheelBoatActorWheelActor>(SpawnActor(AWheelBoatActorWheelActor::StaticClass(), Name = ActorName, Level = GetLevel(), bDeferredSpawn = true));
		WheelSubActor.MakeNetworked(this, ActorName);
		
		WheelSubActor.SetControlSide(ControllingPlayer);
		FinishSpawningActor(WheelSubActor);

		WheelSubActor.AttachToActor(this);
		WheelSubActor.ParentBoat = this;
		WheelSubActor.SetOwner(WheelSubActor.ParentBoat);
		WheelSubActor.AddCapability(n"WheelBoatSubActorMovementCapability");
		WheelSubActor.AddCapability(n"WheelBoatSubActorStreamMovementCapability");
		WheelSubActor.AddCapability(n"WheelBoatSubActorBossMovementCapability");
		WheelSubActor.AddCapability(n"WheelBoatTurnWheelsCapability");
		WheelSubActor.MovementData.bIsLeftActor = PlayerType == EHazePlayer::May;

		// Cannons
		CanonSubActor.AttachToComponent(RotationBase, n"", EAttachmentRule::KeepWorld);
		CanonSubActor.ParentBoat = this;
		CanonSubActor.SetOwner(this);
		CanonSubActor.SetControlSide(ControllingPlayer);
		CanonSubActor.InitializeCanonBalls(this, ControllingPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		SetWheelBoatBlocked(false);

		if (LeftWheelSubActor != nullptr)
		{
			LeftWheelSubActor.DestroyActor();
			LeftWheelSubActor = nullptr;
		}

		if (RightWheelSubActor != nullptr)
		{
			RightWheelSubActor.DestroyActor();
			RightWheelSubActor = nullptr;
		}
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
	{
		if(!bUpdatedMovement && bLastUpdatedMovement)
		{
			StopMovement();

			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_AngularVelocity", 0.0f, 0.f);
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Yaw", 0.0f, 0.f);

			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Boat_VelocityDelta", 0.0f, 0.f);

			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Velocity", 0.0f, 0.f);
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Stream_Velocity", 0.0f, 0.f);
		}

	#if EDITOR		
		if(bHazeEditorOnlyDebugBool)
		{
			{
				FString LeftDebug = "";
				LeftDebug += "LeftInput: " + GetPlayerWheelBoatInput(Game::GetMay())  + "\n";
				FWheelBoatMovementData LeftMovementData = LeftWheelSubActor.MovementData;	
				LeftDebug += "LeftMovementData.WheelRange: " + LeftMovementData.WheelMovementRange + "\n";
				LeftDebug += "LeftMovementData.WheelDeltaVelocity: " + LeftMovementData.WheelMovementVelocity + "\n";	
				LeftDebug += "LeftMovementData.Input: " + LeftMovementData.WheelMovementVelocity + "\n";	
				PrintToScreen("LEFT\n" + LeftDebug, 0.f, FLinearColor::LucBlue);
			}
		
			{
				FString RightDebug = "";
				RightDebug += "RightInput: " + GetPlayerWheelBoatInput(Game::GetCody()) + "\n";
				FWheelBoatMovementData RightMovementData = RightWheelSubActor.MovementData;
				RightDebug += "RightMovementData.WheelRange: " + RightMovementData.WheelMovementRange + "\n";
				RightDebug += "RightMovementData.WheelDeltaVelocity: " + RightMovementData.WheelMovementVelocity + "\n";
				PrintToScreen("RIGHT\n" + RightDebug, 0.f, FLinearColor::Green);
			}
		}
	#endif

		bLastUpdatedMovement = bUpdatedMovement;
		bUpdatedMovement = false;
	}

	void SetWheelBoatBlocked(bool bStatus)
	{
		if(bHasBlockedWheelBoatTag == bStatus)
			return;

		bHasBlockedWheelBoatTag = bStatus;
		const FName Tag = n"WheelBoat";
		if(bStatus)
		{
			LeftCannon.BlockCapabilities(Tag, this);
			RightCannon.BlockCapabilities(Tag, this);

			LeftWheelSubActor.BlockCapabilities(Tag, this);
			ClearSubActorMovement(LeftWheelSubActor);
			LeftWheelSubActor.BlockMovementSyncronization(this);

			RightWheelSubActor.BlockCapabilities(Tag, this);
			ClearSubActorMovement(RightWheelSubActor);
			RightWheelSubActor.BlockMovementSyncronization(this);
			
			for(auto Player : Game::GetPlayers())
			{
				Player.BlockCapabilities(n"WheelBoatInput", this);
			}
	
			MovementComponent.StopMovement();
		}
		else
		{
			if(LeftCannon != nullptr)
				LeftCannon.UnblockCapabilities(Tag, this);

			if(RightCannon != nullptr)
				RightCannon.UnblockCapabilities(Tag, this);

			if(LeftWheelSubActor != nullptr)
			{
				LeftWheelSubActor.UnblockCapabilities(Tag, this);
				LeftWheelSubActor.UnblockMovementSyncronization(this);
			}
	
			if(RightWheelSubActor != nullptr)
			{
				RightWheelSubActor.UnblockCapabilities(Tag, this);
				RightWheelSubActor.UnblockMovementSyncronization(this);
			}

			for(auto Player : Game::GetPlayers())
			{
				Player.UnblockCapabilities(n"WheelBoatInput", this);
			}
		}
	}

	private void ClearSubActorMovement(AWheelBoatActorWheelActor SubActor)
	{
		FWheelBoatMovementData& MovementData = SubActor.MovementData;	
		MovementData.Finalize(0.f);
		MovementData.StopMovement();
		SubActor.CleanupCurrentMovementTrail();	
	}

	void GetInputValue(AHazePlayerCharacter ForPlayer, float& OutMovementInput, float& OutAnimationInput) const
	{
		const bool IsLeftPlayer = LeftWheelSubActor.Player == ForPlayer;
		
		FVector MyInput = IsLeftPlayer ? LeftWheelSubActor.MovementData.CurrentSteering : RightWheelSubActor.MovementData.CurrentSteering;
		FVector OtherInput = !IsLeftPlayer ? LeftWheelSubActor.MovementData.CurrentSteering : RightWheelSubActor.MovementData.CurrentSteering;
		
		// Normal steering
		if(!bUseSteeringInput)
		{
			OutMovementInput = MyInput.Y;
			OutAnimationInput = OutMovementInput;
			return;
		}
		
		const float MyInputSize = MyInput.Size();
		const float OtherInputSize = OtherInput.Size();
		const float BiggestRequiredInputSize = FMath::Max(MyInputSize, OtherInputSize) * 0.25f;
		const float DirectionMultipluer = !IsLeftPlayer ? -1.f : 1.f;

		// if(MyInputSize < BiggestRequiredInputSize)
		// {
		// 	OutMovementInput = OtherInput.Y * 0.1f * DirectionMultipluer;
		// 	OutAnimationInput = 0.f;

		// }
		// else if(OtherInputSize < BiggestRequiredInputSize)
		// {
		// 	OutMovementInput = MyInput.Y * 0.25f;
		// 	OutAnimationInput = OutMovementInput;
		// }
		if(MyInputSize < BiggestRequiredInputSize)
		{
			const float ForwardDot = OtherInput.GetSafeNormal().DotProduct(FVector(0.f, 1.f, 0.f));
			if(FMath::Abs(ForwardDot) >= 0.8f)
			{
				OutMovementInput = OtherInput.Y * 0.1f;
				OutAnimationInput = 0.f;
			}
			else
			{
				const float RightAmount = OtherInput.DotProduct(FVector(1.f, 0.f, 0.f));
				const float LeftRightAmount = (DirectionMultipluer * FMath::Sign(RightAmount)) * FMath::Lerp(0.f, 1.f, FMath::Clamp(FMath::Abs(RightAmount) / 0.8f, 0.f, 1.f));
				OutMovementInput = LeftRightAmount * 0.1f;
				OutAnimationInput = 0.f;
			}
		}
		else if(OtherInputSize < BiggestRequiredInputSize)
		{
			const float ForwardDot = MyInput.GetSafeNormal().DotProduct(FVector(0.f, 1.f, 0.f));
			if(FMath::Abs(ForwardDot) >= 0.8f)
			{
				OutMovementInput = MyInput.Y * 0.25f;
				OutAnimationInput = OutMovementInput;
			}
			else	
			{
				const float RightAmount = MyInput.DotProduct(FVector(1.f, 0.f, 0.f));
				const float LeftRightAmount = (DirectionMultipluer * FMath::Sign(RightAmount)) * FMath::Lerp(0.f, 1.f, FMath::Clamp(FMath::Abs(RightAmount) / 0.8f, 0.f, 1.f));
				OutMovementInput = LeftRightAmount * 0.1f;
				OutMovementInput += MyInput.DotProduct(FVector(0.f, 1.f, 0.f)) * 0.1f;
				OutAnimationInput = OutMovementInput;
			}
		}
		else
		{
			float InputMultiplier = (MyInputSize + OtherInputSize) * 0.5f;
			FVector TotalInput;
			TotalInput.X = FMath::Lerp(MyInput.X, OtherInput.X, 0.5f);
			TotalInput.Y = FMath::Lerp(MyInput.Y, OtherInput.Y, 0.5f);

			const float ForwardDot = TotalInput.GetSafeNormal().DotProduct(FVector(0.f, 1.f, 0.f));

			if(FMath::Sign(MyInput.X) != FMath::Sign(OtherInput.X) && FMath::Abs(TotalInput.Y) < 0.25f)
			{
				OutMovementInput = MyInput.Y;
				OutAnimationInput = OutMovementInput;
			}	
			else if(FMath::Abs(ForwardDot) >= 0.8f)
			{
				const float ForwardAmount = TotalInput.DotProduct(FVector(0.f, 1.f, 0.f));
				OutMovementInput = ForwardAmount * InputMultiplier;
				OutAnimationInput = MyInput.GetSafeNormal().DotProduct(TotalInput.GetSafeNormal()) * OutMovementInput;
			}
			else if(FMath::Sign(MyInput.Y) != FMath::Sign(OtherInput.Y) && FMath::Abs(TotalInput.X) < 0.25f)
			{
				OutMovementInput = MyInput.Y;
				OutAnimationInput = OutMovementInput;
			}
			else
			{
				const float RightAmount = TotalInput.DotProduct(FVector(1.f, 0.f, 0.f));
				const float LeftRightAmount = (DirectionMultipluer * FMath::Sign(RightAmount)) * FMath::Lerp(0.f, 1.f, FMath::Clamp(FMath::Abs(RightAmount) / 0.8f, 0.f, 1.f));
				OutMovementInput = LeftRightAmount * InputMultiplier;
				OutAnimationInput = MyInput.GetSafeNormal().DotProduct(TotalInput.GetSafeNormal()) * OutMovementInput;
			}
		}
	}

	UFUNCTION(BlueprintPure)
	float GetLeftWheelAnimationRange() const
	{
		return LeftWheelSubActor.MovementData.WheelBoatWheelAnimationRange;	
	}

	UFUNCTION(BlueprintPure)
	float GetRightWheelAnimationRange() const
	{
		return RightWheelSubActor.MovementData.WheelBoatWheelAnimationRange;	
	}

	UFUNCTION(BlueprintCallable)
	void OffsetForSequence()
	{
		MeshOffsetComponent.FreezeAndResetWithTime(3.f);
	}

	void FinalizeMovement(float DeltaTime)
	{
		FWheelBoatMovementData& LeftMovementData = LeftWheelSubActor.MovementData;
		FWheelBoatMovementData& RightMovementData = RightWheelSubActor.MovementData;
		float DeltaVelocity = FMath::Max(FMath::Abs(LeftMovementData.WheelMovementVelocity), FMath::Abs(RightMovementData.WheelMovementVelocity));

		if(LeftMovementData.HasUpdatedMovemend())
		{
			bUpdatedMovement = true;
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_LeftWheel_VelocityDelta", LeftMovementData.WheelMovementVelocity, 0.f);
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_LeftWheel_Velocity", LeftMovementData.WheelBoatWheelAnimationRange, 0.f);
		}
		else
		{
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_LeftWheel_VelocityDelta", 0.0f, 0.f);
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_LeftWheel_Velocity", 0.0f, 0.f);
		}
		LeftMovementData.EndOfFrame(DeltaTime);

		if(RightMovementData.HasUpdatedMovemend())
		{
			bUpdatedMovement = true;
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_RightWheel_VelocityDelta", RightMovementData.WheelMovementVelocity, 0.f);
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_RightWheel_Velocity", RightMovementData.WheelBoatWheelAnimationRange, 0.f);
		}
		else
		{
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_RightWheel_VelocityDelta", 0.0f, 0.f);
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_RightWheel_Velocity", 0.0f, 0.f);
		}
		RightMovementData.EndOfFrame(DeltaTime);

		if(bUpdatedMovement)
		{	
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_AngularVelocity", FMath::Abs((-RightMovementData.WheelBoatWheelAnimationRange + LeftMovementData.WheelBoatWheelAnimationRange)/2), 0.f);
			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Yaw", ActorRotation.Yaw, 0.f);

			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Boat_VelocityDelta", DeltaVelocity, 0.f);

			float WheelBoatVelocity = HazeAudio::NormalizeRTPC01(MovementComponent.Velocity.Size(), 0.f, 350.f);

			AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Velocity", WheelBoatVelocity, 0.f);

			if(IsInStream() && !IsInBossFight())
			{
				float MaxVelocity = (StreamComponent.StreamMovementForce + BoatSettings.AccelerationSpeed * 2) / BoatSettings.ForwardDrag;
				AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Stream_Velocity", MovementComponent.Velocity.Size()/MaxVelocity, 0.f);
			}
		}	
	}

	bool IsInStream()const
	{
		if(!bStreamActive)
			return false;

		if(StreamComponent == nullptr)
			return false;

		if(StreamComponent.LockedStream == nullptr)
			return false;

		if(StreamComponent.LockedStream.Spline == nullptr)
			return false;

		return true;
	}

	bool IsInBossFight()const
	{
		if(!bBossFightActive)
			return false;

		if(OctopusBoss == nullptr)
			return false;

		return true;
	}

	bool UseBossFightMovement()const
	{
		if(!IsInBossFight())
			return false;

		if(BossFightIndex == 3)
			return false;

		return true;
	}

	bool BossIsPreparingNextAttackSequence()const
	{
		if(!IsInBossFight())
			return false;

		return bBossIsPreparingNextAttackSequence;
	}

	bool IsAvoidingPoint()const
	{
		return AvoidPoint.IsValid();
	}

	void TriggerImpact(float ImpactMultiplier)
	{
		OnImpact.Broadcast();

		if(PlayerWithFullscreen != nullptr)
		{
			CurrentActiveShake = PlayerWithFullscreen.PlayCameraShake(ImpactCameraShake, ImpactMultiplier);
		}

		if(ImpactForceFeedback != nullptr)
		{		
			if(PlayerInLeftWheel != nullptr)
				PlayerInLeftWheel.PlayForceFeedback(HitForceFeedback, false, true, n"ShipCollisionLeft", ImpactMultiplier);

			if(PlayerInRightWheel != nullptr)
				PlayerInRightWheel.PlayForceFeedback(HitForceFeedback, false, true, n"ShipCollisionRight", ImpactMultiplier);
		}

		if(WheelBoatCollisionImpactEvent != nullptr)
			AkComponent.HazePostEvent(WheelBoatCollisionImpactEvent);


		if(Time::GetGameTimeSince(TimeStampCollisionBark) > CollisionBarkCooldown)
		{
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayRoomGoldbergBoatCollisionGeneric");
			TimeStampCollisionBark = Time::GetGameTimeSeconds();
		}
	}

	void StopMovement()
	{
		MovementComponent.StopMovement();
		LeftWheelSubActor.MovementData.StopMovement();
		RightWheelSubActor.MovementData.StopMovement();
		bReactingToImpact = false;
		ImpactCount += 100;
	}

	UFUNCTION(BlueprintCallable)
	void StartSpinning(bool SpinToLeft, float SpinForce, float SpinAmount)
	{
		if(bDead)
			return;

		if(SpinToLeft)
			SpinDirection = 1;
		else
			SpinDirection = -1;
		
		CurrentSpinForce = SpinForce * SpinDirection;
		TotalAmountToSpin = SpinAmount;

		if(WheelBoatSpinningStart != nullptr)
			AkComponent.HazePostEvent(WheelBoatSpinningStart);

		OnBoatJabbedEvent.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void StopSpinning()
	{
		bSpinning = false;
		CurrentSpinForce = 0;
		TotalAmountToSpin = 0;

		// OnStopSpinning.Broadcast();

		if(WheelBoatSpinningStop != nullptr)
			AkComponent.HazePostEvent(WheelBoatSpinningStop);
		// Print("Stopped Spinning Boat", 1.0f);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnteredStream()
	{
		bStreamActive = true;
		if(WheelBoatStreamStartEvent != nullptr && !AkComponent.EventInstanceIsPlaying(BoatStreamAudioEventInstance))
		{
			BoatStreamAudioEventInstance = AkComponent.HazePostEvent(WheelBoatStreamStartEvent);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void LeftStream()
	{
		bStreamActive = false;
		if(WheelBoatStreamStopEvent != nullptr)
		{
			AkComponent.HazePostEvent(WheelBoatStreamStopEvent);
		}

		AkComponent.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Stream_Velocity", 0.0f, 0.f);
	}

	float GetStreamDetectDistance()const
	{
		return 0.f;
	}

	UFUNCTION()
	void AttachMayToLeftWheel()
	{
		auto Player = Game::GetMay();
		PlayerInLeftWheel = Player;
		InitPlayerOnWheelBoat(Player, LeftWheelPlayerAttachPoint, LeftWheelSubActor, LeftCannon);
		SetFullScreenIfBothPlayersAreInBoat(Player); 
		Player.DisableOutlineByInstigator(this);

		if(WheelBoatLeftWheelStartEvent != nullptr && !AkComponent.EventInstanceIsPlaying(LeftWheelEventInstance))
		{
			LeftWheelEventInstance = AkComponent.HazePostEvent(WheelBoatLeftWheelStartEvent);
		}

		if(PlayerInRightWheel == nullptr)
		{
			if(WheelBoatMovingStartEvent != nullptr && !AkComponent.EventInstanceIsPlaying(RightWheelEventInstance))
			{
				RightWheelEventInstance = AkComponent.HazePostEvent(WheelBoatMovingStartEvent);
			}
		}

		if(Player.HasControl())
			NetTellPlayerIsReady();
	}

	UFUNCTION()
	void AttachCodyToRightWHeel()
	{	
		auto Player = Game::GetCody();
		PlayerInRightWheel = Player;
		InitPlayerOnWheelBoat(Player, RightWheelPlayerAttachPoint, RightWheelSubActor, RightCannon);
		SetFullScreenIfBothPlayersAreInBoat(Player); 
		Player.DisableOutlineByInstigator(this);

		if(WheelBoatRightWheelStartEvent != nullptr)
		{
			AkComponent.HazePostEvent(WheelBoatRightWheelStartEvent);
		}

		if(PlayerInLeftWheel == nullptr)
		{
			if(WheelBoatMovingStartEvent != nullptr)
			{
				AkComponent.HazePostEvent(WheelBoatMovingStartEvent);
			}
		}	

		if(Player.HasControl())
			NetTellPlayerIsReady();
	}

	UFUNCTION(NetFunction)
	void NetTellPlayerIsReady()
	{
		PlayerReadyCount++;
	}

	bool BothPlayersAreReady()const
	{
		return PlayerReadyCount >= 2;
	}

	private void InitPlayerOnWheelBoat(AHazePlayerCharacter Player, USceneComponent WheelAttachPoint, AWheelBoatActorWheelActor WheelSubActor, AToyCannonActor CanonSubActor)
	{
		ShouldChangePlayerCamera.Broadcast(Player, true); 

		Player.AddCapabilitySheet(WheelBoatSheet, EHazeCapabilitySheetPriority::High, this);
		auto Comp = UOnWheelBoatComponent::Get(Player);
		Comp.WheelBoat = this;

		WheelSubActor.Player = Player; 
		CanonSubActor.Player = Player; 

		if(!bActivatedFromCheckpoint)
		{
			// Smooth lerp to the attachlocation
			//Player.MeshOffsetComponent.FreezeAndResetWithTime(0.3f);
		}

		Player.TriggerMovementTransition(this, n"AttachToWheelBoat");
		Player.AttachToComponent(WheelAttachPoint, NAME_None, EAttachmentRule::SnapToTarget);
	}

	
	void SetFullScreenIfBothPlayersAreInBoat(AHazePlayerCharacter LastEnteredPlayer)
	{
		if(PlayerInRightWheel != nullptr && PlayerInLeftWheel != nullptr)
		{
			LastEnteredPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
			PlayerWithFullscreen = LastEnteredPlayer;
			BothPlayersAreInTheBoat.Broadcast();
		}	
	}

	UFUNCTION()
	void StartingFromCheckpoint()
	{
		bActivatedFromCheckpoint = true;

		// Cody
		if(PlayerInRightWheel == nullptr || RightWheelSubActor.Player != PlayerInRightWheel)
		{
			AttachCodyToRightWHeel();			
		}

		// May
		if(PlayerInLeftWheel == nullptr|| RightWheelSubActor.Player != PlayerInRightWheel)
		{
			AttachMayToLeftWheel();
		}

		bActivatedFromCheckpoint = false;
	}

	UFUNCTION()
	void ReleasePlayer(AHazePlayerCharacter Player)
	{
		if(Player == PlayerInLeftWheel)
		{
			PlayerInLeftWheel = nullptr;
			RemoveOnWheelBoat(Player, LeftWheelSubActor, LeftCannon);

			if(WheelBoatLeftWheelStopEvent != nullptr)
			{
				AkComponent.HazePostEvent(WheelBoatLeftWheelStopEvent);
			}	
		}
		else if(Player == PlayerInRightWheel)
		{
			PlayerInRightWheel = nullptr;
			RemoveOnWheelBoat(Player, RightWheelSubActor, RightCannon);

			if(WheelBoatRightWheelStopEvent != nullptr)
			{
				AkComponent.HazePostEvent(WheelBoatRightWheelStopEvent);
			}	
		}

		Player.EnableOutlineByInstigator(this);
	}

	private void RemoveOnWheelBoat(AHazePlayerCharacter Player, AWheelBoatActorWheelActor WheelActor, AToyCannonActor CanonActor)
	{	
		ShouldChangePlayerCamera.Broadcast(Player, false);
		Player.RemoveCapabilitySheet(WheelBoatSheet, this);
		if(PlayerWithFullscreen == Player)
			Player.ClearViewSizeOverride(this);

		if (WheelActor != nullptr)
			WheelActor.Player = nullptr;
		if (CanonActor != nullptr)
			CanonActor.Player = nullptr;

		if(Player.AttachParentActor == this)
			Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		auto Comp = UOnWheelBoatComponent::Get(Player);
		if(Comp != nullptr)
		{
			Comp.WheelBoat = nullptr;
			Comp.CannonInput = false;
			//Comp.PlayerWheelInput = 0.0f;
		}
	}

	bool CheckIfPlayerIsOnBoat(AHazePlayerCharacter Player)
	{
		if(Player != nullptr)
		{
			if(Player == PlayerInRightWheel || Player == PlayerInLeftWheel)
			{
				return true;
			}
			else
				return false;
		}
		else
		{
			return false;
		}
	}

	UFUNCTION()
	void DockWheelBoat(FVector DockPosition, FRotator DockRotation)
	{
		CapsuleComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		TeleportBoat(DockPosition, DockRotation);
	
		auto Connector = URailCartRailForcedConnector::Get(RailCartRail);
		Connector.EstablishConnection();
	
		bDocked = true;

		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(auto Player : Players)
			ReleasePlayer(Player);

		StopMovement();
		if(WheelBoatMovingStopEvent != nullptr)
		{
			AkComponent.HazePostEvent(WheelBoatMovingStopEvent);
		}	
	}

	void StartBossFight(APirateOceanStreamActor BossStream, AHazeActor BossActor, float OffsetAmount)
	{
		BossFightIndex = 1;
		OctopusBoss = BossActor;
		StreamComponent.SetStreamSpline(BossStream);
		bBossFightActive = true;
		CapsuleComponent.CollisionEnabled = ECollisionEnabled::QueryOnly;
		SetPlayerInBossFight(PlayerInRightWheel, true);
		SetPlayerInBossFight(PlayerInLeftWheel, true);
		// FRotator TeleportationRotation = (OctopusBoss.GetActorLocation() - GetActorLocation()).Rotation();
		FRotator TeleportationRotation = StreamComponent.LockedStream.Spline.GetRotationAtDistanceAlongSpline(0, ESplineCoordinateSpace::World);
		FVector TeleportLocation = StreamComponent.LockedStream.Spline.GetLocationAtDistanceAlongSpline(0, ESplineCoordinateSpace::World);
		TeleportLocation.Z += OffsetAmount;
		TeleportBoat(TeleportLocation, TeleportationRotation);
		StreamComponent.ActivateSplineMovement(BossStream.Spline);
		Health = MaxHealth;
		OnBossFightStart.Broadcast();
	}

	// bool CheckIfIsInBossFight(AHazePlayerCharacter Player)
	// {
	// 	auto Comp = UOnWheelBoatComponent::Get(Player);
	// 	return Comp.bInBossFight;
	// }

	void StartBossFightSecondPart(AActor NewBoatPosition)
	{
		devEnsure(OctopusBoss != nullptr);

		CapsuleComponent.CollisionEnabled = ECollisionEnabled::QueryOnly;
		if(NewBoatPosition != nullptr)
		{
			BossFightIndex = 2;
			StreamComponent.SetStreamSpline(nullptr);
			StreamComponent.DeactivateSplineMovement();

			FRotator TeleportationRotation = NewBoatPosition.ActorRotation;
			FVector TeleportLocation = NewBoatPosition.ActorLocation;
			TeleportBoat(TeleportLocation, TeleportationRotation);
			OnBossFightSecondPartStart.Broadcast();
		}
	}

	void StartBossFightThirdPart(FVector TeleportLocation)
	{
		devEnsure(OctopusBoss != nullptr);

		PlayerWithFullscreen.ApplyCameraSettings(ThirdPhaseCameraSettings, 2.0f, this, EHazeCameraPriority::High);

		FHitResult SweepHitResult;
		BoatCamera.SetActorRelativeRotation(FRotator(-45.f, 0.f, 0.f), false, SweepHitResult, false);
		
		BossFightIndex = 3;
		CapsuleComponent.CollisionEnabled = ECollisionEnabled::QueryOnly;
		StreamComponent.SetStreamSpline(nullptr);
		FRotator TeleportationRotation;
		TeleportationRotation.Yaw = (OctopusBoss.GetActorLocation() - GetActorLocation()).Rotation().Yaw;
		TeleportBoat(TeleportLocation, TeleportationRotation);
		OnBossFightThirdPartStart.Broadcast();
	}

	void ResetAfterBoss()
	{
		PlayerWithFullscreen.ClearCameraSettingsByInstigator(this);
		CapsuleComponent.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
		BossFightIndex = 0;
		bBossFightActive = false;
		StreamComponent.SetStreamSpline(nullptr);	
		SetPlayerInBossFight(PlayerInRightWheel, false);
		SetPlayerInBossFight(PlayerInLeftWheel, false);
		OnBossFightStop.Broadcast();
	}

	private void SetPlayerInBossFight(AHazePlayerCharacter Player, bool IsInBossFight)
	{
		auto Comp = UOnWheelBoatComponent::Get(Player);
		Comp.bInBossFight = IsInBossFight;	
	}

	UFUNCTION(BlueprintCallable)
	void BoatWasHit(float Amount, EWheelBoatHitType HitType)
	{
		if(bDead)
			return;

		if(bIsAirborne)
			return;
			
		GiveDamageFeedback();

		float FinalDamageAmount = Amount;

		if(!CanPlayerBeDamaged(PlayerInLeftWheel) || !CanPlayerBeDamaged(PlayerInRightWheel))
			FinalDamageAmount = 0;

		Health -= FinalDamageAmount;
		OnTakeDamage.Broadcast(FinalDamageAmount);

		if(Health <= (MaxHealth * 0.25f) && !bUsingBrokenMesh)
		{
			BoatMesh.SetSkeletalMesh(BrokenMesh);
			bUsingBrokenMesh = true;
		}

		//Activate ReactionCapability
		FHazeAnimationDelegate OnBlendIn;
		FHazeAnimationDelegate OnBlendOut;

		if (HitType == EWheelBoatHitType::CannonBall)
			BoatMesh.SetAnimBoolParam(n"bBoatWasHitByCannonBall", true);
		else if (HitType == EWheelBoatHitType::TentacleSlam) 
		{
			//Print("BOAT SLAMMED");
			BoatMesh.SetAnimBoolParam(n"bBoatWasSlammed", true);
			OnHitByTentacleSlam.Broadcast();
			PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayRoomGoldbergBossFightTentacleHitReaction");
		}

		UAkAudioEvent HitTypeEvent;

		switch(HitType)
		{
			case(EWheelBoatHitType::TentacleSlam):
				HitTypeEvent = WheelBoatTentacleHitEvent;
				break;
			default:
				break;
		}
		
		if(WheelBoatDamageTakenEvent != nullptr)
		{
			AkComponent.HazePostEvent(WheelBoatDamageTakenEvent);
			if(HitTypeEvent != nullptr)
				AkComponent.HazePostEvent(HitTypeEvent);
		}

		if (HasControl() && Health <= 0.f)
		{
			NetDie();
		}
	}

	UFUNCTION()
	void BoatEmerge()
	{
		BoatMesh.SetAnimBoolParam(n"bBoatisEmerging", true);
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	void NetDie()
	{
		Health = 0.f;

		if(!bIsDying)
		{
			bIsDying = true;

			// // We add a small delay so you have time to react to that you died
			// System::SetTimer(this, n"BroadcastDeath", 1.0f, false);
			
			// Testing no delay with new death anims
			BroadcastDeath();
		}

	}

	UFUNCTION(NotBlueprintCallable)
	void BroadcastDeath()
	{
		bIsDying = false;
		BoatMesh.SetAnimBoolParam(n"bBoatisDying", true);
		OnDeath.Broadcast();
		bDead = true;
	}

	void GiveDamageFeedback()
	{
		FlashActor(this, DamageFlashDuration, DamageFlashColor);

		if(PlayerInLeftWheel != nullptr)
		{
			if(IsInBossFight())
				CurrentActiveShake = PlayerInLeftWheel.PlayCameraShake(BossHitCameraShake);
			else
				CurrentActiveShake = PlayerInLeftWheel.PlayCameraShake(HitCameraShake);

			PlayerInLeftWheel.PlayForceFeedback(HitForceFeedback, false, true, n"ShipWasHit");
		}
		if(PlayerInRightWheel != nullptr)
		{
			if(IsInBossFight())
				CurrentActiveShake = PlayerInRightWheel.PlayCameraShake(BossHitCameraShake);
			else			
				CurrentActiveShake = PlayerInRightWheel.PlayCameraShake(HitCameraShake);

			PlayerInRightWheel.PlayForceFeedback(HitForceFeedback, false, true, n"ShipWasHit");
		}
	}

	UFUNCTION()
	void PlaySpinFeedback()
	{
		if(PlayerInLeftWheel != nullptr)
		{
			CurrentActiveShake = PlayerInLeftWheel.PlayCameraShake(SpinCameraShake);
		}
		if(PlayerInRightWheel != nullptr)
		{
			CurrentActiveShake = PlayerInRightWheel.PlayCameraShake(SpinCameraShake);
		}
	}

	UFUNCTION()
	void RestoreHealth()
	{
		Health = MaxHealth;
		bIsDying = false;

		if(Health >= (MaxHealth * 0.25f) && bUsingBrokenMesh)
		{
			BoatMesh.SetSkeletalMesh(WholeMesh);
			bUsingBrokenMesh = false;
		}
	}

	UFUNCTION()
	void AddHealth(float Amount)
	{
		Health += Amount;

		if (Health > MaxHealth)
			Health = MaxHealth;

		if(Health >= (MaxHealth * 0.25f) && bUsingBrokenMesh)
		{
			BoatMesh.SetSkeletalMesh(WholeMesh);
			bUsingBrokenMesh = false;
		}
	}

	void TeleportBoat(FVector Location, FRotator Rotation)
	{
		StopMovement();
		TArray<AHazeActor> SubActors;
		SubActors.Add(LeftWheelSubActor);
		SubActors.Add(RightWheelSubActor);
		TeleportActorAndSubActors(SubActors, Location, Rotation);
		RotationBase.SetRelativeRotation(FRotator::ZeroRotator);
		BoatZLocation = ActorLocation.Z;
	}

	float GetAngularAcceleration()
	{
		if(AngularAccelerationSettingsOverride >= 0)
			return AngularAccelerationSettingsOverride;

		return BoatSettings.AngularAcceleration;
	}

	void SetPlayerDirectionInput(AHazePlayerCharacter Player, FVector Input)
	{
		// We send the input through the wheel actors channel
		if(Player == PlayerInLeftWheel)
			LeftWheelSubActor.NetReplicateDirectionInput(Input);
		else if(Player == PlayerInRightWheel)
			RightWheelSubActor.NetReplicateDirectionInput(Input);
	}

	void SetBothPlayerDirection(AHazePlayerCharacter Player, FVector Input)
	{
		if(Player == PlayerInLeftWheel)
			LeftWheelSubActor.NetReplicateBothDirectionInput(Input);
		else if(Player == PlayerInRightWheel)
			RightWheelSubActor.NetReplicateBothDirectionInput(Input);
	}

	void SetFireInput(AHazePlayerCharacter Player, bool bInput)
	{
		if(Player == PlayerInLeftWheel)
			NetSetLeftFireInputEnable(bInput ? 1 : 0);
		else if(Player == PlayerInRightWheel)
			NetSetRightFireInputEnable(bInput ? 1 : 0);
	}
	
	UFUNCTION(NetFunction)
	void NetSetLeftFireInputEnable(int EnableValue)
	{
		if(LeftCannon.HasControl())
		{
			LeftCannon.bRequestedInput = EnableValue == 1 ? true : false;
		}
	}

	UFUNCTION(NetFunction)
	void NetSetRightFireInputEnable(int EnableValue)
	{
		if(RightCannon.HasControl())
		{
			RightCannon.bRequestedInput = EnableValue == 1 ? true : false;
		}
	}

	UFUNCTION()
	void ActivatePointOfInterest(FVector Location, float Time)
	{
		PointOfInterestLoc = Location;
		OnSetPOIEvent.Broadcast(Time);
	}

	void GetOverlapShapes(TArray<FHazeShapeSettings>& OutShapes)
	{
		
	}

	UFUNCTION()
	void ActivateTutorials()
	{
		bShowTutorials = true;
	}

	UFUNCTION(BlueprintCallable)
	void StopBoatAudio()
	{
		AkComponent.HazeStopEvent();
	}
}
