import Vino.Checkpoints.Checkpoint;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortal;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePortalComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;

class ASpaceStationLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	USpacestationVOBank VOBank;

	UFUNCTION()
	void ResetPlayersAfterGeneratorActivation(ACheckpoint Checkpoint)
	{
		Game::GetMay().SetCapabilityActionState(n"ResetGravityBoots", EHazeActionState::Active);
		
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(CapabilityTags::Interaction, this);
			Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		}

		Game::GetCody().SetCapabilityActionState(n"ForceResetSize", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION()
	void PlaySpaceStationBark(AHazePlayerCharacter Player, FName MayEventName, FName CodyEventName)
	{
		FName EventName = Player.IsMay() ? MayEventName : CodyEventName;
		VOBank.PlayFoghornVOBankEvent(EventName);
	}
}