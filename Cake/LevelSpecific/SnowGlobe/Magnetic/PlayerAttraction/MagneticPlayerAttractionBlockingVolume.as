import Peanuts.Triggers.HazeTriggerBase;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

class AMagneticPlayerAttractionBlockingVolume : AHazeTriggerBase
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	TArray<EHazePlayer> PlayersInVolume;

	bool ShouldTrigger(AActor Actor) override
	{
		if(!Actor.IsA(AHazePlayerCharacter::StaticClass()))
			return false;

		if(UMagneticPlayerAttractionComponent::Get(Actor) == nullptr)
			return false;

		return true;
	}

	void EnterTrigger(AActor Actor) override
	{
		AHazePlayerCharacter PlayerCharacter = Cast<AHazePlayerCharacter>(Actor);
		PlayersInVolume.AddUnique(PlayerCharacter.Player);

		if(HasControl() && PlayersInVolume.Num() == 1)
			BlockMagneticPlayerAttraction();
	}

	void LeaveTrigger(AActor Actor) override
	{
		AHazePlayerCharacter PlayerCharacter = Cast<AHazePlayerCharacter>(Actor);
		PlayersInVolume.Remove(PlayerCharacter.Player);

		if(HasControl() && PlayersInVolume.Num() == 0)
			UnblockMagneticPlayerAttraction();
	}

	UFUNCTION(NetFunction)
	private void BlockMagneticPlayerAttraction()
	{
		UMagneticPlayerAttractionComponent::Get(Game::May).bIsDisabled = true;
		UMagneticPlayerAttractionComponent::Get(Game::Cody).bIsDisabled = true;
	}

	UFUNCTION(NetFunction)
	private void UnblockMagneticPlayerAttraction()
	{
		UMagneticPlayerAttractionComponent::Get(Game::May).bIsDisabled = false;
		UMagneticPlayerAttractionComponent::Get(Game::Cody).bIsDisabled = false;
	}
}