import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Swimming.SwimmingSettings;
import Vino.Movement.Capabilities.Swimming.Stream.SwimmingStream;
import Vino.Movement.Capabilities.Swimming.SwimmingData;

import void SnowGlobeLakeTeamPlayerIsInWater(EHazePlayer Player, bool bStatus) from "Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeTeam";

UCLASS(Abstract)
class USnowGlobeSwimmingComponent: UActorComponent
{
	UPROPERTY(Category = Animation)
	UHazeLocomotionStateMachineAsset LocomotionAssetCody;

	UPROPERTY(Category = Animation)
	UHazeLocomotionStateMachineAsset LocomotionAssetMay;

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings; 
	
	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset VortexCameraSettings; 
	
	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset VortexDashCameraSettings; 

	UPROPERTY(Category = Camera)
	UHazeCameraSpringArmSettingsDataAsset StreamCameraSettings;

	UPROPERTY(Category = Data)
	TPerPlayer<USwimmingAudioData> AudioData;

	UPROPERTY(Category = Particles)
	UNiagaraSystem TrailsFX; 

	UPROPERTY(Category = Particles)
	UNiagaraSystem SplashFX; 

	UPROPERTY(Category = Particles)
	UNiagaraSystem BubblesFX; 
	
	UPROPERTY(Category = Gameplay)
	ESwimmingState SwimmingState = ESwimmingState::Inactive;

	UPROPERTY(Category = Gameplay)
	bool bIsBoosting = false; 	

	UPROPERTY(Category = Gameplay)
	bool bIsSwimmingForward = false; 

	bool bIsInWater = false;
	bool bWasActuallyInWater = false;
	bool bIsUnderwater = false;
	bool bFeatureAdded = false;
	bool bForceSurface = false;
	bool bForceUnderwater = false;

	int SwimmingScore = 0;

	float SplashSoundCooldown = 0.f;

	UPROPERTY()
	ESwimmingSpeedState SwimmingSpeedState = ESwimmingSpeedState::Normal;

	UPROPERTY()
	bool bVortexActive = false;
	FSwimmingVortexData ActiveVortexData;
	UPROPERTY()
	float VortexVerticalDirectionn = 0.f;
	UPROPERTY()
	float VerticalScale = 0.f;
	int VortexSafeVolumeCount = 0;

	UPROPERTY()
	FVector2D StreamInput;

	TArray<ASwimmingStream> NearbyStreams;
	ASwimmingStream ActiveStream;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset SurfaceCameraSettings;	

	// Swimming Speed Settings
	UPROPERTY()
	float DesiredSpeed = SwimmingSettings::Speed.DesiredMin;
	float DesiredDecayCooldown = 0.f;
	float DesiredLockCooldown = 0.f;
	float BlockSurfaceDuration = 0.f;

	UPROPERTY(Category = "Event Handlers")
	TArray<TSubclassOf<USwimmingEventHandler>> EventHandlerTypes;
	TArray<USwimmingEventHandler> EventHandlers;

	UFUNCTION(BlueprintPure)
	bool IsSwimmingActive()
	{
		if (bIsInWater || SwimmingState != ESwimmingState::Inactive)
			return true;
		
		return false;
	}

	void EnteredSwimmingVolume()
	{
		SwimmingScore += 1;
		CheckAndSetSwimming();
	}

	void LeftSwimmingVolume()
	{
		SwimmingScore -= 1;
		CheckAndSetSwimming();
	}

	void EnteredStopSwimmingVolume()
	{
		SwimmingScore -= 1;
		CheckAndSetSwimming();
	}

	void LeftStopSwimmingVolume()
	{
		SwimmingScore += 1;
		CheckAndSetSwimming();
	}

	void CheckAndSetSwimming()
	{
		if (SwimmingScore > 0 && !bIsInWater)
			SetInWater(true);
		else if (SwimmingScore <= 0 && bIsInWater)
			SetInWater(false);
	}

	void SetInWater(bool bInWater)
	{
		bIsInWater = bInWater;
		bWasActuallyInWater = bIsInWater;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player != nullptr)
		{
			SnowGlobeLakeTeamPlayerIsInWater(Player.Player, bIsInWater);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Spawn the event handlers!
		for(auto HandlerType : EventHandlerTypes)
		{
			auto Handler = Cast<USwimmingEventHandler>(NewObject(this, HandlerType));
			EventHandlers.Add(Handler);

			Handler.InitInternal(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Update a state so iceskating can know about swimming without importing comp
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		Player.SetCapabilityActionState(n"IsSwimming", IsSwimmingActive() ? EHazeActionState::Active : EHazeActionState::Inactive);

		if (SplashSoundCooldown > 0.f)
			SplashSoundCooldown -= DeltaTime;

		for(auto Handler : EventHandlers)
			Handler.OnTick(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		Player.SetCapabilityActionState(n"IsSwimming", EHazeActionState::Inactive);
	}

	void AddFeature(AHazePlayerCharacter Player)
	{
		if (!bFeatureAdded)
		{
			Player.AddLocomotionAsset(Player.IsCody() ? LocomotionAssetCody : LocomotionAssetMay, this);
			bFeatureAdded = true;
		}
	}

	void RemoveFeature(AHazePlayerCharacter Player)
	{
		if (bFeatureAdded)
		{
			Player.ClearLocomotionAssetByInstigator(this);
			bFeatureAdded = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		bWasActuallyInWater = false;
	}

	void UpdateSwimmingSpeedState()
	{
		ESwimmingSpeedState CurrentState = SwimmingSpeedState;

		if (DesiredSpeed > SwimmingSettings::Speed.DesiredCruise)
			SwimmingSpeedState = ESwimmingSpeedState::Cruise;
		else if (DesiredSpeed > SwimmingSettings::Speed.DesiredFast)
			SwimmingSpeedState = ESwimmingSpeedState::Fast;
		else
			SwimmingSpeedState = ESwimmingSpeedState::Normal;

		if (SwimmingSpeedState != CurrentState)
			CallOnSwimmingSpeedStateChanged(SwimmingSpeedState);
	}

	void PlaySplashSound(UHazeAkComponent PlayerAKComp, float Speed, ESplashType SplashType = ESplashType::Normal)
	{		
		if (SplashSoundCooldown > 0.f)
			return;

		if (PlayerAKComp == nullptr)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player == nullptr)
			return;

		UAkAudioEvent SplashEvent;
		switch (SplashType)
		{
			case ESplashType::Normal:
			{
				if (Speed > 2000.f)
					SplashEvent = AudioData[Player].PlayerSplashBreachApex;
				else 
					SplashEvent = AudioData[Player].PlayerSplashNormal;
				break;
			}
			case ESplashType::Breach:
			{
				SplashEvent = AudioData[Player].PlayerSplashBreachApex;
				break;
			}
			case ESplashType::Vortex:
			{
				SplashEvent = AudioData[Player].VortexEnteredFromAir;
				break;
			}
		}
		if (SplashEvent == nullptr)
			return;

		PlayerAKComp.HazePostEvent(SplashEvent);
		SplashSoundCooldown = 1.0f;
	}

	/* EVENTS */
	void CallOnDash()
	{
		for(auto Handler : EventHandlers)
			Handler.OnDash();
	}

	void CallOnEnteredUnderwater()
	{
		for(auto Handler : EventHandlers)
			Handler.OnEnteredUnderwater();
	}

	void CallOnExitedUnderwater()
	{
		for(auto Handler : EventHandlers)
			Handler.OnExitedUnderwater();
	}

	void CallOnEnteredSurface()
	{
		for(auto Handler : EventHandlers)
			Handler.OnEnteredSurface();
	}

	void CallOnExitedSurface()
	{
		for(auto Handler : EventHandlers)
			Handler.OnExitedSurface();
	}

	void CallOnSurfaceJump()
	{
		for(auto Handler : EventHandlers)
			Handler.OnSurfaceJump();
	}

	void CallOnSurfaceDive()
	{
		for(auto Handler : EventHandlers)
			Handler.OnSurfaceDive();
	}

	void CallOnMagnetBuoyStartedUsing()
	{
		for(auto Handler : EventHandlers)
			Handler.OnMagnetBuoyStartedUsing();
	}

	void CallOnMagnetBuoyStoppedUsing()
	{
		for(auto Handler : EventHandlers)
			Handler.OnMagnetBuoyStoppedUsing();
	}

	void CallOnSwimmingSpeedStateChanged(ESwimmingSpeedState NewSpeed)
	{
		for(auto Handler : EventHandlers)
			Handler.OnSwimmingSpeedStateChanged(NewSpeed);
	}
	/* EVENTS */
}

class USwimmingEventHandler : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	USnowGlobeSwimmingComponent SwimComp;

	UFUNCTION(BlueprintPure, Category = Swimming)
	USwimmingAudioData GetAudioData()
	{
		return SwimComp.AudioData[Player];
	}

	UFUNCTION(BlueprintPure, Category = Swimming)
	bool IsSwimmingActive()
	{
		return SwimComp.IsSwimmingActive();
	}

	UFUNCTION(BlueprintPure, Category = Swimming)
	bool IsUnderwater()
	{
		return SwimComp.bIsUnderwater;
	}

	UFUNCTION(BlueprintPure, Category = Swimming)
	bool IsInWater()
	{
		return SwimComp.bIsInWater;
	}

	UFUNCTION(BlueprintPure, Category = Swimming)
	ESwimmingState GetSwimmingState()
	{
		return SwimComp.SwimmingState;
	}

	UFUNCTION(BlueprintPure, Category = Swimming)
	ESwimmingSpeedState GetSwimmingSpeedState()
	{
		return SwimComp.SwimmingSpeedState;
	}

	void InitInternal(USnowGlobeSwimmingComponent Owner)
	{
		SetWorldContext(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner.Owner);
		SwimComp = Owner;

		BeginPlay();
	}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void BeginPlay() {}
	
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTick(float DeltaTime) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnDash() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnEnteredSurface() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnExitedSurface() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnEnteredUnderwater() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnExitedUnderwater() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSurfaceJump() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSurfaceDive() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnSwimmingSpeedStateChanged(ESwimmingSpeedState NewSpeed) {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetBuoyStartedUsing() {}

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetBuoyStoppedUsing() {}
}

enum ESplashType
{
	Normal,
	Breach,
	Vortex
}

enum ESwimmingState
{
	Inactive,
	Swimming,
	Dash,
	Breach,
	BreachDive,
	Surface,
	SurfaceDive,
	SurfaceJump,
	Stream,
	Vortex,
	VortexDash
}

struct FSwimmingDolphinComboData
{
	// 2500 is ish max speed atm, but maybe a bit too fast?
	UPROPERTY()
	float BoostSpeed = 1800.f;
	UPROPERTY()
	float CruiseSpeed = 1000.f;
}

struct FSwimmingVortexData
{
	UPROPERTY()
	FTransform VortexTransform;

	UPROPERTY()
	float CapsuleRadius;

	UPROPERTY()
	float CapsuleHalfHeight;

	UPROPERTY()
	float HardLimitMargin;
}

enum ESwimmingSpeedState
{
	Normal,
	Fast,
	Cruise
}