import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Peanuts.Outlines.Outlines;

class UCharacterChangeSizeBeltCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCharacterChangeSizeComponent ChangeSizeComp;

	UHazeSkeletalMeshComponentBase SizeBeltMeshComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
		// SizeBeltMeshComp = Player.AddExtraSkeletalMesh(ChangeSizeComp.SizeBeltMesh);
		AddMeshToPlayerOutline(SizeBeltMeshComp, Player, this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		RemoveMeshFromPlayerOutline(SizeBeltMeshComp, this);
		// Player.RemoveExtraSkeletalMesh(ChangeSizeComp.SizeBeltMesh);
    }
}