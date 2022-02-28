import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePinball.SpacePinballSpring;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePinball.SpacePinballToggleableWall;

event void FOnSpacePinballCrashed();

UCLASS(Abstract)
class ASpacePinball : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BallRoot;

	UPROPERTY(DefaultComponent, Attach = BallRoot)
	UStaticMeshComponent BallMesh;

	UPROPERTY(DefaultComponent, Attach = BallRoot)
	UStaticMeshComponent BallDoorMesh;

	UPROPERTY(DefaultComponent, Attach = BallRoot)
	UBoxComponent EnterTrigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent CollisionSphere;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent TrailEffectComp;
	default TrailEffectComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent RespawnEffectComp;
	default RespawnEffectComp.bAutoActivate = false;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;

	UPROPERTY(DefaultComponent, Attach = BallMesh)
	UHazeAkComponent BallHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BallCrashAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OpenHatchAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CloseHatchAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PinballCompleteAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BallStartMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BallStoptMoveAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionEffect;
	
	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenHatchTimeLike;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY()
	FOnSpacePinballCrashed OnSpacePinballCrashed;

	UPROPERTY()
	FOnSpacePinballCrashed OnPinballCompleted;

	UPROPERTY()
	FOnSpacePinballCrashed OnPinballHatchOpened;

	UPROPERTY()
	FOnSpacePinballCrashed OnPinballHatchClosed;

	UPROPERTY()
	ASpacePinballSpring TargetSpring;

	UPROPERTY()
	AActor SuccessTrigger;

	bool bMoving = false;
	bool bControlled = false;

	float MaxSpeed = 6500.f;
	float MinSpeed = 3500.f;
	float CurrentSpeed = 0.f;
	float NetworkMaxSpeed = 4000.f;
	float NetworkMinSpeed = 2000.f;

	float CurrentSideInput = 0.f;
	float CurrentSideModifier = 0.f;

	FVector StartLocation;
	FRotator StartRotation;

	bool bHatchOpening = false;

	float RightClamp;
	float LeftClamp;

	bool bCompleted = false;
	bool bCrashed = false;

	bool bDeathByToggleableWall = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetCody());

		StartLocation = ActorLocation;
		StartRotation = ActorRotation;
		LeftClamp = StartLocation.X;
		RightClamp = LeftClamp - 500.f;

		MoveComp.Setup(CollisionSphere);

		TargetSpring.OnSpringReleased.AddUFunction(this, n"SpringReleased");

		AttachToSpring();

		OpenHatchTimeLike.BindUpdate(this, n"UpdateOpenHatch");
		OpenHatchTimeLike.BindFinished(this, n"FinishOpenHatch");

		TargetSpring.OnParkedAtStart.AddUFunction(this, n"ParkedAtStart");

		EnterTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterBall");

		if (Network::IsNetworked())
		{
			MinSpeed = NetworkMinSpeed;
			MaxSpeed = NetworkMaxSpeed;
		}
	}

	UFUNCTION()
	void ForceCompleted()
	{
		BallDoorMesh.SetRelativeRotation(FRotator(180.f, -90.f, 180.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterBall(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player == Game::GetCody() && Player.HasControl() && !bControlled)
			NetPutCodyInBall();
	}

	UFUNCTION()
	void SetPinballCompleted()
	{
		bCompleted = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void ParkedAtStart()
	{
		if (bCompleted)
			return;

		bHatchOpening = true;
		OpenHatchTimeLike.PlayFromStart();
		BallHazeAkComp.HazePostEvent(OpenHatchAudioEvent);
	}

	void CloseHatch()
	{
		bHatchOpening = false;
		OpenHatchTimeLike.ReverseFromEnd();
		BallHazeAkComp.HazePostEvent(CloseHatchAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenHatch(float CurValue)
	{
		float Rot = FMath::Lerp(180.f, 290.f, CurValue);
		BallDoorMesh.SetRelativeRotation(FRotator(Rot, -90.f, 180.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishOpenHatch()
	{
		if (!bHatchOpening)
		{
			OnPinballHatchClosed.Broadcast();
			TargetSpring.ExposeHandle();
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationPinballStart");
			
		}
		else
		{
			OnPinballHatchOpened.Broadcast();
		}
	}

	UFUNCTION(NetFunction)
	void NetPutCodyInBall()
	{
		Game::GetCody().SetCapabilityAttributeObject(n"Pinball", this);
		Game::GetCody().SetCapabilityActionState(n"ControlPinball", EHazeActionState::Active);

		CloseHatch();
		bControlled = true;
	}

	UFUNCTION()
	void SpringReleased()
	{
		StartMoving();
	}

	UFUNCTION()
	void StartMoving()
	{
		TrailEffectComp.Activate(true);

		DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CurrentSpeed = MaxSpeed;
		bMoving = true;

		FTutorialPrompt MoveTutorial;
		MoveTutorial.Action = AttributeVectorNames::MovementRaw;
		MoveTutorial.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		ShowTutorialPrompt(Game::GetCody(), MoveTutorial, this);
		BallHazeAkComp.HazePostEvent(BallStartMoveAudioEvent);

		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationPinballLaunchCody");
	}

	UFUNCTION()
	void ResetBall()
	{
		CurrentSideModifier = 0.f;
		bMoving = false;
		bControlled = false;
		bCrashed = false;
		AttachToSpring();
		SetActorHiddenInGame(false);
		RespawnEffectComp.Activate(true);
	}

	void AttachToSpring()
	{
		// AttachToComponent(TargetSpring.BallAttachPoint, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
		AttachToComponent(TargetSpring.BallAttachPoint);
		// SetActorRotation(StartRotation);
	}

	void UpdateControlledInput(float Input)
	{
		CurrentSideInput = Input;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bMoving)
		{
			if (HasControl())
			{
				FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Pinball");
				CurrentSpeed -= 2900.f * DeltaTime;
				CurrentSpeed = FMath::Clamp(CurrentSpeed, MinSpeed, MaxSpeed);
				FVector Delta = ActorForwardVector * CurrentSpeed * DeltaTime;

				if (bControlled)
				{
					CurrentSideModifier = FMath::FInterpTo(CurrentSideModifier, CurrentSideInput, DeltaTime, 5.f);
					CurrentSideModifier = FMath::Clamp(CurrentSideModifier, -1.f, 1.f);
					FVector ForwardDelta = Delta;
					Delta += ActorRightVector * CurrentSideModifier * 12.f;
					if ((ActorLocation.X + Delta.X) < RightClamp || (ActorLocation.X + Delta.X) > LeftClamp)
						Delta = ForwardDelta;
				}

				MoveData.ApplyDelta(Delta);
				MoveData.ApplyActorVerticalVelocity();
				MoveData.ApplyGravityAcceleration();
				MoveComp.Move(MoveData);

				CrumbComp.LeaveMovementCrumb();

				BallRoot.AddWorldRotation(FRotator(-Delta.X, 0.f, Delta.Y) * 0.28f);

				if (MoveComp.ForwardHit.bBlockingHit)
				{
					if (MoveComp.ForwardHit.Actor == SuccessTrigger)
					{
						FHazeDelegateCrumbParams Params;
						CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_TriggerSuccess"), Params);
						return;
					}

					FHazeDelegateCrumbParams Params;
					Params.AddObject(n"CrashActor", MoveComp.ForwardHit.Actor);
					CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_CrashBall"), Params);
				}
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

				FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"Movement");
				MoveData.ApplyConsumedCrumbData(ConsumedParams);

				BallRoot.AddWorldRotation(FRotator(-ConsumedParams.DeltaTranslation.X, 0.f, ConsumedParams.DeltaTranslation.Y) * 0.28f);

				MoveComp.Move(MoveData);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_TriggerSuccess(const FHazeDelegateCrumbData& CrumbData)
	{
		bCompleted = true;
		bMoving = false;
		MoveComp.StopMovement(true, true);
		TrailEffectComp.Deactivate();
		CleanupCurrentMovementTrail();
		RemoveTutorialPromptByInstigator(Game::GetCody(), this);
		BallHazeAkComp.HazePostEvent(BallStoptMoveAudioEvent);
		OnPinballCompleted.Broadcast();
		UHazeAkComponent::HazePostEventFireForget(PinballCompleteAudioEvent, FTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_CrashBall(const FHazeDelegateCrumbData& CrumbData)
	{
		if (bCrashed)
			return;

		AActor CrashActor = Cast<AActor>(CrumbData.GetObject(n"CrashActor"));
		if (CrashActor != nullptr)
		{
			ASpacePinballToggleableWall Wall = Cast<ASpacePinballToggleableWall>(CrashActor);
			if (Wall != nullptr)
				bDeathByToggleableWall = true;
			else
				bDeathByToggleableWall = false;
				
			FOnRespawnTriggered RespawnEvent;
			RespawnEvent.BindUFunction(this, n"RespawnTriggered");
			BindOnPlayerRespawnedEvent(RespawnEvent);
		}

		bCrashed = true;
		bMoving = false;
		TrailEffectComp.Deactivate();

		RemoveTutorialPromptByInstigator(Game::GetCody(), this);
		CleanupCurrentMovementTrail();
		
		BallHazeAkComp.HazePostEvent(BallStoptMoveAudioEvent);
		DestroyBall();
	}

	UFUNCTION()
	void DestroyBall()
	{
		BallHazeAkComp.HazePostEvent(BallCrashAudioEvent);
		OnSpacePinballCrashed.Broadcast();
		SetActorHiddenInGame(true);
		Niagara::SpawnSystemAtLocation(ExplosionEffect, ActorLocation);

		BallRoot.SetRelativeRotation(FRotator(0.f, 180.f, 0.f));

		TargetSpring.BallCrashed();
		System::SetTimer(this, n"ResetSpring", 1.25f, false);
		TargetSpring.OnParkedAtStart.AddUFunction(this, n"SpringFullyReset");
	}

	UFUNCTION(NotBlueprintCallable)
	void RespawnTriggered(AHazePlayerCharacter Player)
	{
		UnbindOnPlayerRespawnedEvent(this);
    	if (bDeathByToggleableWall)
        	System::SetTimer(this, n"PlayDeathMayFaultBark", .7f, false);
    	else
        	System::SetTimer(this, n"PlayDeathCodyFaultBark", .7f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayDeathMayFaultBark()
	{
		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationPinballDeathMayFault");
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayDeathCodyFaultBark()
	{
		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationPinballDeathCodyFault");
	}

	UFUNCTION(NotBlueprintCallable)
	void ResetSpring()
	{
		TargetSpring.StartReturningToStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void SpringFullyReset()
	{
		ResetBall();
	}
}