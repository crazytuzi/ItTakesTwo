import Vino.Interactions.InteractionComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Bounce.BounceComponent;
import Vino.Tilt.TiltComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCarDepotDoor;
import Vino.Camera.Components.CameraSpringArmComponent;
import Peanuts.Triggers.ActorTrigger;

settings PullbackCarMovementSettings for UMovementSettings
{
	PullbackCarMovementSettings.MoveSpeed = 400.f;
	PullbackCarMovementSettings.GravityMultiplier = 6.f;
	PullbackCarMovementSettings.ActorMaxFallSpeed = 5000.f;
	PullbackCarMovementSettings.StepUpAmount = 80.f;
	PullbackCarMovementSettings.CeilingAngle = 30.f;
	PullbackCarMovementSettings.WalkableSlopeAngle = 55.f;
	PullbackCarMovementSettings.AirControlLerpSpeed = 2500.f;
	PullbackCarMovementSettings.GroundRotationSpeed = 20.f;
	PullbackCarMovementSettings.AirRotationSpeed = 10.f;
	PullbackCarMovementSettings.VerticalForceAirPushOffThreshold = 500.f;
}

event void FPullbackCarWasDestroyed();
event void FPullbackCarWasDestroyedVo(AHazePlayerCharacter Player);
event void FPullbackCarAudioDriverInteracted(bool bEnteredCar);
event void FPullbackCarAudioWindupPlayerInteracted(bool bStartedPulling);

import void AddCarToPlayer(AHazePlayerCharacter, APullbackCar, bool) from "Cake.LevelSpecific.Hopscotch.SideContent.PullbackCarWindupCharacterAnimComponent";
import void RemoveCarFromPlayer(AHazePlayerCharacter, bool) from "Cake.LevelSpecific.Hopscotch.SideContent.PullbackCarWindupCharacterAnimComponent";

enum EPullBackCarMovementState
{
	Idle,
	WindingUp,
	Released,
	Exploding,
	Respawning,
}

class APullbackCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;
	default MoveComp.DefaultMovementSettings = PullbackCarMovementSettings;
	default MoveComp.bDepenetrateOutOfOtherMovementComponents = false;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default ReplicateAsMovingActor();

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxComponent;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UInteractionComponent DriverInteractComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UInteractionComponent WindupPullcarInteractComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	USceneComponent DriverAttachComp;

	UPROPERTY(DefaultComponent, Attach = DriverAttachComp)
	USkeletalMeshComponent DriverPreviewMesh;
	default DriverPreviewMesh.bIsEditorOnly = true;
	default DriverPreviewMesh.bHiddenInGame = true;
	default DriverPreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WindupAttachComp;

	UPROPERTY(DefaultComponent, Attach = WindupAttachComp)
	USkeletalMeshComponent WindupPreviewMesh;
	default WindupPreviewMesh.bIsEditorOnly = true;
	default WindupPreviewMesh.bHiddenInGame = true;
	default WindupPreviewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BackTraceLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FrontTraceLocation;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UBoxComponent FrontKillCollision;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	USceneComponent BaseMeshRoot;

	UPROPERTY(DefaultComponent, Attach = BaseMeshRoot)
	USceneComponent BounceRoot;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UTiltComponent TiltComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UBounceComponent BounceComp;

	UPROPERTY(DefaultComponent, Attach = BounceRoot)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	USceneComponent WheelsRoot;

	UPROPERTY(DefaultComponent, Attach = WheelsRoot)
	UStaticMeshComponent WheelsMeshFront;

	UPROPERTY(DefaultComponent, Attach = WheelsRoot)
	UStaticMeshComponent WheelsMeshBack;

	UPROPERTY(DefaultComponent, Attach = BaseMeshRoot)
    UHazeAkComponent HazeAkComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayGetInCarAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyGetInCarAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.f;

	UPROPERTY()
	AActorTrigger LaunchTrigger;
	
	UPROPERTY()
	TSubclassOf<UHazeCapability> PullbackCarCapability;

	// UPROPERTY()
	// TSubclassOf<UHazeCapability> PullbackCarAirborneMovementCapability;

	// UPROPERTY()
	// TSubclassOf<UHazeCapability> PullbackCarMoveDuringWindupCapability;

	// UPROPERTY()
	// TSubclassOf<UHazeCapability> PullbackCarMoveFromDepotCapability;

	// UPROPERTY()
	// TSubclassOf<UHazeCapability> PullbackCarMoveWhileDrivingCapability;

	// UPROPERTY()
	// TSubclassOf<UHazeCapability> PullbackCarAccelerationCapability;

	// UPROPERTY()
	// TSubclassOf<UHazeCapability> PullbackCarDecelerationCapability;

	UPROPERTY()
	TSubclassOf<UHazeCapability> PullbackCarAudioCapability;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet DriverSheet;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet PullerSheet;

	UPROPERTY()
	FPullbackCarAudioDriverInteracted PullbackCarAudioDriverInteracted;

	UPROPERTY()
	FPullbackCarAudioWindupPlayerInteracted PullbackCarAudioWindupPlayerInteracted;

	UPROPERTY()
	FHazeTimeLike CamFovTimeline;
	default CamFovTimeline.Duration = 1.f;

	UPROPERTY()
	FPullbackCarWasDestroyed OnPullbackCarWasDestroyed;

	UPROPERTY()
	FPullbackCarWasDestroyedVo OnPullbackCarWasDestroyedVo;

	UPROPERTY()
	UNiagaraSystem SlowExplosionFX;

	UPROPERTY()
	UNiagaraSystem FastExplosionFX;

	UPROPERTY()
	AActor RespawnLocationActor;

	UPROPERTY()
	AActor DriverToFromDepotLocationActor;

	UPROPERTY()
	PullbackCarDepotDoor DepotDoor;

	UPROPERTY()
	UHazeCameraSettingsDataAsset DriverCamSettings;

	UPROPERTY()
	TArray<UTexture> CarTextureArray;

	AHazePlayerCharacter PlayerPullingCar;

	const float CamDefaultFov = 70.f;
	float CamFovMultiplier = 1.f;	

	FVector WindupDirection;
	float DriverSteeringDirection = 0;

	float CurrentWindupRotationForce = 0.f;
	const float WindupForceMultiplier = 450.f;
	const float WindupRotationForceMultiplier = -50.f;

	float RespawnTimer = -1.f;
	int RespawnTextureIndex = 0;
	bool bPlayerIsHonking = false;

	AHazePlayerCharacter PlayerDrivingCar;
	AHazePlayerCharacter BlockedJumpinPlayer;

	EPullBackCarMovementState CurrentMovementState = EPullBackCarMovementState::Idle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//BounceComp.SetBounceComponentEnabled(false);

		// if (HasControl())
		// 	NetSetCarPassive(true);
		
		MoveComp.Setup(BoxComponent);
		//FrontKillCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnKillCollisionOverlap");
		DriverInteractComp.OnActivated.AddUFunction(this, n"DriverInteractionCompActivated");
		WindupPullcarInteractComp.OnActivated.AddUFunction(this, n"WindupPullcarInteractCompActivated");
		CamFovTimeline.BindUpdate(this, n"CamFovTimelineUpdate");
		SetCapabilityActionState(n"AudioCarNotAirborne", EHazeActionState::ActiveForOneFrame);
		
		AddCapability(PullbackCarCapability);
		//AddCapability(PullbackCarAirborneMovementCapability);
		//AddCapability(PullbackCarMoveDuringWindupCapability);
		//AddCapability(PullbackCarMoveFromDepotCapability);
		//AddCapability(PullbackCarMoveWhileDrivingCapability);
		//AddCapability(PullbackCarAccelerationCapability);
		//AddCapability(PullbackCarDecelerationCapability);
		AddCapability(PullbackCarAudioCapability);

		// LaunchTrigger.OnActorEnter.AddUFunction(this, n"LaunchOverlap");
		// LaunchTrigger.OnActorLeave.AddUFunction(this, n"LaunchEndOverlap");

		CrumbComponent.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this, true);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(PlayerDrivingCar != nullptr)
			PlayerDrivingCar.RemoveCapabilitySheet(DriverSheet, this);

		if(PlayerPullingCar != nullptr)
			PlayerPullingCar.RemoveCapabilitySheet(PullerSheet, this);
	}

	// UFUNCTION()
	// void LaunchOverlap(AHazeActor Actor)
	// {
	// 	if (HasControl())
	// 	{
	// 		SetCapabilityActionState(n"PullbackCarLaunch", EHazeActionState::Active);
	// 	}
	// }

	// UFUNCTION()
	// void LaunchEndOverlap(AHazeActor Actor)
	// {
	// 	if (HasControl())
	// 	{
	// 		SetCapabilityActionState(n"PullbackCarLaunch", EHazeActionState::Inactive);
	// 	}
	// }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		if(RespawnTimer > 0 && CurrentMovementState == EPullBackCarMovementState::Exploding)
		{
			RespawnTimer -= DeltaTime;
			if(RespawnTimer <= 0)
			{
				RespawnTimer = -1;
				RespawnCarLocally();
			}
		}
	
		if(IsAnyCapabilityActive(n"PullbackCarMoveDuringWindupCapability"))
		{
			WheelsMeshFront.AddLocalRotation(FRotator(MoveComp.ActualVelocity.Size() * DeltaTime, 0.f, 0.f)); 
			WheelsMeshBack.AddLocalRotation(FRotator(MoveComp.ActualVelocity.Size() * DeltaTime, 0.f, 0.f)); 
		}
		else
		{
			WheelsMeshFront.AddLocalRotation(FRotator(-MoveComp.ActualVelocity.Size() * DeltaTime, 0.f, 0.f)); 
			WheelsMeshBack.AddLocalRotation(FRotator(-MoveComp.ActualVelocity.Size() * DeltaTime, 0.f, 0.f));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_DestroyCar(const FHazeDelegateCrumbData& CrumbData)
	{
		if(CurrentMovementState == EPullBackCarMovementState::Released)
		{
			DestroyCarLocally();
		}
	}

	// This comes from a crumb in the level and from the impact crumb
	UFUNCTION()
	void DestroyCarLocally()
	{
		if(PlayerDrivingCar != nullptr)
		{
			RemoveCarFromPlayer(PlayerDrivingCar, true);
			PlayerDrivingCar.KillPlayer();
			PlayerDrivingCar = nullptr;
		}

		CurrentMovementState = EPullBackCarMovementState::Exploding;
		FVector EffectPosition = GetActorLocation();
		Niagara::SpawnSystemAtLocation(SlowExplosionFX, EffectPosition);
		Niagara::SpawnSystemAtLocation(FastExplosionFX, EffectPosition);
		SetCapabilityActionState(n"AudioCarExploded", EHazeActionState::ActiveForOneFrame);
		MovementRoot.SetRelativeTransform(FTransform::Identity);
		OnPullbackCarWasDestroyed.Broadcast();
		NetSetupRespawnParams(FMath::RandRange(0, CarTextureArray.Num() - 1));
		SetActorHiddenInGame(true);
	}

	UFUNCTION(NetFunction)
	void NetSetupRespawnParams(int TextureIndex)
	{
		RespawnTextureIndex = TextureIndex;
		RespawnTimer = 2.f;
	}

	private void RespawnCarLocally()
	{
		TriggerMovementTransition(this, n"Respawn");
		SetActorTransform(RespawnLocationActor.ActorTransform);
		MovementRoot.SetWorldRotation(RespawnLocationActor.ActorRotation);
		SetActorHiddenInGame(false);
		DepotDoor.OpenDoorForDuration(3.f);
		//SetCapabilityActionState(n"MoveFromDepot", EHazeActionState::Active);
		CurrentMovementState = EPullBackCarMovementState::Respawning;
		BaseMesh.CreateDynamicMaterialInstance(1).SetTextureParameterValue(n"M1", CarTextureArray[RespawnTextureIndex]);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_FinishRespawn(const FHazeDelegateCrumbData& CrumbData)
	{
		CurrentMovementState = EPullBackCarMovementState::Idle;
		for (auto Player : Game::GetPlayers())
		{
			DriverInteractComp.EnableForPlayerAfterFullSyncPoint(Player, n"Driving");
			WindupPullcarInteractComp.EnableForPlayerAfterFullSyncPoint(Player, n"Pulling");
		}

		if(BlockedJumpinPlayer != nullptr)
		{
			for (auto Player : Game::GetPlayers())
				DriverInteractComp.EnableForPlayerAfterFullSyncPoint(Player, n"Driving");
				
			BlockedJumpinPlayer = nullptr;
		}
	}
	
	UFUNCTION(NetFunction)
	void NetSetHonking(bool bStatus)
	{
		bPlayerIsHonking = bStatus;
	}

	bool CanHonk() const
	{
		if(CurrentMovementState == EPullBackCarMovementState::Respawning)
			return false;

		if(CurrentMovementState == EPullBackCarMovementState::Exploding)
			return false;

		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	private void DriverInteractionCompActivated(UInteractionComponent Component, AHazePlayerCharacter InteractedPlayer)
	{
		for (auto Player : Game::GetPlayers())
			DriverInteractComp.DisableForPlayer(Player, n"Driving");
		
		PlayerDrivingCar = InteractedPlayer;
		//InteractedPlayer.AddCapability(PullbackCarPlayerInputCapability);
		InteractedPlayer.AddCapabilitySheet(DriverSheet, EHazeCapabilitySheetPriority::Interaction, this);
		AddCarToPlayer(InteractedPlayer, this, true);
		// InteractedPlayer.SetCapabilityAttributeObject(n"PullbackCar", this);
		// InteractedPlayer.SetCapabilityActionState(n"DrivingCar", EHazeActionState::Active);
		// FHazeCameraBlendSettings Blend;
		// InteractedPlayer.ApplyCameraSettings(DriverCamSettings, Blend, this, EHazeCameraPriority::Medium);
		//InteractedPlayer.BlockCapabilities(CapabilityTags::CollisionAndOverlap, this);
		//PlayerDrivingCar = InteractedPlayer;
		//DriverAnimComp = UPullbackCarWindupCharacterAnimComponent::GetOrCreate(PlayerDrivingCar, n"PullbackCarWindupAnimComp");
		
		PullbackCarAudioDriverInteracted.Broadcast(true);

		if (InteractedPlayer == Game::GetCody())
		{
			InteractedPlayer.PlayerHazeAkComp.HazePostEvent(CodyGetInCarAudioEvent);
		}
		else if (InteractedPlayer == Game::GetMay())
		{
			InteractedPlayer.PlayerHazeAkComp.HazePostEvent(MayGetInCarAudioEvent);
		}
	}

	UFUNCTION(BlueprintPure)
	bool HasDriver() const
	{
		return PlayerDrivingCar != nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	void WindupPullcarInteractCompActivated(UInteractionComponent Component, AHazePlayerCharacter InteractedPlayer)
	{
		for (auto Player : Game::GetPlayers())
			WindupPullcarInteractComp.DisableForPlayer(Player, n"Pulling");

		PlayerPullingCar = InteractedPlayer;

		PlayerPullingCar.AddCapabilitySheet(PullerSheet, EHazeCapabilitySheetPriority::Interaction, this);
		AddCarToPlayer(PlayerPullingCar, this, false);

		if(HasControl())
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"InteractedPlayer", InteractedPlayer);
			CleanupCurrentMovementTrailFromControl(FHazeCrumbDelegate(this, n"Crumb_PullcarInteract"), CrumbParams);
		}

		SetCapabilityActionState(n"AudioGrabCar", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_PullcarInteract(FHazeDelegateCrumbData CrumbData)
	{
		PlayerPullingCar = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"InteractedPlayer"));
		if(PlayerPullingCar != nullptr)
			SetControlSide(PlayerPullingCar);

		if(PlayerPullingCar.HasControl())
		{
			auto PlayerCrumb = UHazeCrumbComponent::Get(PlayerPullingCar);
					
			FHazeDelegateCrumbParams CrumbParams;
			PlayerCrumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_ActivateWindup"), CrumbParams);	
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_ActivateWindup(const FHazeDelegateCrumbData& CrumbData)
	{
		CurrentMovementState = EPullBackCarMovementState::WindingUp;
	}

	UFUNCTION(NetFunction)
	void NetRequestPlayerExitDriverInteraction()
	{
		if(!HasControl())
			return;

		if(!CanManuallyExitAsDriver())
			return;
		
		FHazeDelegateCrumbParams CrumbParams;
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_RespondToDriverExitCarRequest"), CrumbParams);
	}

	bool CanManuallyExitAsDriver() const
	{
		if(PlayerDrivingCar == nullptr)
			return false;
		
		if(CurrentMovementState != EPullBackCarMovementState::Idle)
			return false;
		
		return true;
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_RespondToDriverExitCarRequest(const FHazeDelegateCrumbData& CrumbData)
	{
		if(PlayerDrivingCar != nullptr)
		{
			RemoveCarFromPlayer(PlayerDrivingCar, true);
			PlayerDrivingCar.SetCapabilityActionState(n"ManuallyExitCar", EHazeActionState::ActiveForOneFrame);
			PlayerDrivingCar = nullptr;
			for (auto Player : Game::GetPlayers())
				DriverInteractComp.EnableForPlayerAfterFullSyncPoint(Player, n"Driving");
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayerStoppedWindingUpCar()
	{
		if(PlayerPullingCar == nullptr)
			return;
		
		if(PlayerDrivingCar == nullptr)
		{
			BlockedJumpinPlayer = PlayerPullingCar.GetOtherPlayer();
			for (auto Player : Game::GetPlayers())
				DriverInteractComp.DisableForPlayer(Player, n"Driving");
		}

		if(!HasControl())
			return;

		FHazeDelegateCrumbParams CrumbParams;
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_RespondToPullerExitCarRequest"), CrumbParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_RespondToPullerExitCarRequest(const FHazeDelegateCrumbData& CrumbData)
	{
		if(PlayerPullingCar != nullptr)
		{
			RemoveCarFromPlayer(PlayerPullingCar, false);
			PlayerPullingCar = nullptr;
		}

		WindupDirection = FVector::ZeroVector;
		CurrentMovementState = EPullBackCarMovementState::Released;
		SetCapabilityActionState(n"AudioLaunchCar", EHazeActionState::ActiveForOneFrame);
	}

	void SetDriverFov(float NewLaunchedWindupAmount, float NewWindupAmountMax)
	{
		if (NewLaunchedWindupAmount == 0.f)
			return;

		CamFovMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(0.f, NewWindupAmountMax), FVector2D(1.f, NewWindupAmountMax), NewLaunchedWindupAmount);
		CamFovTimeline.SetPlayRate(1 / NewLaunchedWindupAmount);
		CamFovTimeline.PlayFromStart();
	}	

	UFUNCTION()
	void CamFovTimelineUpdate(float CurrentValue)
	{
		if (PlayerDrivingCar != nullptr)
		{
			FHazeCameraBlendSettings Blend;
			PlayerDrivingCar.ApplyFieldOfView(FMath::Lerp(CamDefaultFov, CamDefaultFov * CamFovMultiplier, CurrentValue), Blend, this);
		}
	}
}