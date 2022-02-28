import Vino.DoublePull.DoublePullComponent;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkTags;

class UWindWalkDoublePullMagnetChargeCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullMagnetCharge);

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AHazePlayerCharacter PlayerOwner;

	const float ChargeTime = 0.5;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UObject DoublePullObject = GetAttributeObject(n"DoublePull");
		if(DoublePullObject == nullptr)
			return EHazeNetworkActivation::DontActivate;

		UDoublePullComponent DoublePullComponent = Cast<UDoublePullComponent>(DoublePullObject);
		if(!DoublePullComponent.AreBothPlayersInteracting())
			return EHazeNetworkActivation::DontActivate;

		if(!PlayerOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger))
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.SetCapabilityActionState(WindWalkTags::MagnetCharging, EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;
		float RumbleValue = DeltaTime * ElapsedTime * 20.f;
		PlayerOwner.SetFrameForceFeedback(RumbleValue, RumbleValue);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(ElapsedTime >= ChargeTime)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		if(ElapsedTime >= ChargeTime)
			SyncParams.AddActionState(n"MagnetCharged");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.SetCapabilityActionState(WindWalkTags::MagnetCharging, EHazeActionState::Inactive);

		if(DeactivationParams.GetActionState(n"MagnetCharged"))
			PlayerOwner.SetCapabilityActionState(WindWalkTags::MagnetActivated, EHazeActionState::ActiveForOneFrame);

		ElapsedTime = 0.f;
	}
}