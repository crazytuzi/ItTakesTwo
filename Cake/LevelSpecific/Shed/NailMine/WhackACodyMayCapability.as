import Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent;
import Vino.Interactions.AnimNotify_Interaction;

//TODO:
// Add Additional VFX for Cody Hit.
//If disabling a turning hit, save Enum on comittment to atk, stop reading input for rotation/rotating while performing hit.

class UWhackACodyMayCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WhackACody");

	default CapabilityDebugCategory = n"WhackACody";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 30;

	UPROPERTY()
	EWhackACodyDirection MayPositionEnum = EWhackACodyDirection::Up;
	EWhackACodyDirection LastPosition = EWhackACodyDirection::Up;

	UPROPERTY()
	UWhackACodyComponent WhackaComp;

	FVector2D LeftStickInput;
	FRotator TargetRotation;

	AHazePlayerCharacter Player;
	FHazeAnimNotifyDelegate HitAnimDelegate;
	USceneComponent MayAttach;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WhackaComp = UWhackACodyComponent::Get(Player);
		if (WhackaComp.WhackABoardRef != nullptr)
			MayPositionEnum = WhackaComp.WhackABoardRef.CurrentCodyPositionEnum;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WhackaComp.WhackABoardRef == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.AttachToComponent(WhackaComp.WhackABoardRef.MayAttachPoint, NAME_None, EAttachmentRule::SnapToTarget);
		MayAttach = WhackaComp.WhackABoardRef.MayAttachPoint;

		Player.AddLocomotionFeature(WhackaComp.MayAnimFeature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}
}