import Cake.LevelSpecific.SnowGlobe.WindWalk.DoublePull.WindWalkDoublePullActor;

class UWindWalkDoublePullPlayerHeadMotionCapability : UHazeCapability
{
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePull);
	default CapabilityTags.Add(WindWalkTags::WindWalkDoublePullPlayerHeadMotion);

	default TickGroup = ECapabilityTickGroups::Input;

	default CapabilityDebugCategory = WindWalkTags::WindWalk;

	AHazePlayerCharacter PlayerOwner;
	UHazeSmoothSyncFloatComponent SmoothNetHorizontalInput;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		SmoothNetHorizontalInput = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"WindWalkDoublePullHeadMotionSync");
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

		if(IsPlayerFalling())
			return EHazeNetworkActivation::DontActivate;

		if(!AreBothPlayersActivatingMagnet())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			SmoothNetHorizontalInput.Value = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw).X;

		PlayerOwner.SetAnimFloatParam(n"HorizontalInput", SmoothNetHorizontalInput.Value);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsPlayerFalling())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!AreBothPlayersActivatingMagnet())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	bool AreBothPlayersActivatingMagnet() const
	{
		return !PlayerOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger) && !PlayerOwner.OtherPlayer.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullRequireTrigger);
	}

	bool IsPlayerFalling() const
	{
		return PlayerOwner.IsAnyCapabilityActive(WindWalkTags::WindWalkDoublePullTumble);
	}
}