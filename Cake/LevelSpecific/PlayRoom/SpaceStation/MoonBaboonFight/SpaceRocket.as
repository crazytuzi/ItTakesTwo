import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.SpaceRocketImpactComponent;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.Interactions.InteractionComponent;
import Vino.Camera.Components.WorldCameraShakeComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

event void FOnSpaceRocketExploded();

UCLASS(Abstract)
class ASpaceRocket : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RocketRoot;

	UPROPERTY(DefaultComponent, Attach = RocketRoot)
	UCapsuleComponent CollisionComp;

    UPROPERTY(DefaultComponent, Attach = RocketRoot)
    UStaticMeshComponent RocketMesh;

	UPROPERTY(DefaultComponent, Attach = RocketMesh)
	UArrowComponent ForwardDirection;

	UPROPERTY(DefaultComponent, Attach = RocketRoot)
	USceneComponent AttachmentPoint;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UInteractionComponent InteractionPoint;

	UPROPERTY(DefaultComponent, Attach = RocketRoot)
	UNiagaraComponent ThrusterEffect;

	UPROPERTY(DefaultComponent, Attach = RocketRoot)
	UCapsuleComponent PlayerCollision;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(DefaultComponent)
	UWorldCameraShakeComponent CamShakeComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bDisabledAtStart = true;

	UPROPERTY(DefaultComponent)
	UHazeNetworkControlSideInitializeComponent ControlSideComp;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RocketShotFiredEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RocketPlayerBoostEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RocketStopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ExplosionEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopFollowingPlayerAudioEvent;

	bool bMoving = false;

	float CurrentMovementSpeed = 600.f;
	float DefaultHomingSpeed = 600.f;
	float MaxHomingSpeed = 1200.f;
	float DefaultPlayerSpeed = 2000.f;

	FVector2D PlayerInput;

	TArray<AActor> ActorsToIgnoreWhenMounted;

	UPROPERTY()
	EHazePlayer PlayerToFollow;

	AHazePlayerCharacter TargetPlayer;
	AHazePlayerCharacter MountedPlayer;

	UPROPERTY(NotVisible)
	float FollowTime = 8.f;

	UPROPERTY(NotVisible)
	float ActiveTime = 12.f;
	
	FVector ClosestGroundLocation;

	UPROPERTY(NotVisible)
	bool bFollowingPlayer = false;
	
	FRotator TargetRotation;

	float RotationSpeed = 3.f;

	float CurrentPitch;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> RocketDamageEffect;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ExplosionEffect;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface BlinkingMaterial;
	UMaterialInterface DefaultMaterial;

	UPROPERTY()
	FOnSpaceRocketExploded OnSpaceRocketExploded;

	UPROPERTY(NotVisible)
	bool bDisabled = true;

	FTimerHandle FollowHandle;
	FTimerHandle RespawnHandle;
	FTimerHandle StartBlinkingHandle;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> ControlCapability;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DropTimeLike;
	FVector DropStartLocation;
	FVector DropEndLocation;
	FRotator DropStartRotation;
	FRotator DropEndRotation;

	bool bPermanentlyDisabled = false;
	bool bEverEnabled = false;

	bool bFirstTimeDropped = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MoveComp.Setup(CollisionComp);
		
		DefaultMaterial = RocketMesh.GetMaterial(0);

		TargetPlayer = PlayerToFollow == EHazePlayer::Cody ? Game::GetCody() : Game::GetMay();

		ActorsToIgnoreWhenMounted.Add(Game::GetCody());
		ActorsToIgnoreWhenMounted.Add(Game::GetMay());

		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		AddCapability(n"SpaceRocketMovementCapability");
		AddCapability(n"SpaceRocketHomingCapability");
		
		Capability::AddPlayerCapabilityRequest(ControlCapability.Get());

		ChangeSizeCallbackComp.OnCharacterChangedSize.AddUFunction(this, n"CodyChangedSize");

		DropTimeLike.BindUpdate(this, n"UpdateDrop");
		DropTimeLike.BindFinished(this, n"FinishDrop");
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(ControlCapability.Get());
	}

	UFUNCTION(NotBlueprintCallable)
	void CodyChangedSize(FChangeSizeEventTempFix Size)
	{
		if (Size.NewSize == ECharacterSize::Medium)
			InteractionPoint.EnableForPlayer(Game::GetCody(), n"Size");
		else
			InteractionPoint.DisableForPlayer(Game::GetCody(), n"Size");
	}

	void StartFollowingPlayer()
	{
		if (RocketShotFiredEvent != nullptr)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_HomingOrPlayerControl", 0);
			HazeAkComp.HazePostEvent(RocketShotFiredEvent);
		}

		if (InteractionPoint.IsDisabled(n"Exploded"))
			InteractionPoint.Enable(n"Exploded");
		if (!InteractionPoint.IsDisabled(n"Homing"))
			InteractionPoint.Disable(n"Homing");

		if (!bEverEnabled)
		{
			EnableActor(nullptr);
			bEverEnabled = true;
		}

		CleanupCurrentMovementTrail();

		SetActorHiddenInGame(false);
		RocketMesh.SetHiddenInGame(false);
		SetActorEnableCollision(true);
		// ThrusterEffect.Activate(true);
		bFollowingPlayer = true;
		bDisabled = false;
		
		if (HasControl())
		{
			ChangeControlSide(TargetPlayer);
		}

		if (TargetPlayer.HasControl())
		{
			FollowHandle = System::SetTimer(this, n"StopFollowingPlayer", FollowTime, false);
		}

		System::SetTimer(this, n"PlayThrusterEffect", 0.1f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayThrusterEffect()
	{
		ThrusterEffect.Activate(true);
	}

	void StartMovingRocket()
	{
		ThrusterEffect.Activate();
		bMoving = true;
		if (RocketPlayerBoostEvent != nullptr)
			HazeAkComp.HazePostEvent(RocketPlayerBoostEvent);
	}

	void UpdatePlayerInput(FVector2D Input)
	{	
		PlayerInput = Input;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bPermanentlyDisabled)
			return;

		if (bMoving && MountedPlayer != nullptr)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_Velocity", 0.f, 0);
			HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_HomingOrPlayerControl", 1, 0);

			if (MountedPlayer.HasControl())
			{
				FVector TraceLocation = ActorLocation + (ForwardDirection.ForwardVector * 150);
				FHitResult HitResult;
				System::BoxTraceSingle(TraceLocation, TraceLocation + FVector(0.1f, 0.f, 0.f), FVector(40.f, 40.f, 150.f), RocketMesh.WorldRotation, ETraceTypeQuery::Visibility, false, ActorsToIgnoreWhenMounted, EDrawDebugTrace::None, HitResult, true);
				
				HazeAudio::SetPlayerPanning(HazeAkComp, Cast<AHazeActor>(MountedPlayer));

				if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
				{
					bool bHitBoss = false;
					USpaceRocketImpactComponent ImpactComp = Cast<USpaceRocketImpactComponent>(HitResult.Actor.GetComponentByClass(USpaceRocketImpactComponent::StaticClass()));
					if (ImpactComp != nullptr)
					{
						bHitBoss = true;
						ImpactComp.HitByRocket();
					}
					
					if (!bHitBoss)
						NetPlayCollisionBark(MountedPlayer);

					NetTriggerExplosion();
				}
			}
		}

		if (bFollowingPlayer)
		{
			float SpeedAlpha = MoveComp.ActualVelocity.Size()/MaxHomingSpeed;
			SpeedAlpha = Math::Saturate(SpeedAlpha);
			HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_Velocity", SpeedAlpha, 0);
			HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_HomingOrPlayerControl", 0, 0);

			if (HasControl())
			{
				FVector TraceLocation = ActorLocation + (ActorForwardVector * 150);
				FHitResult HitResult;
				TArray<AActor> DummyIgnoreActors;
				TArray<EObjectTypeQuery> ObjectTypes;
				ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
				System::BoxTraceSingleForObjects(TraceLocation, TraceLocation + FVector(0.f, 0.f, 1.f), FVector(50.f, 50.f, 150.f), RocketMesh.WorldRotation, ObjectTypes, false, DummyIgnoreActors, EDrawDebugTrace::None, HitResult, true);

				if (HitResult.bBlockingHit)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(HitResult.Actor);
					if (Player != nullptr)
					{
						Player.KillPlayer();
						NetTriggerExplosion();
					}
				}
			}
		}

		FHitResult GroundHitResult;
		System::LineTraceSingle(ActorLocation, ActorLocation - (FVector(0.f, 0.f, 10000.f)), ETraceTypeQuery::Visibility, false, ActorsToIgnoreWhenMounted, EDrawDebugTrace::None, GroundHitResult, true);

		if (GroundHitResult.bBlockingHit)
		{
			ClosestGroundLocation = GroundHitResult.ImpactPoint;
		}

		// AUDIO IMPLEMENTATION FOR ACCELERATION/DECELERATION
		// HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_Velocity_Delta ", Speed, 0);
		
		float ElevationDirection = RocketRoot.WorldRotation.Pitch;
		HazeAkComp.SetRTPCValue("Rtpc_Vehicles_Rocket_Elevation_Direction", ElevationDirection, 0);
	}

	UFUNCTION()
	void StopFollowingPlayer()
	{
		FHazeDelegateCrumbParams Params;
		Params.AddVector(n"DropEndLoc", ClosestGroundLocation + FVector(0.f, 0.f, 35.f));
		Params.AddValue(n"DropEndRot", ActorRotation.Yaw);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_StopFollowingPlayer"), Params);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_StopFollowingPlayer(const FHazeDelegateCrumbData& CrumbData)
	{
		bFollowingPlayer = false;
		HazeAkComp.HazePostEvent(StopFollowingPlayerAudioEvent);

		DropStartLocation = ActorLocation;
		DropEndLocation = CrumbData.GetVector(n"DropEndLoc");
		DropStartRotation = ActorRotation;
		DropEndRotation = FRotator(0.f, CrumbData.GetValue(n"DropEndRot"), 0.f);

		DropTimeLike.PlayFromStart();
		ThrusterEffect.Deactivate();

		if (!bFirstTimeDropped)
		{
			bFirstTimeDropped = true;

			FHazePointOfInterest PoISettings;
			PoISettings.FocusTarget.Actor = this;
			PoISettings.FocusTarget.WorldOffset = FVector(0.f, 0.f, 150.f);
			PoISettings.Blend.BlendTime = 1.5f;
			TargetPlayer.ApplyPointOfInterest(PoISettings, this);
			TargetPlayer.ApplyIdealDistance(650.f, FHazeCameraBlendSettings(2.f), this);
			TargetPlayer.ApplyFieldOfView(60.f, FHazeCameraBlendSettings(2.f), this);
			TargetPlayer.ApplyCameraOffset(FVector(0.f, 120.f, 0.f), FHazeCameraBlendSettings(2.f), this);
			TargetPlayer.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, 150.f), FHazeCameraBlendSettings(2.f), this);
			if (TargetPlayer == Game::GetMay())
				System::SetTimer(this, n"MayRocketFirstTimeDropped", 1.5f, false);
			else
				System::SetTimer(this, n"CodyRocketFirstTimeDropped", 1.5f, false);
		}
	}

	UFUNCTION()
	void MayRocketFirstTimeDropped()
	{
		Game::GetMay().ClearPointOfInterestByInstigator(this);
		Game::GetMay().ClearIdealDistanceByInstigator(this, 3.f);
		Game::GetMay().ClearFieldOfViewByInstigator(this, 3.f);
		Game::GetMay().ClearCameraOffsetByInstigator(this, 3.f);
		Game::GetMay().ClearCameraOffsetOwnerSpaceByInstigator(this, 3.f);
	}

	UFUNCTION()
	void CodyRocketFirstTimeDropped()
	{
		Game::GetCody().ClearPointOfInterestByInstigator(this);
		Game::GetCody().ClearIdealDistanceByInstigator(this, 3.f);
		Game::GetCody().ClearFieldOfViewByInstigator(this, 3.f);
		Game::GetCody().ClearCameraOffsetByInstigator(this, 3.f);
		Game::GetCody().ClearCameraOffsetOwnerSpaceByInstigator(this, 3.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateDrop(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(DropStartLocation, DropEndLocation, CurValue);
		FRotator CurRot = FMath::LerpShortestPath(DropStartRotation, DropEndRotation, CurValue);
		SetActorTransform(FTransform(CurRot, CurLoc, FVector::OneVector));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishDrop()
	{
		BP_Wobble();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Wobble() {}

	UFUNCTION()
	void ActivateInteractionPoint()
	{
		InteractionPoint.Enable(n"Homing");
		if (HasControl())
			RespawnHandle = System::SetTimer(this, n"NetTriggerExplosion", ActiveTime, false);
	}

	UFUNCTION()
	void PermanentlyDisableRocket()
	{
		InteractionPoint.Disable(n"PermanentlyDisabled");
		bPermanentlyDisabled = true;
		BlockCapabilities(CapabilityTags::Movement, this);
		NetTriggerExplosion();
		DisableActor(this);
	}

	UFUNCTION(NetFunction)
	void NetPlayCollisionBark(AHazePlayerCharacter Player)
	{
		FName EventName = Player.IsMay() ? n"FoghornDBPlayRoomSpaceStationBossFightRocketFailMay" : n"FoghornDBPlayRoomSpaceStationBossFightRocketFailCody";
		VOBank.PlayFoghornVOBankEvent(EventName);
	}

	UFUNCTION(NotBlueprintCallable, NetFunction)
	void NetTriggerExplosion()
	{
		if (bDisabled)
			return;
			
		bMoving = false;
		bFollowingPlayer = false;
		bDisabled = true;
		if (MountedPlayer != nullptr)
			MountedPlayer.SetCapabilityActionState(n"ControlSpaceRocket", EHazeActionState::Inactive);
		MountedPlayer = nullptr;
		Niagara::SpawnSystemAtLocation(ExplosionEffect, CollisionComp.WorldLocation);
		OnSpaceRocketExploded.Broadcast();
		RocketMesh.SetHiddenInGame(true);
		SetActorEnableCollision(false);
		ThrusterEffect.Deactivate();
		CurrentMovementSpeed = DefaultHomingSpeed;
		System::ClearAndInvalidateTimerHandle(RespawnHandle);
		System::ClearAndInvalidateTimerHandle(FollowHandle);
		System::ClearAndInvalidateTimerHandle(StartBlinkingHandle);
		RocketMesh.SetMaterial(0, DefaultMaterial);
		InteractionPoint.Disable(n"Exploded");
		InteractionPoint.Enable(n"Mounted");
		CamShakeComp.Play();

		if(RocketStopEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(RocketStopEvent);
			HazeAkComp.HazePostEvent(ExplosionEvent);
		}
	}

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		if (!HasControl())
		{
			FHazeActorReplicationFinalized Data;
			CrumbComponent.ConsumeCrumbTrailMovement(GetActorDeltaSeconds(), Data);
		}

		CleanupCurrentMovementTrail();

		if (HasControl())
			ChangeControlSide(Player);

		MountedPlayer = Player;
		InteractionPoint.Disable(n"Mounted");
		Player.SetCapabilityAttributeObject(n"SpaceRocketActor", this);
		Player.SetCapabilityActionState(n"ControlSpaceRocket", EHazeActionState::Active);
		StartBlinkingHandle = System::SetTimer(this, n"StartBlinking", ActiveTime - 4.f, false);

		if (HasControl())
		{
			if (!bDisabled)
			{
				RespawnHandle = System::SetTimer(this, n"NetTriggerExplosion", ActiveTime, false);
			}
		}
    }

	void ChangeControlSide(AHazePlayerCharacter Player)
	{
		FHazeDelegateCrumbParams CrumbParams;

		CrumbParams.AddObject(n"PlayerToControl", Player);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbControlSideChange"), CrumbParams);
	}

	UFUNCTION()
	void CrumbControlSideChange(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"PlayerToControl"));
		SetControlSide(CrumbData.GetObject(n"PlayerToControl"));
	}

	UFUNCTION(NotBlueprintCallable)
	void StartBlinking()
	{
		RocketMesh.SetMaterial(0, BlinkingMaterial);
	}
}