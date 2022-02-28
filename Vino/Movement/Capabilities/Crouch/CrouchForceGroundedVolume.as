import Vino.Movement.Capabilities.Crouch.CharacterCrouchComponent;

class ACrouchForceGroundedVolume : AVolume
{
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;
		
		UCharacterCrouchComponent CrouchComp = UCharacterCrouchComponent::Get(Player);
		if(CrouchComp != nullptr)
			CrouchComp.ForceGrounded();
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;
		
		UCharacterCrouchComponent CrouchComp = UCharacterCrouchComponent::Get(Player);
		if(CrouchComp != nullptr)
			CrouchComp.UnforceGrounded();
    }
}
