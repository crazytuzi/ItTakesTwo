import Cake.LevelSpecific.Hopscotch.MarbleMazeBall;
import Cake.LevelSpecific.Hopscotch.MarbleMazeManager;
import Cake.LevelSpecific.Hopscotch.MarbleMazeBall;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;
import Peanuts.Audio.AudioStatics;
import Vino.Tilt.TiltComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Buttons.GroundPoundButton;
import Cake.LevelSpecific.Hopscotch.MarbleMazeMouse;
import Peanuts.Triggers.ActorTrigger;
import Cake.LevelSpecific.Hopscotch.MarbleMazeButton;

event void FMarbleMazeSignature();
event void FMarbleRoomCleared();

enum EMazeCompToMove
{
	Start,
	End
}

enum EHopscotchMarbleMaze
{
	Maze01,
	Maze02
}

class AMarbleMaze : AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = MazeInnerMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMarbleMazeBoardAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LidUpAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LidDownAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FenceDownAudioEvent;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MazeOuterMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MazeOuterMeshRoot)
	UStaticMeshComponent MazeOuterMesh;

	UPROPERTY(DefaultComponent, Attach = MazeOuterMeshRoot)
	UStaticMeshComponent OuterMazeTurnerMesh01;

	UPROPERTY(DefaultComponent, Attach = MazeOuterMeshRoot)
	UStaticMeshComponent OuterMazeTurnerMesh02;

	UPROPERTY(DefaultComponent, Attach = MazeOuterMeshRoot)
	UTiltComponent OuterTiltComp;

	UPROPERTY(DefaultComponent, Attach = MazeOuterMeshRoot)
	USceneComponent MazeInnerMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UStaticMeshComponent ButtonBase01;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UStaticMeshComponent ButtonBase02;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UStaticMeshComponent MazeInnerMesh;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UStaticMeshComponent InnerMazeTurnerMesh01;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UStaticMeshComponent InnerMazeTurnerMesh02;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UTiltComponent InnerTiltComp;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	USceneComponent MazeStartMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UBoxComponent BlockingVolume01;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UBoxComponent BlockingVolume02;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UBoxComponent BlockingVolume03;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UBoxComponent BlockingVolume04;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UBoxComponent BlockingVolume05;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UStaticMeshComponent Hatch;

	UPROPERTY(DefaultComponent, Attach = MazeStartMeshRoot)
	UStaticMeshComponent MazeStartMesh;

	UPROPERTY(DefaultComponent, Attach = MazeStartMeshRoot)
	UBoxComponent MazeStartCollision;

	UPROPERTY(DefaultComponent, Attach = MazeStartMeshRoot)
	USceneComponent FenceMeshRoot;

	UPROPERTY(DefaultComponent, Attach = FenceMeshRoot)
	UStaticMeshComponent FenceMesh;

	UPROPERTY(DefaultComponent, Attach = MazeStartMesh)
	USceneComponent StartAttachLocation;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	USceneComponent MazeEndMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MazeEndMeshRoot)
	UStaticMeshComponent MazeEndMesh;

	UPROPERTY(DefaultComponent, Attach = MazeEndMeshRoot)
	USphereComponent MazeEndCollision;

	UPROPERTY(DefaultComponent, Attach = MazeEndMesh)
	USceneComponent EndAttachLocation;

	UPROPERTY(DefaultComponent, Attach = MazeOuterMeshRoot)
	USphereComponent BallRespawnLocationComp;
	default BallRespawnLocationComp.SphereRadius = 69.f;

	UPROPERTY(DefaultComponent, Attach = MazeInnerMeshRoot)
	UBoxComponent TempBlockVolume;

	UPROPERTY()
	FHazeTimeLike MoveStartOrEndUpTimeline;

	UPROPERTY()
	FHazeTimeLike MoveStartOrEndDownTimeline;

	UPROPERTY()
	FMarbleMazeSignature GoalReachedEvent;

	UPROPERTY()
	FMarbleRoomCleared MarbleRoomCleared;

	UPROPERTY()
	AActorTrigger BallFailSoundTrigger;
	
	UPROPERTY()
	float MaxDegreesToRotate;
	default MaxDegreesToRotate = 15.f;
	
	UPROPERTY()
	float RotationInterpSpeed;
	default RotationInterpSpeed = 1.f;

	UPROPERTY()
	AMarbleMazeBall Ball;

	UPROPERTY()
	bool bShouldHaveHatch = false;
	
	UPROPERTY()
	bool bDebugMode = false;

	UPROPERTY()
	EHopscotchMarbleMaze MarbleMaze;

	UPROPERTY()
	AGroundPoundButton GroundPoundButtonRef;

	UPROPERTY()
	FHazeTimeLike FenceTimeline;
	default FenceTimeline.Duration = 0.2f;

	UPROPERTY()
	AMarbleMazeButton Button01;

	UPROPERTY()
	AMarbleMazeButton Button02;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteractionActor;

	USceneComponent CurrentStartOrEndToMove;
	float StartOrEndDownLoc = -2000.f;
	float StartOrEndUpLoc = 0.f;
	float EndFinalLocation = 580.f;
	
	bool bCheckIfBallLeftStartArea = false;
	bool bBallCurrentlyResetting = false;
	bool bMarbleMazeActive = false;
	
	UPROPERTY()
	bool bReachedGoal = false;

	bool bBallIsActive = false;

	bool bMarbleMazeCurrentlyFrozen = false;
	bool bShouldResetMaze = false;
	
	float MarbleMazeXLastTick = 0.f;
	float MarbleMazeYLastTick = 0.f;

	FVector FenceUpLocation = FVector::ZeroVector;
	FVector FenceDownLocation = FVector(0.f, 0.f, -85.f);
	private FVector PreviousVelocity;

	/* Timers */
	float ResetBallTimer = 0.f;
	bool bShouldTickResetBallTimer = false;
	/* ---- */

	/* Audio Parameters */
	float AudioMarbleMazeX = 0.f;
	float AudioMarbleMazeY = 0.f;
	float AudioMarbleMazeSpeed = 0.f;
	/* ---- */

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// NOTE : Changed to tracking velocity instead, keeping as is if the remote hit could be fixed.
		// FActorImpactedDelegate ImpactDelegate;
		// ImpactDelegate.BindUFunction(this, n"OnBallHit");
		// BindOnForwardImpacted(this, ImpactDelegate);	

		UActorImpactedCallbackComponent::Get(this).bCanBeActivedLocallyOnTheRemote = true;

		MazeEndCollision.OnComponentBeginOverlap.AddUFunction(this, n"EndCollisionOverlap");

		HazeAkComp.HazePostEvent(StartMarbleMazeBoardAudioEvent);

		MoveStartOrEndUpTimeline.BindUpdate(this, n"MoveStartOrEndUpTimelineUpdate");
		MoveStartOrEndDownTimeline.BindUpdate(this, n"MoveStartOrEndDownTimelineUpdate");
		FenceTimeline.BindUpdate(this, n"FenceTimelineUpdate");

		BallFailSoundTrigger.OnActorEnter.AddUFunction(this, n"OnBallEnterFailVolume");

		SetBlockingVolumesActive(false);

		FActorImpactedByPlayerDelegate DownImpactDelegate;
		DownImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(this, DownImpactDelegate);

		Button01.AttachToComponent(MazeInnerMeshRoot, n"", EAttachmentRule::KeepWorld);
		Button02.AttachToComponent(MazeInnerMeshRoot, n"", EAttachmentRule::KeepWorld);
		DoubleInteractionActor.AttachToComponent(MazeInnerMeshRoot, n"", EAttachmentRule::KeepWorld);

		DoubleInteractionActor.OnLeftInteractionReady.AddUFunction(this, n"DoubleInteractionStarted");
		DoubleInteractionActor.OnRightInteractionReady.AddUFunction(this, n"DoubleInteractionStarted");
		DoubleInteractionActor.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"DoubleInteractionCancel");

		if (!bShouldHaveHatch)
		{
			Hatch.SetHiddenInGame(true);
			Hatch.CollisionEnabled = ECollisionEnabled::NoCollision;
		}

		if (Ball != nullptr)
		{
			AttachBallToComp(EMazeCompToMove::Start);
			Ball.MarbleBallReachedGoal.AddUFunction(this, n"OnMarbleBallReachedGoal");
		}

		MazeStartMeshRoot.SetRelativeLocation(FVector(MazeStartMeshRoot.RelativeLocation.X, MazeStartMeshRoot.RelativeLocation.Y, StartOrEndDownLoc));
	}

	UFUNCTION()
	void DoubleInteractionStarted(AHazePlayerCharacter Player)
	{
		InnerTiltComp.LockRotationFromPlayer(Player);
		OuterTiltComp.LockRotationFromPlayer(Player);
	}

	UFUNCTION()
	void DoubleInteractionCancel(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		// InnerTiltComp.ClearRotationLockFromPlayer(Player);
		// OuterTiltComp.ClearRotationLockFromPlayer(Player);
	}

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, FHitResult Hit)
	{
		InnerTiltComp.ClearRotationLockFromPlayer(Player);
		OuterTiltComp.ClearRotationLockFromPlayer(Player);
	}

	UFUNCTION()
	void OnBallHit(AHazeActor Actor, FHitResult Hit)
	{
		if (Ball != nullptr)
		{
			float Dot = Ball.MoveComp.Velocity.DotProduct(-Hit.ImpactNormal);
			if (Dot > 100.f)
				Ball.OnBallHitWall();
		}
	}

	UFUNCTION()
	void FreezeMarbleMaze(bool bFrozen, bool bResetMaze)
	{
		InnerTiltComp.SetTiltComponentEnabled(!bFrozen);
		OuterTiltComp.SetTiltComponentEnabled(!bFrozen);	
		bMarbleMazeCurrentlyFrozen = bFrozen;
		bShouldResetMaze = bResetMaze;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// From -10 to 10
		AudioMarbleMazeX = MazeOuterMeshRoot.RelativeRotation.Roll * 2.f;
		HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_MarbleMaze_X", AudioMarbleMazeX);
		
		// From -10 to 10
		AudioMarbleMazeY = MazeInnerMeshRoot.RelativeRotation.Pitch * 2.f;
		HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_MarbleMaze_Y", AudioMarbleMazeY);

		AudioMarbleMazeSpeed = ((MazeOuterMeshRoot.RelativeRotation.Roll * 2.f - MarbleMazeXLastTick) + (MazeInnerMeshRoot.RelativeRotation.Pitch * 2.f - AudioMarbleMazeY)) / DeltaTime;
		// From 0 to around 10
		AudioMarbleMazeSpeed = FMath::Abs(AudioMarbleMazeSpeed);
		HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_MarbleMaze_Velocity", AudioMarbleMazeSpeed);

		MarbleMazeXLastTick = MazeOuterMeshRoot.RelativeRotation.Roll * 2.f;
		MarbleMazeYLastTick = MazeInnerMeshRoot.RelativeRotation.Pitch * 2.f;

		if (bMarbleMazeCurrentlyFrozen)
		{
			if (bShouldResetMaze)
			{
				MazeInnerMeshRoot.SetRelativeRotation(FMath::RInterpTo(MazeInnerMeshRoot.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 1.f));
				MazeOuterMeshRoot.SetRelativeRotation(FMath::RInterpTo(MazeOuterMeshRoot.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 1.f));
			}
		}
		
		if (!bMarbleMazeActive)
			return;

		if (Ball != nullptr)
		{
			if (Ball.bShouldLerpToGoal)
				Ball.CurrentGoalLoc = EndAttachLocation.WorldLocation;
		}

		if (Ball != nullptr)
		{
			if (bCheckIfBallLeftStartArea)
			{
				if (!MazeStartCollision.IsOverlappingActor(Ball))
				{
					bCheckIfBallLeftStartArea = false;
					StartMovingStartOrEnd(false, EMazeCompToMove::Start);
				}
			}
			
			Ball.GetMazeRotation(MazeInnerMeshRoot.WorldRotation);

			float BallZDifference = Ball.ActorLocation.Z - ActorLocation.Z;
			if (BallZDifference < -3000.f && !bBallCurrentlyResetting && bBallIsActive)
			{
				if (HasControl())
				{
					ResetBall();
				}
			}

			if (bBallIsActive)
			{
				if (!PreviousVelocity.IsNearlyZero(0.01f))
				{
					FVector NormalizedVelocity = Ball.MoveComp.Velocity.GetSafeNormal();
					FVector PrevNormalizedVelocity = PreviousVelocity.GetSafeNormal();
					float VelcitySize = (Ball.MoveComp.Velocity - PreviousVelocity).Size();
					float Dot = NormalizedVelocity.DotProduct(PrevNormalizedVelocity);

					if (Dot <= 0.6f && VelcitySize > 80.f)
					{
						Ball.OnBallHitWall();
					}
				}
				PreviousVelocity = Ball.MoveComp.Velocity;
			}
		}		

		if (bShouldTickResetBallTimer)
		{
			ResetBallTimer -= DeltaTime;
			if (ResetBallTimer <= 0.f)
			{
				bShouldTickResetBallTimer = false;
				Ball.SetBallActive(true);
				bBallIsActive = true;
				bBallCurrentlyResetting = false;
				DetachBallFromComp();
			}
		}		
	}

	UFUNCTION()
	void SetBlockingVolumesActive(bool bActive)
	{
		ECollisionEnabled NewCollision = bActive ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision;
		BlockingVolume01.SetCollisionEnabled(NewCollision);
		BlockingVolume02.SetCollisionEnabled(NewCollision);
		BlockingVolume03.SetCollisionEnabled(NewCollision);
		BlockingVolume04.SetCollisionEnabled(NewCollision);
		BlockingVolume05.SetCollisionEnabled(NewCollision);
	}

	UFUNCTION()
	void StartMarbleMaze()
	{
		DetachBallFromComp();
		Ball.AddBallCapability();
		Ball.SetBallActive(true);
		bBallIsActive = true;
		bMarbleMazeActive = true;
	}

	UFUNCTION()
	void ActivateMazeVolumes()
	{
		SetBlockingVolumesActive(true);
	}

	UFUNCTION()
	void AttachBallToComp(EMazeCompToMove CompToMove)
	{
		USceneComponent CompToAttachTo = CompToMove == EMazeCompToMove::Start ? StartAttachLocation : EndAttachLocation; 
		Ball.TeleportActor(CompToAttachTo.WorldLocation, Ball.ActorRotation);
		Ball.AttachToComponent(CompToAttachTo, n"", EAttachmentRule::KeepWorld);
		Ball.SetBallActive(false);
		bBallIsActive = false;
	}

	UFUNCTION()
	void DetachBallFromComp()
	{
		Ball.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Ball.SetBallActive(true);
		bBallIsActive = true;
		FenceTimeline.Play();
		UHazeAkComponent::HazePostEventFireForget(FenceDownAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NetFunction)
	void NetTeleportBall(FVector TeleportLocation)
	{
		Ball.TeleportActor(TeleportLocation, FRotator::ZeroRotator);
	}

	// Telling the Ball's movecomp to start going towards the GoalLocation. When it's close enought to the goal location, OnMarbleBallReachedGoal() will be called
	UFUNCTION()
    void EndCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	UPrimitiveComponent OtherComponent, int OtherBodyIndex,
	bool bFromSweep, FHitResult& Hit)
	{
		if (OtherActor == Ball && Ball.HasControl())
		{
			Ball.bShouldLerpToGoal = true;
		}			
	}

	// Called when the Ball is close enough to get attached to the goal component.
	UFUNCTION()
	void OnMarbleBallReachedGoal()
	{
		NetBallIsAtGoalLoc();
	}

	UFUNCTION()
	void SetNewBall(AMarbleMazeBall NewBall)
	{
		Ball = NewBall;
		Ball.MarbleBallReachedGoal.AddUFunction(this, n"OnMarbleBallReachedGoal");
	}

	// make crum trail invalid and attach to component. 
	UFUNCTION(NetFunction)
	void NetBallIsAtGoalLoc()
	{
		Ball.TriggerMovementTransition(this, n"MarbleBallGoalAttach");
		GoalReachedEvent.Broadcast();
		bReachedGoal = true;
		AttachBallToComp(EMazeCompToMove::End);
		bMarbleMazeActive = false;
		SetBlockingVolumesActive(false);
		Ball.BallReachedGoal();
		
		//Either finish the marble maze challenge, or move on the the next marble maze.
		if (MarbleMaze == EHopscotchMarbleMaze::Maze01)
			StartMovingStartOrEnd(false, EMazeCompToMove::End);
	}

	UFUNCTION()
	void StartMovingStartOrEnd(bool bUp, EMazeCompToMove CompToMove)
	{
		CurrentStartOrEndToMove = CompToMove == EMazeCompToMove::Start ? MazeStartMeshRoot : MazeEndMeshRoot; 
		bUp ? MoveStartOrEndUpTimeline.PlayFromStart() : MoveStartOrEndDownTimeline.PlayFromStart();

		if (bUp && CompToMove == EMazeCompToMove::Start)
			bCheckIfBallLeftStartArea = true;
		
		if (bUp)
		{
			UHazeAkComponent::HazePostEventFireForget(LidUpAudioEvent, CurrentStartOrEndToMove.GetWorldTransform());
			FenceTimeline.Reverse();
		}

		else if (!bUp)
		{
			UHazeAkComponent::HazePostEventFireForget(LidDownAudioEvent, CurrentStartOrEndToMove.GetWorldTransform());
		}
	}

	UFUNCTION()
	void MoveStartOrEndUpTimelineUpdate(float CurrentValue)
	{
		CurrentStartOrEndToMove.SetRelativeLocation(FVector(CurrentStartOrEndToMove.RelativeLocation.X, CurrentStartOrEndToMove.RelativeLocation.Y, FMath::Lerp(StartOrEndDownLoc, StartOrEndUpLoc, CurrentValue)));
		PrintToScreen("UP! CurrentValue: " + CurrentValue);
	}

	UFUNCTION()
	void MoveStartOrEndDownTimelineUpdate(float CurrentValue)
	{
		CurrentStartOrEndToMove.SetRelativeLocation(FVector(CurrentStartOrEndToMove.RelativeLocation.X, CurrentStartOrEndToMove.RelativeLocation.Y, FMath::Lerp(StartOrEndUpLoc, StartOrEndDownLoc, CurrentValue)));
		PrintToScreen("DOWN! CurrentValue: " + CurrentValue);
	}

	UFUNCTION()
	void FenceTimelineUpdate(float CurrentValue)
	{
		FenceMesh.SetRelativeLocation(FMath::Lerp(FenceUpLocation, FenceDownLocation, CurrentValue));
	}

	UFUNCTION(NetFunction)
	void ResetBall()
	{
		Ball.TriggerMovementTransition(this, n"BallFellDOwn");
		Ball.SetBallActive(false);
		bBallIsActive = false;
		AttachBallToComp(EMazeCompToMove::Start);
		StartMovingStartOrEnd(true, EMazeCompToMove::Start);
		ResetBallTimer = 1.5f;
		bShouldTickResetBallTimer = true;
		bBallCurrentlyResetting = true;
	}

	UFUNCTION()
	void OnBallEnterFailVolume(AHazeActor Actor)
	{
		AMarbleMazeBall BallFail = Cast<AMarbleMazeBall>(Actor);

		if (BallFail != nullptr && !bBallCurrentlyResetting && !bReachedGoal)
		{
			BallFail.BallFailed();
		}
	}
}
