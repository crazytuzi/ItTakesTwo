import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;
import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;

class UPlayerDropFlyingBombCameraCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	UBirdFlyingBombTrackerComponent TrackerComp;

	AFlyingBomb DroppedBomb;
	float Timer = 0.f;

	bool bInputBlocked = false;
	bool bPoIAssigned = false;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TrackerComp = UBirdFlyingBombTrackerComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (TrackerComp.FollowDroppedBomb != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (DroppedBomb == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (Timer <= 0.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Bomb", TrackerComp.FollowDroppedBomb);
		TrackerComp.FollowDroppedBomb = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DroppedBomb = Cast<AFlyingBomb>(ActivationParams.GetObject(n"Bomb"));

		if (DroppedBomb != nullptr)
		{
			if (DroppedBomb.DroppedBombCameraSettings != nullptr)
			{
				Player.ApplyCameraSettings(DroppedBomb.DroppedBombCameraSettings,
					FHazeCameraBlendSettings(DroppedBomb.DroppedBombPOIBlend), this);
			}

			FHazePointOfInterest Poi;
			Poi.FocusTarget.Component = DroppedBomb.RootComponent;
			Poi.Blend = DroppedBomb.DroppedBombPOIBlend;
			Player.ApplyPointOfInterest(Poi, this);

			Timer = FMath::Max(DroppedBomb.DroppedBombPOIDuration, DroppedBomb.DroppedBombInputBlockDuration);
			bPoIAssigned = true;

			if (DroppedBomb.DroppedBombInputBlockDuration > 0.f)
			{
				Player.BlockCapabilities(CapabilityTags::Input, this);
				bInputBlocked = true;
			}
		}
		else
		{
			Timer = 1.f;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		DroppedBomb = nullptr;

		if (bPoIAssigned)
		{
			Player.ClearCameraSettingsByInstigator(this);
			Player.ClearPointOfInterestByInstigator(this);
			bPoIAssigned = false;
		}

		if (bInputBlocked)
		{
			Player.UnblockCapabilities(CapabilityTags::Input, this);
			bInputBlocked = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Timer -= DeltaTime;

		if (bInputBlocked && ActiveDuration >= DroppedBomb.DroppedBombInputBlockDuration)
		{
			Player.UnblockCapabilities(CapabilityTags::Input, this);
			bInputBlocked = false;
		}

		if (bPoIAssigned && ActiveDuration >= DroppedBomb.DroppedBombPOIDuration)
		{
			Player.ClearCameraSettingsByInstigator(this);
			Player.ClearPointOfInterestByInstigator(this);
			bPoIAssigned = false;
		}

		if (DroppedBomb != nullptr
			&& DroppedBomb.CurrentState != EFlyingBombState::Falling
			&& DroppedBomb.CurrentState != EFlyingBombState::HeldByBird
			&& DroppedBomb.bDroppedBombRemovePoIOnExplode)
		{
			Timer = FMath::Min(Timer, DroppedBomb.DroppedBombPOIBlend);
		}
	}
}