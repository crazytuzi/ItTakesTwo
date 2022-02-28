import Peanuts.Spline.SplineActor;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.LevelActors.MoleTunnel.ChasingMoleFeature;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Vino.PlayerHealth.PlayerDeathEffect;
import Vino.BouncePad.CharacterBouncePadCapability;
import Cake.LevelSpecific.Garden.LevelActors.MoleTunnel.ChasingMoleBounceComponent;

event void FOnBounceOnMoleStuck(AHazePlayerCharacter Player);
event void FOnMoleReachedEndOfSpline();
event void FOnPlaySpecialClashRightMoleVO(AHazePlayerCharacter Player);

UCLASS(Abstract)
class AChasingMole : AHazeCharacter
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent DeathTriggerHeadNew;
	default DeathTriggerHeadNew.CapsuleRadius = 206.5f;
	default DeathTriggerHeadNew.CapsuleHalfHeight = 412.5f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeLazyPlayerOverlapComponent DeathTrigger;
	default DeathTrigger.Shape.InitializeAsBox(FVector(32,500,400));
	default DeathTrigger.ResponsiveDistanceThreshold = 2000;
	UPROPERTY(DefaultComponent)
	UHazeLazyPlayerOverlapComponent DeathTriggerBody;
	default DeathTriggerBody.Shape.InitializeAsCapsule(300, 616);
	default DeathTriggerBody.ResponsiveDistanceThreshold = 2000;
	UPROPERTY(DefaultComponent)
	UHazeLazyPlayerOverlapComponent DeathTriggerLeftHand;
	default DeathTriggerLeftHand.Shape.InitializeAsSphere(30.0f);
	default DeathTriggerLeftHand.ResponsiveDistanceThreshold = 2000;
	UPROPERTY(DefaultComponent)
	UHazeLazyPlayerOverlapComponent DeathTriggerRightHand;
	default DeathTriggerRightHand.Shape.InitializeAsSphere(30.0f);
	default DeathTriggerRightHand.ResponsiveDistanceThreshold = 2000;

	UPROPERTY(DefaultComponent)
	UHazeLazyPlayerOverlapComponent SpecialRightSideMoleVOTriggerBox;
	default DeathTriggerRightHand.Shape.InitializeAsBox(FVector(20,20,20));
	default DeathTriggerRightHand.ResponsiveDistanceThreshold = 1000;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDeathEffect> DeathEffect;
	UPROPERTY(DefaultComponent)
	UCapsuleComponent GroundPoundCapsule;
	UPROPERTY(DefaultComponent)
	USceneComponent DeathPosition;
	

	UPROPERTY()
	ASplineActor SplineToFollow;
	UPROPERTY()
	ASplineActor SecondSplineToFollow;
	UPROPERTY()
	ASplineActor ThirdSplineToFollow;
	UPROPERTY()
	UHazeLocomotionStateMachineAsset MoleStateMachine;
	UPROPERTY()
	UChasingMoleFeature MoleFeature;
	UPROPERTY()
    FOnMoleReachedEndOfSpline OnMoleReachedEndOfSpline;
	UPROPERTY()
    FOnPlaySpecialClashRightMoleVO OnPlaySpecialClashRightMoleVO;

	UPROPERTY()
	UAnimSequence StartStopLedge;
	UPROPERTY()
	UAnimSequence MhStopLedge;
	UPROPERTY()
	UAnimSequence StartCrash;
	UPROPERTY()
	UAnimSequence EndingCrashLeft;
	UPROPERTY()
	UAnimSequence EndingCrashRight;
	UPROPERTY()
	UAnimSequence MhCrash;
	UPROPERTY()
	UAnimSequence StartClimb;
	UPROPERTY()
	UAnimSequence StartStepOnMole;

	UPROPERTY()
	float DesiredFollowSpeed = 850.f;
	UPROPERTY()
	float CurrentFollowSpeed;
	UPROPERTY()
	float LerpSpeed = 3.f;
	UPROPERTY()
	bool bFollowingSpline = false;
	float DistanceAlongSpline = 0.f;
	UPROPERTY()
	bool bPlayEnterAnimationWhenStartFollowSpline = false;
	UPROPERTY()
	float BaseSpeed;
	UPROPERTY()
	bool CanKillPlayers = true;
	UPROPERTY()
	bool bChasing = false;
	UPROPERTY()
	bool IsAtEnd = false;
	UPROPERTY()
	bool IsBouncyMole = false;
	UPROPERTY()
	bool bStuckFallingDown = false;
	UPROPERTY()
	float RunningSpeed = 0;
	UPROPERTY()
	bool bIsClimbing = false;
	UPROPERTY()
	bool bMolesIsInCrystalField = false;
	bool bIsMainMole = false;
	UPROPERTY()
	float AnimationMultiplier = 1;

	bool bSpecialRightMoleClashVoPlayed = false;

	UPROPERTY()
	EAtEndOfSplineOptions AtEndOfSplineOptions = EAtEndOfSplineOptions::DisableActor;

	// Audio
	UPROPERTY(DefaultComponent, NotEditable)
    UHazeAkComponent HazeAkComponent;

	UPROPERTY()
	float DeathRadius = 400.f;
	

	//---------------BouncePad-------------
    UPROPERTY()
    FOnBounceOnMoleStuck OnBounceOnMole;

	UHazeCapabilitySheet CurrentBounceSheet;
	//-------------------------------------
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathTriggerHeadNew.OnComponentBeginOverlap.AddUFunction(this, n"EnterDeathTriggerHead");
		DeathTrigger.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
		DeathTriggerBody.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
		DeathTriggerLeftHand.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
		DeathTriggerRightHand.OnPlayerBeginOverlap.AddUFunction(this, n"EnterDeathTrigger");
		SpecialRightSideMoleVOTriggerBox.OnPlayerBeginOverlap.AddUFunction(this, n"EnterSpecialRightClashMoleVOTrigger");

		DeathTriggerBody.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Spine1"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		DeathTriggerHeadNew.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Head"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		DeathTriggerLeftHand.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"LeftHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		DeathTriggerLeftHand.AddLocalOffset(FVector(100, 0, 0));
		DeathTriggerRightHand.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightHand"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		DeathTriggerRightHand.AddLocalOffset(FVector(100, 0, 0));
		
		BaseSpeed = DesiredFollowSpeed;
		DeathPosition.AttachToComponent(Mesh, n"Spine1", EAttachmentRule::KeepRelative);
		//GroundPoundMesh.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Belly"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		GroundPoundCapsule.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Align"), EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
	}

	//Networked PlayerTrigger & ActorTriggers with (Path Determined by Control)
	UFUNCTION()
	void StartFollowingSpline()
	{
		if (SplineToFollow != nullptr)
		{
			bFollowingSpline = true;
			if(bPlayEnterAnimationWhenStartFollowSpline == true)
				PlayMoleEmergeAnimation();
		}
	}
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bFollowingSpline)
		{
			CurrentFollowSpeed = FMath::FInterpTo(CurrentFollowSpeed, DesiredFollowSpeed, DeltaTime, LerpSpeed);

			DistanceAlongSpline += CurrentFollowSpeed * DeltaTime;
			FVector Loc = SplineToFollow.Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			FRotator Rot = SplineToFollow.Spline.GetRotationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
			SetActorLocationAndRotation(Loc, Rot);
			RunningSpeed = CurrentFollowSpeed/2000 * AnimationMultiplier;
			//PrintToScreen("AnimationMultiplier " + AnimationMultiplier);

			if(DistanceAlongSpline >= SplineToFollow.Spline.GetSplineLength())
			{
				bFollowingSpline = false;
				OnMoleReachedEndOfSpline.Broadcast();

				if(AtEndOfSplineOptions == EAtEndOfSplineOptions::DisableActor)
				{
					DisableActor(nullptr);
				}
				else if(AtEndOfSplineOptions == EAtEndOfSplineOptions::Crash)
				{
					PlayMoleCrashAnimation();
				}
				else if(AtEndOfSplineOptions == EAtEndOfSplineOptions::LedgeStop)
				{
					PlayMoleStopLedgeAnimation();
				}
				else if(AtEndOfSplineOptions == EAtEndOfSplineOptions::Climb)
				{
					PlayMoleClimbAnimation();
				}
				else if(AtEndOfSplineOptions == EAtEndOfSplineOptions::EndingCrashLeft)
				{
					PlayEndingCrashLeft();
				}
				else if(AtEndOfSplineOptions == EAtEndOfSplineOptions::StepOnMole)
				{
					PlayMoleSteopOnMoleAnimation();
				}
			}
		}

		if(CurrentBounceSheet != nullptr)
		{
			auto BounceComp = UChasingMoleBounceComponent::Get(this);
			if(BounceComp.IsFinished())
			{
				BounceComp.Reset();
				RemoveCapabilitySheet(CurrentBounceSheet);
				CurrentBounceSheet = nullptr;
			}
		}
	}

	// Called from the manager on all the active moles
	void UpdateDeathTriggers(TArray<AHazePlayerCharacter> Players)
	{
		if(CanKillPlayers)
		{
			for(auto Player : Players)
			{
				if(!Player.HasControl())
					continue;

				FVector DeltaToPlayer = Player.GetActorLocation() - DeathPosition.GetWorldLocation();
				float DistSq = DeltaToPlayer.SizeSquared();
				if(DistSq < FMath::Square(DeathRadius))
				{
					Player.KillPlayer(DeathEffect);
				}
				else
				{
					FVector DirToPlayer = DeltaToPlayer.GetSafeNormal();
					float Angle = DeathPosition.GetWorldRotation().Vector().DotProduct(DirToPlayer);
					if(Angle < -0.5f)
						Player.KillPlayer(DeathEffect);
				}		
			}
		}
	}

	void DrawDebug()
	{
		if(CanKillPlayers)
		{
			System::DrawDebugArrow(DeathPosition.GetWorldLocation(), DeathPosition.GetWorldLocation() + (DeathPosition.GetWorldRotation().Vector() * 1000.f), 250, Thickness = 30);
			System::DrawDebugSphere(DeathPosition.GetWorldLocation(), DeathRadius);		
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterDeathTrigger(AHazePlayerCharacter Player)
	{
	 	if(CanKillPlayers == true)
	 	{
			// Networked in the player
			Player.KillPlayer(DeathEffect);
		}
	}
	UFUNCTION(NotBlueprintCallable)
	void EnterDeathTriggerHead(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
	 	if(CanKillPlayers == true)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

			if (Player != nullptr && !IsPlayerDead(Player))
			{
				if(Player.HasControl())
				{
					Player.KillPlayer(DeathEffect);
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterSpecialRightClashMoleVOTrigger(AHazePlayerCharacter Player)
	{
		if(bSpecialRightMoleClashVoPlayed)
			return;

	 	if(Player == Game::GetMay())
		{
			NetEnterSpecialRightClashMoleVOTrigger(Game::GetMay());
		}
		else if(Player == Game::GetCody())
		{
			NetEnterSpecialRightClashMoleVOTrigger(Game::GetCody());
		}
	}
	UFUNCTION(NetFunction)
	void NetEnterSpecialRightClashMoleVOTrigger(AHazePlayerCharacter Player)
	{
		if(bSpecialRightMoleClashVoPlayed)
			return;

		bSpecialRightMoleClashVoPlayed = true;
		OnPlaySpecialClashRightMoleVO.Broadcast(Player);
	}

	//Networked via ActorTriggers with (Path Determined by Control)
	UFUNCTION()
	void ActivateBouncyMole(UHazeCapabilitySheet BounceSheet)
	{
		CanKillPlayers = false;
		bStuckFallingDown = true;
		CurrentBounceSheet = BounceSheet;
		AddCapabilitySheet(BounceSheet);
	}

	////-----------------Animations--------------------
	//Networked via PlayerTriggers & ActorTriggers with (Path Determined by Control)
	UFUNCTION()
	void PlayMoleJumpAnimation()
	{
		SetAnimBoolParam(n"MoleJump", true);
	}
	UFUNCTION()
	void PlayMoleObstacleImpactAnimation()
	{
		SetAnimBoolParam(n"MoleObstacleImpact", true);
	}
	UFUNCTION()
	void PlayMoleEmergeAnimation()
	{
		SetAnimBoolParam(n"MoleEmerge", true);
	}
	UFUNCTION()
	void PlayMoleImpactLeftAnimation()
	{
		SetAnimBoolParam(n"MoleObstacleImpactLeft", true);
	}
	UFUNCTION()
	void PlayMoleImpactMiddleAnimation()
	{
		SetAnimBoolParam(n"MoleObstacleImpactMiddle", true);
	}
	UFUNCTION()
	void PlayMoleImpactRightAnimation()
	{
		SetAnimBoolParam(n"MoleObstacleImpactRight", true);	
	}
	UFUNCTION()
	void PlayMoleClimbAnimationStart()
	{
		bIsClimbing = true;
	}
	UFUNCTION()
	void StopMoleClimbAnimationStart()
	{
		bIsClimbing = false;
	}
	

	UFUNCTION()
	void PlayMoleStopLedgeAnimation()
	{
		if(bMolesIsInCrystalField == true)
			bMolesIsInCrystalField = false;
			
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"PlayMhMoleStopLedgeAnimation");
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = StartStopLedge, bLoop = false, BlendTime = 0.5f);
	}
	UFUNCTION()
	void PlayMhMoleStopLedgeAnimation()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = MhStopLedge, bLoop = true);
	}


	UFUNCTION()
	void PlayMoleCrashAnimation()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"PlayMhMoleCrashAnimation");
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = StartCrash);
	}
	UFUNCTION()
	void PlayMhMoleCrashAnimation()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = MhCrash, bLoop = true);	
	}

	UFUNCTION()
	void PlayEndingCrashLeft()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = EndingCrashLeft);	
	}
	UFUNCTION()
	void PlayEndingCrashRight()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = EndingCrashRight);	
	}


	UFUNCTION()
	void PlayMoleSteopOnMoleAnimation()
	{
		//PrintToScreen("AAAAAAAAAAAAA", 5.f);
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"PlayMoleSteopOnMoleAnimationFinished");
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = StartStepOnMole, bLoop = false, BlendTime = 0.5f);

	//	Player.PlaySlotAnimation(Animation = ExitAnimToUse, bLoop = false, BlendTime = 0.2f);

		//Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOutDelegate, DiveComp.EnterAnim, false, EHazeBlendType::BlendType_Inertialization, 0.2f, 0.4f);
		AtEndOfSplineOptions = EAtEndOfSplineOptions::Climb;
		SplineToFollow = SecondSplineToFollow;
		DistanceAlongSpline = 0;
	}
	UFUNCTION()
	void PlayMoleSteopOnMoleAnimationFinished()
	{
		//PrintToScreen("BBBBBBBBBBB", 5.f);
		bFollowingSpline = true;
	}
	UFUNCTION()
	void PlayMoleClimbAnimation()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;
		OnBlendingOut.BindUFunction(this, n"MoleClimbAnimationFinished");
		PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Animation = StartClimb,  bLoop = false, BlendTime = 0.5f);
		AtEndOfSplineOptions = EAtEndOfSplineOptions::LedgeStop;
		SplineToFollow = ThirdSplineToFollow;
		DistanceAlongSpline = 0;
	}
	UFUNCTION()
	void MoleClimbAnimationFinished()
	{
		//Print("AAAAAAAAAAAAA");
		bFollowingSpline = true;
	}
}

enum EAtEndOfSplineOptions
{
	LedgeStop,
	Crash,
	DisableActor,
	Climb,
	EndingCrashLeft,
	StepOnMole,
	None
}
