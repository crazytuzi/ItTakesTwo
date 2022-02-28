import Peanuts.Triggers.PlayerTrigger;
import Vino.Movement.Capabilities.Crouch.CharacterCrouchComponent;

class AForceCrouchVolume : APlayerTrigger
{
	void EnterTrigger(AActor Actor) override
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		OnPlayerEnter.Broadcast(Player);

		UCharacterCrouchComponent CrouchComp = UCharacterCrouchComponent::GetOrCreate(Player);
		if (CrouchComp != nullptr)
			CrouchComp.EnteredForceCrouchVolume();
    }

	void LeaveTrigger(AActor Actor) override
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		OnPlayerLeave.Broadcast(Player);

		UCharacterCrouchComponent CrouchComp = UCharacterCrouchComponent::GetOrCreate(Player);
		if (CrouchComp != nullptr)
			CrouchComp.LeftForceCrouchVolume();
    }
}