import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.HarpoonHarpSeal;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetHarpoonWater;
import Vino.Trajectory.TrajectoryDrawer;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Camera.Components.CameraUserComponent;

enum EHarpoonSpearState
{
	Still,
	ToOrigin,
	ToTarget
}

enum EHarpoonClawAnimState
{
	Closed,
	Open,
	Caught
}

enum EHarpoonRotationState
{
	Locked,
	Moving
}

class AMagnetHarpoonActor : AHazeActor
{
	EHarpoonSpearState HarpoonSpearState;
		
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkCompGun;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase HarpoonBaseSkel;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpearAttached;

	UPROPERTY(DefaultComponent, Attach = SpearAttached)
	UHazeSkeletalMeshComponentBase HarpoonSpearSkel;
	
	UPROPERTY(DefaultComponent, Attach = HarpoonSpearSkel)
	UHazeAkComponent AkCompHarpoon;

	UPROPERTY(DefaultComponent, Attach = HarpoonSpearSkel)
	USceneComponent HarpoonClawHoldingPosition;

	UPROPERTY(DefaultComponent, Attach = HarpoonSpearSkel)
	USceneComponent HarpoonSpearLineAttach;
	
	UPROPERTY(DefaultComponent, Attach = HarpoonBaseSkel)
	USceneComponent HarpoonSpearLineOrigin;

	UPROPERTY(DefaultComponent, Attach = HarpoonBaseSkel)
	UStaticMeshComponent HarpoonLineMesh;
	default HarpoonLineMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default HarpoonLineMesh.SetWorldScale3D(FVector(0.03f, 0.03f, 0.03f));
	FVector DefaultLineScale(0.03f, 0.03f, 0.03f); 

	UPROPERTY(DefaultComponent, Attach = HarpoonBaseSkel)
	USceneComponent AimPoint;

	UPROPERTY(DefaultComponent, Attach = HarpoonPlatform)
	UInteractionComponent InteractionComp;
	default InteractionComp.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent HazeDisableComp;

	UPROPERTY(DefaultComponent)
	UTrajectoryDrawer TrajectoryDrawer;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;

	UPROPERTY(Category = "States")
	EHarpoonClawAnimState HarpoonClawAnimState;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet HarpoonCapabilitySheet;

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem WaterSplash;

	UPROPERTY(Category = "Setup")
	AHarpoonHarpSeal HarpoonSeal;

	UPROPERTY(Category = "Setup")
	AMagnetHarpoonWater MagnetHarpoonWater;

	UPROPERTY(Category = "Setup")
	TArray<AMagnetFishActor> MagnetFishArray;

	UPROPERTY(Category = "Setup")
	AMagnetHarpoonActor OtherHarpoon;

	UPROPERTY()
	float YawInputCheckForSeal;

//*** ANIMATION VALUES ***//
	UPROPERTY()
	FHazeAcceleratedRotator HarpoonRotation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent PitchSyncComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent YawSyncComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent RotationSyncComp;

	FHazeAcceleratedFloat AccelPitch;
	FHazeAcceleratedFloat AccelYaw;
	float SealCamDot;

	float PitchInput;
	float YawInput;

	AHazePlayerCharacter UsingPlayer;

	UCameraUserComponent CameraUserComp;

	AMagnetFishActor CaughtFish;
	
	FVector StartLineLocation;
	FVector TraceEndPoint;
	FVector CameraEndPoint;
	FVector SpearTargetLocation;

	float CatchRadius = 90.f;
	float ShootDistance = 1600.f;
	float SpearSpeed = 3300.f;
	FHazeAcceleratedFloat AccelSpearSpeed;

	float SpearAudioSpeed;

	bool bGotCatch;
	private bool bHarpoonSpear;
	private bool bCanReleaseCatch;

	bool bSpearIsFiring;

	bool bPlayerReleasedCatch;

	bool bPlayedCurrentWaterSplash;
	bool bDidPlayEnterSplash;

	bool bWaitingForPending;

	UHarpoonPlayerComponent PlayerComp;

//*** AUDIO ***//
	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventShootingHarpoon;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventHarpoonReturn;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventStartHarpoonMovement;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventStopHarpoonMovement;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventReleaseCatch;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventStartGunMovement;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventStopGunMovement;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ClawSplashAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ClawCloseAudioEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpearAttached.AttachToComponent(HarpoonBaseSkel, n"SpearOrigin", EAttachmentRule::SnapToTarget);
		HarpoonSpearLineOrigin.AttachToComponent(HarpoonBaseSkel, n"SpearOrigin", EAttachmentRule::SnapToTarget);
		AimPoint.AttachToComponent(HarpoonBaseSkel, n"SpearOrigin", EAttachmentRule::SnapToTarget);

		if (HarpoonCapabilitySheet != nullptr)
			AddCapabilitySheet(HarpoonCapabilitySheet);

		InteractionComp.OnActivated.AddUFunction(this, n"PlayerInteracted");

		HarpoonLineMesh.SetScalarParameterValueOnMaterials(n"Slack", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetAimTrace();
		AimVisuals();
		LineFollowMesh();
		HarpoonClawWaterCheck();
		HarpoonClawHitSealCheck();
		AudioHarpoonSpeedRTCP(1.f);
	}

	UFUNCTION()
	void PlayerInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(n"HarpoonGun Interaction");
		OtherHarpoon.InteractionComp.DisableForPlayer(Player, n"OtherInUse");

		Player.SetCapabilityAttributeObject(n"MagnetHarpoon", this);
		Player.TriggerMovementTransition(this);
		Player.SmoothSetLocationAndRotation(InteractComp.WorldLocation, InteractComp.WorldRotation);

		UsingPlayer = Player;
		CameraUserComp = UCameraUserComponent::Get(UsingPlayer);

		if (PlayerCapabilitySheet != nullptr)
			Player.AddCapabilitySheet(PlayerCapabilitySheet);

		PlayerComp = UHarpoonPlayerComponent::Get(Player);

		if (PlayerComp == nullptr)
			return;

		if (PlayerComp.OnPlayerCancelledMagnetHarpoon.IsBound())
			PlayerComp.OnPlayerCancelledMagnetHarpoon.Clear();	
		
		PlayerComp.OnPlayerCancelledMagnetHarpoon.AddUFunction(this, n"PlayerCancelled"); 

		if (CaughtFish == nullptr)
			PlayerComp.MagnetHarpoonState = EMagnetHarpoonState::Default;

		SetControlSide(Player);
		HarpoonSeal.SetControlSide(Player);

		Player.AttachToComponent(HarpoonBaseSkel, NAME_None, EAttachmentRule::KeepWorld);
	}

	void HarpoonClawWaterCheck()
	{
		if (HarpoonSpearState == EHarpoonSpearState::ToTarget && HarpoonClawHoldingPosition.WorldLocation.Z <= MagnetHarpoonWater.ActorLocation.Z && !bPlayedCurrentWaterSplash)
		{
			bPlayedCurrentWaterSplash = true;
			Niagara::SpawnSystemAtLocation(WaterSplash, HarpoonClawHoldingPosition.WorldLocation, HarpoonClawHoldingPosition.WorldRotation);
			AkCompHarpoon.HazePostEvent(ClawSplashAudioEvent);
			AkCompHarpoon.SetRTPCValue("Rtpc_World_SideContent_Snowglobe_Interactions_MagnetHarpoon_WaterCheck", 1.f);
			bDidPlayEnterSplash = true;
		} 
		else if (HarpoonSpearState == EHarpoonSpearState::ToOrigin && HarpoonClawHoldingPosition.WorldLocation.Z >= MagnetHarpoonWater.ActorLocation.Z && !bPlayedCurrentWaterSplash && bDidPlayEnterSplash)
		{
			bPlayedCurrentWaterSplash = true;
			Niagara::SpawnSystemAtLocation(WaterSplash, HarpoonClawHoldingPosition.WorldLocation, HarpoonClawHoldingPosition.WorldRotation, FVector(0.4f));
			AkCompHarpoon.HazePostEvent(ClawSplashAudioEvent);
			AkCompHarpoon.SetRTPCValue("Rtpc_World_SideContent_Snowglobe_Interactions_MagnetHarpoon_WaterCheck", 0.f);
			bDidPlayEnterSplash = false;
		} 
	}

	void ResetWaterSplash()
	{
		bPlayedCurrentWaterSplash = false;
	}

	void HarpoonClawHitSealCheck()
	{
		if (HarpoonSpearState != EHarpoonSpearState::ToTarget)
			return;
			
		float Distance = (HarpoonSeal.ActorLocation - HarpoonClawHoldingPosition.WorldLocation).Size();

		if (Distance <= 80.f)
		{
			HarpoonSeal.SetOnHitSeal();
			HarpoonSpearState = EHarpoonSpearState::ToOrigin;
		}
	}

	void SetAimTrace()
	{
		FHazeTraceParams TraceParams;

		TraceParams.InitWithCollisionProfile(n"BlockAll");
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::WeaponTrace);
		TraceParams.SetToLineTrace();
		TraceParams.IgnoreActor(this);

		TraceParams.From = AimPoint.WorldLocation;
		TraceParams.To = AimPoint.WorldLocation + AimPoint.ForwardVector * ShootDistance;

		FHazeHitResult Hit;
		
		if (TraceParams.Trace(Hit))
		{
			if (Hit.Actor.ActorHasTag(n"IceFloe"))
				TraceEndPoint = Hit.ImpactPoint;
			else
				TraceEndPoint = Hit.ImpactPoint + (AimPoint.ForwardVector * 150.f);
		}
		else
		{
			TraceEndPoint = TraceParams.To;
		}

		if (PlayerComp != nullptr)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(PlayerComp.Owner);

			FVector Direction = TraceParams.To - TraceParams.From;
			Direction.Normalize();

			float Length = 0.f;

			if (TraceEndPoint != TraceParams.To)
				Length = (TraceEndPoint - TraceParams.To).Size() * 2.5f;
			else
				Length = ShootDistance * 1.3f;

			FVector Velocity = Direction * SpearSpeed;
		}
	}	

	UFUNCTION()
	void LineFollowMesh()
	{
		FVector Direction = HarpoonSpearLineAttach.WorldLocation - HarpoonLineMesh.WorldLocation;
		float Distance = Direction.Size() / 50.f;

		Direction.Normalize();
		FRotator Rotation = FRotator::MakeFromZ(Direction);
		HarpoonLineMesh.SetWorldRotation(Rotation);

		FVector NewScale(DefaultLineScale.X, DefaultLineScale.Y, Distance);

		HarpoonLineMesh.SetWorldScale3D(NewScale);

		FVector NewWorldLoc = (HarpoonSpearLineOrigin.WorldLocation + HarpoonSpearLineAttach.WorldLocation) / 2;
		HarpoonLineMesh.SetWorldLocation(NewWorldLoc);
	}

	void AimVisuals()
	{
		if (GetCatch())
			return;
	}
	
	void HarpoonSpearFired()
	{
		bWaitingForPending = true;
		HarpoonSpearState = EHarpoonSpearState::ToTarget;
	}

	UFUNCTION()
	void PlayerCancelled(AHazePlayerCharacter Player)
	{
		InteractionComp.EnableAfterFullSyncPoint(n"HarpoonGun Interaction");
		OtherHarpoon.InteractionComp.EnableForPlayerAfterFullSyncPoint(Player, n"OtherInUse");

		Player.RemoveCapabilitySheet(PlayerCapabilitySheet);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		PlayerComp = nullptr;
		UsingPlayer = nullptr;
		CameraUserComp = nullptr; 
	}

	void ReleaseCatch()
	{
		Print("ReleaseCatch");
		SetAnimBoolParam(n"FishReleased", true);
		bPlayerReleasedCatch = true;	
		// HarpoonSeal.bPlayerHasFish = false;	
	}

	void CompleteRelease()
	{
		bGotCatch = false;
		SetClawState(EHarpoonClawAnimState::Closed);
		AkCompHarpoon.HazePostEvent(ClawCloseAudioEvent);
		CaughtFish = nullptr;
	}

	bool GetCatch()
	{
		return bGotCatch;
	}
	
	bool GetCanRelease()
	{
		return bCanReleaseCatch;
	}

	void SetCanRelease(bool bCanRelease)
	{
		bCanReleaseCatch = bCanRelease;
	}

	UFUNCTION()
	void AttachFish(AMagnetFishActor MagnetFish)
	{
		CaughtFish = MagnetFish;
		CaughtFish.TriggerMovementTransition(this);
		CaughtFish.CatchFish();
		CaughtFish.AttachToComponent(HarpoonClawHoldingPosition, NAME_None, EAttachmentRule::SnapToTarget);

		HarpoonSeal.bPlayerHasFish = true;	
		SetClawState(EHarpoonClawAnimState::Caught);
		AkCompHarpoon.HazePostEvent(ClawCloseAudioEvent);
		HarpoonSpearState = EHarpoonSpearState::ToOrigin;
		bGotCatch = true;

		PlayerComp.MagnetHarpoonState = EMagnetHarpoonState::GotCatch;
	}

	void SetClawState(EHarpoonClawAnimState State)
	{
		HarpoonClawAnimState = State;
	}

	UFUNCTION(NetFunction)
	void NetCatchFish(AMagnetFishActor InFish)
	{
		AttachFish(InFish);
	}
	
	bool CanPendingFire() const
	{
		FVector ToCamDir = (CameraEndPoint - AimPoint.WorldLocation).GetSafeNormal();
		float Dot = AimPoint.ForwardVector.DotProduct(ToCamDir);
		return AimPoint.ForwardVector.DotProduct(ToCamDir) > 0.9995f;
	}

//*** AUDIO ***//

	//*** Harpoon ***//
	void AudioShootingHarpoon(AHazePlayerCharacter Player)
	{
		AkCompHarpoon.HazePostEvent(EventShootingHarpoon);
	}

	void AudioHarpoonReturn()
	{
		AkCompHarpoon.HazePostEvent(EventHarpoonReturn);
	}

	void AudioStartHarpoonMovement()
	{
		AkCompHarpoon.HazePostEvent(EventStartHarpoonMovement);
	}

	void AudioStopHarpoonMovement()
	{
		AkCompHarpoon.HazePostEvent(EventStopHarpoonMovement);
	}

	void AudioHarpoonSpeedRTCP(float Value)
	{
		AkCompHarpoon.SetRTPCValue("Rtcp_World_SideContent_SnowGlobe_Interactions_HarpoonMovement_Speed", Value);
	}

	void AudioReleaseCatch()
	{
		AkCompHarpoon.HazePostEvent(EventReleaseCatch);
	}

	//*** Harpoon ***//
	void AudioStartGunMovement()
	{
		AkCompGun.HazePostEvent(EventStartGunMovement);
	}

	void AudioStopGunMovement()
	{
		AkCompGun.HazePostEvent(EventStopGunMovement);
	}

	void AudioRTCPGunMovement(float Value)
	{
		AkCompGun.SetRTPCValue("Rtpc_World_SideContent_Snowglobe_Interactions_MagnetHarpoon_GunMovement", Value);
	}

}