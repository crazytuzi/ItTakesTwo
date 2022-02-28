import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagPlayerComp;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagCancelComp;
import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.TagStartingPoint;

class UTagPlayerOnInteractedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TagPlayerOnInteractedCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UTagCancelComp TagCancelComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		TagCancelComp = UTagCancelComp::Get(Player);
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
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.CleanupCurrentMovementTrail();

		Player.BlockCapabilities(MovementSystemTags::Jump, this);
		Player.BlockCapabilities(MovementSystemTags::AirJump, this);
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);

		TagCancelComp.ShowPlayerCancel(Player);
		
		ATagStartingPoint TagStartPoint = Cast<ATagStartingPoint>(TagCancelComp.TagStartingPointObj);
		
		if (TagStartPoint == nullptr)
			return;

		if (!HasControl())
			Player.SmoothSetLocationAndRotation(TagStartPoint.ActorLocation, TagStartPoint.ActorRotation, 1.f, 1.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		Player.UnblockCapabilities(MovementSystemTags::AirJump, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);	
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
    }
}