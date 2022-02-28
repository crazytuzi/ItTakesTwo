import Vino.Characters.AICharacter;

class UAICollisionEnableCapability : UHazeCollisionEnableCapability
{
	default CapabilityTags.Add(CapabilityTags::Collision);
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        AAICharacter Character = Cast<AAICharacter>(Owner);
		SetupCollisions(Character.CapsuleComponent, Trace::GetCollisionProfileName(Character.Deactivated));
	}
};