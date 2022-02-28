import Vino.DoublePull.DoublePullComponent;
import Vino.DoublePull.LocomotionFeatureDoublePull;
import Vino.DoublePull.DoublePullActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;

class UWindWalkDoublePullRequireTriggerCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullRequireTrigger);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(ActionNames::PrimaryLevelAbility))
	        return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetAnimBoolParam(n"DoublePullReleasedMagnet", true);
		Owner.SetAnimBoolParam(n"MagnetIsActive", false);

		auto DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		ADoublePullActor DoublePullActor = Cast<ADoublePullActor>(DoublePull.Owner);

		DoublePullActor.SetCapabilityActionState(n"DoublePullForceGoBack", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(WindWalkTags::MagnetActivated))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.SetAnimBoolParam(n"DoublePullReleasedMagnet", false);
		Owner.SetAnimBoolParam(n"MagnetIsActive", true);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (!Player.OtherPlayer.IsAnyCapabilityActive(n"WindWalkRequireTrigger"))
		{
			auto DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
			ADoublePullActor DoublePullActor = Cast<ADoublePullActor>(DoublePull.Owner);
			DoublePullActor.SetCapabilityActionState(n"DoublePullForceGoBack", EHazeActionState::Inactive);
		}
	}
};