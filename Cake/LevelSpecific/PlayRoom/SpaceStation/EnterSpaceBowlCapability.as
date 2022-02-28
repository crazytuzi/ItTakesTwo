import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceBowl;

class UEnterSpaceBowlCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gravity");
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
    ASpaceBowl CurSpaceBowl;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"EnterSpaceBowl"))
            return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(n"EnterSpaceBowl", EHazeActionState::Inactive);
        Player.BlockCapabilities(CapabilityTags::Movement, this);
        CurSpaceBowl = Cast<ASpaceBowl>(GetAttributeObject(n"SpaceBowl"));
        Player.AttachToActor(CurSpaceBowl, AttachmentRule = EAttachmentRule::KeepWorld);
        Player.SmoothSetLocationAndRotation(CurSpaceBowl.ActorLocation, CurSpaceBowl.ActorRotation);
		Player.TriggerMovementTransition(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CurSpaceBowl.SpaceBowlLeft(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
	}
}