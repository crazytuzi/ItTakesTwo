import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.RotatingLever;

class URotatingLeverCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	bool bStop = false;

	AHazePlayerCharacter Player;
	ARotatingLever RotatingLever;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (RotatingLever != nullptr)
			return EHazeNetworkActivation::ActivateLocal;
		
		else
			return EHazeNetworkActivation::DontActivate;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bStop)
		{
		    return EHazeNetworkDeactivation::DeactivateFromControl;
		}
        else
		{
            return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bStop = false;
		Player.BlockCapabilities(n"Movement", this);
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), RotatingLever.AnimationToUse, true);
		Player.AttachToComponent(RotatingLever.RotationRoot, n"", EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RotatingLever.LeverDeActivated();
		RotatingLever = nullptr;
		Player.UnblockCapabilities(n"Movement", this);
		Player.StopAllSlotAnimations();
		Player.DetachFromActor(EDetachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject Lever;
		if (ConsumeAttribute(n"RotatingLever", Lever))
		{
			RotatingLever = Cast<ARotatingLever>(Lever);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
		FVector LeftStickVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
		RotatingLever.LeftStickInput(LeftStickVector);
		
		if (IsActioning(ActionNames::Cancel))
		{
			bStop = true;
		}
			
	}

}