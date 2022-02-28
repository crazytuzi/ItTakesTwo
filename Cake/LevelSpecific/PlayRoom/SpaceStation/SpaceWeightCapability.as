import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceWeightSpawner;

class USpaceWeightCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASpaceWeightSpawner WeightSpawner;
	UButtonMashProgressHandle MashHandle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WeightSpawner == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (WeightSpawner.bWeightPushed)
			return EHazeNetworkActivation::DontActivate;

		if (MashHandle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (MashHandle.MashRateControlSide < 2.f)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WeightSpawner == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (WeightSpawner.bWeightPushed)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (MashHandle == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (MashHandle.MashRateControlSide < 1.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.SmoothSetLocationAndRotation(WeightSpawner.PlayerAttachmentPoint.WorldLocation, WeightSpawner.PlayerAttachmentPoint.WorldRotation);

		UBlendSpace1D BlendSpace = Player.IsMay() ? WeightSpawner.MayBlendSpace : WeightSpawner.CodyBlendSpace;
		Player.PlayBlendSpace(BlendSpace);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.StopBlendSpace();

		if (MashHandle != nullptr)
			MashHandle.Progress = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		WeightSpawner = Cast<ASpaceWeightSpawner>(GetAttributeObject(n"SpaceWeightSpawner"));
		if (WeightSpawner == nullptr)
		{
			MashHandle = nullptr;
			return;
		}

		if (Player == Game::GetMay())
		{
			MashHandle = WeightSpawner.MayMashHandle;
		}
		else
		{
			MashHandle = WeightSpawner.CodyMashHandle;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		float NewProgress = MashHandle.Progress + (MashHandle.MashRateControlSide * 0.1f * DeltaTime);
		NewProgress = Math::Saturate(NewProgress);
		MashHandle.Progress = NewProgress;

		Player.SetBlendSpaceValues(NewProgress, 0.f);

		if (NewProgress == 1)
			WeightSpawner.PushWeight();
	}
}