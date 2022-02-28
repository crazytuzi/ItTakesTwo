import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;
import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticComponent;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

class UParentBlobKinematicPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"ParentBlobButtonHold");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	float MayHoldProgress = 0.f;
	float CodyHoldProgress = 0.f;
	float TotalHoldProgress = 0.f;

	AHazePlayerCharacter Player;
	UParentBlobKineticComponent InteractionComponent;
	UParentBlobPlayerComponent ParentBlobComponent;
	AParentBlob ParentBlob;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ParentBlobComponent = UParentBlobPlayerComponent::Get(Player);
		ParentBlob = ParentBlobComponent.ParentBlob;
		InteractionComponent = UParentBlobKineticComponent::Get(ParentBlob);
		SetMutuallyExclusive(n"ParentBlobButtonHold", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		SetMutuallyExclusive(n"ParentBlobButtonHold", false);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
		 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
		 	return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FParentBlobKineticPlayerInputData& PlayerData = InteractionComponent.PlayerInputData[Player.Player];
		PlayerData.bIsHolding = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FParentBlobKineticPlayerInputData& PlayerData = InteractionComponent.PlayerInputData[Player.Player];
		PlayerData.bIsHolding = false;
	}
}