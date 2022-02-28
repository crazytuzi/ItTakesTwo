import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;

class UWaspFlyingRotationCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Flying");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 10.f;

    UWaspBehaviourComponent BehaviourComp;

    FHazeAcceleratedRotator AcceleratedRotation;
	UWaspComposableSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
        BehaviourComp = UWaspBehaviourComponent::Get(Owner);
		Settings = UWaspComposableSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Will only need to run on control side, remote side rotation will be 
		// handled by movement capability leaving crumbs
		if (HasControl())
		{
			FRotator TargetRotation = (BehaviourComp.MovementDestination - Owner.GetActorLocation()).Rotation(); 
			if (BehaviourComp.bHasFocus)
				TargetRotation = (BehaviourComp.FocusLocation - Owner.GetActorLocation()).Rotation();
			AcceleratedRotation.Value = Owner.GetActorRotation();
			AcceleratedRotation.AccelerateTo(TargetRotation, Settings.FlyingRotationDuration, DeltaSeconds);
			MoveComp.SetTargetFacingRotation(AcceleratedRotation.Value); 
		
			// Behaviour comp needs to have focus set every tick or it will revert to default
			BehaviourComp.bHasFocus = false;
		}
	}
};
