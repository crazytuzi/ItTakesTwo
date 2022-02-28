import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.BirdStar.BirdStarPlayerBirdComponent;
import Cake.LevelSpecific.Music.NightClub.RhythmActor;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.BirdStar.BirdStarBirdComponent;
class UBirdStarPlayerBirdOutputCapability : UHazeCapability

{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 30;

	UBirdStarPlayerBirdComponent PlayerBirdComp;
	UPlayerRhythmComponent PlayerRhythmComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		PlayerBirdComp = UBirdStarPlayerBirdComponent::Get(Owner);
		PlayerRhythmComp = UPlayerRhythmComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PlayerBirdComp.Bird != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlayerBirdComp.Bird == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UBirdStarBirdComponent BirdComponent = UBirdStarBirdComponent::GetOrCreate(PlayerBirdComp.Bird);
		BirdComponent.bTopHit = PlayerRhythmComp.bTopHit;
		BirdComponent.bLeftHit = PlayerRhythmComp.bLeftHit;
		BirdComponent.bRightHit = PlayerRhythmComp.bRightHit;
		BirdComponent.bIsCody = Player.IsCody();
	}
}